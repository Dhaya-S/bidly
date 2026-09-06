$pages = @(0, 1, 2)
$successCount = 0
$failCount = 0

foreach ($p in $pages) {
    $r = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=$p&size=10"
    foreach ($item in $r.data) {
        $url = $item.reelUrl
        $t = $item.title
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.Method = "GET"
            $req.AddRange(0, 1024)
            $req.Timeout = 4000
            $res = $req.GetResponse()
            $status = [int]$res.StatusCode
            $res.Close()
            if ($status -eq 200 -or $status -eq 206) {
                $successCount++
                Write-Host "[OK 206] $t" -ForegroundColor Green
            } else {
                Write-Host "Unexpected status $status for $t" -ForegroundColor Yellow
                $failCount++
            }
        } catch {
            Write-Host "Failed for $t" -ForegroundColor Red
            $failCount++
        }
    }
}

Write-Host "`nResult: $successCount playable reels (206), $failCount failed." -ForegroundColor Green
