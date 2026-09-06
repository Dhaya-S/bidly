$r = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=0&size=50"
Write-Host "Total returned from /api/listings/reels: $($r.data.Count)"
foreach ($item in $r.data) {
    Write-Host "ID: $($item.id) | Title: $($item.title) | ReelUrl: $($item.reelUrl)"
}
