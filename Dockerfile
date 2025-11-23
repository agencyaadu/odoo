FROM odoo:19

# Copy custom addons and config. DB settings in debian/odoo.conf are left empty
# so container env vars (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSLMODE)
# control the external Postgres connection.
COPY --chown=odoo:odoo addons /mnt/extra-addons
COPY --chown=odoo:odoo debian/odoo.conf /etc/odoo/odoo.conf

USER odoo
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]
