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
app = cors(app, allow_origin="*")

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
    
    config = Config()
    config.bind = ["127.0.0.1:8000"]
    config.use_reloader = True
    
    asyncio.run(hypercorn.asyncio.serve(app, config))
