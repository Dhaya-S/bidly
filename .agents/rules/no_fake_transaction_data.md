# Bidly Project Rule: No Fake Transaction Data

## Overview
HARDCODED VALUES ARE STRICTLY FORBIDDEN FOR REAL APPLICATION AND TRANSACTION DATA.
This rule applies across the entire Bidly application, including all backend services, database seeders, API controllers, Flutter clients, state management providers, and UI screens.

## Allowed Hardcoded Values
Hardcoded values are allowed ONLY for UI/design constants such as:
- Colors and theme palettes
- Spacing, padding, and margins
- Border radius and elevations
- Animation durations and curves
- Typography and font sizes
- Static UI labels and button texts
- Standard Material/Cupertino icons
- Fixed UI configuration (e.g. maximum upload sizes, pagination defaults)
- Static category / option names that are genuinely part of domain business rules
- Validation limits (e.g. minimum password length, phone regex)

## Forbidden Hardcoded Values
Never hardcode or use fake/sample/mock fallback values for:
- User names, buyer names, seller names, bidder names
- Profile information (emails, phone numbers, addresses, bios)
- Listing titles, descriptions, prices, condition notes, images/media URLs
- Offer amounts, counter-offer amounts, bid amounts, bid counts
- Auction winner, auction status, countdown/end times
- Order IDs, listing IDs, offer IDs, bid IDs, client transaction IDs
- Wallet balances, wallet top-up transactions, escrow amounts
- Verification OTP values, OTP expiration timestamps
- Tracking numbers, courier partner names, shipment status events
- Meetup dates, meetup times, meetup locations
- Buyer addresses, seller locations, dispatch hubs
- Chat messages, message timestamps, unread counts
- Order statuses, payment statuses, delivery statuses
- Sale dates, sale amounts, review/rating information
- Any database entity fields or API response payload attributes

## Null Fallback Rules
DO NOT use fake values as null fallbacks.
Examples of strictly forbidden patterns:
```dart
// BAD:
order['buyerName']?.toString() ?? 'Priya Menon';
listing['price'] ?? 75000;
shipment['trackingNumber'] ?? 'EKRT2345678';
order['meetupDate'] ?? DateTime(2026, 5, 20);
buyerFromApi ?? 'Demo Buyer';
walletState.balance ?? 38000.0;
summary['transactionId'] ?? '#TXN-12345';
```

If a real backend/database value is missing or null:
1. Show an appropriate loading state (CircularProgressIndicator, skeleton shimmer)
2. Show an empty state ("No orders yet", "No messages yet")
3. Show an unavailable/pending state ("Tracking pending", "Location to be coordinated")
4. Show an error or retry state when network/API failure occurs

## Architecture & Data Flow
Real transaction data MUST flow as:
```
Database -> Spring Boot Entity -> Repository -> Service -> Controller / API -> Flutter ApiClient -> Riverpod Provider/Notifier -> Flutter UI Screen
```
Never bypass the real backend by fabricating transactions or fallbacks in the Flutter client.
