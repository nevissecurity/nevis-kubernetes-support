#!/usr/bin/env bash
set -euo pipefail

SOURCE="cloudsmith"
USERNAME="${GITHUB_TOKEN:-}"  # Default to same as token if not set explicitly
TOKEN="${GITHUB_TOKEN:-}"  # Pre-fill from env var if available
ACR_NAME=""
VERSION=""

print_help() {
  echo ""
  echo "Script to pull Docker images from a source registry and push to a target Azure Container Registry"
  echo ""
  echo "Usage: $0 [--source github|cloudsmith] [--username <name>] [--token <token>] --target <target_acr_name> --version <nevis_version>"
  echo ""
  echo "Notes:"
  echo "  - If the environment variable GITHUB_TOKEN is set, --token is optional."
  echo "  - --username is only required for GitHub; Cloudsmith uses a fixed account."
  echo "  - Only Nevis employees can pull from GitHub."
  echo "  - Other users should pull from Cloudsmith (default)."
  echo ""
  echo "Example: $0 --source cloudsmith --token *** --target myacr --version 8.2511.0"
  echo ""
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="$2"
      shift 2
      ;;
    --username)
      USERNAME="$2"
      shift 2
      ;;
    --token)
      TOKEN="$2"
      shift 2
      ;;
    --target)
      ACR_NAME="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "❌ Unknown parameter: $1"
      echo ""
      print_help
      exit 1
      ;;
  esac
done

# === Validate parameters ===
missing=()

if [[ "$SOURCE" == "github" && -z "$USERNAME" ]]; then
  missing+=("--username (or set GITHUB_TOKEN)")
fi

if [[ -z "$TOKEN" ]]; then
  # Only mark token as missing if GITHUB_TOKEN was not set
  missing+=("--token (or set GITHUB_TOKEN)")
fi

[[ -z "$ACR_NAME" ]] && missing+=("--target")
[[ -z "$VERSION" ]] && missing+=("--version")

if (( ${#missing[@]} > 0 )); then
  echo ""
  echo "❌ Missing required parameter(s): ${missing[*]}"
  print_help
  exit 1
fi

# === Optional validation for source ===
if [[ "$SOURCE" != "cloudsmith" && "$SOURCE" != "github" ]]; then
  echo "❌ Invalid --source value: '$SOURCE' (must be 'cloudsmith' or 'github')"
  exit 1
fi

# === Normalize ACR name ===
if [[ "$ACR_NAME" != *.azurecr.io ]]; then
  ACR_NAME="${ACR_NAME}.azurecr.io"
fi

# === Configuration ===
# Images that use the provided version
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

# Images with their own fixed version
STATIC_IMAGES=(
  "nevis-git-init:1.4.0"
  "nevis-ubi-tools:1.4.0"
)

# Registry definitions
GITHUB_REGISTRY="ghcr.io/nevissecurity"
CLOUDSMITH_REGISTRY="docker.cloudsmith.io/nevissecurity/rolling"

# === Select source registry and authenticate ===
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
  *)
    echo "❌ Error: Unknown source '$SOURCE'. Must be 'github' or 'cloudsmith'."
    exit 1
    ;;
esac

# === Login to Azure Container Registry ===
echo "🔐 Logging into Azure Container Registry: $ACR_NAME"
az acr login --name "$ACR_NAME" >/dev/null

pull_and_push_image() {
  local src="$1"
  local dst="$2"
  local version="$3"

  local major minor patch
  IFS='.' read -r major minor patch <<< "$version"

  # Ensure patch is numeric
  if ! [[ "$patch" =~ ^[0-9]+$ ]]; then
    echo "⚠️  Invalid version format: $version"
    return
  fi

  while (( patch >= 0 )); do
    local current_version="$major.$minor.$patch"
    local current_src="${src%:$version}:$current_version"
    local current_dst="${dst%:$version}:$current_version"

    echo "→ Attempting: $current_src → $current_dst"

    if docker pull "$current_src"; then
      docker tag "$current_src" "$current_dst"
      docker push "$current_dst"
      echo "✓ Synced $(basename "$current_dst"):$current_version"
      return 0
    else
      echo "⚠️  Image not found: $current_src"
      ((patch--))
    fi
  done

  echo "⚠️  No available version found for $(basename "$dst"). Skipping."
}

# === Sync versioned images ===
echo "🚀 Syncing Nevis images (version: $VERSION)..."

for IMAGE in "${COMMON_IMAGES[@]}"; do
  SRC_IMAGE="${SRC_REGISTRY}/${IMAGE}:${VERSION}"
  DST_IMAGE="${ACR_NAME}/nevis/${IMAGE}:${VERSION}"
  pull_and_push_image "$SRC_IMAGE" "$DST_IMAGE" "$VERSION"
done

# === Sync static-version images (unchanged) ===
for IMAGE in "${STATIC_IMAGES[@]}"; do
  SRC_IMAGE="${SRC_REGISTRY}/${IMAGE}"
  DST_IMAGE="${ACR_NAME}/nevis/${IMAGE}"
  echo "→ Syncing static image: $SRC_IMAGE → $DST_IMAGE"
  if docker pull "$SRC_IMAGE"; then
    docker tag "$SRC_IMAGE" "$DST_IMAGE"
    docker push "$DST_IMAGE"
    echo "✓ Synced static $(basename "$DST_IMAGE")"
  else
    echo "⚠️  Static image not found: $SRC_IMAGE. Skipping."
  fi
done

echo "✅ All images have been successfully pushed to $ACR_NAME."
