#!/bin/bash
# Script to update Odoo admin password from environment variables
# This runs after Odoo has started

DB_NAME="${ODOO_DB_NAME:-nidan}"
ADMIN_EMAIL="${ODOO_ADMIN_EMAIL:-admin}"
ADMIN_PASSWORD="${ODOO_ADMIN_PASSWORD:-admin}"
ODOO_WEB_BASE_URL="${ODOO_WEB_BASE_URL}"
ODOO_WEB_BASE_URL_FREEZE="${ODOO_WEB_BASE_URL_FREEZE:-True}"

# Wait for Odoo to finish initialization and registry to be loaded
echo "Waiting for Odoo to initialize (checking logs)..."
# We check the logs for 'Registry loaded' to be sure we can run odoo shell
# Max wait 300 seconds
for i in {1..60}; do
    if grep -q "Registry loaded" /var/lib/odoo/odoo.log 2>/dev/null || [ -f /var/lib/odoo/sessions/initialized ]; then
        echo "Odoo Registry loaded!"
        break
    fi
    echo "Waiting for Odoo Registry... ($i/60)"
    sleep 5
done

# Extra buffer
sleep 5

# Update config parameters using Odoo shell
odoo shell -d "$DB_NAME" <<EOF
# Update Admin User
admin_user = env['res.users'].browse(2)
if admin_user.exists():
    admin_user.write({
        'login': '${ADMIN_EMAIL}',
        'password': '${ADMIN_PASSWORD}'
    })
    print(f"✅ Admin user updated: login='${ADMIN_EMAIL}'")

# Update Web Base URL
if '${ODOO_WEB_BASE_URL}':
    env['ir.config_parameter'].set_param('web.base.url', '${ODOO_WEB_BASE_URL}')
    env['ir.config_parameter'].set_param('web.base.url.freeze', '${ODOO_WEB_BASE_URL_FREEZE:-True}')
    print(f"✅ Web Base URL updated: ${ODOO_WEB_BASE_URL}")

env.cr.commit()
EOF

