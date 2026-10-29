# Spliit on Railway — free, open-source Splitwise alternative (spliit).
#
# WHY THIS WRAPPER EXISTS (house-style notes):
#
# - FROM pins the upstream image by tag AND digest, never :latest, so every
#   deploy runs the exact build we tested: ghcr.io/spliit-app/spliit 1.30.0
#   (release 2026-10-11), digest verified against the GHCR packages API.
# - USER root: the upstream runner stage sets no USER, so it already runs
#   as root; stating it keeps the intent explicit and matches the app
#   service having no volume (nothing to chown, nothing to break).
# - No PORT baking: the Next.js standalone server reads Railway's injected
#   PORT at runtime (falling back to the image's baked 3000), so a static
#   port declaration would fight the platform. No EXPOSE for the same
#   reason — the listen port is PORT-or-3000, not a fixed number.
# - HOSTNAME=0.0.0.0 is already baked into the upstream image: the
#   standalone server binds all interfaces instead of its localhost
#   default, which would be unreachable from outside the container.
# - DB wiring lives in entrypoint.sh, not in ENV: `railway templates
#   create` carries ONLY ${{...}} expressions into template defaults, and
#   it cannot reliably compose several refs into one URL value. So the
#   template carries two single-ref variables (SPLIIT_DB_HOST and
#   SPLIIT_DB_PASSWORD, each one ${{...}} ref to the postgres companion)
#   and the entrypoint composes the two Prisma connection strings from
#   them in shell, with user/db/port baked as constants.
# - BASE_URL is a runtime override in Spliit (src/lib/env.ts): the
#   prebuilt image can be told where it is reachable without a rebuild.
#   The template sets it to https://${{RAILWAY_PUBLIC_DOMAIN}}; the
#   entrypoint derives the same value as a fallback so a deploy without
#   the variable still builds correct metadata links. (Same-domain
#   server actions pass Next.js's origin check on Host match alone, so
#   group/expense creation works even before BASE_URL resolves.)
# - No Docker HEALTHCHECK: the Alpine base has no curl/wget; Railway's
#   external healthcheckPath (/api/health/readiness, a public,
#   unauthenticated endpoint that checks the database) covers it.
# - ENTRYPOINT is our script, not the upstream one, because we must
#   compose the Prisma URLs and BASE_URL first; it then chains into the
#   upstream entrypoint, which runs `prisma migrate deploy` (idempotent
#   schema setup, and a readiness gate: it fails while postgres is down)
#   and execs the standalone server intact.

FROM ghcr.io/spliit-app/spliit:1.30.0@sha256:cfaf0f84ef4f11cd3e4c46329039a0f1f51a7d7bf8cc218bf7c1b366e58a99f1

USER root

WORKDIR /usr/app

COPY entrypoint.sh /railway-entrypoint.sh
RUN chmod +x /railway-entrypoint.sh

ENTRYPOINT ["/railway-entrypoint.sh"]

LABEL org.opencontainers.image.source="https://github.com/mc9max/spliit"
LABEL org.opencontainers.image.title="Spliit"
LABEL org.opencontainers.image.description="Spliit expense splitting with friends and family, wrapped for one-click Railway deploys"
