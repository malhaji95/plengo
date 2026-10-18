# Free hosted demo: step by step

This puts Plengo online for free so you and testers can use it: the **admin panel**, the
**student website**, and an **Android test app**. It takes about 1–2 hours the first time. You
need only a browser and the GitHub account that holds the repository; no developer tools on
your computer.

## What goes where

| Part           | Service                               | Cost                                   | Web address you get                |
| -------------- | ------------------------------------- | -------------------------------------- | ---------------------------------- |
| Database       | Neon                                  | Free                                   | (internal)                         |
| API (server)   | Render                                | Free                                   | `https://<name>.onrender.com`      |
| Admin panel    | Vercel                                | Free (Hobby, non-commercial)           | `https://<name>.vercel.app`        |
| Student web    | Cloudflare Pages                      | Free                                   | `https://staging.<name>.pages.dev` |
| Images         | Cloudflare R2 (recommended)           | Free up to 10 GB; needs a card on file | `https://pub-….r2.dev`             |
| Android app    | GitHub Actions builds an APK          | Free                                   | a file you download                |
| Email          | Not needed for the demo (see step 10) | —                                      | —                                  |
| Push           | Not needed for the demo (see step 11) | —                                      | —                                  |
| Store accounts | Not needed for the demo (see step 12) | Google $25 once, Apple $99/year        | —                                  |

How it fits together: the admin panel and the student website each forward `/api` requests to
the server on Render, so logins work on these free addresses without buying a domain. The
Android app talks to Render directly.

**Free-tier limits to expect:** Render's free server sleeps after 15 minutes without visitors,
so the first visit after a pause takes up to about a minute. Neon's free database also pauses
when idle and wakes in about a second. Fine for a demo; not for real students.

## Before you start: your worksheet

Pick short, unique names now and write everything down in a password manager or a private
note. You will paste these values in several places.

| Item                          | Example                                          | Yours |
| ----------------------------- | ------------------------------------------------ | ----- |
| Render service name           | `plengo-demo-api`                                |       |
| API URL                       | `https://plengo-demo-api.onrender.com`           |       |
| Vercel project name           | `plengo-demo-admin`                              |       |
| Admin URL                     | `https://plengo-demo-admin.vercel.app`           |       |
| Cloudflare Pages project name | `plengo-demo`                                    |       |
| Student web URL               | `https://staging.plengo-demo.pages.dev`          |       |
| Neon connection string        | `postgresql://…neon.tech/neondb?sslmode=require` |       |
| 7 secrets                     | generated in step 1                              |       |

If a name is already taken, the service will suggest another; use what it actually gives you
and update the worksheet. Addresses must start with `https://` and have **no** trailing `/`.

---

## Step 1 — Generate the secrets (5 min)

You need seven random values. Generate each one separately and never reuse them.

**On a Mac or Linux:** open Terminal and run the command shown.
**On Windows:** open PowerShell and run the Windows command.

| Name                          | Mac / Linux                                                                      | Windows PowerShell                                                                               |
| ----------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `BETTER_AUTH_SECRET`          | `openssl rand -hex 32`                                                           | `-join ([Security.Cryptography.RandomNumberGenerator]::GetBytes(32) \| % { $_.ToString('x2') })` |
| `MOBILE_ACCESS_JWT_SECRET`    | `openssl rand -hex 32`                                                           | same as above                                                                                    |
| `MOBILE_REFRESH_TOKEN_PEPPER` | `openssl rand -hex 32`                                                           | same as above                                                                                    |
| `COUPON_HMAC_SECRET`          | `openssl rand -hex 32`                                                           | same as above                                                                                    |
| `COUPON_ENCRYPTION_KEY`       | `openssl rand -base64 32`                                                        | `[Convert]::ToBase64String([Security.Cryptography.RandomNumberGenerator]::GetBytes(32))`         |
| `ADMIN_PASSWORD`              | a strong password you choose (at least 12 characters) — for **your** admin login |                                                                                                  |
| `SEED_PASSWORD`               | another password you choose — shared by the sample student and admin accounts    |                                                                                                  |

Keep them safe. `COUPON_HMAC_SECRET` and `COUPON_ENCRYPTION_KEY` must never change once you
create activation codes, or those codes stop working.

## Step 2 — Database on Neon (10 min)

1. Go to **neon.tech** → **Sign up** (GitHub or Google sign-in works). No card needed.
2. Create a project:
   - **Project name:** `plengo-demo`
   - **Postgres version:** 16 if offered (17 also works)
   - **Region:** **AWS Europe Central 1 (Frankfurt)**, the closest to Syria
3. On the project dashboard click **Connect**.
4. In the connection dialog **turn off "Connection pooling"**. The server's job queue needs a
   direct connection.
5. Copy the connection string. It looks like
   `postgresql://neondb_owner:…@ep-….eu-central-1.aws.neon.tech/neondb?sslmode=require`.
   Save it in your worksheet as the **Neon connection string**.

## Step 3 — Image storage on Cloudflare R2 (15 min, recommended)

Without R2 the demo still runs, but every image (flashcards, teacher photos, banners) is kept in
the server's memory and **disappears each time the free server sleeps or redeploys**, and the
sample flashcards have no pictures. With R2 images are permanent. R2 asks for a card but the
demo stays well inside the free 10 GB.

_Skipping R2? Jump to step 4 and use the "without R2" values there._

1. Go to **dash.cloudflare.com** → **Sign up** (free). You will use this account again in
   step 7.
2. In the left menu open **R2 Object Storage** → **Purchase R2 / Add payment method** and add a
   card (you are not charged inside the free tier).
3. **Create two buckets:** click **Create bucket**:
   - Name `media-private`, location **Automatic** → **Create bucket**
   - Name `media-public`, location **Automatic** → **Create bucket**
4. **Make `media-public` readable:** open `media-public` → **Settings** → **Public access** →
   **R2.dev subdomain** → **Allow access** → type `allow` → confirm. Copy the
   `https://pub-….r2.dev` address = **R2 public URL**.
5. **Create an access key:** back on the R2 overview page → **Manage R2 API Tokens** (or **API**
   → **Manage API tokens**) → **Create API token**:
   - Permissions: **Object Read & Write**
   - Specify buckets: `media-private` and `media-public`
   - **Create API Token**, then copy the **Access Key ID** and **Secret Access Key** (shown
     once).
6. Copy your **Account ID**: shown on the R2 overview page (right side) and in the dashboard URL.
7. **Allow uploads from your sites (CORS).** Open `media-private` → **Settings** → **CORS
   policy** → **Add CORS policy** → paste this, replacing the two addresses with yours from
   the worksheet → **Save**:

   ```json
   [
     {
       "AllowedOrigins": ["https://plengo-demo-admin.vercel.app", "https://staging.plengo-demo.pages.dev"],
       "AllowedMethods": ["PUT"],
       "AllowedHeaders": ["content-type"],
       "MaxAgeSeconds": 3600
     },
     {
       "AllowedOrigins": ["https://staging.plengo-demo.pages.dev"],
       "AllowedMethods": ["GET"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```

   Then open `media-public` → **Settings** → **CORS policy** → add:

   ```json
   [{ "AllowedOrigins": ["*"], "AllowedMethods": ["GET"], "MaxAgeSeconds": 3600 }]
   ```

## Step 4 — The API server on Render (15 min)

1. Go to **render.com** → **Get Started** → sign up **with GitHub** (no card needed).
2. **New +** → **Web Service** → **Git Provider** → connect GitHub and give Render access to
   the `malhaji95/plengo` repository → select it.
3. Fill in:
   - **Name:** your Render service name (e.g. `plengo-demo-api`)
   - **Language:** **Docker**
   - **Branch:** `claude/friendly-gates-mcmxsy`
   - **Region:** **Frankfurt (EU Central)**
   - **Root Directory:** leave empty
   - **Dockerfile Path:** `apps/api/Dockerfile`
   - **Docker Build Context Directory:** `.` (a single dot)
   - **Instance Type:** **Free**
4. **Environment Variables** → **Add from .env**, or add one by one:

   | Key                           | Value                       |
   | ----------------------------- | --------------------------- |
   | `APP_ENV`                     | `staging`                   |
   | `DATABASE_URL`                | your Neon connection string |
   | `BETTER_AUTH_SECRET`          | from step 1                 |
   | `BETTER_AUTH_URL`             | your API URL                |
   | `APP_WEB_ORIGIN`              | your student web URL        |
   | `ADMIN_ORIGIN`                | your admin URL              |
   | `MOBILE_ACCESS_JWT_SECRET`    | from step 1                 |
   | `MOBILE_REFRESH_TOKEN_PEPPER` | from step 1                 |
   | `COUPON_HMAC_SECRET`          | from step 1                 |
   | `COUPON_ENCRYPTION_KEY`       | from step 1                 |
   | `TRUST_PROXY_HOPS`            | `1`                         |
   | `JOBS_ENABLED`                | `true`                      |
   | `EMAIL_PROVIDER`              | `console`                   |

   **With R2 (step 3) add:**

   | Key                    | Value                      |
   | ---------------------- | -------------------------- |
   | `STORAGE_DRIVER`       | `r2`                       |
   | `R2_ACCOUNT_ID`        | your Cloudflare Account ID |
   | `R2_ACCESS_KEY_ID`     | from step 3.5              |
   | `R2_SECRET_ACCESS_KEY` | from step 3.5              |
   | `R2_PRIVATE_BUCKET`    | `media-private`            |
   | `R2_PUBLIC_BUCKET`     | `media-public`             |
   | `R2_PUBLIC_BASE_URL`   | your R2 public URL         |

   **Without R2 add instead:** `STORAGE_DRIVER` = `memory`.

5. **Advanced** → **Health Check Path:** `/health`.
6. **Create Web Service.** The first build takes about 5–10 minutes. Wait for **Live**.
7. Check it: open `https://<your-api>.onrender.com/health` in the browser. You should see
   `{"status":"ok"}`. If the address Render gave you differs from your worksheet, update the
   worksheet and the `BETTER_AUTH_URL` variable (Render redeploys automatically).

> The database is still empty at this point; step 5 fills it.

## Step 5 — Fill the database with one click (10 min)

This runs on GitHub, using the **Demo database setup** workflow in the repository.

1. On GitHub open the repository → **Settings** → **Environments** → **New environment** →
   name it `demo` → **Configure environment**.
2. Under **Environment secrets** → **Add environment secret**, add each of these (same values
   as on Render):
   - `DATABASE_URL`, `BETTER_AUTH_SECRET`, `MOBILE_ACCESS_JWT_SECRET`,
     `MOBILE_REFRESH_TOKEN_PEPPER`, `COUPON_HMAC_SECRET`, `COUPON_ENCRYPTION_KEY`
   - `ADMIN_PASSWORD` and `SEED_PASSWORD` (from step 1)
   - With R2 also: `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
3. Under **Environment variables** → **Add environment variable**:
   - `API_URL` = your API URL
   - `APP_WEB_ORIGIN` = your student web URL
   - `ADMIN_ORIGIN` = your admin URL
   - With R2: `STORAGE_DRIVER` = `r2`, `R2_PRIVATE_BUCKET` = `media-private`,
     `R2_PUBLIC_BUCKET` = `media-public`, `R2_PUBLIC_BASE_URL` = your R2 public URL
4. Open **Actions** → **Demo database setup** (left list) → **Run workflow**:
   - Branch: `claude/friendly-gates-mcmxsy`
   - **Load the sample content**: ticked
   - **Your admin email**: your own email address
   - **Your admin display name**: your name
   - **Run workflow**
5. Wait for the green tick (2–4 minutes). Open the run → **setup** → **Sample content…** to see
   the 10 sample activation codes it printed.

You now have:

- **Your admin account:** your email + `ADMIN_PASSWORD`.
- **Sample students** (password `SEED_PASSWORD`):
  - `student1@example.com`: permanent access to Baccalaureate Maths, plus a finished quiz,
    mistakes and statistics to look at;
  - `student2@example.com`: 7 days of access to teacher Ahmad's Physics track.
    Both can open the free Physics content and redeem a Physics activation code.
- **Sample content:** subjects, units and lessons, teachers and tracks, questions, flashcards,
  quizzes, a banner and an exam countdown.

## Step 6 — Admin panel on Vercel (10 min)

1. Go to **vercel.com** → **Sign Up** → **Hobby** → **Continue with GitHub** (no card needed).
2. **Add New…** → **Project** → find `malhaji95/plengo` → **Import** (grant access to the
   repository if asked).
3. Configure:
   - **Project Name:** your Vercel project name (e.g. `plengo-demo-admin`)
   - **Framework Preset:** Next.js (detected automatically)
   - **Root Directory:** click **Edit** → choose `apps/admin` → **Continue**
   - **Environment Variables:**
     - `NEXT_PUBLIC_API_BASE_URL` = your **admin URL** (the Vercel address itself, not Render)
     - `API_PROXY_TARGET` = your **API URL** (Render)
4. **Deploy** (2–3 minutes).
5. In the project → **Settings** → **Git** → **Production Branch**: set to
   `claude/friendly-gates-mcmxsy` and save, so future pushes deploy automatically.
6. Check the real address under **Domains**. If it is not what you wrote down, update
   `NEXT_PUBLIC_API_BASE_URL` (Settings → Environment Variables), then **Deployments** → latest
   → **⋯** → **Redeploy**. Also update `ADMIN_ORIGIN` on Render and in the GitHub `demo`
   environment, and the R2 CORS rule.
7. **Log in:** open the admin URL → your email + `ADMIN_PASSWORD`. The first login asks you to
   set up two-step verification: install **Google Authenticator** or **Microsoft
   Authenticator** on your phone, scan the QR code, type the 6-digit code. Save the backup codes
   it shows.

## Step 7 — Student website on Cloudflare Pages (15 min)

The **Deploy student web** workflow builds the site on GitHub and uploads it to Cloudflare.

1. **Cloudflare API token** (same Cloudflare account as step 3): **dash.cloudflare.com** →
   top-right profile icon → **My Profile** → **API Tokens** → **Create Token** → **Create Custom
   Token**:
   - Name: `plengo-pages-deploy`
   - Permissions: **Account** → **Cloudflare Pages** → **Edit**
   - Account resources: your account
   - **Continue to summary** → **Create Token** → copy the token (shown once).
2. **GitHub environment:** repository → **Settings** → **Environments** → **New environment** →
   `staging`:
   - **Secrets:** `CLOUDFLARE_API_TOKEN` = the token; `CLOUDFLARE_ACCOUNT_ID` = your Account ID
   - **Variables:**
     - `API_BASE_URL` = your **student web URL** (e.g. `https://staging.plengo-demo.pages.dev`)
     - `CLOUDFLARE_PAGES_PROJECT` = your Pages project name (e.g. `plengo-demo`)
     - `MEDIA_ORIGINS` = with R2: `<your R2 public URL>,https://<ACCOUNT_ID>.r2.cloudflarestorage.com`;
       without R2: your API URL
3. **Run the deploy:** **Actions** → **Deploy student web** → **Run workflow** → branch
   `claude/friendly-gates-mcmxsy`, environment **staging** → **Run workflow**. Takes about 10
   minutes (it builds the Flutter app). The first run also creates the Pages project.
4. **Connect it to the API:** Cloudflare dashboard → **Workers & Pages** → your project →
   **Settings** → **Variables and Secrets** → **Add**:
   - Type: **Text**, Name: `API_ORIGIN`, Value: your **API URL**
   - Add it for **Preview** (the `staging` address) and also **Production**.
   - Save.
5. **Run the deploy workflow once more** (step 7.3) so the site picks up `API_ORIGIN`.
6. Open your student web URL → the yellow Plengo screen → intro pages → log in as
   `student1@example.com` with `SEED_PASSWORD`.

## Step 8 — Android test app (15 min)

1. **Actions** → **Build test APK** → **Run workflow**:
   - Branch: `claude/friendly-gates-mcmxsy`
   - **API address:** your **API URL** (Render)
   - **Show activation-code redemption:** ticked
   - **Run workflow**
2. When it finishes (about 10–15 minutes), open the run → **Artifacts** → download
   `plengo-test-apk` (a zip) → unzip → `app-release.apk`.
3. Send the APK to the phone (WhatsApp, Telegram, Google Drive, or a USB cable). Open it; Android
   asks to allow **Install unknown apps** for that app → allow → **Install**.
4. Log in as a sample student, or create a new account (see step 10 for the email code).

**iPhone testers** use the student website in Safari; it is the same app. Installing on iPhones
needs an Apple Developer account (step 12).

## Step 9 — Demo checklist

Open the API URL `/health` first to wake the server, then:

- [ ] Admin: log in with two-step verification; the dashboard shows numbers and recent activity.
- [ ] Admin: **البطاقات التعليمية** → open a deck → bulk-upload a few `001-front.png` /
      `001-back.png` images → publish.
- [ ] Admin: **الكوبونات** → create a small batch of activation codes.
- [ ] Student web: home shows the countdown, banner, daily goal and continue learning.
- [ ] Student web: open Physics → take a practice quiz → see the results screen.
- [ ] Student web: study the due flashcards; rate a few cards.
- [ ] Android app: log in as `student2@example.com` → **حسابي** → **إدخال كود التفعيل** → enter
      one of the codes from step 5 → the whole Baccalaureate Physics subject unlocks.
- [ ] Admin: **الإشعارات** → send an announcement → it appears in the students' inbox (bell).

## Step 10 — Email (optional, later)

For the demo the server does not send email (`EMAIL_PROVIDER=console`). New registrations and
password resets need a 6-digit code; it is printed in the server log instead: Render → your
service → **Logs** → search for the email address. The sample accounts need no code.

To send real email you need your own domain, because Resend's free plan only delivers to
addresses you verify yourself:

1. Buy a domain (about $10/year; Cloudflare Registrar sells at cost).
2. **resend.com** → sign up → **Domains** → **Add Domain** → add the DNS records it lists in
   Cloudflare → wait for **Verified**.
3. **API Keys** → **Create API Key** (sending access).
4. On Render set `EMAIL_PROVIDER` = `resend`, `EMAIL_PROVIDER_API_KEY` = the key,
   `EMAIL_FROM` = `Plengo <no-reply@yourdomain.com>`.

Free plan: 3,000 emails a month, 100 a day.

## Step 11 — Push notifications with Firebase (optional, later)

The in-app inbox (bell icon) already works without Firebase. Push to the phone's lock screen
also needs a small piece of app code that can only be finished and tested on real phones
(`docs/release.md` §2). You can prepare the account now; it is free (Spark plan):

1. **console.firebase.google.com** → **Create a project** → name `plengo` → Google Analytics
   can be off → **Create**.
2. **Add app** → Android → package name `com.plengo.plengo` → register (download
   `google-services.json` and keep it for later).
3. ⚙️ **Project settings** → **Service accounts** → **Generate new private key** → a JSON file
   downloads. Keep it secret.
4. On Render add, from that JSON file: `FCM_PROJECT_ID` = `project_id`, `FCM_CLIENT_EMAIL` =
   `client_email`, `FCM_PRIVATE_KEY` = `private_key` (the whole text including the BEGIN/END
   lines).
5. For iPhones later: add an iOS app in Firebase and upload an APNs key from your Apple
   Developer account.

## Step 12 — Google Play and Apple (not needed for the demo)

Neither is free, and the demo above needs neither. When you are ready for real testers:

**Google Play Console** (US $25 once):

1. **play.google.com/console** → sign up → choose **Organization** if you have a registered
   company (needs a D-U-N-S number) or **Personal**. Identity verification takes a few days.
2. New personal accounts must run a **closed test with at least 12 testers for 14 days**
   before publishing to everyone, so start early.
3. Uploads need a signed App Bundle (`docs/release.md` §4) instead of the test APK.

**Apple Developer Program** (US $99 a year):

1. **developer.apple.com/programs** → **Enroll** with your Apple ID; organizations need a
   D-U-N-S number. Approval takes from a day to a few weeks.
2. Testers then install through **TestFlight**. Building for iOS needs a Mac with Xcode
   (`docs/release.md` §5).

## Keeping the demo up to date

- **New code pushed to the branch:** Render and Vercel redeploy automatically.
- **Database changes in new code:** run **Demo database setup** again with **Load the sample
  content** unticked and the admin email empty; it applies only new migrations.
- **Student website:** run **Deploy student web** again.
- **Android app:** run **Build test APK** again and reinstall.

## Troubleshooting

| Symptom                                         | Fix                                                                                                                    |
| ----------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| First page load hangs for ~1 minute             | Render's free server was asleep. Wait, or open `/health` first.                                                        |
| Render deploy fails with "Invalid environment"  | A variable is missing or too short (secrets need 32+ characters). The log names it.                                    |
| Admin login says the connection failed          | `NEXT_PUBLIC_API_BASE_URL` must be the admin's own URL and `API_PROXY_TARGET` the Render URL; redeploy after changing. |
| Admin or web login loops back to the login page | `ADMIN_ORIGIN` / `APP_WEB_ORIGIN` on Render must match the real addresses exactly (https, no trailing `/`).            |
| Student web shows a network error               | `API_ORIGIN` missing in the Pages project, or the deploy ran before you added it: add it and run the deploy again.     |
| Images missing or broken                        | Without R2 they vanish when the server sleeps. With R2 check the CORS rules and `MEDIA_ORIGINS`.                       |
| Activation codes say "invalid"                  | The coupon secrets differ between Render and the GitHub `demo` environment. They must be identical.                    |
| Demo database setup fails at "Migrations"       | `DATABASE_URL` is wrong, or a pooled Neon address was used; copy it again with pooling turned off.                     |
