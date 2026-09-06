$deals = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/deals-near-you" -Method Get
Write-Host "Deals Near You count: $($deals.data.Count)"
foreach ($d in $deals.data) {
    Write-Host "  - $($d.title) | ₹$($d.price) | $($d.sellingMethod) | loc=$($d.locality)"
}

$sellers = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/top-sellers" -Method Get
Write-Host "`nTop Sellers count: $($sellers.data.Count)"
foreach ($s in $sellers.data) {
    Write-Host "  - $($s.name) | listings=$($s.listingsCount) | rating=$($s.rating)"
}

$recent = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/recently-viewed" -Method Get
Write-Host "`nRecently Viewed count: $($recent.data.Count)"
foreach ($r in $recent.data) {
    Write-Host "  - $($r.title) | ₹$($r.price)"
}

$search = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/search?page=0&size=10" -Method Get
Write-Host "`nMarketplace search count: $($search.data.Count)"
foreach ($m in $search.data) {
    Write-Host "  - $($m.title) | ₹$($m.price) | $($m.sellingMethod) | cond=$($m.condition)"
}
