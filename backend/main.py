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
    
    # Use PORT from environment (for deployment) or default to 8000
    port = int(os.environ.get("PORT", 8000))
    host = os.environ.get("HOST", "127.0.0.1")
    
    config = Config()
    config.bind = [f"{host}:{port}"]
    config.use_reloader = os.environ.get("ENVIRONMENT") != "production"
    
    asyncio.run(hypercorn.asyncio.serve(app, config))
