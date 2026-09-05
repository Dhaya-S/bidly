# Bidly Backend - Quick Start Script
# Usage: .\run.ps1

$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }
    Write-Host "[OK] Environment variables loaded from .env" -ForegroundColor Green
} else {
    Write-Host "[ERROR] .env file not found! Copy .env.example to .env and fill in your credentials." -ForegroundColor Red
    exit 1
}

# Auto-detect JAVA_HOME if not configured
if (-not $env:JAVA_HOME -and -not (Get-Command java -ErrorAction SilentlyContinue)) {
    $candidateJdks = @(
        "C:\Program Files\Android\Android Studio\jbr",
        "C:\Program Files\Java\jdk-21",
        "C:\Program Files\Java\jdk-17",
        "C:\Program Files\Eclipse Adoptium\jdk-21.0.0.35-hotspot",
        "C:\Program Files\Eclipse Adoptium\jdk-17.0.0.35-hotspot"
    )
    foreach ($jdk in $candidateJdks) {
        if (Test-Path "$jdk\bin\java.exe") {
            $env:JAVA_HOME = $jdk
            $env:PATH = "$jdk\bin;$env:PATH"
            Write-Host "[OK] JAVA_HOME auto-configured to $jdk" -ForegroundColor Green
            break
        }
    }
}

# Check and free port 8081 if occupied
$portOccupied = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($portOccupied) {
    $procId = $portOccupied.OwningProcess
    Write-Host "[WARN] Port 8081 is already in use by process ID $procId. Stopping it..." -ForegroundColor Yellow
    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# Auto-configure ADB reverse for Android devices
$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
$adbPath = $null
if ($adbCmd) {
    $adbPath = $adbCmd.Source
} elseif (Test-Path "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe") {
    $adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
}

if ($adbPath) {
    $devices = & $adbPath devices | Select-String -Pattern "\bdevice\b"
    if ($devices) {
        & $adbPath reverse tcp:8081 tcp:8081
        Write-Host "[OK] ADB port reverse (tcp:8081 -> tcp:8081) configured for Android device." -ForegroundColor Green
    }
}

$jarPath = Join-Path $PSScriptRoot "build\libs\bidly-backend-0.0.1-SNAPSHOT.jar"
if (Test-Path $jarPath) {
    Write-Host "[INFO] Starting Bidly Backend (Standalone JAR) on port 8081..." -ForegroundColor Cyan
    & java -jar $jarPath
} else {
    Write-Host "[INFO] Starting Bidly Backend via Gradle on port 8081..." -ForegroundColor Cyan
    .\gradlew.bat bootRun --no-daemon
}
