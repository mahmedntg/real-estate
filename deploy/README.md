# Deploying Aqar to a VPS

One small VPS runs three containers behind Caddy, which terminates TLS for a
DuckDNS hostname and routes everything from that single origin:

```
https://<host>/            → Caddy serves the Flutter web build from ./web
https://<host>/api/*       → Spring Boot API (never published directly)
https://<host>/media/*     → Spring Boot serves files (only in local-disk mode)
https://<host>/download/*  → the Android APK, served as an attachment
https://<host>/actuator/health → answered by Caddy, for uptime checks
```

PostgreSQL is a named volume next to the API. Listing photos and videos go to
S3-compatible storage (AWS S3, Cloudflare R2, Backblaze B2 or MinIO) and are
served straight from the bucket's public URL, so the server disk holds no
uploads.

The web bundle is host-agnostic: it calls the API on its own origin, so a new
domain never needs a rebuild. The APK embeds the API URL at build time and
does need one.

## 1. What you need before starting

- A VPS with 2 vCPU / 2–4 GB RAM / 20 GB disk, Ubuntu 24.04.
- A free DuckDNS name (for example `aqar-demo.duckdns.org`) pointing at the
  server's public IP. Caddy obtains and renews the certificate over HTTP-01, so
  ports **80** and **443** must be open and the name must resolve to the server
  before the first boot.
- An S3 bucket with public read access for its objects, and an access key that
  can write and delete them. For R2/B2/MinIO also note the endpoint URL.
- WhatsApp Cloud API credentials (token, phone number id, approved
  authentication template) and/or a Gmail App Password for the email fallback.
- An Android release keystore (section 6). Keep it outside the repository.

## 2. Build the artifacts on your workstation

Never install Flutter or Maven on the server; ship built files.

```bash
# Web bundle (host-agnostic)
cd app
flutter build web --release

# Android APK — needs the public hostname and the release keystore.
# Run it on JDK 21+ (set JAVA_HOME): AGP 9.3's bundled lint crashes on JDK 17.
flutter build apk --release \
  --dart-define=API_BASE_URL=https://aqar-demo.duckdns.org
```

Copy the bundle into the staging directory and add the APK:

```bash
rm -rf deploy/web && mkdir -p deploy/web
cp -r app/build/web/. deploy/web/
mkdir -p deploy/web/download
cp app/build/app/outputs/flutter-apk/app-release.apk deploy/web/download/aqar.apk
```

`deploy/web` is gitignored except for a `.gitkeep`; it is the only directory
the server has to receive on every web/APK release.

## 3. Prepare the server

```bash
# Docker Engine + Compose plugin
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker "$USER"   # log out and back in

# Firewall
sudo ufw allow 22,80,443/tcp
sudo ufw allow 443/udp            # HTTP/3
sudo ufw enable
```

Place the project on the server. Either clone the repository or copy just the
`backend/` and `deploy/` directories:

```bash
rsync -av --delete backend deploy user@SERVER:~/aqar/
```

## 4. Fill in the secrets

```bash
cd ~/aqar/deploy
cp env.prod.example .env.prod
openssl rand -hex 48   # AQAR_JWT_SECRET
openssl rand -base64 24 # AQAR_DB_PASSWORD
```

Edit `.env.prod`:

| Variable | Set it to |
| --- | --- |
| `SITE_ADDRESS` | the DuckDNS hostname, bare (no `https://`) |
| `AQAR_DB_PASSWORD` | the generated password |
| `AQAR_JWT_SECRET` | the generated secret |
| `AQAR_CORS_ORIGINS` | `https://<host>` |
| `AQAR_S3_BUCKET` / `AQAR_S3_ACCESS_KEY` / `AQAR_S3_SECRET_KEY` | the bucket and key; leave the bucket empty to fall back to server disk |
| `AQAR_S3_ENDPOINT` / `AQAR_S3_PUBLIC_URL` | R2/B2/MinIO only: the S3 endpoint and the public base URL of the bucket |
| `AQAR_WHATSAPP_TOKEN` / `AQAR_WHATSAPP_PHONE_ID` | WhatsApp Cloud API credentials |
| `AQAR_SMTP_USERNAME` / `AQAR_SMTP_PASSWORD` | Gmail address and App Password for the fallback |

Keep `AQAR_SEED=false`, `AQAR_EXPOSE_VERIFICATION_CODE=false` and
`AQAR_SWAGGER_ENABLED=false`. The file holds live credentials: it is gitignored,
and it must stay readable only by the deploy user (`chmod 600 .env.prod`).

## 5. First boot

```bash
cd ~/aqar/deploy
docker compose --env-file .env.prod -f compose.prod.yml up -d --build
docker compose --env-file .env.prod -f compose.prod.yml ps
```

The API applies the Flyway migrations on start and reports healthy after about
30–40 seconds. Then check, in this order:

1. `curl https://<host>/actuator/health` returns `ok`.
2. `https://<host>/` serves the app; the certificate is valid and a second
   visit is cached by the service worker.
3. Register a test account: the 6-digit code arrives on WhatsApp (or by email
   when WhatsApp fails), and the account can verify and log in.
4. Sign in, upload a listing photo, and confirm the image URL points at the S3
   public URL, not `/media/...`.
5. `https://<host>/download/aqar.apk` downloads the APK.

If the site does not come up, `docker compose --env-file .env.prod -f
compose.prod.yml logs -f caddy api` shows the failing service; a missing
certificate almost always means the DuckDNS name does not resolve to the server
or port 80 is blocked.

If `flutter build apk` fails in lint with `NoSuchMethodError` from
`JavaDocParser`, Gradle is running on JDK 17 — point `JAVA_HOME` at a JDK 21+
and rebuild.

## 6. Release signing for the APK

Play Store and Android both require the same signing key across updates. Create
it once, on your workstation, and back it up:

```bash
keytool -genkeypair -v -keystore ~/aqar-release.jks -keyalg RSA \
  -keysize 4096 -validity 10000 -alias aqar
```

Write `app/android/key.properties` (gitignored) next to the Android project:

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=aqar
storeFile=C:/absolute/path/to/aqar-release.jks
```

`flutter build apk --release` then signs with that key; without
`key.properties` the build falls back to debug signing, which is only good for
testing. The keystore and its passwords are unrecoverable: losing them means
every installed copy has to be replaced with a new package identity.

## 7. Releasing an update

```bash
# Web only
rsync -av --delete deploy/web/ user@SERVER:~/aqar/deploy/web/

# API (rebuilds the image; migrations run on start)
rsync -av --delete backend/ user@SERVER:~/aqar/backend/
ssh user@SERVER 'cd ~/aqar/deploy && docker compose --env-file .env.prod -f compose.prod.yml up -d --build api'
```

Both the web bundle and the API can be updated independently. Caddy serves the
index and the entry scripts with `Cache-Control: no-cache`, so a new release is
picked up on the next load; hashed assets under `/assets` are cached for a day.

## 8. Backups

```bash
# Database
docker compose --env-file .env.prod -f compose.prod.yml exec postgres \
  pg_dump -U aqar aqar > aqar-$(date +%F).sql
```

- Photos and videos live in the S3 bucket; enable versioning there if the
  bucket supports it.
- Back up `deploy/.env.prod` and the release keystore somewhere safe offline.
  Neither can be regenerated.

## 9. Hardening checklist

- [ ] `AQAR_SEED=false` (no demo accounts on the public site)
- [ ] `AQAR_EXPOSE_VERIFICATION_CODE=false`
- [ ] `AQAR_SWAGGER_ENABLED=false`
- [ ] Random `AQAR_JWT_SECRET` and `AQAR_DB_PASSWORD` (not the examples)
- [ ] `chmod 600 deploy/.env.prod`
- [ ] S3 bucket allows public reads of objects only, not listing or writes
- [ ] Ports 80/443 open, everything else closed (`sudo ufw status`)
- [ ] WhatsApp template approved in WhatsApp Manager, SMTP App Password tested
- [ ] `docker compose ... ps` shows api and postgres healthy
