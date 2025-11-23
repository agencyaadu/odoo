#!/bin/bash
set -euo pipefail

DB_ARGS=()

add_arg_if_set() {
    local flag="$1"
    local value="${2:-}"
    if [ -n "$value" ]; then
        DB_ARGS+=("$flag" "$value")
    fi
}

add_arg_if_set "--db_host" "${DB_HOST:-}"
add_arg_if_set "--db_port" "${DB_PORT:-}"
add_arg_if_set "--db_user" "${DB_USER:-}"
add_arg_if_set "--db_password" "${DB_PASSWORD:-}"
add_arg_if_set "--database" "${DB_NAME:-}"
add_arg_if_set "--db_sslmode" "${DB_SSLMODE:-}"

# Check if database is initialized by probing a core table.
db_is_initialized() {
    python - <<'PY'
import os
import sys
import psycopg2
from psycopg2 import sql
params = {
    "host": os.environ.get("DB_HOST", ""),
    "port": os.environ.get("DB_PORT", "5432"),
    "user": os.environ.get("DB_USER", ""),
    "password": os.environ.get("DB_PASSWORD", ""),
    "dbname": os.environ.get("DB_NAME", ""),
    "sslmode": os.environ.get("DB_SSLMODE", "prefer") or "prefer",
}
if not params["host"] or not params["dbname"]:
    sys.exit(1)
try:
    with psycopg2.connect(**params) as conn:
        with conn.cursor() as cr:
            cr.execute(sql.SQL("SELECT state FROM ir_module_module WHERE name = 'base'"))
            row = cr.fetchone()
            if not row:
                sys.exit(1)
            if row[0] not in ('installed', 'to upgrade'):
                sys.exit(1)
    sys.exit(0)
except psycopg2.errors.UndefinedTable:
    sys.exit(1)
except Exception as exc:
    sys.stderr.write(f"DB init check failed: {exc}\n")
    sys.exit(2)
PY
}

# Only wait for Postgres if a host is provided and the helper exists.
if [ -n "${DB_HOST:-}" ]; then
    if command -v wait-for-psql.py >/dev/null 2>&1; then
        wait-for-psql.py \
            --db_host "${DB_HOST}" \
            --db_port "${DB_PORT:-5432}" \
            --db_user "${DB_USER:-odoo}" \
            --db_password "${DB_PASSWORD:-}" \
            --timeout "${DB_TIMEOUT:-30}"
    else
        echo "wait-for-psql.py not found; skipping DB wait."
    fi
else
    echo "DB_HOST not set; skipping wait-for-psql. Odoo will use config/CLI defaults."
fi

# Initialize the database schema once if needed.
if [ -n "${DB_HOST:-}" ] && [ -n "${DB_NAME:-}" ]; then
    if db_is_initialized; then
        echo "Database ${DB_NAME} already initialized; skipping -i base."
    else
        echo "Database ${DB_NAME} not initialized; running -i base once."
        odoo -c /etc/odoo/odoo.conf -d "${DB_NAME}" -i base --without-demo all
    fi
fi

exec odoo -c /etc/odoo/odoo.conf "${DB_ARGS[@]}" "$@"
