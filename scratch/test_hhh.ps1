$url = "listings/reels/bff21717-78ab-432c-bfc6-dd92ffdb16c5.mp4"
$presigned = Invoke-RestMethod -Uri "http://localhost:8081/api/listings/4d63453c-53b0-4f0c-98c1-bcfe141207ba" -Method Get
Write-Host "hhh reelUrl: $($presigned.data.reelUrl)"

if ($presigned.data.reelUrl) {
    try {
        $req = [System.Net.HttpWebRequest]::Create($presigned.data.reelUrl)
        $req.Method = "GET"
        $req.AddRange(0, 1024)
        $res = $req.GetResponse()
        Write-Host "hhh Video Playable! Status: $($res.StatusCode)" -ForegroundColor Green
        $res.Close()
    } catch {
        Write-Host "hhh Video Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}
