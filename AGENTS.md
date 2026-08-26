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

- AWS deployment is always manual in this repository.
- Do not add CI/CD, hosted build pipelines, registry pushes, automatic
  deployment hooks, or Kubernetes.
- Do not use Nginx as the default AWS application deployment layer.
- AWS ALB owns external HTTPS, host routing, health checks, and load balancing.
- The production-like application container should be Spring Boot once the
  backend exists.
- Spring Boot should serve both `/api/*` and the built Vue static assets in the
  default AWS demo strategy.
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
- The AWS deployment path should use `.fordeploy/aws-backup/` as the local
  staging and backup area for deployment-time files that must not live in the
  application source tree.
- Local Docker images for AWS deployment should be built locally from a clean
  clone or another explicitly selected source directory, saved as tarballs, and
  transferred to AWS through the Bastion/private-host path.
- Image tarballs are transfer artifacts only. They must not be committed and
  should be deleted locally and remotely after the script has loaded the image
  on the target host.
- Environment files, credential files, and copied runtime files must be
  excluded from Git and must also be excluded from Docker build contexts and
  final Docker images.
- The deployment script must treat `.fordeploy/aws-backup/` paths as local
  absolute paths before copying anything to AWS. Do not rely on the caller's
  current directory for secret or backup file resolution.
- During script execution, before copying any file from
  `.fordeploy/aws-backup/` to the AWS host, the script must print the source
  absolute path, destination host, and destination absolute path, then ask for a
  terminal confirmation using a clear `y/N` prompt.
- If the operator answers anything other than `y` or `Y`, the script must skip
  that file transfer or abort the requested credential/bootstrap step without
  treating it as a deployment failure.
- The script must never print the contents of environment files or credential
  files. It may print filenames, byte sizes, checksums, timestamps, and target
  paths.
- AWS-side destination paths for copied runtime files should live under the
  repository-specific runtime root, such as `/home/ubuntu/vueshines`, and image
  archives should live only temporarily under a repository-specific image root,
  such as `/home/ubuntu/docker_images/vueshines`.

## Script Deployment Strategy

- Place deployment scripts under `.fordeploy/`.
- Keep scripts readable, conservative, and idempotent where practical.
- Use `set -euo pipefail` in shell scripts.
- Make image names, tags, container names, ports, remote paths, and health check
  paths configurable through environment variables with safe defaults.
- Print each major step before executing it: build, save, transfer, load,
  replace, health check, cleanup.
- Never print secrets or full env files.
- Do not commit generated image archives, copied env files, or credential
  files.
- A script may replace the `frontend` and `backend` containers.
- A script must not remove MySQL or Redis volumes unless it is explicitly named
  and documented as a destructive development reset script.
- For remote hosts behind a Bastion, prefer the same shape as neighboring
  repositories: build locally, copy image tar to Bastion, copy to private host,
  load, replace, verify.
- Keep manual runbook documentation beside scripts in `.fordeploy/README.md`.
- Scripts that need runtime env files should support an explicit bootstrap step
  rather than silently copying local files.
- A bootstrap step should read candidate files from `.fordeploy/aws-backup/`,
  resolve them to absolute local paths, show the planned AWS destination, and
  require `y/N` confirmation for each transfer.
- Scripts should separate app image deployment from secret/runtime-file
  transfer. Re-deploying an application image should not overwrite a target
  host env file unless the operator explicitly confirms that overwrite.
- Scripts should fail fast when required runtime files are missing on AWS, but
  the failure message should describe the expected target path instead of
  dumping local secret contents.

## Secrets And Runtime Files

- Never include `.env`, `.env.local`, private keys, or secret files in Docker
  images.
- Runtime env files belong on the target host.
- Repository examples may include `.env.example` only with non-secret local
  defaults.
- `.fordeploy/aws-backup/` is a local staging and backup area for AWS runtime
  configuration material, not application source. It may contain local copies
  or templates used to prepare target-host runtime files.
- Real files under `.fordeploy/aws-backup/` must be ignored by Git by default.
  Commit only deliberate documentation or sanitized examples such as
  `.env.example`, `*.example`, or `README.md`.
- Docker build contexts must exclude `.fordeploy/` so that env files,
  credentials, tarballs, and local runtime material cannot be copied into an
  image accidentally.
- Do not move local database dumps or local database files to AWS as part of
  this repository's deployment flow. AWS database state should be created and
  managed on the AWS side through migrations, seed data, or target-host
  database administration.
- When a script copies an env file or credential file from
  `.fordeploy/aws-backup/` to AWS, it must use the local absolute path and ask
  the operator for `y/N` confirmation in the terminal before transfer.
- Target-host env files should be placed under the application runtime root,
  for example `/home/ubuntu/vueshines/.env`, and mounted or read at container
  runtime. They should not be baked into the image.
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
