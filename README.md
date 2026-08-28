# Bidly — Buy & Sell Near You

An OLX-like Android classifieds marketplace built with Flutter + Spring Boot.

## Tech Stack
| Layer | Technology |
|---|---|
| Mobile | Flutter 3.41 (Android) |
| Backend API | Spring Boot 3.3 (Java 17) |
| ORM | Spring Data JPA + Hibernate |
| Database | Neon PostgreSQL (serverless) |
| Migrations | Flyway |
| Storage | Cloudflare R2 (images/videos) |
| Auth | OTP via Twilio Verify → JWT |
| State Mgmt | Riverpod 2.x |
| Navigation | GoRouter |
| HTTP | Dio |

## Project Structure
```
bidly/
├── bidly_app/          # Flutter Android app
│   ├── lib/
│   │   ├── core/       # API client, theme, constants, router
│   │   └── features/   # auth, home, listing, chat, profile…
│   └── assets/         # fonts, images, icons, animations
│
└── bidly_backend/      # Spring Boot REST API
    └── src/main/java/com/bidly/
        ├── auth/       # OTP + JWT
        ├── user/       # User CRUD
        ├── listing/    # Listing CRUD + search
        ├── category/   # Categories
        ├── media/      # Cloudflare R2 pre-signed URLs
        └── common/     # Config, security, exceptions
```

## Getting Started

### Backend
1. Copy `.env.example` → `.env` and fill in your credentials
2. Set environment variables (or use IDE run config)
3. Run: `./gradlew bootRun`

### Flutter
1. `cd bidly_app && flutter pub get`
2. `flutter run` (with Android emulator/device connected)

## Environment Variables
See [`bidly_backend/.env.example`](bidly_backend/.env.example) for all required variables.

## Media Upload Flow
```
Flutter → GET /api/media/presigned-url
       ← { uploadUrl, publicUrl }
Flutter → PUT {uploadUrl} (direct to Cloudflare R2)
Flutter → POST /api/listings { mediaUrls: [publicUrl, ...] }
```
