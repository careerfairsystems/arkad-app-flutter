# API Generation Script for Arkad Flutter App (PowerShell)
# This script generates the API client using OpenAPI Generator CLI

param(
    [string]$OpenApiUrl = "https://staging.backend.arkadtlth.se/api/openapi.json",
    [string]$OutputDir = "api/arkad_api",
    [string]$GeneratorVersion = "7.9.0"
)

$JarFile = "openapi-generator-cli.jar"

Write-Host "Arkad API Client Generation" -ForegroundColor Green
Write-Host "=================================="

# Check if Java is available
try {
    $javaVersion = java -version 2>&1
    Write-Host "Java is available" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Java is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Java 11 or later to use this script"
    exit 1
}

# Download OpenAPI Generator CLI with retry logic if not exists
if (-Not (Test-Path $JarFile)) {
    Write-Host "Downloading OpenAPI Generator CLI v$GeneratorVersion with retry logic..." -ForegroundColor Yellow
    $downloadUrl = "https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/$GeneratorVersion/openapi-generator-cli-$GeneratorVersion.jar"
    
    $maxAttempts = 3
    $success = $false
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        Write-Host "Download attempt $i/$maxAttempts" -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $JarFile -TimeoutSec 300
            Write-Host "Download complete" -ForegroundColor Green
            $success = $true
            break
        } catch {
            Write-Host "Download attempt $i failed: $($_.Exception.Message)" -ForegroundColor Red
            if ($i -eq $maxAttempts) {
                Write-Host "ERROR: All download attempts failed" -ForegroundColor Red
                Write-Host "Please check your internet connection and try again"
                exit 1
            }
            Write-Host "Retrying in 10 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }
} else {
    Write-Host "OpenAPI Generator CLI already available" -ForegroundColor Green
}

# Remove existing generated code
if (Test-Path $OutputDir) {
    Write-Host "Removing existing API client..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $OutputDir
}

# Create output directory
Write-Host "Creating output directory..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

# Step 1: API Change Detection and Generation
Write-Host "Step 1: API Change Detection and Generation" -ForegroundColor Yellow

# API change detection mechanism
$apiHashFile = "api/.api_spec_hash"

Write-Host "Checking for OpenAPI spec changes..." -ForegroundColor Yellow
# Download and hash the current OpenAPI spec
$currentHash = ""
$maxAttempts = 3

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "Fetching OpenAPI spec (attempt $i/$maxAttempts)" -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $OpenApiUrl -OutFile "current_openapi.json" -TimeoutSec 60
        $currentHash = (Get-FileHash -Path "current_openapi.json" -Algorithm SHA256).Hash.ToLower()
        Write-Host "Current OpenAPI spec hash: $currentHash" -ForegroundColor Green
        break
    } catch {
        Write-Host "Failed to fetch OpenAPI spec (attempt $i/$maxAttempts): $($_.Exception.Message)" -ForegroundColor Red
        if ($i -eq $maxAttempts) {
            Write-Host "WARNING: Could not fetch OpenAPI spec for change detection, proceeding with generation" -ForegroundColor Yellow
            $currentHash = "force-generation"
            break
        }
        Start-Sleep -Seconds 5
    }
}

# Check if we have a previous hash and if the spec has changed
$shouldGenerate = $true
if (Test-Path $apiHashFile) {
    $previousHash = Get-Content -Path $apiHashFile -Raw
    $previousHash = $previousHash.Trim()
    Write-Host "Previous OpenAPI spec hash: $previousHash" -ForegroundColor Green
    
    $serializersFile = Join-Path $OutputDir "lib/src/serializers.g.dart"
    if (($currentHash -eq $previousHash) -and (Test-Path $OutputDir) -and (Test-Path $serializersFile)) {
        Write-Host "OpenAPI spec unchanged and valid API client exists - skipping generation" -ForegroundColor Green
        $shouldGenerate = $false
    } else {
        Write-Host "OpenAPI spec changed or API client missing - proceeding with generation" -ForegroundColor Yellow
    }
} else {
    Write-Host "No previous hash found - proceeding with initial generation" -ForegroundColor Yellow
}

if ($shouldGenerate) {
    Write-Host "Generating API client..." -ForegroundColor Yellow
    
    # Generate base API files with OpenAPI CLI with retry logic

$maxAttempts = 3
$success = $false

for ($i = 1; $i -le $maxAttempts; $i++) {
    Write-Host "API generation attempt $i/$maxAttempts" -ForegroundColor Yellow
    
    $generateArgs = @(
        "-jar", $JarFile, "generate",
        "-i", $OpenApiUrl,
        "-g", "dart-dio",
        "-o", $OutputDir,
        "--additional-properties=pubName=arkad_api,pubVersion=1.0.0,pubDescription=`"OpenAPI API client`""
    )
    & java @generateArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "API generation successful" -ForegroundColor Green
        $success = $true
        break
    } else {
        Write-Host "API generation attempt $i failed" -ForegroundColor Red
        if ($i -eq $maxAttempts) {
            Write-Host "ERROR: All API generation attempts failed" -ForegroundColor Red
            Write-Host "Please check your internet connection and the OpenAPI endpoint"
            exit 1
        }
        Write-Host "Retrying in 15 seconds..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
        
        # Clean up partial generation
        if (Test-Path $OutputDir) {
            Get-ChildItem -Path $OutputDir -Recurse | Remove-Item -Force -Recurse
        }
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
}

Write-Host "Base API client generated successfully" -ForegroundColor Green

# Step 2: Complete API generation with build_runner
Write-Host "Step 2: Completing API generation with build_runner..." -ForegroundColor Yellow

# Check if Flutter is available
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "Flutter is available" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter to complete API generation"
    exit 1
}

# Enter API directory and install dependencies
$originalLocation = Get-Location
try {
    Set-Location $OutputDir
    
    Write-Host "Installing API dependencies with retry logic..." -ForegroundColor Yellow
    $pubGetMaxAttempts = 3
    $pubGetSuccess = $false
    
    for ($j = 1; $j -le $pubGetMaxAttempts; $j++) {
        Write-Host "Flutter pub get attempt $j/$pubGetMaxAttempts" -ForegroundColor Yellow
        flutter pub get
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Dependencies installed successfully" -ForegroundColor Green
            $pubGetSuccess = $true
            break
        } else {
            Write-Host "Flutter pub get attempt $j failed" -ForegroundColor Red
            if ($j -eq $pubGetMaxAttempts) {
                Write-Host "ERROR: All flutter pub get attempts failed" -ForegroundColor Red
                Write-Host "Please check your internet connection and pub.dev availability"
                exit 1
            }
            Write-Host "Retrying in 10 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }
    
    Write-Host "Generating .g.dart files with build_runner (with retry logic)..." -ForegroundColor Yellow
    $buildRunnerMaxAttempts = 2
    $buildRunnerSuccess = $false
    
    for ($k = 1; $k -le $buildRunnerMaxAttempts; $k++) {
        Write-Host "Build runner attempt $k/$buildRunnerMaxAttempts" -ForegroundColor Yellow
        dart run build_runner build --delete-conflicting-outputs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Build runner completed successfully" -ForegroundColor Green
            $buildRunnerSuccess = $true
            break
        } else {
            Write-Host "Build runner attempt $k failed" -ForegroundColor Red
            if ($k -eq $buildRunnerMaxAttempts) {
                Write-Host "ERROR: All build runner attempts failed" -ForegroundColor Red
                exit 1
            }
            Write-Host "Retrying in 5 seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            # Clean up partial .g.dart files before retry
            Get-ChildItem -Path . -Recurse -Filter "*.g.dart" | Remove-Item -Force
        }
    }
    
} finally {
    Set-Location $originalLocation
}

# Step 3: Validate generation completed successfully
Write-Host "Step 3: Validating API generation..." -ForegroundColor Yellow

# Check for critical .g.dart files
$serializersFile = Join-Path $OutputDir "lib/src/serializers.g.dart"
if (-Not (Test-Path $serializersFile)) {
    Write-Host "ERROR: serializers.g.dart not generated" -ForegroundColor Red
    Write-Host "API generation may be incomplete"
    exit 1
}

# Count .g.dart files to ensure generation worked
$generatedFiles = Get-ChildItem -Path $OutputDir -Recurse -Filter "*.g.dart"
$generatedCount = $generatedFiles.Count
Write-Host "Generated $generatedCount .g.dart files" -ForegroundColor Green

if ($generatedCount -lt 5) {
    Write-Host "ERROR: Too few .g.dart files generated ($generatedCount < 5)" -ForegroundColor Red
    Write-Host "API generation may be incomplete"
    exit 1
}

# Update main project dependencies
Write-Host "Updating main project dependencies..." -ForegroundColor Yellow
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "Warning: Failed to update main project dependencies" -ForegroundColor Yellow
    Write-Host "You may need to run 'flutter pub get' manually"
}

    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "API generation completed successfully!" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    
    # Store the current hash for future change detection
    New-Item -ItemType Directory -Path "api" -Force | Out-Null
    Set-Content -Path $apiHashFile -Value $currentHash
    Write-Host "Stored API spec hash for future change detection" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Generated files:" -ForegroundColor Green
    Write-Host "  - Base API client: $OutputDir"
    Write-Host "  - Generated .g.dart files: $generatedCount"
    Write-Host "  - Serializers: $serializersFile"
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Green
    Write-Host "  - API client is ready to use in your Flutter app"
    Write-Host "  - Import from: 'package:arkad_api/arkad_api.dart'"
    Write-Host "  - Run 'flutter analyze' to verify integration"
    
} else {
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host "API client is up to date (no changes)" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Using existing files:" -ForegroundColor Green
    Write-Host "  - Base API client: $OutputDir"
    $existingSerializersFile = Join-Path $OutputDir "lib/src/serializers.g.dart"
    Write-Host "  - Serializers: $existingSerializersFile"
    Write-Host ""
    Write-Host "The API client is ready to use in your Flutter app" -ForegroundColor Green
}

# Cleanup temporary files
if (Test-Path "current_openapi.json") {
    Remove-Item "current_openapi.json" -Force
}