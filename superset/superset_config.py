# Superset Configuration for Path-Based Deployment
import os

# Use PyMySQL for any mysql:// SQLAlchemy URIs (avoids requiring mysqlclient / MySQLdb C extension)
try:
    import pymysql

    pymysql.install_as_MySQLdb()
except ImportError:
    pass

from flask import redirect
from flask_appbuilder import expose, IndexView

# Secret key for session encryption
SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', 'your-secret-key-here')

# SQLAlchemy database URI
SQLALCHEMY_DATABASE_URI = 'sqlite:////app/superset_home/superset.db'

# Flask App Configuration
# CRITICAL: Tell Superset it's behind /superset/ prefix
ENABLE_PROXY_FIX = True

# Application root for URL generation (no trailing slash to avoid double prefix in redirects)
APPLICATION_ROOT = '/superset'

# Static assets must use the same prefix so CSS/JS load correctly behind proxy
STATIC_ASSETS_PREFIX = '/superset'

# WTF CSRF settings
WTF_CSRF_ENABLED = True
WTF_CSRF_EXEMPT_LIST = []
WTF_CSRF_TIME_LIMIT = None

# Set the authentication type
# AUTH_TYPE = AUTH_DB  # Database authentication (default)

# Uncomment to setup Full admin role name
# AUTH_ROLE_ADMIN = 'Admin'

# Uncomment to setup Public role name, no authentication needed
# AUTH_ROLE_PUBLIC = 'Public'

# Will allow user self registration
# AUTH_USER_REGISTRATION = True

# The default user self registration role
# AUTH_USER_REGISTRATION_ROLE = "Public"

# CORS settings (if needed for API access)
ENABLE_CORS = True
CORS_OPTIONS = {
    'supports_credentials': True,
    'allow_headers': ['*'],
    'origins': ['*']
}

# Session configuration
SESSION_COOKIE_NAME = 'superset_session'
SESSION_COOKIE_PATH = '/superset/'
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = False  # Set to True if using HTTPS

# Disable async queries for simplicity (optional)
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
}

# Configure logging
LOGGER_LEVEL = 'INFO'

# Prevent Superset from redirecting to root
PREFERRED_URL_SCHEME = 'http'  # Change to 'https' in production

# Additional configuration for reverse proxy
ENABLE_PROXY_FIX = True
PROXY_FIX_CONFIG = {
    "x_for": 1,
    "x_proto": 1,
    "x_host": 1,
    "x_port": 1,
    "x_prefix": 1,
}

# Custom post-login redirect - avoid broken /superset/welcome/ (404), use dashboard list
class SupersetIndexView(IndexView):
    @expose("/")
    def index(self):
        from flask import g
        if hasattr(g, "user") and g.user and g.user.is_authenticated:
            return redirect("/superset/dashboard/list/")
        return redirect("/superset/login/")


FAB_INDEX_VIEW = "superset_config.SupersetIndexView"