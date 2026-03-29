const express = require("express");
const { Pool } = require("pg");
const { createClient } = require("redis");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;

// --- Postgres -----------------------------------------------------------
const pool = new Pool({
  host: process.env.POSTGRES_HOST || "postgres",
  port: Number(process.env.POSTGRES_PORT) || 5432,
  database: process.env.POSTGRES_DB || "testdb",
  user: process.env.POSTGRES_USER || "postgres",
  password: process.env.POSTGRES_PASSWORD || "test",
});

// --- Redis --------------------------------------------------------------
const redis = createClient({
  url: `redis://${process.env.REDIS_HOST || "redis"}:${process.env.REDIS_PORT || 6379}`,
});
redis.on("error", (err) => console.error("Redis error:", err));

// --- DB bootstrap -------------------------------------------------------
async function bootstrap() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS items (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);
}

// --- Routes -------------------------------------------------------------

// Health & readiness (both /healthz and /api/healthz for probe + proxy access)
app.get(["/healthz", "/api/healthz"], (_req, res) => res.json({ status: "ok" }));

app.get(["/readyz", "/api/readyz"], async (_req, res) => {
  try {
    await pool.query("SELECT 1");
    await redis.ping();
    res.json({ status: "ready", postgres: "ok", redis: "ok" });
  } catch (err) {
    res.status(503).json({ status: "not ready", error: err.message });
  }
});

// Platform info — useful to verify env vars are injected correctly
app.get("/api/info", (_req, res) => {
  res.json({
    service: "example-backend",
    dcId: process.env.DC_ID || "unknown",
    dcBranch: process.env.DC_BRANCH || "unknown",
    nodeVersion: process.version,
    uptime: process.uptime(),
  });
});

// CRUD items — exercises postgres
app.get("/api/items", async (_req, res) => {
  const { rows } = await pool.query("SELECT * FROM items ORDER BY id");
  res.json(rows);
});

app.post("/api/items", async (req, res) => {
  const { name } = req.body;
  if (!name) return res.status(400).json({ error: "name is required" });
  const { rows } = await pool.query(
    "INSERT INTO items (name) VALUES ($1) RETURNING *",
    [name]
  );
  // Invalidate cache
  await redis.del("items:count");
  res.status(201).json(rows[0]);
});

app.delete("/api/items/:id", async (req, res) => {
  await pool.query("DELETE FROM items WHERE id = $1", [req.params.id]);
  await redis.del("items:count");
  res.status(204).end();
});

// Counter — exercises redis caching
app.get("/api/items/count", async (_req, res) => {
  let count = await redis.get("items:count");
  if (count === null) {
    const { rows } = await pool.query("SELECT COUNT(*) FROM items");
    count = rows[0].count;
    await redis.set("items:count", count, { EX: 60 });
  }
  res.json({ count: Number(count), cached: count !== null });
});

// --- Start --------------------------------------------------------------
async function main() {
  await redis.connect();
  await bootstrap();
  app.listen(PORT, () => console.log(`Backend listening on :${PORT}`));
}

main().catch((err) => {
  console.error("Failed to start:", err);
  process.exit(1);
});
