FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev 2>/dev/null || npm install --omit=dev
COPY src/ ./src/
EXPOSE 8080
# Note: USER node is omitted in dev environments to allow Skaffold file sync
# (sync uses kubectl exec + tar which requires write permissions)
CMD ["node", "src/server.js"]
