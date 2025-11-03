"""
App configuration for the 'myapp' Django application.

This file defines the configuration class for the 'myapp' app,
which is referenced in myapp/__init__.py via default_app_config.
"""

from django.apps import AppConfig


class MyappConfig(AppConfig):
    """
    Configuration class for the 'myapp' application.
    
    Attributes:
        default_auto_field (str): The default primary key field type.
        name (str): The name of the app (must match the folder name).
        verbose_name (str): Human-readable name for the admin interface.
    """
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'myapp'
    verbose_name = 'Cybercrime Prevention on Social Media'