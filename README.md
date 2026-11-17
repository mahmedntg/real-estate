# Aqar — Flutter + Spring Boot real-estate marketplace

A bilingual (English / Arabic, full RTL) rental-and-sale listing app: browse and filter listings, sign up with WhatsApp (or email) verification, sign in, save favorites, manage your own listings with photos and an optional video, list land with its area in qirats and sahm and plot details, and message owners from inside a conversation thread. The catalog is Egypt-only for now: countries, governorates, areas, currency symbols and taglines are served by the API and gated by a country `active` flag, so re-opening another market (Kuwait ships deactivated) is a data change.

- `app/` — Flutter client (Riverpod, go_router, dio)
- `backend/` — Spring Boot REST API (PostgreSQL, Flyway, JWT)
- `docker-compose.yml` — PostgreSQL 18.7 for local development
- `deploy/` — production stack for a VPS (Caddy, API, PostgreSQL) and its runbook

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

`API_BASE_URL` overrides the API origin. Without it the app uses the page origin on web and `http://localhost:8081` elsewhere, so local development on port 8090 passes the define and the production web bundle needs none:

```bash
flutter build web --release
# Android, which embeds the URL at build time:
flutter build apk --release --dart-define=API_BASE_URL=https://your-host
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
- Listing detail with a swipeable photo gallery (mouse drag works on web, prev/next arrows), optional video playback, specs, owner card with call, WhatsApp and Facebook buttons, and a message prompt.
- Auth with JWT, persisted session, redirect-back after login, and verification: registration requires a unique email and a unique mobile number, sends a 6-digit code to the number over WhatsApp with email as the fallback, unverified accounts cannot log in, and the code can be re-sent.
- Favorites with optimistic toggling.
- My listings: create, edit and delete, up to 8 photos and one optional video (MP4/WebM/MOV, 50 MB) per listing.
- Listings without photos fall back to a bundled illustrated cover on cards, chat rows and the detail header.
- Titles and descriptions only need one language: at least one title and one description are required, and the UI falls back to the language that was provided.
- Land listings: the area is stated in qirats with an optional sahm part (24 sahm = 1 qirat), agricultural plots require it and building plots may omit it; both kinds carry a permit status, the four plot sides named by direction (bahri, qibli, east and west), street width and a negotiable-price flag; the detail page draws the plot with an arrow per side and the qirat/sahm area in the middle.
- Messaging: start a conversation from a listing, threaded chat, unread badges, polling refresh.
- Seller contact: registration requires a mobile number; the profile screen edits the display name, optional WhatsApp number and Facebook link, and changing the mobile number requires confirming a code sent to the new number before it is applied; listing details expose the details so buyers can call, open WhatsApp or visit the seller's Facebook page.
- Profile: language switch (English / Arabic with RTL), theme switch (system / light / dark), logout.
- Admin role is surfaced on the profile screen; listing ownership is enforced server-side.

## Markets

`GET /api/v1/locations` returns the active countries ordered for display, each with its governorates, areas, currency code, English/Arabic currency symbols and tagline. It is public and cached for an hour (`Cache-Control: public, max-age=3600`).

Only countries with `active = true` are served and accepted. `V5__egypt_only.sql` sets Kuwait inactive; to re-open it (or add a market), insert or update rows in `countries`, `governorates` and `areas` — no code changes. The app defaults to Egypt, falls back to the first active country if the stored one disappears, and hides the country switcher while only one country is active.

JSON bodies use **snake_case** field names throughout (`country_code`, `area_sqm`, `verification_required`), matching the Warba convention; query parameters stay camelCase (`listingType`, `minPrice`). The Flutter client reads and writes the same snake_case keys in every model and request body. Listings reference locations by **codes**, not database ids: `country`, `governorate` and `area` query parameters on `GET /properties`, and `country_code`, `governorate_code`, `area_code` in listing payloads. The API rejects writes whose governorate does not belong to the country (or whose country is inactive), or whose area does not belong to the governorate, with `400 Invalid location`; reads are scoped to active markets.

## Registration and verification

`POST /auth/register` creates the account unverified and returns `{ "email": "you@example.com", "verification_required": true }`. Email addresses and mobile numbers are both unique — registration is refused with `409 Email already registered` or `409 Phone already registered` — and stored numbers keep only digits and a single leading `+`. A 6-digit code (15-minute TTL, stored as a SHA-256 hash) is sent to the registered number over WhatsApp and, failing that, to the email address; `POST /auth/verify` with `{ "email", "code" }` marks the account verified and returns the JWT, and `POST /auth/resend` issues a new code. Login is refused with `403 Email not verified` until then.

Codes go out through the WhatsApp Cloud API when `AQAR_WHATSAPP_TOKEN` and `AQAR_WHATSAPP_PHONE_ID` are set: the API posts the code as the single body parameter of an approved authentication template (`AQAR_WHATSAPP_TEMPLATE`, default `aqar_verification_code`; `AQAR_WHATSAPP_TEMPLATE_LANG`, default `ar`) to `graph.facebook.com`. Meta only delivers approved authentication templates, so create and approve one in WhatsApp Manager before pointing the app at it. Any WhatsApp failure falls back to SMTP (STARTTLS + auth) when `AQAR_SMTP_HOST` is set; for Gmail use `smtp.gmail.com`, port `587`, the account address as username and a 16-character Google App Password. With neither configured the code is written to the API log only, so local registration and number changes can still be tested. `aqar.mail.expose-code` (default `false`) remains a dev escape hatch that puts the code back in the response.

## Listing media

Gallery photos are uploaded with `POST /properties/{id}/images` (JPEG/PNG/WebP, 8 MB each, 8 per listing). A listing can also carry one optional video via `POST /properties/{id}/video` (MP4/WebM/MOV, 50 MB); the detail payload exposes `video_url` and the detail page plays it with `video_player`. `DELETE /properties/{id}/video` removes it, and replacing/deleting a listing cleans the file up.

Files are written to `AQAR_MEDIA_DIR` and served from `/media/{filename}` by default. When `AQAR_S3_BUCKET`, `AQAR_S3_ACCESS_KEY` and `AQAR_S3_SECRET_KEY` are set, uploads go to that S3-compatible bucket instead, deletes remove the object, and the returned URLs point at the bucket's public address (`AQAR_S3_PUBLIC_URL`, or the AWS/R2/MinIO convention derived from the region and endpoint) — so a diskless server keeps working across rebuilds and replicas.

Titles and descriptions are optional per language, but at least one of each is required: missing text is stored empty and the client falls back to the provided language.

## Land plots

`LAND` listings carry plot details on top of the common fields; the editor only shows them when the property type is land.

| Field | Applies to | Rule |
| --- | --- | --- |
| `land_kind` | land | `AGRICULTURAL` or `BUILDING` |
| `area_qirats` | land | the plot area in qirats (1 qirat = 175.03 m²); required for agricultural land, optional for building plots |
| `area_sahm` | land | optional sahm on top of the qirats, an integer from 0 to 23 (24 sahm = 1 qirat); rejected without qirats |
| `area_sqm` | non-land listings | the area in square metres; land rejects it because `area_sqm` is derived as `(qirats + sahm / 24) × 175.03` and returned read-only |
| `north_side_m`, `south_side_m` | both kinds | the bahri and qibli sides in metres; they may differ |
| `east_side_m`, `west_side_m` | both kinds | the east and west sides in metres; they may differ |
| `street_width_m` | both kinds | width of the adjacent street in metres |
| `building_permit` | building plot | required; whether the plot has a permit |
| `boundary_north`, `boundary_south`, `boundary_east`, `boundary_west` | both kinds | four free-text boundary lines (up to 200 characters each), e.g. the bahri/qibli side; shown as a "Boundaries" block on the detail page |
| `negotiable` | all listings | price is negotiable; shown as a badge on the detail page |

The API rejects land details on a non-land listing, an agricultural plot without qirats, sahm without qirats or outside 0–23, a land payload that submits `area_sqm`, a building plot without permit status, and partial plot sides (some but not all of the four) — all with `400` validation errors — and it clears stale land fields (boundaries and sides included) when a listing is saved as another property type. Cards and the detail page show the area in qirats and sahm; the detail page draws a plot diagram with a double-headed arrow per side and the qirat/sahm area in the middle.

## Seller contact

Registration requires a mobile number (`^\+?[0-9][0-9 \-]{6,19}$`). `PUT /auth/me` updates the display name, an optional WhatsApp number (same pattern) and an optional Facebook link (`http(s)://…`, up to 300 characters) and returns the updated profile; it does not change the mobile number. The profile screen opens these fields from a "Contact details" row.

A new mobile number is applied only after it is verified:

- `POST /auth/me/phone` with `{ "phone": "…" }` stores the new number as pending and sends it a code (`202`). The current number stays in place until the change is confirmed, and the pending change expires after 15 minutes.
- `PUT /auth/me/phone` with `{ "phone", "code" }` applies the pending number and returns the updated profile. A wrong code or a number that differs from the pending one is `400 Invalid code`, a number registered to another account is `409`, and confirming with no pending change is `400 No pending mobile change`.

The contact editor in the app asks for the verification code as soon as the typed number differs from the stored one, then saves the remaining fields. Listing details include a read-only `contact` object built from the owner account, with numbers normalised the same way as registration:

```json
"contact": { "phone": "+201005550101", "whatsapp": "+201005550101", "facebook_url": "https://www.facebook.com/aqar.eg" }
```

The detail page shows the phone under the owner name, a full-width "Message owner" button, and call / WhatsApp / Facebook buttons for the details the seller provided; WhatsApp opens `https://wa.me/<digits>` with the number stripped of separators.

## Deployment

The production stack lives in `deploy/`: `compose.prod.yml` runs PostgreSQL 18.7, the API image built from `backend/Dockerfile` and Caddy 2, which terminates TLS for one DuckDNS hostname and routes `/api/*` and `/media/*` to the API while serving the web bundle from a mounted directory. Everything shares one origin, so the browser needs no CORS and the web build needs no hostname. The API exposes `GET /actuator/health` for the Caddy and container health checks, Swagger is switched off, and the demo seed stays off on a public server. Step-by-step instructions, including DNS, secrets, release signing, updates and backups, are in [`deploy/README.md`](deploy/README.md).

The web build is an installable PWA (branded manifest, maskable icons and theme colour `#0E7C66`), and the profile screen carries a web-only "Download Android app" entry that serves `/download/aqar.apk` as an attachment for sideloading.

## API

Base path `/api/v1`. Errors use RFC 9457 `ProblemDetail`.

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/auth/register` | – | create account, returns verification info |
| POST | `/auth/verify` | – | confirm the 6-digit code, returns JWT |
| POST | `/auth/resend` | – | issue a new verification code |
| POST | `/auth/login` | – | sign in (rejected until verified) |
| GET | `/auth/me` | token | current user |
| PUT | `/auth/me` | token | update name, WhatsApp number and Facebook link |
| POST | `/auth/me/phone` | token | start a mobile-number change, sends a code to the new number |
| PUT | `/auth/me/phone` | token | confirm the pending mobile number with its code |
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
| `AQAR_WHATSAPP_TOKEN` / `AQAR_WHATSAPP_PHONE_ID` | empty — set both to send verification codes over the WhatsApp Cloud API |
| `AQAR_WHATSAPP_TEMPLATE` / `AQAR_WHATSAPP_TEMPLATE_LANG` | `aqar_verification_code` / `ar` — approved authentication template name and its language |
| `AQAR_EXPOSE_VERIFICATION_CODE` | `false` (dev-only: return the code in the API response) |
| `AQAR_S3_BUCKET` | empty — set it (with the key pair) to store media in S3 instead of `AQAR_MEDIA_DIR` |
| `AQAR_S3_REGION` | `us-east-1` |
| `AQAR_S3_ENDPOINT` / `AQAR_S3_PUBLIC_URL` | empty — R2/B2/MinIO endpoint and the bucket's public base URL |
| `AQAR_S3_ACCESS_KEY` / `AQAR_S3_SECRET_KEY` | empty — credentials for the bucket |
| `AQAR_CORS_ORIGINS` | `http://localhost:*,http://127.0.0.1:*` — comma-separated origin patterns allowed from a browser |
| `AQAR_SWAGGER_ENABLED` | `true` — set to `false` to turn off springdoc and Swagger UI |

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
  service/            business logic and demo seeding (S3MediaStore for bucket uploads)
  payload/request/    Lombok request bodies with Jakarta Bean Validation constraints
  payload/response/   Lombok response bodies (snake_case JSON)
  payload/model/      shared nested models (images, video, owner)
  validation/         `ValidationGroups.OnCreate` / `OnUpdate` markers
  security/           JWT filter, current-user resolution
  config/             security, properties, CORS
backend/src/main/resources/db/migration   Flyway schema
deploy/
  compose.prod.yml    PostgreSQL + API + Caddy for a VPS
  Caddyfile           TLS, path routing, cache headers, SPA fallback
  env.prod.example    every production setting, no secrets
  web/                staging directory for the built web bundle and the APK
```

The backend follows the Warba repository layout: request/response payloads are Lombok classes in `payload/request|response` annotated with `@JsonNaming(SnakeCaseStrategy)`, controllers validate them with `@Validated(ValidationGroups.OnCreate.class)` or `@Validated(ValidationGroups.OnUpdate.class)`, and both groups extend `Default`, so the plain constraints run on create and update alike.

## Verified

- `flutter analyze` — no issues. `flutter test` — 14 widget tests pass (English LTR, Arabic RTL, market currency formatting, qirat/sahm area formatting, WhatsApp link formatting, phone normalisation, one-language title fallback, governorate autocomplete filtering, register confirmation/phone validation, verify page asks for the emailed code, land sides and boundary lines survive the API round-trip, plot diagram renders four sides and its centre label, listings without a photo use the bundled default cover, and a changed mobile number is verified before the profile saves).
- `flutter build web --release` — succeeds; the bundle carries the Aqar manifest (name, `#0E7C66` theme and background, 192/512 icons plus maskable variants), the branded favicon and title, and calls the API on its own origin, so no rebuild is needed per hostname. `deploy/web` holds the built bundle ready for the server.
- Backend test suite (`Tests run: 15`) and migrations pass against PostgreSQL 18.7 (schema version 14): auth with verification (403 before verify, code from the log, wrong code, resend, duplicate email, repeated verification, required phone), unique mobile numbers with a verified change (409 for a duplicate email or phone, `202` start with the old number retained, normalised new number, wrong code, mismatched pending number, taken and unchanged numbers, 401 without a token, confirming with no pending change), active-country catalog and write rejection, search filters/sorting and favorite/ownership flags, image upload (JPEG/PNG/WebP with ids), image and video serving/deletion for MP4/WebM/MOV, one-language listings, validation and malformed-body errors, seller contact (PUT `/auth/me` round-trip with a normalised WhatsApp number, 401 without a token, invalid Facebook link, missing name, the detail `contact` block), the land-detail rules including qirats with sahm (5 qirats + 12 sahm = 962.67 m²), the four sides, sahm/qirats ordering, rejection of `area_sqm` on land, partial-side rejection and the four boundary lines, and the S3 store (upload request with bucket/key/content type, delete request, disabled without credentials, public URL derivation for AWS and custom endpoints).
- Packaging: `docker build` of `backend/Dockerfile` produces the runnable API image; `docker compose -f deploy/compose.prod.yml config` accepts the production stack; `caddy validate` accepts the Caddyfile.
- Maven coordinates are `com.aqar:aqar-api` and every source file lives under `com.aqar.api`; no `kw.*` package remains.
- Against the running backend: the location catalog returns Egypt only; registration returns `{email, verification_required}` with no code, login before verification is `403`, `POST /auth/verify` with the code from the log returns a JWT; a listing with an English-only title/description is accepted while an empty-title payload is `400 Missing title`; a Kuwait write is `400 Invalid location`; a land listing created with qirats, sahm, four sides and boundary lines returns them unchanged in its detail with `area_sqm` derived from the qirats and sahm; image upload returns `{"id", "url"}`, the file is served and deleting the image removes it; video upload returns `/media/<uuid>.mp4`, the file is served as `video/mp4`, and deleting it clears `video_url`; `PUT /auth/me` updates the name, WhatsApp number and Facebook link without touching the mobile number, and a demo listing detail returns them in `contact` while the detail page shows the fixed owner card with the full-width message button plus call, WhatsApp and Facebook buttons. Registering with an existing email or mobile is `409`; a fresh registration returns `{email, verification_required}` and the code appears in the log (no WhatsApp or SMTP credentials configured); changing the demo owner's number through `POST` + `PUT /auth/me/phone` keeps the old number until the code confirms, updates `GET /auth/me` and the listing `contact` block, and a wrong code is `400 Invalid code`.
- The database holds 11 Egypt listings (9 homes, 2 land plots with boundaries) and one demo conversation; Kuwait has no listings.

## Quality gates

`./mvnw verify` runs the same static-analysis stack as the Warba common repository and fails the build on any finding:

| Gate | Plugin / rules | Scope |
| --- | --- | --- |
| Checkstyle | 3.6.0 with Checkstyle 10.26.1, `checkstyle.xml` copied from the Warba project (Google style, 150 cols, required Javadoc and `@throws` tags) | every production type and method |
| PMD | 3.28.0 (PMD 7.17), default Maven ruleset | unused code, imports, error-prone constructs |
| SpotBugs | 4.9.6.0 with the Warba `spotbugs-ignore.xml` | bytecode defects; `EI_EXPOSE_REP*` suppressed |
| JaCoCo | 0.8.13 | 80% bundle complexity, demo-data seeder excluded |

Current run: Checkstyle, PMD and SpotBugs clean; JaCoCo complexity 80.0% (the demo seeder is excluded because it is fixtures, not production logic).
