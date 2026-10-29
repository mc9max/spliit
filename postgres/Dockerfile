# PostgreSQL 16 companion for the Spliit Railway template.
#
# Bakes every constant as ENV because Railway's `templates create` only
# carries ${{...}} expressions into template defaults — literals would land
# on the deploy form as required fields. The only variable on this service
# is POSTGRES_PASSWORD (${{secret(32)}}), which spliit references as
# ${{postgres.POSTGRES_PASSWORD}} (via SPLIIT_DB_PASSWORD).
#
# Volume handling: the official postgres image starts as root and its
# entrypoint chowns $PGDATA, which tolerates Railway's root-owned volumes.
# PGDATA is a SUBDIR of the mount because initdb refuses a volume mount
# point directly (it contains lost+found). The volume is created at deploy
# time on /var/lib/postgresql/data via `railway volume add`.
#
# Digest reused from the proven listmonk-lite companion (same postgres:16
# image, live since 2026-10-18) rather than re-pinning a moving tag.

FROM postgres:16@sha256:ca0bd484cb98bf4b24eb1010e73fb3fcbd6714d240fbc1a10eea5b7dbecb641d

ENV PGDATA=/var/lib/postgresql/data/pgdata \
    POSTGRES_USER=spliit \
    POSTGRES_DB=spliit

LABEL org.opencontainers.image.source="https://github.com/mc9max/spliit"
