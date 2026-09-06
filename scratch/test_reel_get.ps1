$r = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/reels?page=0&size=50"
Write-Host "Testing GET on $($r.data.Count) reels..."

foreach ($item in $r.data) {
    $url = $item.reelUrl
    $id = $item.id
    $title = $item.title
    try {
        $req = [System.Net.HttpWebRequest]::Create($url)
        $req.Method = "GET"
        $req.AddRange(0, 1024) # read first 1KB
        $req.Timeout = 5000
        $res = $req.GetResponse()
        $status = [int]$res.StatusCode
        $len = $res.ContentLength
        $type = $res.ContentType
        $stream = $res.GetResponseStream()
        $buf = New-Object byte[] 16
        $read = $stream.Read($buf, 0, 16)
        $stream.Close()
        $res.Close()
        Write-Host "[OK $status] $title ($id): type=$type, readBytes=$read" -ForegroundColor Green
    } catch [System.Net.WebException] {
        $errRes = $_.Exception.Response
        if ($errRes) {
            $errStatus = [int]$errRes.StatusCode
            $sr = New-Object System.IO.StreamReader($errRes.GetResponseStream())
            $body = $sr.ReadToEnd()
            $sr.Close()
            Write-Host "[FAIL $errStatus] $title ($id): $body" -ForegroundColor Red
        } else {
            Write-Host "[ERR] $title ($id): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
