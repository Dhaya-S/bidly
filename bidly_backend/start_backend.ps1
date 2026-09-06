# Bidly Backend - Background Start Script
$envFile = Join-Path $PSScriptRoot ".env"
$jvmArgs = @()
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            $k = $matches[1].Trim()
            $v = $matches[2].Trim()
            $jvmArgs += "-D$k=$v"
        }
    }
}

# Free port 8081 if occupied
$portOccupied = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($portOccupied) {
    $procId = $portOccupied.OwningProcess
    Write-Host "[WARN] Stopping existing process on port 8081 (PID $procId)..."
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
        Write-Host "[OK] ADB port reverse (tcp:8081 -> tcp:8081) configured."
    }
}

$javaBin = "java"
if (Test-Path "C:\Program Files\Android\Android Studio\jbr\bin\java.exe") {
    $javaBin = "C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
}

$jarPath = Join-Path $PSScriptRoot "build\libs\bidly-backend-0.0.1-SNAPSHOT.jar"
$outLog = Join-Path $PSScriptRoot "backend_out.log"
$errLog = Join-Path $PSScriptRoot "backend_err.log"

$argList = @()
foreach ($arg in $jvmArgs) {
    $argList += $arg
}
$argList += "-jar"
$argList += $jarPath

Write-Host "[INFO] Launching independent backend process with $javaBin..."
$proc = Start-Process -FilePath $javaBin -ArgumentList $argList -RedirectStandardOutput $outLog -RedirectStandardError $errLog -PassThru
Write-Host "[OK] Bidly backend launched with PID $($proc.Id)!"
