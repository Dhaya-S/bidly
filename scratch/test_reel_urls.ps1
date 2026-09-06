$r = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=0&size=50"
Write-Host "Checking $($r.data.Count) reels..."

foreach ($item in $r.data) {
    $url = $item.reelUrl
    $id = $item.id
    $title = $item.title
    try {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = "HEAD"
        $req.Timeout = 5000
        $res = $req.GetResponse()
        $status = [int]$res.StatusCode
        $len = $res.ContentLength
        $type = $res.ContentType
        $res.Close()
        Write-Host "[OK $status] $title ($id): len=$len, type=$type" -ForegroundColor Green
    } catch [System.Net.WebException] {
        $errRes = $_.Exception.Response
        if ($errRes) {
            $errStatus = [int]$errRes.StatusCode
            Write-Host "[FAIL $errStatus] $title ($id): $($_.Exception.Message)" -ForegroundColor Red
        } else {
            Write-Host "[ERR] $title ($id): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
