FROM odoo:19

# Copy custom addons and config. DB settings in debian/odoo.conf are left empty
# so container env vars (DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME, DB_SSLMODE)
# control the external Postgres connection.
COPY addons /mnt/extra-addons
COPY debian/odoo.conf /etc/odoo/odoo.conf

# Ensure ownership for the odoo user used by the base image.
RUN chown -R odoo:odoo /mnt/extra-addons /etc/odoo/odoo.conf

USER odoo
CMD ["odoo", "-c", "/etc/odoo/odoo.conf"]
