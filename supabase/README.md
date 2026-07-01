# Supabase — CheckPlan

Local Supabase project config for CheckPlan's cloud sync (accounts + backup/restore).
`config.toml` is committed; **secrets live in the gitignored `.env`** (see [`../.env.example`](../.env.example)).

- **Cloud project:** `CheckPlan` (ref `awxnfthjqktbmcveybtf`), region `us-east-1`, Pro plan.
- **Prerequisites:** the Supabase CLI (`brew install supabase/tap/supabase`) and Docker.

## Local stack

```bash
supabase start          # boot the local stack (Postgres, Auth, Studio, mail catcher)
supabase status         # show local URLs + keys
supabase stop           # tear it down
```

- **Studio:** <http://127.0.0.1:54323>
- **Local mail catcher (Mailpit):** <http://127.0.0.1:54324> — with `enable_confirmations = true`, local
  sign-ups send a confirmation email here (nothing leaves your machine locally).

### Config choices (mirroring production)

- `auth.email.enable_confirmations = true` — matches the cloud project (confirmation on). A headless
  integration test creates a **confirmed** user via the admin (service_role) API, since the emailed
  PKCE link can't be followed in the local stack.
- `auth.enable_anonymous_sign_ins = false` — anonymous sign-in stays disabled (the app's local-only
  mode is client-side, not a server identity).
- `auth.additional_redirect_urls = ["io.checkplan.app://login-callback"]` — the app's PKCE deep-link scheme.
- `db.major_version = 17` — matches the cloud Postgres version.

## Linking to the cloud (for migrations)

```bash
supabase login                                   # browser OAuth (one-time, per machine)
supabase link --project-ref awxnfthjqktbmcveybtf # connect this repo to the cloud project
```

The accounts/identity work adds **no** schema, so no migrations are pushed yet. The remote mirror tables
and row-level security arrive with the backup/restore work, under `supabase/migrations/`.

## Running the app against the cloud

```bash
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

Without these defines, the app runs **local-only** (no Supabase calls) — the permanent first-class mode.

## Auth email (Resend) — cloud project

Real confirmation/reset emails on the cloud project send via **custom SMTP (Resend)**, configured in the
dashboard (Authentication → Emails → SMTP Settings), from the verified domain **`mail.checkplan.io`**
(DKIM + SPF + return-path MX + DMARC on Cloudflare; sender `noreply@mail.checkplan.io`) — verified
end-to-end. The built-in sender is test-only (~2 emails/hour). Local dev never needs Resend — it uses the
Mailpit catcher above.
