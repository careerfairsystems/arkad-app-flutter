#!/bin/bash

# API Generation Script for Arkad Flutter App
# Generates API client using OpenAPI Generator CLI

set -e

# Configuration
OPENAPI_URL="https://staging.backend.arkadtlth.se/api/openapi.json"
OUTPUT_DIR="api/arkad_api"
API_HASH_FILE="api/.api_spec_hash"

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
  if ! command -v java &>/dev/null; then
    log_error "Java is required but not found in PATH"
    exit 1
  fi

  if ! command -v flutter &>/dev/null; then
    log_error "Flutter is required but not found in PATH"
    exit 1
  fi

  if ! command -v openapi-generator-cli &>/dev/null; then
    log_error "OpenAPI Generator CLI is required but not found in PATH"
    log_error "Please install it from: https://openapi-generator.tech/"
    log_error "Or use the JAR file method as documented in the installation guide"
    exit 1
  fi
}

# Get current API spec hash
get_api_hash() {
  if curl -sf --max-time 30 --retry 2 --retry-delay 5 "$OPENAPI_URL" -o temp_openapi.json 2>/dev/null; then
    local hash
    hash=$(sha256sum temp_openapi.json | cut -d' ' -f1)
    rm -f temp_openapi.json
    echo "$hash"
  else
    log_warn "Could not fetch OpenAPI spec for change detection"
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

  # Clean and recreate output directory
  rm -rf "$OUTPUT_DIR"
  mkdir -p "$OUTPUT_DIR"

  # Generate base API client
  if ! openapi-generator-cli generate \
    -i "$OPENAPI_URL" \
    -g dart-dio \
    -o "$OUTPUT_DIR" \
    --additional-properties=pubName=arkad_api; then
    log_error "API generation failed"
    exit 1
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
  fi
}

main "$@"
