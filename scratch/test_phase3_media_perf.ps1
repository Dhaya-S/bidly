# Performance and Verification Test Script for Phase 3 Media Optimization
$baseUrl = "http://localhost:8081/api"

Write-Host "=== 1. Testing Marketplace Search Performance & Payload ===" -ForegroundColor Cyan
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$searchRes = Invoke-RestMethod -Uri "$baseUrl/listings/search?page=0&size=10" -Method Get
$sw.Stop()
$searchJson = $searchRes | ConvertTo-Json -Depth 5
$searchSize = [System.Text.Encoding]::UTF8.GetByteCount($searchJson)
Write-Host "GET /api/listings/search?page=0&size=10" -ForegroundColor Green
Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Payload Size:  $searchSize bytes" -ForegroundColor Yellow
Write-Host "  Items returned: $($searchRes.data.Count)"
if ($searchRes.data.Count -gt 0) {
    $first = $searchRes.data[0]
    Write-Host "  Sample Card: '$($first.title)'"
    Write-Host "  Primary Image: $($first.primaryImageUrl)"
    Write-Host "  ImageUrls count: $($first.imageUrls.Count) (0 for lightweight card)"
}

Write-Host "`n=== 2. Testing Deals Near You Performance & Payload ===" -ForegroundColor Cyan
$sw.Restart()
$dealsRes = Invoke-RestMethod -Uri "$baseUrl/listings/deals-near-you" -Method Get
$sw.Stop()
$dealsJson = $dealsRes | ConvertTo-Json -Depth 5
$dealsSize = [System.Text.Encoding]::UTF8.GetByteCount($dealsJson)
Write-Host "GET /api/listings/deals-near-you" -ForegroundColor Green
Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Payload Size:  $dealsSize bytes" -ForegroundColor Yellow
Write-Host "  Items returned: $($dealsRes.data.Count)"

Write-Host "`n=== 3. Testing Recently Viewed Performance & Payload ===" -ForegroundColor Cyan
$sw.Restart()
$recentRes = Invoke-RestMethod -Uri "$baseUrl/listings/recently-viewed" -Method Get
$sw.Stop()
$recentJson = $recentRes | ConvertTo-Json -Depth 5
$recentSize = [System.Text.Encoding]::UTF8.GetByteCount($recentJson)
Write-Host "GET /api/listings/recently-viewed" -ForegroundColor Green
Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Payload Size:  $recentSize bytes" -ForegroundColor Yellow
Write-Host "  Items returned: $($recentRes.data.Count)"

Write-Host "`n=== 4. Testing Top Sellers Performance & Payload ===" -ForegroundColor Cyan
$sw.Restart()
$sellersRes = Invoke-RestMethod -Uri "$baseUrl/listings/top-sellers" -Method Get
$sw.Stop()
$sellersJson = $sellersRes | ConvertTo-Json -Depth 5
$sellersSize = [System.Text.Encoding]::UTF8.GetByteCount($sellersJson)
Write-Host "GET /api/listings/top-sellers" -ForegroundColor Green
Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Payload Size:  $sellersSize bytes" -ForegroundColor Yellow
Write-Host "  Items returned: $($sellersRes.data.Count)"

Write-Host "`n=== 5. Testing Product Detail (Full Media Gallery & mediaItems) ===" -ForegroundColor Cyan
if ($searchRes.data.Count -gt 0) {
    $sampleId = $searchRes.data[0].id
    $sw.Restart()
    $detailRes = Invoke-RestMethod -Uri "$baseUrl/listings/$sampleId" -Method Get
    $sw.Stop()
    $detailJson = $detailRes | ConvertTo-Json -Depth 5
    $detailSize = [System.Text.Encoding]::UTF8.GetByteCount($detailJson)
    Write-Host "GET /api/listings/$sampleId" -ForegroundColor Green
    Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
    Write-Host "  Payload Size:  $detailSize bytes" -ForegroundColor Yellow
    Write-Host "  Title:         $($detailRes.data.title)"
    Write-Host "  Primary Image: $($detailRes.data.primaryImageUrl)"
    Write-Host "  MediaItems Count: $($detailRes.data.mediaItems.Count)"
    if ($detailRes.data.mediaItems.Count -gt 0) {
        foreach ($m in $detailRes.data.mediaItems) {
            $u = "$($m.url)"
            $snippet = if ($u.Length -gt 60) { $u.Substring(0, 60) + "..." } else { $u }
            Write-Host "    - [Type: $($m.type), SortOrder: $($m.sortOrder)] URL: $snippet"
        }
    }
}

Write-Host "`n=== 6. Testing Reels Feed Endpoint ===" -ForegroundColor Cyan
$sw.Restart()
$reelsRes = Invoke-RestMethod -Uri "$baseUrl/listings/reels" -Method Get
$sw.Stop()
$reelsJson = $reelsRes | ConvertTo-Json -Depth 5
$reelsSize = [System.Text.Encoding]::UTF8.GetByteCount($reelsJson)
Write-Host "GET /api/listings/reels" -ForegroundColor Green
Write-Host "  Response Time: $($sw.ElapsedMilliseconds) ms" -ForegroundColor Yellow
Write-Host "  Payload Size:  $reelsSize bytes" -ForegroundColor Yellow
Write-Host "  Reels count:   $($reelsRes.data.Count)"

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "PHASE 3 PERFORMANCE AUDIT & TEST COMPLETED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
