#!/bin/bash
# Script to update Odoo admin password from environment variables
# This runs after Odoo has started

DB_NAME="${ODOO_DB_NAME:-nidan}"
ADMIN_EMAIL="${ODOO_ADMIN_EMAIL:-admin}"
ADMIN_PASSWORD="${ODOO_ADMIN_PASSWORD:-admin}"
ODOO_WEB_BASE_URL="${ODOO_WEB_BASE_URL}"
ODOO_WEB_BASE_URL_FREEZE="${ODOO_WEB_BASE_URL_FREEZE:-True}"

# Wait for Odoo to be ready for shell commands
echo "Waiting for Odoo to initialize database $DB_NAME..."
while true; do
    # Check if the res_users table exists (indicates base module is installed)
    # Use postgres superuser for this check to be sure we can access it
    if PGPASSWORD="${POSTGRES_PASSWORD:-odoo}" psql -h "${HOST:-odoo-db}" -U "${POSTGRES_USER:-odoo}" -d "$DB_NAME" -tc "SELECT 1 FROM information_schema.tables WHERE table_name = 'res_users'" 2>/dev/null | grep -q 1; then
        echo "Odoo Registry Ready (res_users table found)!"
        break
    else
        echo "Odoo is still initializing (tables not ready yet)..."
    fi
    sleep 5
done

# Extra buffer to ensure registry is fully stable
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

