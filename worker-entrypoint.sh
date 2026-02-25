#!/bin/bash
set -e

KOHA_INSTANCE="library"
KOHA_CONF="/etc/koha/sites/$KOHA_INSTANCE/koha-conf.xml"

# ── Wait for the DB ──────────────────────────────────────────────────────────
echo "[worker] Waiting for database..."
until mariadb-admin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; do
  sleep 5
done
echo "[worker] Database is ready."

# ── Wait for the Koha instance to be provisioned by the app container ────────
echo "[worker] Waiting for Koha instance config ($KOHA_CONF)..."
until [ -f "$KOHA_CONF" ]; do
  sleep 5
done
echo "[worker] Koha instance found."

# Give the app container a few extra seconds to finish DB setup / migrations
sleep 10

# ── Install the crontab ──────────────────────────────────────────────────────
# The crontab file is copied into /etc/cron.d; set correct permissions.
if [ -f /etc/cron.d/koha-worker ]; then
  chmod 0644 /etc/cron.d/koha-worker
  chown root:root /etc/cron.d/koha-worker
fi

# ── OpenSearch: initial index build ─────────────────────────────────────────
echo "[worker] Running initial OpenSearch index rebuild..."
KOHA_CONF="$KOHA_CONF" \
  perl /usr/share/koha/bin/search_tools/rebuild_elasticsearch.pl \
    -a -b -v --instance "$KOHA_INSTANCE" 2>&1 || \
  echo "[worker] WARNING: Initial index rebuild had errors (continuing anyway)."

# ── Start cron daemon ────────────────────────────────────────────────────────
echo "[worker] Starting cron daemon..."
service cron start

# ── Start background_jobs_worker (index queue) in background ────────────────
echo "[worker] Starting background_jobs_worker (index queue)..."
KOHA_CONF="$KOHA_CONF" \
  perl /usr/share/koha/bin/background_jobs_worker.pl \
    --instance "$KOHA_INSTANCE" \
    --job-queue index &

# ── Start background_jobs_worker (default queue) – foreground (PID 1 proxy) ─
echo "[worker] Starting background_jobs_worker (default queue)..."
exec env KOHA_CONF="$KOHA_CONF" \
  perl /usr/share/koha/bin/background_jobs_worker.pl \
    --instance "$KOHA_INSTANCE"
