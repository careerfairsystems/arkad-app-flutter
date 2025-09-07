#!/bin/bash

# API Generation Script for Arkad Flutter App
# This script generates the API client using OpenAPI Generator CLI

set -e

# Configuration
OPENAPI_URL="https://staging.backend.arkadtlth.se/api/openapi.json"
OUTPUT_DIR="api/arkad_api"
GENERATOR_VERSION="7.9.0"
JAR_FILE="openapi-generator-cli.jar"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Arkad API Client Generation${NC}"
echo "==============================="

# Check if Java is available
if ! command -v java &> /dev/null; then
    echo -e "${RED}ERROR: Java is not installed or not in PATH${NC}"
    echo "Please install Java 11 or later to use this script"
    exit 1
fi

# Download OpenAPI Generator CLI with retry logic if not exists
if [ ! -f "$JAR_FILE" ]; then
    echo -e "${YELLOW}Downloading OpenAPI Generator CLI v$GENERATOR_VERSION with retry logic...${NC}"
    DOWNLOAD_URL="https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$GENERATOR_VERSION/openapi-generator-cli-$GENERATOR_VERSION.jar"
    
    for i in {1..3}; do
        echo -e "${YELLOW}Download attempt $i/3${NC}"
        if curl -L --connect-timeout 30 --max-time 300 --retry 3 --retry-delay 5 "$DOWNLOAD_URL" -o "$JAR_FILE"; then
            echo -e "${GREEN}Download complete${NC}"
            break
        else
            echo -e "${RED}Download attempt $i failed${NC}"
            if [ $i -eq 3 ]; then
                echo -e "${RED}ERROR: All download attempts failed${NC}"
                echo "Please check your internet connection and try again"
                exit 1
            fi
            echo -e "${YELLOW}Retrying in 10 seconds...${NC}"
            sleep 10
        fi
    done
else
    echo -e "${GREEN}OpenAPI Generator CLI already available${NC}"
fi

# Step 1: API Change Detection and Generation
echo -e "${YELLOW}Step 1: API Change Detection and Generation${NC}"

# API change detection mechanism
API_HASH_FILE="api/.api_spec_hash"

echo -e "${YELLOW}Checking for OpenAPI spec changes...${NC}"
# Download and hash the current OpenAPI spec
CURRENT_HASH=""
for i in {1..3}; do
    echo -e "${YELLOW}Fetching OpenAPI spec (attempt $i/3)${NC}"
    if curl -s --connect-timeout 30 --max-time 60 "$OPENAPI_URL" -o current_openapi.json; then
        CURRENT_HASH=$(sha256sum current_openapi.json | cut -d' ' -f1)
        echo -e "${GREEN}Current OpenAPI spec hash: $CURRENT_HASH${NC}"
        break
    else
        echo -e "${RED}Failed to fetch OpenAPI spec (attempt $i/3)${NC}"
        if [ $i -eq 3 ]; then
            echo -e "${YELLOW}WARNING: Could not fetch OpenAPI spec for change detection, proceeding with generation${NC}"
            CURRENT_HASH="force-generation"
            break
        fi
        sleep 5
    fi
done

# Check if we have a previous hash and if the spec has changed
SHOULD_GENERATE=true
if [ -f "$API_HASH_FILE" ]; then
    PREVIOUS_HASH=$(cat "$API_HASH_FILE")
    echo -e "${GREEN}Previous OpenAPI spec hash: $PREVIOUS_HASH${NC}"
    
    if [ "$CURRENT_HASH" = "$PREVIOUS_HASH" ] && [ -d "$OUTPUT_DIR" ] && [ -f "$OUTPUT_DIR/lib/src/serializers.g.dart" ]; then
        echo -e "${GREEN}OpenAPI spec unchanged and valid API client exists - skipping generation${NC}"
        SHOULD_GENERATE=false
    else
        echo -e "${YELLOW}OpenAPI spec changed or API client missing - proceeding with generation${NC}"
    fi
else
    echo -e "${YELLOW}No previous hash found - proceeding with initial generation${NC}"
fi

if [ "$SHOULD_GENERATE" = "true" ]; then
    echo -e "${YELLOW}Generating API client...${NC}"
    
    # Remove existing generated code before generation
    if [ -d "$OUTPUT_DIR" ]; then
        echo -e "${YELLOW}Removing existing API client...${NC}"
        rm -rf "$OUTPUT_DIR"
    fi
    
    # Create output directory
    echo -e "${YELLOW}Creating output directory...${NC}"
    mkdir -p "$OUTPUT_DIR"
    
    # Generate base API files with OpenAPI CLI with retry logic
    for i in {1..3}; do
    echo -e "${YELLOW}API generation attempt $i/3${NC}"
    if java -jar "$JAR_FILE" generate \
        -i "$OPENAPI_URL" \
        -g dart-dio \
        -o "$OUTPUT_DIR" \
        --additional-properties=pubName=arkad_api,pubVersion=1.0.0,pubDescription="OpenAPI API client"; then
        echo -e "${GREEN}API generation successful${NC}"
        break
    else
        echo -e "${RED}API generation attempt $i failed${NC}"
        if [ $i -eq 3 ]; then
            echo -e "${RED}ERROR: All API generation attempts failed${NC}"
            echo "Please check your internet connection and the OpenAPI endpoint"
            exit 1
        fi
        echo -e "${YELLOW}Retrying in 15 seconds...${NC}"
        sleep 15
        # Clean up partial generation
        if [ -d "$OUTPUT_DIR" ]; then
            rm -rf "$OUTPUT_DIR"/*
        fi
        mkdir -p "$OUTPUT_DIR"
    fi
done

echo -e "${GREEN}Base API client generated successfully${NC}"

# Step 2: Complete API generation with build_runner  
echo -e "${YELLOW}Step 2: Completing API generation with build_runner...${NC}"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter to complete API generation"
    exit 1
fi

# Enter API directory and install dependencies
if ! cd "$OUTPUT_DIR"; then
    echo -e "${RED}ERROR: Could not enter API directory${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing API dependencies with retry logic...${NC}"
for i in {1..3}; do
    echo -e "${YELLOW}Flutter pub get attempt $i/3${NC}"
    if flutter pub get; then
        echo -e "${GREEN}Dependencies installed successfully${NC}"
        break
    else
        echo -e "${RED}Flutter pub get attempt $i failed${NC}"
        if [ $i -eq 3 ]; then
            echo -e "${RED}ERROR: All flutter pub get attempts failed${NC}"
            echo "Please check your internet connection and pub.dev availability"
            exit 1
        fi
        echo -e "${YELLOW}Retrying in 10 seconds...${NC}"
        sleep 10
    fi
done

echo -e "${YELLOW}Generating .g.dart files with build_runner (with retry logic)...${NC}"
for i in {1..2}; do
    echo -e "${YELLOW}Build runner attempt $i/2${NC}"
    if dart run build_runner build --delete-conflicting-outputs; then
        echo -e "${GREEN}Build runner completed successfully${NC}"
        break
    else
        echo -e "${RED}Build runner attempt $i failed${NC}"
        if [ $i -eq 2 ]; then
            echo -e "${RED}ERROR: All build runner attempts failed${NC}"
            exit 1
        fi
        echo -e "${YELLOW}Retrying in 5 seconds...${NC}"
        sleep 5
        # Clean up partial .g.dart files before retry
        find . -name "*.g.dart" -delete
    fi
done

# Return to project root
cd ../..

# Step 3: Validate generation completed successfully
echo -e "${YELLOW}Step 3: Validating API generation...${NC}"

# Check for critical .g.dart files
if [ ! -f "$OUTPUT_DIR/lib/src/serializers.g.dart" ]; then
    echo -e "${RED}ERROR: serializers.g.dart not generated${NC}"
    echo "API generation may be incomplete"
    exit 1
fi

# Count .g.dart files to ensure generation worked
GENERATED_COUNT=$(find "$OUTPUT_DIR" -name "*.g.dart" | wc -l)
echo -e "${GREEN}Generated $GENERATED_COUNT .g.dart files${NC}"

if [ "$GENERATED_COUNT" -lt 5 ]; then
    echo -e "${RED}ERROR: Too few .g.dart files generated ($GENERATED_COUNT < 5)${NC}"
    echo "API generation may be incomplete"
    exit 1
fi

# Update main project dependencies
echo -e "${YELLOW}Updating main project dependencies...${NC}"
if ! flutter pub get; then
    echo -e "${YELLOW}Warning: Failed to update main project dependencies${NC}"
    echo "You may need to run 'flutter pub get' manually"
fi

    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}API generation completed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    
    # Store the current hash for future change detection
    mkdir -p api
    echo "$CURRENT_HASH" > "$API_HASH_FILE"
    echo -e "${GREEN}Stored API spec hash for future change detection${NC}"
    
    echo ""
    echo -e "${GREEN}Generated files:${NC}"
    echo "  - Base API client: $OUTPUT_DIR"
    echo "  - Generated .g.dart files: $GENERATED_COUNT"
    echo "  - Serializers: $OUTPUT_DIR/lib/src/serializers.g.dart"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo "  - API client is ready to use in your Flutter app"
    echo "  - Import from: 'package:arkad_api/arkad_api.dart'"
    echo "  - Run 'flutter analyze' to verify integration"
    
else
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}API client is up to date (no changes)${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo -e "${GREEN}Using existing files:${NC}"
    echo "  - Base API client: $OUTPUT_DIR"
    echo "  - Serializers: $OUTPUT_DIR/lib/src/serializers.g.dart"
    echo ""
    echo -e "${GREEN}The API client is ready to use in your Flutter app${NC}"
fi

# Cleanup temporary files
rm -f current_openapi.json