#!/usr/bin/env pwsh

# API Generation Script for Arkad Flutter App (PowerShell)
# Generates API client using OpenAPI Generator CLI

param(
    [string]$OpenApiUrl = "https://staging.backend.arkadtlth.se/api/openapi.json",
    [string]$OutputDir = "api/arkad_api",
    [string]$GeneratorVersion = "7.10.0"  # Match CI version
)

$ErrorActionPreference = "Stop"

# Configuration
$JarFile = "openapi-generator-cli.jar"
$ApiHashFile = "api/.api_spec_hash"

# Colors for output
function Write-Info($message) { Write-Host $message -ForegroundColor Green }
function Write-Warn($message) { Write-Host $message -ForegroundColor Yellow }
function Write-Error($message) { Write-Host $message -ForegroundColor Red }

# Check dependencies
function Test-Dependencies {
    if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
        Write-Error "Java is required but not found in PATH"
        exit 1
    }
    
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutter is required but not found in PATH"
        exit 1
    }
}

# Download OpenAPI Generator CLI if needed
function Get-Generator {
    if (Test-Path $JarFile) {
        return
    }
    
    Write-Info "Downloading OpenAPI Generator CLI v$GeneratorVersion..."
    $url = "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$GeneratorVersion/openapi-generator-cli-$GeneratorVersion.jar"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $JarFile -TimeoutSec 120 -RetryIntervalSec 5 -MaximumRetryCount 2
    } catch {
        Write-Error "Failed to download OpenAPI Generator CLI: $_"
        exit 1
    }
}

# Get current API spec hash
function Get-ApiHash {
    try {
        Invoke-WebRequest -Uri $OpenApiUrl -OutFile "temp_openapi.json" -TimeoutSec 30 -MaximumRetryCount 2 -RetryIntervalSec 5
        $hash = (Get-FileHash -Path "temp_openapi.json" -Algorithm SHA256).Hash.ToLower()
        Remove-Item "temp_openapi.json" -Force
        return $hash
    } catch {
        Write-Warn "Could not fetch OpenAPI spec for change detection"
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
    
    # Clean and recreate output directory
    if (Test-Path $OutputDir) {
        Remove-Item -Recurse -Force $OutputDir
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    
    # Generate base API client
    $generateArgs = @(
        "-jar", $JarFile, "generate",
        "-i", $OpenApiUrl,
        "-g", "dart-dio",
        "-o", $OutputDir,
        "--additional-properties=pubName=arkad_api,pubVersion=1.0.0,pubDescription=`"Generated API client`",nullSafe=true"
    )
    
    & java @generateArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "API generation failed"
        exit 1
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

# Main execution
Write-Info "Arkad API Client Generation"

Test-Dependencies
Get-Generator

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