# Example Project — AI Coding Platform

Example application repository that demonstrates how to structure a project for the [AI Coding Platform](https://github.com/jmlopezdona/ai-coding-platform-infra).

## Structure

```
apps/
  backend/             Node.js/Express REST API (postgres + redis)
    Dockerfile
    src/server.js
  frontend/            Static app served by nginx
    Dockerfile
    nginx.conf
    src/index.html

helm/
  stack-chart/         Helm chart defining how this app deploys
    templates/         K8s resource templates (deployments, services, etc.)
    projects/          Environment-specific value overrides
    values.yaml        Default configuration

skaffold.yaml          Build and sync configuration for Skaffold
```

## How it works

When the platform creates an execution environment for a Delivery Cycle:

1. The platform's env-chart creates a dev pod with a Skaffold sidecar
2. The Skaffold sidecar renders `$VAR` placeholders in `skaffold.yaml` and runs `skaffold dev --profile=cluster`
3. The `cluster` profile switches from local Docker builds to Kaniko (in-cluster) and uses ECR as the registry
4. Skaffold builds the images, deploys the stack using `helm/stack-chart`, and starts watching for changes
5. When the agent modifies source files, Skaffold detects changes via inotify and syncs them to the running pods

### Skaffold profiles

| Profile | Build | Registry | Activated by |
|---|---|---|---|
| (default) | Local Docker | `--default-repo` flag | `skaffold dev` on your machine |
| `cluster` | Kaniko (in-cluster) | `$SKAFFOLD_DEFAULT_REPO` (ECR) | Platform sidecar (`--profile=cluster`) |

### Platform-provided env vars

The `cluster` profile uses these variables (rendered by the platform before Skaffold starts):

| Variable | Description |
|---|---|
| `$DC_ID` | Delivery Cycle identifier |
| `$DC_BRANCH` | Git branch |
| `$SKAFFOLD_DEFAULT_REPO` | ECR registry prefix |
| `$SKAFFOLD_NAMESPACE` | Target K8s namespace |

## Requirements for app pods

See the platform's [implementation guide](https://github.com/jmlopezdona/ai-coding-platform-infra#guide-implementing-application-pods) for the full list. Key points:

### App pods with file sync must run as root

Skaffold sync uses `kubectl exec + tar` to copy files. The container must run as root for tar to have write permissions.

```yaml
# In deployment templates for pods that receive file sync
spec:
  securityContext:
    runAsUser: 0
```

### Enable hot reload

Without hot reload, synced files have no effect until the pod restarts.

```dockerfile
# Use nodemon for Node.js
CMD ["npx", "nodemon", "--watch", "src/", "src/server.js"]
```

### All containers need resource requests/limits

The namespace has a ResourceQuota. Pods without resources will fail to schedule.

### App pods must tolerate spot nodes

```yaml
nodeSelector:
  role: app
tolerations:
  - key: "spot"
    value: "true"
    effect: "NoSchedule"
```

## Local development

```bash
# Run locally with Skaffold (requires Docker + kubectl)
skaffold dev --default-repo=registry.internal

# Port forwards: backend → localhost:8080, frontend → localhost:3000
```
