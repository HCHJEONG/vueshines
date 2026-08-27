#!/usr/bin/env bash
set -euo pipefail

: "${APP_NAME:=vueshines}"
: "${IMAGE_NAME:=vueshines}"
: "${REPO_URL:=https://github.com/HCHJEONG/vueshines.git}"
: "${DEPLOY_REF:=main}"
: "${CLEAN_CLONE_ROOT:=/home/hchjeong/deploy-remote-repo}"
: "${AWS_DEMO_HOST:=aws-demo}"
: "${REMOTE_APP_DIR:=/home/ubuntu/vueshines}"
: "${REMOTE_IMAGE_DIR:=/home/ubuntu/docker_images/vueshines}"
: "${REMOTE_OWNER:=ubuntu}"
: "${REMOTE_GROUP:=ubuntu}"
: "${HOST_PORT:=8180}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKING_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
LOCAL_ENV_FILE="${WORKING_ROOT}/.fordeploy/aws-backup/.env"
LOCAL_COMPOSE_FILE="${WORKING_ROOT}/.fordeploy/compose.aws-demo.yaml"
CLEAN_CLONE_DIR="${CLEAN_CLONE_ROOT}/${APP_NAME}"
LOCAL_IMAGE_DIR="${CLEAN_CLONE_ROOT}/images/${APP_NAME}"
REMOTE_ENV_FILE="${REMOTE_APP_DIR}/.env"
REMOTE_COMPOSE_FILE="${REMOTE_APP_DIR}/compose.aws-demo.yaml"
LOCAL_IMAGE_FILE=""
IMAGE=""

log() { printf '[vueshines aws-demo] %s\n' "$*"; }
fail() { printf '[vueshines aws-demo] ERROR: %s\n' "$*" >&2; exit 1; }

confirm() {
  local answer
  read -r -p "$1 [y/N] " answer
  [ "$answer" = "y" ] || [ "$answer" = "Y" ]
}

cleanup() {
  [ -z "$LOCAL_IMAGE_FILE" ] || rm -f -- "$LOCAL_IMAGE_FILE"
}
trap cleanup EXIT

require_local_files() {
  [ -f "$LOCAL_ENV_FILE" ] || fail "required env file is missing: $LOCAL_ENV_FILE"
  [ -f "$LOCAL_COMPOSE_FILE" ] || fail "AWS Compose file is missing: $LOCAL_COMPOSE_FILE"

  local required_keys=(
    SPRING_PROFILES_ACTIVE SERVER_PORT APP_SEARCH_INDEXING_ENABLED
    DB_APP_PASSWORD DB_ROOT_PASSWORD
    SPRING_DATASOURCE_URL SPRING_DATASOURCE_USERNAME
    SPRING_DATA_REDIS_HOST SPRING_DATA_REDIS_PORT
    MYSQL_DATABASE MYSQL_USER
  )
  local key
  for key in "${required_keys[@]}"; do
    grep -Eq "^${key}=.+" "$LOCAL_ENV_FILE" || fail "required env key is missing or empty: $key"
  done
}

validate_clone_path() {
  local resolved_root resolved_parent clone_name
  resolved_root="$(realpath "$CLEAN_CLONE_ROOT")"
  resolved_parent="$(realpath -m "$(dirname -- "$CLEAN_CLONE_DIR")")"
  clone_name="$(basename -- "$CLEAN_CLONE_DIR")"

  [ "$resolved_root" = "/home/hchjeong/deploy-remote-repo" ] || fail "unexpected clean clone root: $resolved_root"
  [ "$resolved_parent" = "$resolved_root" ] || fail "clean clone must be directly under build root: $CLEAN_CLONE_DIR"
  [ "$clone_name" = "vueshines" ] || fail "unexpected clean clone directory name: $clone_name"
  case "$CLEAN_CLONE_DIR" in
    ""|/|/home/hchjeong|/home/hchjeong/deploy-remote-repo|*/images)
      fail "refusing unsafe clean clone path: $CLEAN_CLONE_DIR"
      ;;
  esac
}

require_local_files
validate_clone_path

log "env source absolute path: $LOCAL_ENV_FILE"
log "env destination host: $AWS_DEMO_HOST"
log "env destination absolute path: $REMOTE_ENV_FILE"
confirm "Transfer the env file and overwrite the remote env if it exists?" || fail "env transfer was not approved"

if [ -e "$CLEAN_CLONE_DIR" ]; then
  log "clean clone directory scheduled for complete deletion: $CLEAN_CLONE_DIR"
  confirm "Delete this clean clone directory completely?" || fail "clean clone deletion was not approved"
  rm -rf -- "$CLEAN_CLONE_DIR"
fi

mkdir -p "$CLEAN_CLONE_ROOT" "$LOCAL_IMAGE_DIR"

log "fresh cloning $REPO_URL into $CLEAN_CLONE_DIR"
git clone "$REPO_URL" "$CLEAN_CLONE_DIR"
git -C "$CLEAN_CLONE_DIR" fetch --prune origin
git -C "$CLEAN_CLONE_DIR" checkout --detach "$DEPLOY_REF"

[ "$(git -C "$CLEAN_CLONE_DIR" remote get-url origin)" = "$REPO_URL" ] || fail "unexpected clone origin"
[ -z "$(git -C "$CLEAN_CLONE_DIR" status --porcelain)" ] || fail "fresh clone is not clean"

COMMIT_SHA="$(git -C "$CLEAN_CLONE_DIR" rev-parse HEAD)"
SHORT_SHA="$(git -C "$CLEAN_CLONE_DIR" rev-parse --short=12 HEAD)"
IMAGE_TAG="$(date +%Y%m%d%H%M%S)-${SHORT_SHA}"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
LOCAL_IMAGE_FILE="${LOCAL_IMAGE_DIR}/${IMAGE_NAME}-${IMAGE_TAG}.tar"
REMOTE_IMAGE_FILE="${REMOTE_IMAGE_DIR}/${IMAGE_NAME}-${IMAGE_TAG}.tar"

log "building image from commit: $COMMIT_SHA"
docker build --file "$CLEAN_CLONE_DIR/Dockerfile.aws-demo" \
  --build-arg "VCS_REF=$COMMIT_SHA" --tag "$IMAGE" "$CLEAN_CLONE_DIR"

log "saving image archive: $LOCAL_IMAGE_FILE"
docker save "$IMAGE" -o "$LOCAL_IMAGE_FILE"

log "preparing remote directories with owner ${REMOTE_OWNER}:${REMOTE_GROUP}"
ssh "$AWS_DEMO_HOST" \
  REMOTE_APP_DIR="$REMOTE_APP_DIR" REMOTE_IMAGE_DIR="$REMOTE_IMAGE_DIR" \
  REMOTE_OWNER="$REMOTE_OWNER" REMOTE_GROUP="$REMOTE_GROUP" bash -s <<'REMOTE_PREP'
set -euo pipefail
sudo install -d -o "$REMOTE_OWNER" -g "$REMOTE_GROUP" -m 700 "$REMOTE_APP_DIR"
sudo install -d -o "$REMOTE_OWNER" -g "$REMOTE_GROUP" -m 700 "$REMOTE_IMAGE_DIR"
REMOTE_PREP

REMOTE_ENV_UPLOAD="${REMOTE_ENV_FILE}.upload"
log "transferring env file to temporary target: $AWS_DEMO_HOST:$REMOTE_ENV_UPLOAD"
scp "$LOCAL_ENV_FILE" "$AWS_DEMO_HOST:$REMOTE_ENV_UPLOAD"
log "transferring Compose file: $AWS_DEMO_HOST:$REMOTE_COMPOSE_FILE"
scp "$LOCAL_COMPOSE_FILE" "$AWS_DEMO_HOST:$REMOTE_COMPOSE_FILE"

ssh "$AWS_DEMO_HOST" \
  REMOTE_ENV_UPLOAD="$REMOTE_ENV_UPLOAD" REMOTE_ENV_FILE="$REMOTE_ENV_FILE" \
  REMOTE_COMPOSE_FILE="$REMOTE_COMPOSE_FILE" REMOTE_OWNER="$REMOTE_OWNER" \
  REMOTE_GROUP="$REMOTE_GROUP" bash -s <<'REMOTE_FILES'
set -euo pipefail
sudo install -o "$REMOTE_OWNER" -g "$REMOTE_GROUP" -m 600 "$REMOTE_ENV_UPLOAD" "$REMOTE_ENV_FILE"
rm -f "$REMOTE_ENV_UPLOAD"
sudo chown "$REMOTE_OWNER:$REMOTE_GROUP" "$REMOTE_COMPOSE_FILE"
sudo chmod 644 "$REMOTE_COMPOSE_FILE"
stat -c 'env installed: %n owner=%U:%G mode=%a size=%s' "$REMOTE_ENV_FILE"
stat -c 'compose installed: %n owner=%U:%G mode=%a size=%s' "$REMOTE_COMPOSE_FILE"
REMOTE_FILES

log "transferring image archive to $AWS_DEMO_HOST:$REMOTE_IMAGE_FILE"
scp "$LOCAL_IMAGE_FILE" "$AWS_DEMO_HOST:$REMOTE_IMAGE_FILE"

log "loading image and applying the AWS Compose project"
ssh "$AWS_DEMO_HOST" \
  REMOTE_IMAGE_FILE="$REMOTE_IMAGE_FILE" REMOTE_ENV_FILE="$REMOTE_ENV_FILE" \
  REMOTE_COMPOSE_FILE="$REMOTE_COMPOSE_FILE" APP_NAME="$APP_NAME" \
  IMAGE="$IMAGE" HOST_PORT="$HOST_PORT" bash -s <<'REMOTE_DEPLOY'
set -euo pipefail

DOCKER=(docker)
if ! docker info >/dev/null 2>&1; then
  DOCKER=(sudo docker)
fi

"${DOCKER[@]}" compose version >/dev/null
"${DOCKER[@]}" load -i "$REMOTE_IMAGE_FILE"
rm -f "$REMOTE_IMAGE_FILE"

compose() {
  APP_IMAGE="$IMAGE" APP_HOST_PORT="$HOST_PORT" \
    "${DOCKER[@]}" compose --project-name "$APP_NAME" \
      --env-file "$REMOTE_ENV_FILE" --file "$REMOTE_COMPOSE_FILE" "$@"
}

compose config --quiet
compose up -d --wait mysql redis
compose up -d --no-deps --wait app
curl --fail --silent "http://127.0.0.1:${HOST_PORT}/api/health"
printf '\n'
compose ps
REMOTE_DEPLOY

docker rmi "$IMAGE" >/dev/null 2>&1 || true
log "deploy succeeded from commit $COMMIT_SHA"
