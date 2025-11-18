"""
Blueprints for organizing API routes.
"""

from .query import query_bp
from .health import health_bp

__all__ = ["query_bp", "health_bp"]

