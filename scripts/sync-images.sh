#!/usr/bin/env bash
set -euo pipefail

SOURCE="cloudsmith"
USERNAME="${GITHUB_TOKEN:-}"
TOKEN="${GITHUB_TOKEN:-}"
ACR_NAME=""
VERSION=""
declare -A TAG_OVERRIDES
SKIP_IMAGES=()

print_help() {
  echo ""
  echo "Script to pull Docker images from a source registry and push to a target Azure Container Registry"
  echo ""
  echo "Usage: $0 [--source github|cloudsmith] [--username <name>] [--token <token>] --target <target_acr_name> --version <nevis_version>"
  echo "          [--tags <img1:tag1> <img2:tag2> ...] [--skip-images <img1> <img2> ...]"
  echo ""
  echo "Examples:"
  echo "  $0 --source cloudsmith --token *** --target myacr --version 8.2511.0"
  echo "  $0 --target myacr --version 8.2511.0 --tags nevisproxy:8.2505.7 nevisproxy-dbschema:8.2505.4"
  echo "  $0 --target myacr --version 8.2511.0 --skip-images nevisdetect-core nevisauth"
  echo ""
}

# === Parse arguments ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="$2"; shift 2 ;;
    --username)
      USERNAME="$2"; shift 2 ;;
    --token)
      TOKEN="$2"; shift 2 ;;
    --target)
      ACR_NAME="$2"; shift 2 ;;
    --version)
      VERSION="$2"; shift 2 ;;
    --tags)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        IFS=':' read -r img tag <<< "$1"
        TAG_OVERRIDES["$img"]="$tag"
        shift
      done
      ;;
    --skip-images)
      shift
      while [[ $# -gt 0 && "$1" != --* ]]; do
        SKIP_IMAGES+=("$1")
        shift
      done
      ;;
    -h|--help)
      print_help; exit 0 ;;
    *)
      echo "❌ Unknown parameter: $1"; echo ""; print_help; exit 1 ;;
  esac
done

# === Validate parameters ===
missing=()
[[ "$SOURCE" == "github" && -z "$USERNAME" ]] && missing+=("--username")
[[ -z "$TOKEN" ]] && missing+=("--token (or set GITHUB_TOKEN)")
[[ -z "$ACR_NAME" ]] && missing+=("--target")
[[ -z "$VERSION" ]] && missing+=("--version")

if (( ${#missing[@]} > 0 )); then
  echo ""
  echo "❌ Missing required parameter(s): ${missing[*]}"
  print_help
  exit 1
fi

if [[ "$SOURCE" != "cloudsmith" && "$SOURCE" != "github" ]]; then
  echo "❌ Invalid --source value: '$SOURCE' (must be 'cloudsmith' or 'github')"
  exit 1
fi

# === Normalize ACR name ===
if [[ "$ACR_NAME" != *.azurecr.io ]]; then
  ACR_NAME="${ACR_NAME}.azurecr.io"
fi

# === Configuration ===
COMMON_IMAGES=(
  nevisproxy
  nevisproxy-dbschema
  nevislogrend
  nevisfido
  nevisfido-dbschema
  nevisauth
  nevisauth-dbschema
  nevisidm
  nevisidm-dbschema
  nevismeta
  nevismeta-dbschema
  nevisadmin4
  nevisadmin4-dbschema
  nevisoperator
  nevisadapt
  nevisadapt-dbschema
  nevisdetect-admin
  nevisdetect-core
  nevisdetect-entrypoint
  nevisdetect-persistency
  nevisdetect-persistency-dbschema
  nevisdp
  nevis-base-flyway
)

STATIC_IMAGES=(
  "nevis-git-init:1.4.0"
  "nevis-ubi-tools:1.4.0"
)

GITHUB_REGISTRY="ghcr.io/nevissecurity"
CLOUDSMITH_REGISTRY="docker.cloudsmith.io/nevissecurity/rolling"

# === Authenticate ===
case "$SOURCE" in
  github)
    SRC_REGISTRY="$GITHUB_REGISTRY"
    echo "🔐 Logging into GitHub Container Registry..."
    docker login ghcr.io -u "$USERNAME" -p "$TOKEN"
    ;;
  cloudsmith)
    SRC_REGISTRY="$CLOUDSMITH_REGISTRY"
    echo "🔐 Logging into Cloudsmith..."
    docker login docker.cloudsmith.io -u nevissecurity/rolling -p "$TOKEN"
    ;;
esac

echo "🔐 Logging into Azure Container Registry: $ACR_NAME"
az acr login --name "$ACR_NAME" >/dev/null

# === Helper functions ===
contains() {
  local e match="$1"; shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

pull_and_push_image() {
  local image="$1"
  local src_version="$2"

  local src="${SRC_REGISTRY}/${image}:${src_version}"
  local dst="${ACR_NAME}/nevis/${image}:${src_version}"

  echo "→ Syncing $src → $dst"

  if docker pull "$src"; then
    docker tag "$src" "$dst"
    docker push "$dst"
    echo "✓ Synced $(basename "$dst"):$src_version"
  else
    echo "❌ Image not found: $src"
    exit 1
  fi
}

# === Sync versioned images ===
echo "🚀 Syncing Nevis images (version: $VERSION)..."

for IMAGE in "${COMMON_IMAGES[@]}"; do
  if contains "$IMAGE" "${SKIP_IMAGES[@]}"; then
    echo "⏭️  Skipping image: $IMAGE"
    continue
  fi

  IMG_VERSION="${TAG_OVERRIDES[$IMAGE]:-$VERSION}"
  pull_and_push_image "$IMAGE" "$IMG_VERSION"
done

# === Sync static-version images ===
for IMAGE in "${STATIC_IMAGES[@]}"; do
  SRC_IMAGE="${SRC_REGISTRY}/${IMAGE}"
  DST_IMAGE="${ACR_NAME}/nevis/${IMAGE}"
  NAME="${IMAGE%%:*}"
  if contains "$NAME" "${SKIP_IMAGES[@]}"; then
    echo "⏭️  Skipping static image: $NAME"
    continue
  fi
  echo "→ Syncing static image: $SRC_IMAGE → $DST_IMAGE"
  if docker pull "$SRC_IMAGE"; then
    docker tag "$SRC_IMAGE" "$DST_IMAGE"
    docker push "$DST_IMAGE"
    echo "✓ Synced static $(basename "$DST_IMAGE")"
  else
    echo "❌ Static image not found: $SRC_IMAGE"
    exit 1
  fi
done

echo "✅ All images have been successfully pushed to $ACR_NAME."
