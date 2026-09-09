# Build the Bidly Admin Web App

You are building an admin panel web application for **Bidly** — a second-hand marketplace app (like OLX meets eBay). The app has a Flutter mobile client and a Spring Boot backend already running.

I have provided UI design screenshots in the `ui_reference/` folder. **Follow these designs exactly** for layout, colors, components, and navigation.

## Project Location & Structure

Create this web app **freshly** in the `bidly_admin_web/` folder:

```
c:/Users/Edufic/Desktop/bidly/
├── bidly_app/            ← Flutter mobile app (existing, don't touch)
├── bidly_backend/        ← Spring Boot REST API (existing, don't touch)
├── bidly_admin/          ← Existing folder (don't touch)
└── bidly_admin_web/      ← NEW React admin web app (create everything here from scratch)
```

**Start fresh** — scaffold the React + Vite + TypeScript project from scratch in `bidly_admin_web/`:

```bash
cd c:/Users/Edufic/Desktop/bidly
npx -y create-vite@latest bidly_admin_web -- --template react-ts
cd bidly_admin_web
npm install antd @ant-design/icons @ant-design/charts axios zustand react-router-dom dayjs lucide-react
npm run dev
```

## Tech Stack

- **React 18+** with **Vite** (`react-ts` template)
- **TypeScript**
- **React Router v6** for routing
- **Zustand** for state management
- **Axios** with JWT interceptors for HTTP
- **Ant Design 5** (`antd`) for UI components, tables, forms, layout
- **@ant-design/charts** or **Recharts** for charts
- **Lucide React** or **@ant-design/icons** for icons
- **dayjs** for dates

## Backend Connection (.env)

Create `.env` in `bidly_admin_web/` root:

```env
VITE_API_BASE_URL=http://127.0.0.1:8081/api
VITE_R2_PUBLIC_URL=<CF_R2_PUBLIC_URL from bidly_backend .env>
VITE_APP_NAME=Bidly Admin
VITE_APP_VERSION=1.0.0
```

Create `.env.production`:

```env
VITE_API_BASE_URL=https://your-production-domain.com/api
VITE_R2_PUBLIC_URL=https://pub-xxx.r2.dev
VITE_APP_NAME=Bidly Admin
VITE_APP_VERSION=1.0.0
```

- The Spring Boot backend runs at `http://127.0.0.1:8081/api`
- CORS is already enabled for all origins
- Auth uses JWT — send as `Authorization: Bearer <token>` header
- JWT subject is the user's UUID
- Store token in `localStorage` key `bidly_admin_token`
- On 401 response → clear token → redirect to `/login`
- Media files served via: `VITE_API_BASE_URL + '/media/file/' + objectKey`

---

## UI DESIGN REFERENCE

See `ui_reference/` folder for screenshots. Here is a detailed description of each screen:

### Design System (extracted from UI screenshots)
- **Background**: White (`#FFFFFF`) main content area
- **Sidebar**: Dark navy/charcoal (`#1A1D21`) with white icons, collapsible
- **Primary accent**: Teal/green (`#0D9488` or `#0F766E`) — used for active sidebar items, buttons, links, badges
- **Active status badge**: Green pill (`Active`)
- **Suspended badge**: Orange/red pill (`Suspended`)
- **Inactive badge**: Gray pill (`Inactive`)
- **Verified badge**: Teal pill (`Verified`)
- **Card style**: White cards with subtle gray borders, no heavy shadows
- **Typography**: Clean sans-serif (Inter or system font), dark gray text
- **KPI cards**: White background, colored icon circle (teal, green, orange, red), big number, subtitle, trend text
- **Tables**: Clean rows with light hover, no heavy grid lines
- **Login background**: Dark teal gradient (`#0F4C4C` to `#1A3A3A`)
- **Login card**: White card centered on gradient background
- **Currency**: Indian Rupees (₹) format

### Screen 1: Login — Email Step
- Dark teal gradient background
- Centered white card
- Logo: Bidly icon + "Bidly Admin" title + "Operations Panel" subtitle
- Stepper: Step 1 "Email" (active, green dot) → Step 2 "Verify OTP" (inactive, gray)
- Heading: "Welcome back"
- Subtext: "Enter your email to receive a one-time password"
- Input: "Email address" label, placeholder "admin@bidly.com"
- Button: Teal/green filled button "Send OTP →"
- Validation text below input
- Footer: "© 2025 Bidly Technologies Pvt. Ltd. All rights reserved."

### Screen 2: Login — OTP Verification Step
- Same gradient background and card layout
- Stepper: Step 1 "Email" (completed, green checkmark) → Step 2 "Verify OTP" (active, green dot)
- Heading: "Verify your identity"
- Subtext: "We sent a 6-digit OTP to" + masked email (e.g., "si•••k•••fs2@k•••t")
- 6 individual OTP input boxes (single digit each)
- "Didn't receive the OTP?" link + "Resend in 27s" countdown timer
- Button: Teal filled "Verify & Sign In 🔒"
- "← Change email address" link below
- Footer: same as login
- Below card: "Demo: enter any 6 digits to sign in"

### Screen 3: Dashboard
- **Top bar**: Bidly logo (left), search bar "Search users, auctions, orders...", notification bell with red badge (right), user avatar + "Aryan Sharma" + "Super Admin" (right)
- **Sidebar** (dark, icon-only when collapsed, expandable):
  - Dashboard (grid icon) — active/highlighted
  - Users (people icon)
  - Marketplace section icons (briefcase → Auctions, Direct Buy)
  - Orders (document icon)
  - Payments (credit card icon)
  - Wallet (wallet icon)
  - Subscriptions (star icon)
  - Communities (chat bubbles icon)
  - Trust & Safety (shield icon)
  - Reports & Disputes (flag icon)
  - Reviews (star icon)
  - Engagement (megaphone icon)
  - Analytics (bar chart icon)
  - Settings (gear icon)
  - Collapse arrow (bottom)
- **Page title**: "Dashboard" + "Welcome back! Here's what's happening on Bidly today." + "● Live" green badge
- **4 KPI cards in a row**:
  1. Blue/teal icon circle + "18" Total Users + "+23 this week" (green trend)
  2. Yellow/orange icon circle + "9" Active Auctions + "3 ending soon" (teal link)
  3. Green icon circle + "₹3.98L" Revenue (MTD) + "+18.4% vs last month" (green trend)
  4. Red/orange icon circle + "3" Pending Disputes + "1 critical priority" (red text)
- **Revenue Overview card**: Line chart with area fill (teal), months Jan-Jun, values ₹0-₹438K, dashed baseline, "Click to drill down →" link
- **Auction Activity card**: Bar chart (dark teal bars), monthly auctions
- **User Growth section**: "Buyers vs Sellers — monthly new registrations" + legend (● Buyers ● Sellers) + "View all users →" link
  - 4 mini KPI cards: Total Buyers (2,456, +15.2%), Total Sellers (189, +8.1%), New This Month (322 Buyers + Sellers), Buyer/Seller Ratio (13:1 Healthy ratio)
  - Dual line chart: Buyers line (teal dots) + Sellers line (green dots), Jan-Jun

### Screen 4: Users List
- **Page title**: "Users" + "18 total users · 3 active on both sides" + "⬇ Export CSV" button (top right)
- **4 filter/stat cards**: Total Users (18), Buyers (10), Sellers (11), Both Roles (3) — each with colored icon
- **Filter bar**: Search input "Search by name, location, phone..." + role tabs (All (18), Buyers (7), Sellers (8), Both (3)) + status tabs (All Status, Active, Suspended, Inactive, Verified)
- **Table columns**: User (avatar circle with initials + name + phone), Role (Buyer/Seller/Buyer+Seller badge), Location, Status (Active/Suspended/Inactive badge), Wallet (₹ amount), Joined (date), Last Active (relative time), Action ("View Profile" teal link button)
- **Table rows**: Show user data with colored avatar circles (random colors per user)
- **Footer**: "Showing 18 of 18 users"

### Screen 5: User Detail — Buyer Profile (Priya Singh)
- **Header**: Name "Priya Singh" + status badge (Active, green) + role "Buyer · Joined 2024-02-20"
- **Action buttons**: "💬 Message" (teal) + "⚠ Suspend" (red outline)
- **4 stat cards**: Wallet Balance (₹5,600), Total Spent (₹28,300), Total Bids (21), Auctions Won (5)
- **Tabs**: Profile, Wallet, Activity, Communities, Reports, Chats, Buy, Sell
- **Profile tab content**:
  - User card: Avatar circle "PS" + name + phone
  - Address card: Blue-bordered card with address details + "Preferred meeting radius: 20 km"
  - Recent Orders: List showing "Engineering Books Set ₹3,200 2024-03-01 Delivered"
  - Info rows: Member Since (2024-02-20), Last Active (1 day ago), Reports Filed (1 report)

### Screen 6: User Detail — Buyer Wallet Tab
- **Sidebar expanded** showing full navigation with labels:
  - Dashboard, Users (highlighted), Marketplace → Auctions/Direct Buy, Orders, Payments, Wallet, Subscriptions, Communities, Trust & Safety, Reports & Disputes, Reviews, Engagement, Analytics, Settings, Collapse
- **Wallet tab content**:
  - Dark teal card: "Current Balance ₹5,600" + "Total Spent: ₹18,200"
  - Two action buttons: "+ Credit Wallet" (teal outline) + "🔒 Freeze Wallet" (red outline)
  - **Top-up History table**: Date & Time, Reference, Method, Amount, Status columns
  - **Transaction History**: "No transactions." (empty state)

### Screen 7: User Detail — Seller Profile (TechVault Store)
- **Header**: "TechVault Store" + "Verified" teal badge + "💬 Message" + "⚠ Suspend" buttons
- **Subtitle**: "Seller · Electronics · Joined 2023-08-10"
- **4 stat cards**: Wallet Balance (₹87,600), Total Sales (₹2,34,000), Active Listings (45, green, "View all →"), Items Sold (189, orange, "View all →")
- **Tabs**: Profile, Listings, Sold Items, Performance, Reviews, Communities, Wallet, Buy, Sell
- **Profile tab**:
  - Store card: Avatar "TV" + store name + phone + ⭐ 4.8 (155 reviews)
  - Business Address card: Green-bordered card with "📦 BUSINESS ADDRESS" + full address + "Service radius: 30 km"
  - Info: Category (Electronics), Location (Mumbai), Total Reviews (156 reviews), Member Since (2023-09-16)
  - Community badge: "Admin of 1 community" → "Electronics Hub" + "5,418 members · Bangalore"

### Screen 8: User Detail — Seller Listings Tab
- Same header as seller profile
- **Listings tab active**
- Summary: "2 direct buy + 2 auctions"
- **AUCTIONS section**:
  - Row: "Auction" badge (teal) + "Apple MacBook Pro M3 Max" + "₹1,78,000" + "Live" badge (green)
  - Row: "Auction" badge (teal) + "Sony A7R V Camera Bundle" + "₹2,80,000" + "Upcoming" badge (orange)
- **DIRECT BUY section**:
  - Row: "Direct Buy" badge (green) + "iPhone 15 Pro Max 256GB" + "₹1,60,000" + "Available" badge
  - Row: "Direct Buy" badge (green) + "Sony WH-1000XM5 Headphones" + "₹18,000" + "Available" badge

### Screen 9: Auctions — Collapsed Sidebar
- **Sidebar collapsed** (icon-only mode, narrow)
- Sidebar shows "Bidly Admin" label at top when expanded
- **Page title**: "Auctions" + "8 live · 1 ending soon" + grid/list view toggle buttons (top right)
- **Filter bar**: Search "Search auctions..." + status tabs (All Status, Live, Ending Soon, Upcoming, Completed) + category pills (All, Electronics, Jewelry, Art, Sports, Antiques, Fashion, Books, Vehicles)
- **Table columns**: Auction (title + category subtitle), Seller (store name as teal link), Start Price (₹), Current Bid (₹, bold green), Bids (count), Ends In (countdown like "2h 34m", "4h 12m"), Watchers (count), Status (Live/Upcoming/Ending Soon badge)
- **Status badges**: "Live" = green, "Upcoming" = orange/yellow, "Ending Soon" = red pill
- **Row click**: navigable (arrow indicator)

### Screen 10: Auctions — Expanded Sidebar
- Same auctions page but **sidebar expanded** showing full labels
- Sidebar structure visible:
  - Bidly logo + "Admin" badge
  - Dashboard
  - Users
  - Marketplace (expanded, highlighted section):
    - **Auctions** (currently active, teal highlight)
    - Direct Buy
  - Orders
  - Payments
  - Wallet
  - Subscriptions
  - Communities
  - Trust & Safety (expandable)
  - Reports & Disputes
  - Reviews
  - Engagement
  - Analytics
  - Settings
  - Collapse (bottom)

---

## SIDEBAR NAVIGATION (from UI designs — follow this EXACTLY)

The sidebar is dark (`#1A1D21`), collapsible (icon-only ↔ full labels), with teal highlight on active item.

```
📊 Dashboard                          → /dashboard
👥 Users                              → /users
📦 Marketplace (expandable group)
   ├── 🔨 Auctions                    → /marketplace/auctions
   └── 🛒 Direct Buy                  → /marketplace/direct-buy
📋 Orders                             → /orders
💳 Payments                           → /payments
👛 Wallet                             → /wallets
⭐ Subscriptions                      → /subscriptions
💬 Communities                        → /communities
🛡️ Trust & Safety (expandable group)
   ├── (sub-items TBD)
🚩 Reports & Disputes                → /reports
⭐ Reviews                            → /reviews
📢 Engagement                         → /engagement
📈 Analytics                          → /analytics
⚙️ Settings                           → /settings
↕️ Collapse (toggle sidebar)
```

**Top bar** (always visible):
- Left: Bidly logo icon
- Center: Search bar "Search users, auctions, orders..."
- Right: Notification bell (with red count badge) + User avatar + name + "Super Admin" role

---

## DATABASE ENTITIES (what exists in the backend)

### User
```
id (UUID), phone, name, email, sellerType (INDIVIDUAL/BUSINESS), avatarUrl,
city, state, active (boolean), identityVerified (boolean), identityProvider,
trustScore (int), address, pincode, latitude, longitude, searchRadiusKm,
onboardingCompleted (boolean), interests (Set<String>), createdAt, updatedAt
```

### Listing
```
id (UUID), title, description, price (BigDecimal), category (FK→Category), subcategory,
seller (FK→User), city, state, locality,
condition (NEW/LIKE_NEW/EXCELLENT/GOOD/FAIR/POOR/USED/REFURBISHED),
purchaseDate, hasDamage, damageDetails,
status (ACTIVE/SOLD/EXPIRED/DELETED),
sellingMethod (DIRECT_BUY/AUCTION), sellingScope, communityId, communityName,
targetRadiusKm, startingBid, currentBid, bidIncrement, auctionEndTime,
primaryImageUrl, reelUrl, mediaProcessingStatus (PROCESSING/READY/FAILED),
rating, distanceKm, featured (boolean), viewsCount, likesCount, bidsCount,
latitude, longitude, media (List<ListingMedia>), createdAt, updatedAt
```

### Community
```
id (UUID), name, description, iconUrl, bannerUrl, type (NEIGHBORHOOD/COLLEGE/etc),
category, city, state, address, latitude, longitude, radiusKm, rules (TEXT),
createdBy (UUID), membersCount, recentActivityText, recentActivityTime,
active (boolean), createdAt, updatedAt
```
Related: CommunityMember (communityId, userId, role, joinedAt), CommunityPost (communityId, userId, content, mediaUrls, likesCount), UserRestrict (communityId, userId, restrictedBy, reason)

### Order
```
id (UUID), orderNumber (unique), listing (FK), buyer (FK→User), seller (FK→User),
winningBid (FK→Bid, nullable), offer (FK→Offer, nullable),
orderSource (AUCTION/DIRECT_SALE), deliveryType (COURIER/IN_PERSON_MEETUP),
meetupLocation, meetupTime, meetupOtp, meetupOtpVerified, meetupNotes,
isMeetupConfirmed, deliveryAddress (FK),
amount, platformFee, totalAmount,
status (AUCTION_WON/ORDER_CONFIRMED/SELLER_CONFIRMED/PACKED/SHIPPED/DELIVERED/CANCELLED),
paymentStatus (PENDING/IN_ESCROW/RELEASED/REFUNDED),
courierPartner, trackingNumber, estimatedDeliveryDate, deliveredAt,
trackingEvents (List<OrderTrackingEvent>), createdAt, updatedAt
```

### Bid (Auction)
```
id (UUID), listing (FK), bidder (FK→User), amount (BigDecimal),
deliveryAddress (FK), clientBidId (unique),
status (ACTIVE/OUTBID/WON/LOST/WITHDRAWN), createdAt
```

### Category
```
id (UUID), name, iconUrl, sortOrder (int), parent (FK→Category, nullable),
children (List<Category>), active (boolean), createdAt, updatedAt
```

### OrderReport
```
id (UUID), order (FK→Order), reporter (FK→User), reason, details (TEXT),
status (PENDING_REVIEW/REVIEWED/RESOLVED/DISMISSED), createdAt, updatedAt
```

### Wallet & WalletTransaction
```
Wallet: id, user (FK), balance (BigDecimal), reservedBalance (BigDecimal)
WalletTransaction: id, wallet (FK), amount, type (CREDIT/DEBIT/RESERVE/RELEASE/ESCROW_HOLD/ESCROW_RELEASE),
                   referenceId, referenceType, description, createdAt
```

---

## EXISTING BACKEND API ENDPOINTS

These endpoints already exist and work. Use them:

### Auth
```
POST /api/auth/send-otp                    → { phone }
POST /api/auth/verify-otp                  → { phone, otp } → returns { token, user }
```

### Users
```
GET  /api/users/me                         → current user profile
GET  /api/users/:id                        → user by ID
PUT  /api/users/me                         → update own profile
```

### Listings
```
GET  /api/listings                         → paginated public listing feed
GET  /api/listings/:id                     → listing detail
GET  /api/listings/search                  → search listings
GET  /api/listings/seller/:sellerId        → listings by seller
```

### Communities
```
GET  /api/communities                      → community list
GET  /api/communities/:id                  → community detail
POST /api/communities                      → create community
PUT  /api/communities/:id                  → update community
GET  /api/communities/:id/members          → members list
GET  /api/communities/:id/posts            → posts list
GET  /api/communities/my                   → user's communities
```

### Orders
```
GET  /api/orders/my                        → user's orders
GET  /api/orders/:id                       → order detail
PUT  /api/orders/:id/status                → update order status
```

### Auctions
```
GET  /api/auctions/listings/:id/bids       → bids for a listing
POST /api/auctions/bid                     → place bid
```

### Categories
```
GET  /api/categories                       → all categories with children
POST /api/categories                       → create category
```

### Reports
```
POST /api/reports                          → create report
GET  /api/reports/order/:orderId           → reports for order
```

### Wallet
```
GET  /api/wallet/balance                   → current user wallet
GET  /api/wallet/transactions              → current user transactions
```

### Notifications
```
GET  /api/notifications                    → user's notifications
PUT  /api/notifications/:id/read           → mark as read
```

### Media
```
GET  /api/media/file/{objectKey}           → stream media from R2
POST /api/media/upload                     → upload media file
```

---

## MODULES TO BUILD (match the sidebar navigation)

### 1. Login (`/login`)
- Two-step flow: Email → OTP Verification
- Dark teal gradient background, centered white card
- Bidly logo + "Bidly Admin" + "Operations Panel"
- Step 1: Email input → "Send OTP" button
- Step 2: 6-digit OTP boxes → "Verify & Sign In" button, resend countdown timer, change email link
- On success: store JWT, redirect to `/dashboard`

### 2. Dashboard (`/dashboard` — default after login)
- "● Live" badge top right
- 4 KPI stat cards: Total Users (with weekly trend), Active Auctions (with "ending soon" count), Revenue MTD in ₹ (with % change), Pending Disputes (with critical count)
- Revenue Overview: Line/area chart, monthly, ₹ values, with "Click to drill down →" link
- Auction Activity: Bar chart, monthly auction counts
- User Growth section: "Buyers vs Sellers — monthly new registrations" heading
  - 4 mini cards: Total Buyers, Total Sellers, New This Month, Buyer/Seller Ratio
  - Dual line chart with dots (Buyers + Sellers lines)

### 3. User Management (`/users`, `/users/:id`)
**Users List Page** (`/users`):
- Title: "Users" + count + "Export CSV" button
- 4 stat filter cards: Total Users, Buyers, Sellers, Both Roles
- Filter bar: Search + Role tabs (All/Buyers/Sellers/Both) + Status tabs (All Status/Active/Suspended/Inactive/Verified)
- Table: User (colored avatar + name + phone), Role (badge), Location, Status (badge), Wallet (₹), Joined, Last Active, Action ("View Profile" link)

**User Detail — Buyer** (`/users/:id`):
- Header: Name + Active/Suspended badge + "💬 Message" + "⚠ Suspend" buttons
- Subtitle: "Buyer · Joined {date}"
- 4 stat cards: Wallet Balance, Total Spent, Total Bids, Auctions Won
- Tabs: Profile, Wallet, Activity, Communities, Reports, Chats, Buy, Sell
- Profile tab: User card, Address card (blue border), Recent Orders list, Member info
- Wallet tab: Dark teal balance card (Current Balance + Total Spent), "Credit Wallet" + "Freeze Wallet" buttons, Top-up History table, Transaction History

**User Detail — Seller** (`/users/:id`):
- Header: Store name + "Verified" badge + Message/Suspend buttons
- Subtitle: "Seller · {category} · Joined {date}"
- 4 stat cards: Wallet Balance, Total Sales, Active Listings (green, "View all →"), Items Sold (orange, "View all →")
- Tabs: Profile, Listings, Sold Items, Performance, Reviews, Communities, Wallet, Buy, Sell
- Profile tab: Store card (avatar + name + phone + rating + reviews), Business Address card (green border), Category, Location, Total Reviews, Member Since, Community admin badges
- Listings tab: Grouped by "AUCTIONS" and "DIRECT BUY" sections, each row shows type badge + title + price + status badge (Live/Upcoming/Available)

### 4. Marketplace — Auctions (`/marketplace/auctions`)
- Title: "Auctions" + "8 live · 1 ending soon" + grid/list toggle
- Search bar + Status tabs (All Status, Live, Ending Soon, Upcoming, Completed)
- Category filter pills: All, Electronics, Jewelry, Art, Sports, Antiques, Fashion, Books, Vehicles
- Table: Auction (title + category subtitle), Seller (teal link), Start Price (₹), Current Bid (₹, bold green), Bids, Ends In (countdown), Watchers, Status badge
- Status badges: Live (green), Upcoming (orange), Ending Soon (red)

### 5. Marketplace — Direct Buy (`/marketplace/direct-buy`)
- Similar layout to auctions but for direct buy listings
- Filter by category, status, price range
- Table: Listing title, Seller, Price, Condition, Status, Views, Listed Date

### 6. Orders (`/orders`, `/orders/:id`)
- List: Order Number, Listing, Buyer, Seller, Amount, Fee, Total, Status, Payment Status, Delivery Type
- Filters: Status, Payment Status, Delivery Type, Source, Date Range
- Detail: Summary card, Buyer/Seller cards, Listing card, Delivery info, Payment actions, Tracking timeline

### 7. Payments (`/payments`)
- Payment overview: Total revenue, platform fees collected, pending payouts
- Transaction list with filters
- Payment status tracking

### 8. Wallet Management (`/wallets`, `/wallets/:id`)
- List: User, Balance, Reserved, Available, Last Transaction
- Detail: Balance card (dark teal), Credit/Freeze actions, Top-up History, Transaction History
- Manual adjustment form

### 9. Subscriptions (`/subscriptions`)
- Subscription plans management
- User subscription status
- Revenue from subscriptions

### 10. Communities (`/communities`, `/communities/:id`)
- List: Icon, Name, Type, City, Members, Active, Recent Activity
- Detail tabs: Members (role management), Posts, Listings, Restricted Users, Settings
- Actions: Create, Edit, Deactivate, Delete

### 11. Trust & Safety (`/trust-safety`)
- User verification management
- Trust score management
- Safety policies and enforcement tools

### 12. Reports & Disputes (`/reports`, `/reports/:id`)
- List: ID, Order Number, Reporter, Reason, Status, Created Date
- PENDING_REVIEW always sorted first
- Detail: Report info, linked order, reporter profile
- Actions: Mark Reviewed, Resolve, Dismiss

### 13. Reviews (`/reviews`)
- Review moderation
- Flagged reviews list
- Rating analytics

### 14. Engagement (`/engagement`)
- Push notification management (send to users/segments)
- Notification history
- Campaign management

### 15. Analytics (`/analytics`)
- Date range picker (7d, 30d, 90d, custom)
- User, Listing, Revenue, Auction, Community analytics with charts
- Export to CSV

### 16. Settings (`/settings`)
- Platform settings: Fee %, dev wallet toggle, video limits
- Feature flags: Toggle features
- Admin user management
- Categories CRUD (tree view with drag-and-drop)

---

## FOLDER STRUCTURE

```
bidly_admin_web/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── .env
├── .env.production
├── ui_reference/                # UI design screenshots for reference
├── public/
│   ├── favicon.svg
│   └── bidly-logo.svg
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── api/
    │   ├── client.ts             # Axios instance with JWT interceptor
    │   ├── auth.api.ts
    │   ├── users.api.ts
    │   ├── listings.api.ts
    │   ├── communities.api.ts
    │   ├── orders.api.ts
    │   ├── auctions.api.ts
    │   ├── reports.api.ts
    │   ├── categories.api.ts
    │   ├── wallets.api.ts
    │   ├── media.api.ts
    │   ├── notifications.api.ts
    │   ├── payments.api.ts
    │   ├── reviews.api.ts
    │   ├── settings.api.ts
    │   └── analytics.api.ts
    ├── store/
    │   ├── auth.store.ts
    │   └── theme.store.ts
    ├── types/
    │   ├── user.types.ts
    │   ├── listing.types.ts
    │   ├── community.types.ts
    │   ├── order.types.ts
    │   ├── auction.types.ts
    │   ├── report.types.ts
    │   ├── category.types.ts
    │   ├── wallet.types.ts
    │   ├── media.types.ts
    │   ├── notification.types.ts
    │   ├── payment.types.ts
    │   ├── review.types.ts
    │   ├── settings.types.ts
    │   ├── analytics.types.ts
    │   └── common.types.ts
    ├── hooks/
    │   ├── useAuth.ts
    │   ├── usePagination.ts
    │   ├── useDebounce.ts
    │   └── useMediaQuery.ts
    ├── components/
    │   ├── layout/
    │   │   ├── AppLayout.tsx       # Sidebar + Header + Content wrapper
    │   │   ├── Sidebar.tsx         # Dark collapsible sidebar matching designs
    │   │   ├── Header.tsx          # Top bar: logo, search, notifications, user
    │   │   └── Breadcrumb.tsx
    │   ├── common/
    │   │   ├── StatusBadge.tsx
    │   │   ├── StatCard.tsx
    │   │   ├── SearchInput.tsx
    │   │   ├── FilterBar.tsx
    │   │   ├── ConfirmModal.tsx
    │   │   ├── MediaPreview.tsx
    │   │   ├── EmptyState.tsx
    │   │   └── LoadingSkeleton.tsx
    │   └── charts/
    │       ├── LineChart.tsx
    │       ├── BarChart.tsx
    │       ├── PieChart.tsx
    │       └── AreaChart.tsx
    ├── pages/
    │   ├── auth/LoginPage.tsx
    │   ├── dashboard/DashboardPage.tsx
    │   ├── users/
    │   │   ├── UserListPage.tsx
    │   │   └── UserDetailPage.tsx
    │   ├── marketplace/
    │   │   ├── AuctionListPage.tsx
    │   │   ├── AuctionDetailPage.tsx
    │   │   ├── DirectBuyListPage.tsx
    │   │   └── DirectBuyDetailPage.tsx
    │   ├── orders/
    │   │   ├── OrderListPage.tsx
    │   │   └── OrderDetailPage.tsx
    │   ├── payments/PaymentsPage.tsx
    │   ├── wallets/
    │   │   ├── WalletListPage.tsx
    │   │   └── WalletDetailPage.tsx
    │   ├── subscriptions/SubscriptionsPage.tsx
    │   ├── communities/
    │   │   ├── CommunityListPage.tsx
    │   │   └── CommunityDetailPage.tsx
    │   ├── trust-safety/TrustSafetyPage.tsx
    │   ├── reports/
    │   │   ├── ReportListPage.tsx
    │   │   └── ReportDetailPage.tsx
    │   ├── reviews/ReviewsPage.tsx
    │   ├── engagement/EngagementPage.tsx
    │   ├── analytics/AnalyticsPage.tsx
    │   └── settings/SettingsPage.tsx
    ├── routes/
    │   ├── index.tsx
    │   └── PrivateRoute.tsx
    └── styles/
        ├── global.css
        ├── theme.ts
        └── variables.css
```

## KEY RULES

1. **Follow UI designs exactly** — see `ui_reference/` folder and the screen descriptions above
2. All tables: server-side pagination, sorting, filtering, search, CSV export
3. All detail pages: breadcrumb nav, back button, loading skeletons
4. All destructive actions: confirmation modal
5. Toast notifications on every action (success/error)
6. Error boundaries around every page
7. Loading states with Ant Design Skeleton
8. Empty states when no data
9. Sidebar: dark theme, collapsible (icon-only ↔ full labels), teal active highlight
10. Currency format: Indian Rupees (₹) with Indian number formatting (e.g., ₹2,34,000)
11. Media URLs: `import.meta.env.VITE_API_BASE_URL + '/media/file/' + objectKey`
12. Login uses email + OTP flow (NOT phone), two-step process
13. User detail page adapts based on role (Buyer view vs Seller view with different tabs and stats)

Start by scaffolding the project fresh with Vite, then implement the login flow first, then the dashboard, then module by module.
