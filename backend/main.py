"""
Google Intelligent Group - Backend API Server
Multi-Agent System with LangChain 1.0 & Quart
"""

import os
from quart import Quart
from quart_cors import cors
from dotenv import load_dotenv
from agents.supervisor_langgraph import SupervisorAgentLangGraph
from blueprints.query import query_bp, set_supervisor
from blueprints.health import health_bp

load_dotenv()

# Initialize Quart app
app = Quart(__name__)
app.config["JSON_SORT_KEYS"] = False

# Enable CORS
# Allow all origins in development, or specific origins in production
allowed_origins = os.environ.get("ALLOWED_ORIGINS", "*")
if allowed_origins == "*":
    app = cors(app, allow_origin="*")
else:
    # Split comma-separated origins
    origins = [origin.strip() for origin in allowed_origins.split(",")]
    app = cors(app, allow_origin=origins)

# Initialize LangGraph Supervisor Agent
supervisor = SupervisorAgentLangGraph()
set_supervisor(supervisor)
        
# Register blueprints
app.register_blueprint(health_bp)
app.register_blueprint(query_bp)


if __name__ == "__main__":
    import asyncio
    import hypercorn.asyncio
    from hypercorn.config import Config
    
    # Use PORT from environment (for deployment) or default to 8081
    port = int(os.environ.get("PORT", os.environ.get("BACKEND_PORT", 8081)))
    host = os.environ.get("HOST", os.environ.get("BACKEND_HOST", "127.0.0.1"))
    
    # In containers, we need 0.0.0.0 to listen on all interfaces
    # On Windows local development, use 127.0.0.1 to avoid permission issues
    # Check if we're running in a container (common indicators)
    is_container = os.path.exists("/.dockerenv") or os.environ.get("CONTAINER") == "true"
    
    # Allow 0.0.0.0 for remote access (requires admin on Windows)
    # Only auto-change if explicitly set to avoid permission errors in non-admin mode
    if not is_container and host == "0.0.0.0":
        import platform
        if platform.system() == "Windows":
            # Check if running as admin - if not, warn but allow (user may have admin)
            try:
                import ctypes
                is_admin = ctypes.windll.shell32.IsUserAnAdmin() != 0
                if not is_admin:
                    print("WARNING: 0.0.0.0 requires admin privileges on Windows.")
                    print("If you get permission errors, either:")
                    print("  1. Run PowerShell as Administrator, OR")
                    print("  2. Use 127.0.0.1 for local access only")
                    # Don't auto-change - let user decide
            except:
                pass  # Continue with 0.0.0.0
    
    config = Config()
    config.bind = [f"{host}:{port}"]
    config.use_reloader = os.environ.get("ENVIRONMENT") != "production"
    
    print(f"Starting backend server on http://{host}:{port}")
    print(f"Health check: http://{host}:{port}/health")
    
    asyncio.run(hypercorn.asyncio.serve(app, config))
