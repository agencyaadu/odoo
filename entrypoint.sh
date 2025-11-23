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
add_arg_if_set "--db_name" "${DB_NAME:-}"
add_arg_if_set "--db_sslmode" "${DB_SSLMODE:-}"

# Only wait for Postgres if a host is provided.
if [ -n "${DB_HOST:-}" ]; then
    /usr/bin/wait-for-psql.py \
        --db_host "${DB_HOST}" \
        --db_port "${DB_PORT:-5432}" \
        --db_user "${DB_USER:-odoo}" \
        --db_password "${DB_PASSWORD:-}" \
        --timeout "${DB_TIMEOUT:-30}"
else
    echo "DB_HOST not set; skipping wait-for-psql. Odoo will use config/CLI defaults."
fi

exec odoo -c /etc/odoo/odoo.conf "${DB_ARGS[@]}" "$@"
