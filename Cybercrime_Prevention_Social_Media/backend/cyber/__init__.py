# cyber/__init__.py
# This file makes the 'cyber' directory a Python package.
# It allows Django to import settings, urls, wsgi, and asgi modules.

# Optional: You can add version or app config here
__version__ = "1.0.0"

# This tells Django that this is the root package
default_app_config = 'cyber.apps.CyberConfig'  # Optional, if you have apps.py