$conns = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue
foreach ($c in $conns) {
    Write-Host "Killing PID $($c.OwningProcess)"
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2
Write-Host "Port 8081 cleared"
