# myapp/__init__.py
"""
This file makes the 'myapp' directory a Python package.

It allows Django to import models, views, admin, and other modules
from this app using `from myapp import ...`.

Optional: You can expose commonly used models here for convenience.
"""

# Optional: Import models to make them available at package level
# from .models import (
#     Login, User, Friendrequest, Post, Complaint,
#     Comments, Chat
# )

# Tell Django which AppConfig to use (defined in apps.py)
default_app_config = 'myapp.apps.MyappConfig'