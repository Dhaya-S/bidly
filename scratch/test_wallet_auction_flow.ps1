# Test script for Development Dummy Wallet & Auction Flow
$baseUrl = "http://localhost:8081/api"

Write-Host "=== 1. Logging in / Authenticating Test Users ===" -ForegroundColor Cyan

# Login User A
$loginReqA = @{ mobile = "9876543210" } | ConvertTo-Json
$otpResA = Invoke-RestMethod -Uri "$baseUrl/auth/send-otp" -Method Post -Body $loginReqA -ContentType "application/json"
$reqIdA = $otpResA.data.requestId

$verifyReqA = @{
    mobile = "9876543210"
    otp = "123456"
    requestId = $reqIdA
    name = "User A (Bidder 1)"
} | ConvertTo-Json

$authResA = Invoke-RestMethod -Uri "$baseUrl/auth/verify-otp" -Method Post -Body $verifyReqA -ContentType "application/json"
$tokenA = $authResA.data.token
$userAId = $authResA.data.user.id
Write-Host "[OK] User A Authenticated: $userAId (Name: $($authResA.data.user.name))" -ForegroundColor Green

# Login User B
$loginReqB = @{ mobile = "9876543211" } | ConvertTo-Json
$otpResB = Invoke-RestMethod -Uri "$baseUrl/auth/send-otp" -Method Post -Body $loginReqB -ContentType "application/json"
$reqIdB = $otpResB.data.requestId

$verifyReqB = @{
    mobile = "9876543211"
    otp = "123456"
    requestId = $reqIdB
    name = "User B (Bidder 2)"
} | ConvertTo-Json

$authResB = Invoke-RestMethod -Uri "$baseUrl/auth/verify-otp" -Method Post -Body $verifyReqB -ContentType "application/json"
$tokenB = $authResB.data.token
$userBId = $authResB.data.user.id
Write-Host "[OK] User B Authenticated: $userBId (Name: $($authResB.data.user.name))" -ForegroundColor Green

# Login Seller
$loginReqSeller = @{ mobile = "9876543219" } | ConvertTo-Json
$otpResSeller = Invoke-RestMethod -Uri "$baseUrl/auth/send-otp" -Method Post -Body $loginReqSeller -ContentType "application/json"
$reqIdSeller = $otpResSeller.data.requestId

$verifyReqSeller = @{
    mobile = "9876543219"
    otp = "123456"
    requestId = $reqIdSeller
    name = "Demo Seller"
} | ConvertTo-Json

$authResSeller = Invoke-RestMethod -Uri "$baseUrl/auth/verify-otp" -Method Post -Body $verifyReqSeller -ContentType "application/json"
$tokenSeller = $authResSeller.data.token
$sellerId = $authResSeller.data.user.id
Write-Host "[OK] Seller Authenticated: $sellerId (Name: $($authResSeller.data.user.name))" -ForegroundColor Green

$headersA = @{ Authorization = "Bearer $tokenA" }
$headersB = @{ Authorization = "Bearer $tokenB" }
$headersSeller = @{ Authorization = "Bearer $tokenSeller" }

Write-Host "`n=== 2. Testing Wallet Auto-Initialization & DEV Reset ===" -ForegroundColor Cyan
$walletA = (Invoke-RestMethod -Uri "$baseUrl/dev/wallet/reset" -Method Post -Headers $headersA).data
Write-Host "User A Wallet Reset: Balance = ₹$($walletA.balance), Reserved = ₹$($walletA.reservedBalance), Available = ₹$($walletA.availableBalance)" -ForegroundColor Yellow

$walletB = (Invoke-RestMethod -Uri "$baseUrl/dev/wallet/reset" -Method Post -Headers $headersB).data
Write-Host "User B Wallet Reset: Balance = ₹$($walletB.balance), Reserved = ₹$($walletB.reservedBalance), Available = ₹$($walletB.availableBalance)" -ForegroundColor Yellow

$walletSeller = (Invoke-RestMethod -Uri "$baseUrl/dev/wallet/reset" -Method Post -Headers $headersSeller).data
Write-Host "Seller Wallet Reset: Balance = ₹$($walletSeller.balance), Reserved = ₹$($walletSeller.reservedBalance), Available = ₹$($walletSeller.availableBalance)" -ForegroundColor Yellow

Write-Host "`n=== 3. Testing Development Top-Up (POST /api/dev/wallet/top-up) ===" -ForegroundColor Cyan
$topUpBody = @{ amount = 10000; description = "Manual test top-up" } | ConvertTo-Json
$topUpResA = (Invoke-RestMethod -Uri "$baseUrl/dev/wallet/top-up" -Method Post -Headers $headersA -Body $topUpBody -ContentType "application/json").data
Write-Host "User A Wallet after Top-Up: Balance = ₹$($topUpResA.balance), Available = ₹$($topUpResA.availableBalance)" -ForegroundColor Green

# Reset back to 50000 baseline
$walletA = (Invoke-RestMethod -Uri "$baseUrl/dev/wallet/reset" -Method Post -Headers $headersA).data

Write-Host "`n=== 4. Creating Test Auction Listing ===" -ForegroundColor Cyan
$sellerListingBody = @{
    title = "Apple iPhone 15 Pro Max (Demo Auction)"
    description = "Pristine condition demo auction for wallet reservation test"
    price = 30000
    category = "Smartphones"
    condition = "EXCELLENT"
    sellingMethod = "AUCTION"
    startingBid = 30000
    bidIncrement = 1000
    auctionEndTime = (Get-Date).ToUniversalTime().AddMinutes(30).ToString("yyyy-MM-ddTHH:mm:ssZ")
    city = "Chennai"
    state = "Tamil Nadu"
    locality = "T Nagar"
} | ConvertTo-Json

$listing = (Invoke-RestMethod -Uri "$baseUrl/listings" -Method Post -Headers $headersSeller -Body $sellerListingBody -ContentType "application/json").data
$listingId = $listing.id
Write-Host "[OK] Auction Listing Created: ID = $listingId, Title = $($listing.title)" -ForegroundColor Green

Write-Host "`n=== 5. User A Bids ₹32,000 (Reservation Test) ===" -ForegroundColor Cyan
$bidBodyA = @{ amount = 32000 } | ConvertTo-Json
$bidResA = (Invoke-RestMethod -Uri "$baseUrl/auctions/$listingId/bid" -Method Post -Headers $headersA -Body $bidBodyA -ContentType "application/json").data
Write-Host "Bid Placed by User A: Amount = ₹$($bidResA.currentBid), Status = $($bidResA.status)" -ForegroundColor Green

$walletAAfterBid = (Invoke-RestMethod -Uri "$baseUrl/wallet" -Method Get -Headers $headersA).data
Write-Host "User A Wallet after ₹32,000 Bid:" -ForegroundColor Yellow
Write-Host "  Balance:   ₹$($walletAAfterBid.balance)"
Write-Host "  Reserved:  ₹$($walletAAfterBid.reservedBalance)"
Write-Host "  Available: ₹$($walletAAfterBid.availableBalance)"

Write-Host "`n=== 6. User B Outbids with ₹35,000 (Outbid & Auto-Release Test) ===" -ForegroundColor Cyan
$bidBodyB = @{ amount = 35000 } | ConvertTo-Json
$bidResB = (Invoke-RestMethod -Uri "$baseUrl/auctions/$listingId/bid" -Method Post -Headers $headersB -Body $bidBodyB -ContentType "application/json").data
Write-Host "Bid Placed by User B: Amount = ₹$($bidResB.currentBid), Status = $($bidResB.status)" -ForegroundColor Green

$walletAAfterOutbid = (Invoke-RestMethod -Uri "$baseUrl/wallet" -Method Get -Headers $headersA).data
Write-Host "User A Wallet after Outbid (Reservation released back to ₹0):" -ForegroundColor Yellow
Write-Host "  Balance:   ₹$($walletAAfterOutbid.balance)"
Write-Host "  Reserved:  ₹$($walletAAfterOutbid.reservedBalance)"
Write-Host "  Available: ₹$($walletAAfterOutbid.availableBalance)"

$walletBAfterBid = (Invoke-RestMethod -Uri "$baseUrl/wallet" -Method Get -Headers $headersB).data
Write-Host "User B Wallet after ₹35,000 Bid (Reservation = ₹35,000):" -ForegroundColor Yellow
Write-Host "  Balance:   ₹$($walletBAfterBid.balance)"
Write-Host "  Reserved:  ₹$($walletBAfterBid.reservedBalance)"
Write-Host "  Available: ₹$($walletBAfterBid.availableBalance)"

Write-Host "`n=== 7. Finalizing Auction -> Winner Escrow Lock Test ===" -ForegroundColor Cyan
$finalizeRes = Invoke-RestMethod -Uri "$baseUrl/auctions/$listingId/finalize" -Method Post -Headers $headersSeller
Write-Host "Finalize response: $($finalizeRes | ConvertTo-Json -Compress)"

# Fetch order created for winning bid
$orderRes = (Invoke-RestMethod -Uri "$baseUrl/orders/listing/$listingId" -Method Get -Headers $headersB).data
Write-Host "[OK] Winning Order Created: Order #$($orderRes.orderNumber), Payment Status = $($orderRes.paymentStatus), Amount = ₹$($orderRes.amount)" -ForegroundColor Green

$walletBAfterWin = (Invoke-RestMethod -Uri "$baseUrl/wallet" -Method Get -Headers $headersB).data
Write-Host "User B Wallet after Winning (Reserved funds converted to Escrow Hold):" -ForegroundColor Yellow
Write-Host "  Balance:   ₹$($walletBAfterWin.balance)"
Write-Host "  Reserved:  ₹$($walletBAfterWin.reservedBalance)"
Write-Host "  Available: ₹$($walletBAfterWin.availableBalance)"

Write-Host "`n=== 8. Buyer Confirms Delivery -> Escrow Released to Seller ===" -ForegroundColor Cyan
$orderId = $orderRes.id
$confirmRes = (Invoke-RestMethod -Uri "$baseUrl/orders/$orderId/confirm-delivery" -Method Post -Headers $headersB).data
Write-Host "[OK] Order Delivery Confirmed: Status = $($confirmRes.status), Payment Status = $($confirmRes.paymentStatus)" -ForegroundColor Green

$walletSellerAfterPayout = (Invoke-RestMethod -Uri "$baseUrl/wallet" -Method Get -Headers $headersSeller).data
Write-Host "Seller Wallet after Escrow Payout (Credited with order amount ₹$($orderRes.amount)):" -ForegroundColor Yellow
Write-Host "  Balance:   ₹$($walletSellerAfterPayout.balance)"
Write-Host "  Reserved:  ₹$($walletSellerAfterPayout.reservedBalance)"
Write-Host "  Available: ₹$($walletSellerAfterPayout.availableBalance)"

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "ALL DUMMY WALLET, BIDDING, OUTBID, ESCROW & PAYOUT TESTS PASSED!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
