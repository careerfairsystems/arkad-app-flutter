#!/bin/bash

# API Generation Script for Arkad Flutter App
# Generates API client using OpenAPI Generator Docker image

set -e

# Configuration
USE_STAGING=true  # Set to true for staging, false for production

if [[ "$USE_STAGING" == "true" ]]; then
    OPENAPI_URL="https://staging.backend.arkadtlth.se/api/openapi.json"
else
    OPENAPI_URL="https://backend.arkadtlth.se/api/openapi.json"
fi

OUTPUT_DIR="api/arkad_api"
API_HASH_FILE="api/.api_spec_hash"
TEMP_SPEC_FILE="temp_openapi.json"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${GREEN}$1${NC}"; }
log_warn() { echo -e "${YELLOW}$1${NC}"; }
log_error() { echo -e "${RED}$1${NC}"; }

# Check dependencies
check_dependencies() {
  if ! command -v docker &>/dev/null; then
    log_error "Docker is required but not found in PATH"
    log_error "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
  fi

  if ! command -v flutter &>/dev/null; then
    log_error "Flutter is required but not found in PATH"
    exit 1
  fi
}

# Get current API spec hash
get_api_hash() {
  if curl -sf --max-time 30 --retry 2 --retry-delay 5 "$OPENAPI_URL" -o "$TEMP_SPEC_FILE" 2>/dev/null; then
    local hash
    hash=$(shasum -a 256 "$TEMP_SPEC_FILE" | cut -d' ' -f1)
    echo "$hash"
  else
    log_warn "Could not fetch OpenAPI spec for change detection"
    rm -f "$TEMP_SPEC_FILE"
    echo "force-generation"
  fi
}

# Check if generation is needed
should_generate() {
  local current_hash="$1"

  # Always generate if no previous hash or output directory doesn't exist
  if [[ ! -f "$API_HASH_FILE" ]] || [[ ! -d "$OUTPUT_DIR" ]]; then
    return 0
  fi

  # Always generate if critical files are missing
  if [[ ! -f "$OUTPUT_DIR/lib/arkad_api.dart" ]] || [[ ! -f "$OUTPUT_DIR/lib/src/serializers.g.dart" ]]; then
    return 0
  fi

  # Generate if API spec changed
  local previous_hash
  previous_hash=$(cat "$API_HASH_FILE" 2>/dev/null || echo "")

  if [[ "$current_hash" != "$previous_hash" ]]; then
    log_info "API spec changed"
    return 0
  fi

  return 1
}

# Generate API client
generate_api() {
  log_info "Generating API client..."

  # Download OpenAPI spec if not already present
  if [[ ! -f "$TEMP_SPEC_FILE" ]]; then
    log_info "Downloading OpenAPI spec..."
    if ! curl -sf --max-time 30 --retry 2 --retry-delay 5 "$OPENAPI_URL" -o "$TEMP_SPEC_FILE"; then
      log_error "Failed to download OpenAPI spec"
      exit 1
    fi
  fi

  # Clean and recreate output directory
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"

  # Generate base API client using Docker
  log_info "Running OpenAPI Generator (this may take a moment)..."
  if ! docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "${PWD}:/local" \
    openapitools/openapi-generator-cli generate \
    -i "/local/$TEMP_SPEC_FILE" \
    -g dart-dio \
    -o "/local/$OUTPUT_DIR" \
    --additional-properties=pubName=arkad_api,nullSafe=true; then
    log_error "API generation failed"
    rm -f "$TEMP_SPEC_FILE"
    exit 1
  fi

  # Clean up temp spec file
  rm -f "$TEMP_SPEC_FILE"

  # Fix permissions (in case Docker created files as root)
  if [[ -d "$OUTPUT_DIR" ]]; then
    chmod -R u+w "$OUTPUT_DIR" 2>/dev/null || true
  fi

  # Install dependencies and run build_runner
  cd "$OUTPUT_DIR"

  if ! flutter pub get; then
    log_error "Failed to install dependencies"
    exit 1
  fi

  if ! dart run build_runner build --delete-conflicting-outputs; then
    log_error "Build runner failed"
    exit 1
  fi

  cd - >/dev/null
}

# Validate generation
validate_generation() {
  local required_files=(
    "$OUTPUT_DIR/lib/arkad_api.dart"
    "$OUTPUT_DIR/lib/src/serializers.g.dart"
  )

  for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
      log_error "Required file missing: $file"
      exit 1
    fi
  done

  local generated_count
  generated_count=$(find "$OUTPUT_DIR" -name "*.g.dart" | wc -l)

  if [[ "$generated_count" -lt 2 ]]; then
    log_error "Insufficient generated files ($generated_count < 2)"
    exit 1
  fi
}

# Store API hash
store_api_hash() {
  local hash="$1"
  mkdir -p api
  echo "$hash" >"$API_HASH_FILE"
}

# Cleanup function
cleanup() {
  rm -f "$TEMP_SPEC_FILE"
}

# Set trap to cleanup on exit
trap cleanup EXIT

# Main execution
main() {
  log_info "Arkad API Client Generation"

  check_dependencies

  local current_hash
  current_hash=$(get_api_hash)

  if should_generate "$current_hash"; then
    generate_api
    validate_generation
    store_api_hash "$current_hash"

    # Update main project dependencies (optional)
    if ! flutter pub get &>/dev/null; then
      log_warn "Could not update main project dependencies"
    fi

    log_info "API client generated successfully"
  else
    log_info "API client is up to date"
    rm -f "$TEMP_SPEC_FILE"
  fi
}

main "$@"
