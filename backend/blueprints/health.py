"""
Health check blueprint.
"""

from quart import Blueprint

health_bp = Blueprint("health", __name__)


@health_bp.route("/", methods=["GET"])
async def root():
    """Root endpoint."""
    return {
        "message": "Google Intelligent Group API",
        "status": "running",
        "version": "1.0.0"
    }


@health_bp.route("/health", methods=["GET"])
async def health_check():
    """Health check endpoint."""
    return {"status": "healthy"}

