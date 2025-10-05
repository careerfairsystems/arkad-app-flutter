#!/usr/bin/env pwsh

# API Generation Script for Arkad Flutter App (PowerShell)
# Generates API client using OpenAPI Generator Docker image

param(
    [string]$OutputDir = "api/arkad_api"
)

$ErrorActionPreference = "Stop"

# Configuration
$UseStaging = $false  # Set to $true for staging, $false for production

if ($UseStaging) {
    $OpenApiUrl = "https://staging.backend.arkadtlth.se/api/openapi.json"
} else {
    $OpenApiUrl = "https://backend.arkadtlth.se/api/openapi.json"
}

$TempSpecFile = "temp_openapi.json"
$ApiHashFile = "api/.api_spec_hash"

# Colors for output
function Write-Info($message) { Write-Host $message -ForegroundColor Green }
function Write-Warn($message) { Write-Host $message -ForegroundColor Yellow }
function Write-Error($message) { Write-Host $message -ForegroundColor Red }

# Check dependencies
function Test-Dependencies {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is required but not found in PATH"
        Write-Error "Please install Docker from: https://docs.docker.com/get-docker/"
        exit 1
    }

    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutter is required but not found in PATH"
        exit 1
    }
}

# Get current API spec hash
function Get-ApiHash {
    try {
        Invoke-WebRequest -Uri $OpenApiUrl -OutFile $TempSpecFile -TimeoutSec 30
        $hash = (Get-FileHash -Path $TempSpecFile -Algorithm SHA256).Hash.ToLower()
        return $hash
    } catch {
        Write-Warn "Could not fetch OpenAPI spec for change detection"
        if (Test-Path $TempSpecFile) {
            Remove-Item $TempSpecFile -Force
        }
        return "force-generation"
    }
}

# Check if generation is needed
function Test-ShouldGenerate($currentHash) {
    # Always generate if no previous hash or output directory doesn't exist
    if (-not (Test-Path $ApiHashFile) -or -not (Test-Path $OutputDir)) {
        return $true
    }
    
    # Always generate if critical files are missing
    if (-not (Test-Path "$OutputDir/lib/arkad_api.dart") -or -not (Test-Path "$OutputDir/lib/src/serializers.g.dart")) {
        return $true
    }
    
    # Generate if API spec changed
    $previousHash = Get-Content -Path $ApiHashFile -Raw -ErrorAction SilentlyContinue
    $previousHash = $previousHash.Trim()
    
    if ($currentHash -ne $previousHash) {
        Write-Info "API spec changed"
        return $true
    }
    
    return $false
}

# Generate API client
function Invoke-ApiGeneration {
    Write-Info "Generating API client..."

    # Download OpenAPI spec if not already present
    if (-not (Test-Path $TempSpecFile)) {
        Write-Info "Downloading OpenAPI spec..."
        try {
            Invoke-WebRequest -Uri $OpenApiUrl -OutFile $TempSpecFile -TimeoutSec 30
        } catch {
            Write-Error "Failed to download OpenAPI spec: $_"
            exit 1
        }
    }

    # Clean and recreate output directory
    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    # Get current directory for Docker volume mount (Windows path conversion)
    $currentDir = (Get-Location).Path.Replace('\', '/')
    # Handle Windows drive letter for Docker (C:\ -> /c/)
    if ($currentDir -match '^([A-Z]):') {
        $driveLetter = $matches[1].ToLower()
        $currentDir = $currentDir -replace '^[A-Z]:', "/$driveLetter"
    }

    # Generate base API client using Docker
    Write-Info "Running OpenAPI Generator (this may take a moment)..."
    & docker run --rm `
        -v "${currentDir}:/local" `
        openapitools/openapi-generator-cli generate `
        -i "/local/$TempSpecFile" `
        -g dart-dio `
        -o "/local/$OutputDir" `
        --additional-properties=pubName=arkad_api,nullSafe=true

    if ($LASTEXITCODE -ne 0) {
        Write-Error "API generation failed"
        if (Test-Path $TempSpecFile) {
            Remove-Item $TempSpecFile -Force
        }
        exit 1
    }

    # Clean up temp spec file
    if (Test-Path $TempSpecFile) {
        Remove-Item $TempSpecFile -Force
    }

    # Fix permissions (in case Docker created files with wrong permissions)
    if (Test-Path $OutputDir) {
        Get-ChildItem -Path $OutputDir -Recurse -File | ForEach-Object {
            $_.IsReadOnly = $false
        }
    }

    # Install dependencies and run build_runner
    $originalLocation = Get-Location
    try {
        Set-Location $OutputDir

        flutter pub get
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to install dependencies"
            exit 1
        }

        dart run build_runner build --delete-conflicting-outputs
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build runner failed"
            exit 1
        }
    } finally {
        Set-Location $originalLocation
    }
}

# Validate generation
function Test-Generation {
    $requiredFiles = @(
        "$OutputDir/lib/arkad_api.dart",
        "$OutputDir/lib/src/serializers.g.dart"
    )
    
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file)) {
            Write-Error "Required file missing: $file"
            exit 1
        }
    }
    
    $generatedCount = (Get-ChildItem -Path $OutputDir -Recurse -Filter "*.g.dart").Count
    
    if ($generatedCount -lt 2) {
        Write-Error "Insufficient generated files ($generatedCount < 2)"
        exit 1
    }
}

# Store API hash
function Set-ApiHash($hash) {
    New-Item -ItemType Directory -Path "api" -Force | Out-Null
    Set-Content -Path $ApiHashFile -Value $hash
}

# Cleanup function
function Invoke-Cleanup {
    if (Test-Path $TempSpecFile) {
        Remove-Item $TempSpecFile -Force
    }
}

# Main execution
Write-Info "Arkad API Client Generation"

try {
    Test-Dependencies

    $currentHash = Get-ApiHash

    if (Test-ShouldGenerate $currentHash) {
        Invoke-ApiGeneration
        Test-Generation
        Set-ApiHash $currentHash

        # Update main project dependencies (optional)
        try {
            flutter pub get | Out-Null
        } catch {
            Write-Warn "Could not update main project dependencies"
        }

        Write-Info "API client generated successfully"
    } else {
        Write-Info "API client is up to date"
    }
} finally {
    Invoke-Cleanup
}