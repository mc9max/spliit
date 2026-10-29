[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/spliit?utm_campaign=spliit)

# Deploy and Host

Spliit is a free, open-source alternative to Splitwise: share expenses
with friends and family, track who paid what, and settle up with
minimal friction. Deploy it on Railway in one click: two services (the
Spliit app plus a PostgreSQL companion), one volume for the database,
and a zero-field deploy form. No accounts, no sign-up, no email
verification — create a group, add an expense, and the balance view
proves the whole cycle before you share a link with anyone real.

## About Hosting

Hosting Spliit on Railway means a Next.js standalone server talking to
a PostgreSQL 16 companion over the private network, with the database
on a persistent volume. The wrapper composes the Prisma connection
strings from the companion's private domain and generated password at
boot, runs `prisma migrate deploy` for idempotent schema setup, and
sets the public URL from the Railway domain so metadata links are
correct. The app service itself is stateless (expense documents are
off by default and need S3 when enabled), so restarts and redeploys
keep every group, expense, and balance intact through the database.
Railway terminates TLS at the edge; the app's plain HTTP listener
serves the full UI and API.

## Why Deploy

- **No accounts to manage.** Groups are shared by link, so there is no
  registration wall and no email round-trip before the first expense.
- **Your money math, your server.** Groups, expenses, and balances live
  in your own PostgreSQL database — not on a third-party ledger.
- **Built for the group chat.** One link per group, per-person balances,
  multi-currency support, and a mobile-friendly UI for rent, trips,
  dinners, and shared subscriptions.
- **Light and always on.** A single Next.js service plus Postgres — no
  workers to feed and no queue to drain.

## Common Use Cases

- Splitting rent, utilities, and groceries with roommates.
- Tracking shared costs on a group trip, then settling up at the end.
- Dividing dinners, gifts, and subscriptions among friends and family.
- A household ledger where everyone can see who owes whom at a glance.

## Dependencies for

Spliit needs exactly two services: the app and PostgreSQL 16. There are
no workers, no cache service, and no object storage in the default
deploy — expense documents (an opt-in feature) are the only thing that
adds S3, and receipt/category extraction (also opt-in) is the only
thing that adds an OpenAI-compatible API key.

### Deployment Dependencies

- Railway Hobby plan or higher (two always-on services).
- Memory at rest: roughly 300–500 MB for the app service and ~150 MB
  for Postgres.
- One persistent volume (Postgres data at
  `/var/lib/postgresql/data`, database files in the `pgdata` subdir).
- No GPU, no Docker socket, no special kernel features.

## Configuration (condensed)

The deploy form is zero-field. Auto-wired: `SPLIIT_DB_HOST`
(`${{postgres.RAILWAY_PRIVATE_DOMAIN}}`), `SPLIIT_DB_PASSWORD`
(`${{postgres.POSTGRES_PASSWORD}}`), `BASE_URL`
(`https://${{RAILWAY_PUBLIC_DOMAIN}}`), and the companion's
`POSTGRES_PASSWORD` (`${{secret(32)}}`; user/db `spliit` baked in).
Optional upstream features, all off by default:
`DEFAULT_CURRENCY_CODE` (default `USD`), `ENABLE_GROUP_DELETION` +
`CRON_SECRET` (scheduled purge endpoint), `ENABLE_EXPENSE_DOCUMENTS`
+ `S3_UPLOAD_KEY` / `S3_UPLOAD_SECRET` / `S3_UPLOAD_BUCKET` /
`S3_UPLOAD_REGION` / `S3_UPLOAD_ENDPOINT`, `ENABLE_RECEIPT_EXTRACT`
and `ENABLE_CATEGORY_EXTRACT` + `OPENAI_API_KEY` /
`OPENAI_BASE_URL` / `OPENAI_MODEL_RECEIPT_EXTRACT` /
`OPENAI_MODEL_CATEGORY_EXTRACT`, `ANALYTICS_PROVIDER` (`console`,
`plausible`, `umami`) + `PLAUSIBLE_DOMAIN` / `UMAMI_WEBSITE_ID`.
Full descriptions live in the repo README.
