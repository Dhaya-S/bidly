$p0 = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=0&size=10"
$p1 = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=1&size=10"
$p2 = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=2&size=10"

Write-Host "Page 0 count: $($p0.data.Count)"
Write-Host "Page 1 count: $($p1.data.Count)"
Write-Host "Page 2 count: $($p2.data.Count)"
Write-Host "Total verified across pages: $($p0.data.Count + $p1.data.Count + $p2.data.Count)"

Write-Host "`n--- Sample Items from Page 0 ---"
foreach ($r in $p0.data) {
    Write-Host "- $($r.title) [₹$($r.price)] ($($r.sellingMethod)) - $($r.locality)"
}
