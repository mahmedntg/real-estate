# Aqar — Flutter + Spring Boot real-estate marketplace

A bilingual (English / Arabic, full RTL) rental-and-sale listing app: browse and filter listings, sign up with email verification, sign in, save favorites, manage your own listings with photos and an optional video, list land by qirats with plot details, and message owners from inside a conversation thread. The catalog is Egypt-only for now: countries, governorates, areas, currency symbols and taglines are served by the API and gated by a country `active` flag, so re-opening another market (Kuwait ships deactivated) is a data change.

- `app/` — Flutter client (Riverpod, go_router, dio)
- `backend/` — Spring Boot REST API (PostgreSQL, Flyway, JWT)
- `docker-compose.yml` — PostgreSQL 18.7 for local development

## Stack

| Layer | Technology | Version |
| --- | --- | --- |
| Client | Flutter / Dart | 3.50.0 / 3.14.0 |
| Client widgets | `material_ui` (Material 3) | 1.11.0 |
| State / routing / HTTP | riverpod, go_router, dio | 3.5.0, 18.1.4, 5.11.1 |
| Local storage / photos | shared_preferences, image_picker | 2.5.6, 1.2.4 |
| Video playback | video_player | 2.14.1 |
| Server | Spring Boot (Java 17) | 4.1.2 |
| Server libs | Spring Security 7, Nimbus JWT, Flyway, springdoc | managed |
| Database | PostgreSQL (Docker) | 18.7 |

All components are free and open source.

## Ports

| Service | Port | Why |
| --- | --- | --- |
| PostgreSQL | **55432** (host) → 5432 (container) | the host already runs a native PostgreSQL on 5432; the container is remapped |
| API | **8081** | the host already has a process on 8080 |
| Flutter web dev server | 8090 (example) | any free port works |

## Run it

Prerequisites: Docker, JDK 17, Flutter 3.50.

```bash
# 1. Database
docker compose up -d

# 2. API (terminal 1)
cd backend
./mvnw spring-boot:run          # Windows: mvnw.cmd spring-boot:run
```

The API starts on http://localhost:8081, applies Flyway migrations, and seeds demo data (11 listings in Egypt — 9 residential/commercial plus 2 land plots — 3 users, 1 conversation). Kuwait remains in the location catalog but is inactive and has no seeded listings, so the app only shows Egypt. Swagger UI: http://localhost:8081/swagger-ui.html.

```bash
# 3. App (terminal 2)
cd app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8081
```

`API_BASE_URL` defaults to `http://localhost:8081`, so the dart-define can be omitted for local development. Production web build:

```bash
flutter build web --release --dart-define=API_BASE_URL=https://your-host
```

## Demo accounts

| Role | Email | Password |
| --- | --- | --- |
| Owner (11 seeded listings, 1 conversation) | `owner@aqar.app` | `Demo@12345` |
| Renter | `renter@aqar.app` | `Demo@12345` |
| Admin | `admin@aqar.app` | `Admin@12345` |

The login screen has one-tap chips that fill the owner and renter credentials.

## Features

- Search with debounced query, filters (governorate autocomplete, area, listing type, property type, price range, bedrooms, furnished) and sorting, with infinite scroll.
- One active market (Egypt) with the country switcher hidden until a second active country exists; listings from inactive markets are hidden from search, favorites and my listings, and writes there are rejected.
- Listing detail with a swipeable photo gallery (mouse drag works on web, prev/next arrows), optional video playback, specs, owner card and contact prompt.
- Auth with JWT, persisted session, redirect-back after login, and email verification: registration emails a 6-digit code, unverified accounts cannot log in, and the code can be re-sent.
- Favorites with optimistic toggling.
- My listings: create, edit and delete, up to 8 photos and one optional video (MP4/WebM/MOV, 50 MB) per listing.
- Titles and descriptions only need one language: at least one title and one description are required, and the UI falls back to the language that was provided.
- Land listings: agricultural plots priced and sized in qirats, building plots with permit status, both with dimensions, street width and a negotiable-price flag.
- Messaging: start a conversation from a listing, threaded chat, unread badges, polling refresh.
- Profile: language switch (English / Arabic with RTL), theme switch (system / light / dark), logout.
- Admin role is surfaced on the profile screen; listing ownership is enforced server-side.

## Markets

`GET /api/v1/locations` returns the active countries ordered for display, each with its governorates, areas, currency code, English/Arabic currency symbols and tagline. It is public and cached for an hour (`Cache-Control: public, max-age=3600`).

Only countries with `active = true` are served and accepted. `V5__egypt_only.sql` sets Kuwait inactive; to re-open it (or add a market), insert or update rows in `countries`, `governorates` and `areas` — no code changes. The app defaults to Egypt, falls back to the first active country if the stored one disappears, and hides the country switcher while only one country is active.

JSON bodies use **snake_case** field names throughout (`country_code`, `area_qirats`, `verification_required`), matching the Warba convention; query parameters stay camelCase (`listingType`, `minPrice`). Listings reference locations by **codes**, not database ids: `country`, `governorate` and `area` query parameters on `GET /properties`, and `country_code`, `governorate_code`, `area_code` in listing payloads. The API rejects writes whose governorate does not belong to the country (or whose country is inactive), or whose area does not belong to the governorate, with `400 Invalid location`; reads are scoped to active markets.

## Registration and verification

`POST /auth/register` creates the account unverified and returns `{ "email", "verification_required": true }`. A 6-digit code (15-minute TTL, stored as a SHA-256 hash) is emailed to the address; `POST /auth/verify` with `{ "email", "code" }` marks the address verified and returns the JWT, and `POST /auth/resend` emails a new code. Login is refused with `403 Email not verified` until then.

Codes go out over SMTP (STARTTLS + auth) when `AQAR_SMTP_HOST` is set. For Gmail use `smtp.gmail.com`, port `587`, the account address as username and a 16-character Google App Password. The code is never returned in an API response and never shown in the app; with no SMTP configured it is written to the API log only, so local registration can still be tested. `aqar.mail.expose-code` (default `false`) exists solely as a dev escape hatch that puts the code back in the response.

## Listing media

Gallery photos are uploaded with `POST /properties/{id}/images` (JPEG/PNG/WebP, 8 MB each, 8 per listing). A listing can also carry one optional video via `POST /properties/{id}/video` (MP4/WebM/MOV, 50 MB); the detail payload exposes `video_url` and the detail page plays it with `video_player`. `DELETE /properties/{id}/video` removes it, and replacing/deleting a listing cleans the file up.

Titles and descriptions are optional per language, but at least one of each is required: missing text is stored empty and the client falls back to the provided language.

## Land plots

`LAND` listings carry plot details on top of the common fields; the editor only shows them when the property type is land.

| Field | Applies to | Rule |
| --- | --- | --- |
| `land_kind` | land | `AGRICULTURAL` or `BUILDING` |
| `area_qirats` | agricultural | required; the plot area in qirats (1 qirat = 175.03 m², 24 qirats = 1 feddan ≈ 4,200 m²) |
| `area_sqm` | all listings | for land with qirats it is derived server-side as `qirats × 175.03`, rounded to 2 decimals |
| `frontage_m`, `depth_m` | both kinds | plot dimensions in metres |
| `street_width_m` | both kinds | width of the adjacent street in metres |
| `building_permit` | building plot | required; whether the plot has a permit |
| `boundary_north`, `boundary_south`, `boundary_east`, `boundary_west` | both kinds | four free-text boundary lines (up to 200 characters each), e.g. the bahri/qibli side; shown as a "Boundaries" block on the detail page |
| `negotiable` | all listings | price is negotiable; shown as a badge on the detail page |

The API rejects land details on a non-land listing with `400 Invalid land details`, an agricultural plot without qirats or a building plot without permit status with `400` validation errors, and clears stale land fields — boundaries included — when a listing is saved as another property type. Land areas are shown in qirats (converted per locale) wherever a plot area is present.

## API

Base path `/api/v1`. Errors use RFC 9457 `ProblemDetail`.

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/register` | – | create account, returns verification info |
| POST | `/auth/verify` | – | confirm the 6-digit code, returns JWT |
| POST | `/auth/resend` | – | issue a new verification code |
| POST | `/auth/login` | – | sign in (rejected until verified) |
| GET | `/auth/me` | token | current user |
| GET | `/locations` | – | active countries with governorates, areas, currency and taglines (cached 1 h) |
| GET | `/properties` | optional | search (`q`, `type`, `listingType`, `country`, `governorate`, `area`, `minPrice`, `maxPrice`, `bedrooms`, `furnished`, `sort`, `page`, `size`) |
| GET | `/properties/{id}` | optional | detail (adds `mine`, `favorite`) |
| POST | `/properties` | token | create listing |
| PUT / DELETE | `/properties/{id}` | owner/admin | update / delete |
| POST | `/properties/{id}/images` | owner/admin | multipart upload, max 8 MB per file |
| DELETE | `/properties/{id}/images/{imageId}` | owner/admin | remove photo |
| POST | `/properties/{id}/video` | owner/admin | multipart upload, one video, max 50 MB |
| DELETE | `/properties/{id}/video` | owner/admin | remove video |
| GET | `/media/{filename}` | – | serve uploaded photo or video |
| PUT / DELETE | `/properties/{id}/favorite` | token | add / remove favorite |
| GET | `/me/favorites`, `/me/properties` | token | saved listings, own listings |
| POST | `/properties/{id}/conversations` | token | start conversation |
| GET | `/conversations`, `/conversations/{id}` | token | list / open conversation |
| GET / POST | `/conversations/{id}/messages` | participant | read / send messages |
| POST | `/conversations/{id}/read` | participant | clear unread count |

## Configuration

Everything has a development default and can be overridden with environment variables:

| Variable | Default |
| --- | --- |
| `AQAR_DB_URL` | `jdbc:postgresql://localhost:55432/aqar` |
| `AQAR_DB_USER` / `AQAR_DB_PASSWORD` | `aqar` / `aqar` |
| `AQAR_API_PORT` | `8081` |
| `AQAR_JWT_SECRET` | dev-only secret — replace in any shared environment |
| `AQAR_MEDIA_DIR` | `./uploads` |
| `AQAR_SEED` | `true` |
| `AQAR_ADMIN_EMAIL` / `AQAR_ADMIN_PASSWORD` | `admin@aqar.app` / `Admin@12345` |
| `AQAR_DEMO_PASSWORD` | `Demo@12345` |
| `AQAR_SMTP_HOST` / `AQAR_SMTP_PORT` | empty / `587` — set the host to enable email delivery |
| `AQAR_SMTP_USERNAME` / `AQAR_SMTP_PASSWORD` | empty — SMTP account (Gmail: address + App Password) |
| `AQAR_MAIL_FROM` | empty — envelope sender, defaults to the SMTP username |
| `AQAR_EXPOSE_VERIFICATION_CODE` | `false` (dev-only: return the code in the API response) |

## Project layout

```
app/lib
  app.dart            MaterialApp.router, theme, locale
  router.dart         go_router with auth redirect and tab shell
  core/               config, session, settings, formatting, shared UI
  data/               models and the dio API client
  features/           home, property, listings, auth, favorites, chats, profile, shell
  l10n/               ARB sources and generated localizations
backend/src/main/java/com/aqar/api
  web/                REST controllers
  service/            business logic and demo seeding
  payload/request/    Lombok request bodies with Jakarta Bean Validation constraints
  payload/response/   Lombok response bodies (snake_case JSON)
  payload/model/      shared nested models (images, video, owner)
  validation/         `ValidationGroups.OnCreate` / `OnUpdate` markers
  security/           JWT filter, current-user resolution
  config/             security, properties, CORS
backend/src/main/resources/db/migration   Flyway schema
```

The backend follows the Warba repository layout: request/response payloads are Lombok classes in `payload/request|response` annotated with `@JsonNaming(SnakeCaseStrategy)`, controllers validate them with `@Validated(ValidationGroups.OnCreate.class)` or `@Validated(ValidationGroups.OnUpdate.class)`, and both groups extend `Default`, so the plain constraints run on create and update alike.

## Verified

- `flutter analyze` — no issues. `flutter test` — 9 widget tests pass (English LTR, Arabic RTL, market currency formatting, qirat formatting, one-language title fallback, governorate autocomplete filtering, register confirmation/phone validation, verify page asks for the emailed code, land boundary lines survive the API round-trip).
- `flutter build web --release` — succeeds and the bundle is served on port 8090.
- Backend test suite (`Tests run: 10`) and migrations pass against PostgreSQL 18.7 (schema version 8): auth with verification (403 before verify, code from the mail log, wrong code, resend, duplicate email, repeated verification), active-country catalog and write rejection, search filters/sorting and favorite/ownership flags, image upload (JPEG/PNG/WebP with ids), image and video serving/deletion for MP4/WebM/MOV, one-language listings, validation and malformed-body errors, and the land-detail rules including the four boundary lines.
- Maven coordinates are `com.aqar:aqar-api` and every source file lives under `com.aqar.api`; no `kw.*` package remains.
- Against the running backend: the location catalog returns Egypt only; registration returns `{email, verification_required}` with no code, login before verification is `403`, `POST /auth/verify` with the code from the log returns a JWT; a listing with an English-only title/description is accepted while an empty-title payload is `400 Missing title`; a Kuwait write is `400 Invalid location`; a land listing created with boundary lines returns them unchanged in its detail; image upload returns `{"id", "url"}`, the file is served and deleting the image removes it; video upload returns `/media/<uuid>.mp4`, the file is served as `video/mp4`, and deleting it clears `video_url`.
- The database holds 11 Egypt listings (9 homes, 2 land plots with boundaries) and one demo conversation; Kuwait has no listings.

## Quality gates

`./mvnw verify` runs the same static-analysis stack as the Warba common repository and fails the build on any finding:

| Gate | Plugin / rules | Scope |
| --- | --- | --- |
| Checkstyle | 3.6.0 with Checkstyle 10.26.1, `checkstyle.xml` copied from the Warba project (Google style, 150 cols, required Javadoc and `@throws` tags) | every production type and method |
| PMD | 3.28.0 (PMD 7.17), default Maven ruleset | unused code, imports, error-prone constructs |
| SpotBugs | 4.9.6.0 with the Warba `spotbugs-ignore.xml` | bytecode defects; `EI_EXPOSE_REP*` suppressed |
| JaCoCo | 0.8.13 | 80% bundle complexity, demo-data seeder excluded |

Current run: Checkstyle, PMD and SpotBugs clean; JaCoCo complexity 83.3% (the demo seeder is excluded because it is fixtures, not production logic).
