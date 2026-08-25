# Vueshines Agent Instructions

Before making UI changes in this repository, read and follow `DESIGN.md`.

This project is a small LMS practice application that connects Vue 3, Kotlin
Spring Boot, Redis, MySQL, and Docker Compose. Keep the project focused on the
learning flow described in `docs/plan.md`.

## Work Scope

- Preserve the monorepo shape: Vue at the repository root and Spring Boot under
  `backend/`.
- Do not split the project into multiple repositories.
- Do not introduce Kafka, RabbitMQ, Kubernetes, Elasticsearch, GraphQL,
  WebSocket, payment, real video streaming, or complex authentication unless
  the implementation plan is explicitly changed.
- Prefer simple, explicit code over broad abstractions.
- Use existing Vue, Pinia, Vue Router, Vite, Spring Boot, JPA, Redis, and MySQL
  patterns before adding new dependencies.
- Keep frontend state rules clear: local UI state in components, shared state
  in Pinia, persistence and business rules in the backend.

## Implementation Order

- Treat `docs/plan.md` as the source implementation plan.
- Implement work in small, verifiable turns.
- Complete the base LMS flow before adding Redis behavior:
  course API, course UI, lecture routing, enrollment, simulator, progress.
- Add Redis only where it has a defined reason:
  course cache and progress buffering.
- After each meaningful turn, verify the relevant endpoint or browser flow.

## Local Runtime

- Docker Compose is the default full-runtime path.
- Compose should run one container per role:
  `frontend`, `backend`, `mysql`, and `redis`.
- The frontend container runs the Vue/Vite development server on port `5173`.
- The backend container runs Spring Boot on port `8080`.
- MySQL is exposed on `3306` for local inspection.
- Redis is exposed on `6379` for local inspection.
- Backend-to-service connections must use Compose service names:
  `mysql:3306` and `redis:6379`.
- Browser-to-backend calls should use `http://localhost:8080` in local
  development.

## Manual Deployment Strategy

- Deployment is manual unless the maintainer explicitly introduces automation.
- Do not add CI/CD, hosted build pipelines, registry pushes, or Kubernetes.
- Runtime deployment must use Docker.
- Keep application containers separate from data containers.
- A normal application redeploy must replace only the frontend/backend
  application containers and must not recreate MySQL or Redis volumes.
- Build images from a clean source state when preparing a remote deployment.
- Export images as `.tar` files for transfer when following the neighboring
  project style.
- Load the image on the target host and replace containers with explicit Docker
  or Docker Compose commands.
- Verify deployment with health checks after container replacement:
  frontend HTTP, backend `/api/health`, MySQL connection, Redis connection.
- Keep deployment commands target-specific. Script names should make the target
  obvious, such as `deploy-dev-demo.sh` or `deploy-aws-demo.sh`.

## Script Deployment Strategy

- Place deployment scripts under `.fordeploy/`.
- Keep scripts readable, conservative, and idempotent where practical.
- Use `set -euo pipefail` in shell scripts.
- Make image names, tags, container names, ports, remote paths, and health check
  paths configurable through environment variables with safe defaults.
- Print each major step before executing it: build, save, transfer, load,
  replace, health check, cleanup.
- Never print secrets or full env files.
- Do not commit generated image archives, copied env files, database dumps, or
  credential files.
- A script may replace the `frontend` and `backend` containers.
- A script must not remove MySQL or Redis volumes unless it is explicitly named
  and documented as a destructive development reset script.
- For remote hosts behind a Bastion, prefer the same shape as neighboring
  repositories: build locally, copy image tar to Bastion, copy to private host,
  load, replace, verify.
- Keep manual runbook documentation beside scripts in `.fordeploy/README.md`.

## Secrets And Runtime Files

- Never include `.env`, `.env.local`, private keys, database dumps, or secret
  files in Docker images.
- Runtime env files belong on the target host.
- Repository examples may include `.env.example` only with non-secret local
  defaults.
- Local learning credentials such as `vueshines/vueshines` are acceptable only
  for Docker Compose development and must be documented as local-only.
- Persistent database data must live in Docker volumes or target-host runtime
  directories, not in the application image.

## Frontend Guidance

- Follow `DESIGN.md` before making UI changes.
- Build the actual LMS workflow as the first screen, not a marketing landing
  page.
- Keep the interface calm, readable, and study-focused.
- Use responsive layouts for desktop, narrow desktop, and mobile.
- Do not use neo-brutalism for this project.
- Do not use decorative gradients, glassmorphism, oversized hero layouts, or
  playful visual noise.

## Verification

- For frontend changes, run the available type check, lint, or build command
  when feasible.
- For backend changes, run focused tests or at least verify the changed
  endpoint with the application running.
- For Docker changes, verify `docker compose up` and the health endpoints.
- For Redis behavior, confirm cache HIT/MISS and progress buffer keys.
- For MySQL behavior, confirm seed data, constraints, and progress persistence.

