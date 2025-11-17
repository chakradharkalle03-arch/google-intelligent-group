"""
Google Intelligent Group - Backend API Server
Multi-Agent System with LangChain 1.0 & FastAPI
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, Dict, Any
import os
import json
import asyncio
from dotenv import load_dotenv
from agents.supervisor import SupervisorAgent

load_dotenv()

# Initialize Supervisor Agent
supervisor = SupervisorAgent()

app = FastAPI(
    title="Google Intelligent Group API",
    description="Multi-Agent System Backend with LangChain & Gemini",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class QueryRequest(BaseModel):
    query: str
    stream: Optional[bool] = False


class QueryResponse(BaseModel):
    response: str
    agent_outputs: Optional[Dict[str, Any]] = None
    message: Optional[str] = None


@app.get("/")
async def root():
    return {
        "message": "Google Intelligent Group API",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


async def stream_query_processing(query: str):
    """Stream query processing results as they become available."""
    try:
        # Send initial status
        yield f"data: {json.dumps({'type': 'status', 'message': 'Processing query...', 'agent': 'supervisor'})}\n\n"
        
        # Step 1: Plan agent usage
        yield f"data: {json.dumps({'type': 'status', 'message': 'Analyzing query and planning agent usage...', 'agent': 'supervisor'})}\n\n"
        agent_plan = await supervisor._plan_agent_usage(query)
        
        results = {
            "supervisor": f"Processing query: {query}",
            "plan": agent_plan,
            "agent_outputs": {}
        }
        
        # Execute agents in logical order: GoogleMap -> Research -> Telephone -> Calendar
        # This ensures dependencies are met (e.g., GoogleMap results available for Telephone/Calendar)
        
        # 1. Execute GoogleMap Agent first (if needed) - provides location/phone data
        if agent_plan.get("use_googlemap"):
            yield f"data: {json.dumps({'type': 'status', 'message': 'Searching for locations...', 'agent': 'googleMap'})}\n\n"
            try:
                map_result = await supervisor._execute_googlemap(query)
                results["agent_outputs"]["googleMap"] = map_result
                formatted = map_result.get("formatted", "")
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'googleMap', 'output': formatted})}\n\n"
            except Exception as e:
                error_result = {
                    "agent": "GoogleMap",
                    "success": False,
                    "error": str(e),
                    "formatted": f"❌ GoogleMap Agent Error: {str(e)}"
                }
                results["agent_outputs"]["googleMap"] = error_result
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'googleMap', 'output': error_result['formatted']})}\n\n"
        
        # 2. Execute Research Agent (independent, can run in parallel)
        if agent_plan.get("use_research"):
            yield f"data: {json.dumps({'type': 'status', 'message': 'Researching...', 'agent': 'research'})}\n\n"
            try:
                research_result = await supervisor._execute_research(query)
                results["agent_outputs"]["research"] = research_result
                formatted = research_result.get("formatted", "")
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'research', 'output': formatted})}\n\n"
            except Exception as e:
                error_result = {
                    "agent": "Research",
                    "success": False,
                    "error": str(e),
                    "formatted": f"❌ Research Agent Error: {str(e)}"
                }
                results["agent_outputs"]["research"] = error_result
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'research', 'output': error_result['formatted']})}\n\n"
        else:
            # Research agent not needed - show status
            research_status = {
                "agent": "Research",
                "success": True,
                "formatted": "ℹ️ Research Agent: Not needed for this query. This agent is used for general information and research questions.",
                "skipped": True
            }
            results["agent_outputs"]["research"] = research_status
            yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'research', 'output': research_status['formatted']})}\n\n"
        
        # 3. Execute Telephone Agent (may use GoogleMap results)
        # Also trigger if making reservation and GoogleMap found results
        should_call_telephone = agent_plan.get("use_telephone", False)
        
        # Auto-trigger telephone if making reservation and we have restaurant results
        if not should_call_telephone:
            if agent_plan.get("use_calendar") and results.get("agent_outputs", {}).get("googleMap", {}).get("data", {}).get("results"):
                # Making a reservation with restaurant found - should call
                should_call_telephone = True
        
        if should_call_telephone:
            yield f"data: {json.dumps({'type': 'status', 'message': 'Initiating phone call...', 'agent': 'telephone'})}\n\n"
            try:
                phone_result = await supervisor._execute_telephone(query, results.get("agent_outputs", {}))
                results["agent_outputs"]["telephone"] = phone_result
                formatted = phone_result.get("formatted", "")
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'telephone', 'output': formatted})}\n\n"
            except Exception as e:
                error_result = {
                    "agent": "Telephone",
                    "success": False,
                    "error": str(e),
                    "formatted": f"❌ Telephone Agent Error: {str(e)}"
                }
                results["agent_outputs"]["telephone"] = error_result
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'telephone', 'output': error_result['formatted']})}\n\n"
        
        # 4. Execute Calendar Agent last (may use GoogleMap results)
        if agent_plan.get("use_calendar"):
            yield f"data: {json.dumps({'type': 'status', 'message': 'Managing calendar...', 'agent': 'calendar'})}\n\n"
            try:
                calendar_result = await supervisor._execute_calendar(query, results.get("agent_outputs", {}))
                results["agent_outputs"]["calendar"] = calendar_result
                formatted = calendar_result.get("formatted", "")
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'calendar', 'output': formatted})}\n\n"
            except Exception as e:
                error_result = {
                    "agent": "Calendar",
                    "success": False,
                    "error": str(e),
                    "formatted": f"❌ Calendar Agent Error: {str(e)}"
                }
                results["agent_outputs"]["calendar"] = error_result
                yield f"data: {json.dumps({'type': 'agent_output', 'agent': 'calendar', 'output': error_result['formatted']})}\n\n"
        
        # Generate final summary
        yield f"data: {json.dumps({'type': 'status', 'message': 'Generating final summary...', 'agent': 'supervisor'})}\n\n"
        try:
            summary = await supervisor._generate_summary(query, results)
        except Exception as e:
            # Use fallback summary if LLM summary fails
            summary = supervisor._create_fallback_summary(query, results)
        
        # Format agent outputs for final response
        agent_outputs = {}
        for agent_name, agent_result in results.get("agent_outputs", {}).items():
            if isinstance(agent_result, dict):
                agent_outputs[agent_name] = agent_result.get("formatted", str(agent_result))
            else:
                agent_outputs[agent_name] = str(agent_result)
        
        agent_outputs["supervisor"] = results.get("supervisor", "Query processed")
        
        # Send final response
        final_response = {
            "type": "complete",
            "response": summary,
            "agent_outputs": agent_outputs,
            "message": "Query processed successfully"
        }
        yield f"data: {json.dumps(final_response)}\n\n"
        
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        error_response = {
            "type": "error",
            "error": str(e),
            "message": f"Error processing query: {str(e)}",
            "trace": error_trace
        }
        yield f"data: {json.dumps(error_response)}\n\n"


@app.post("/query")
async def process_query(request: QueryRequest):
    """
    Process user query through Supervisor Agent and return response.
    Uses LangChain Supervisor Agent to coordinate multiple specialized agents.
    Supports both streaming and non-streaming responses.
    """
    try:
        if request.stream:
            # Return streaming response
            return StreamingResponse(
                stream_query_processing(request.query),
                media_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                    "X-Accel-Buffering": "no"
                }
            )
        else:
            # Process query through Supervisor Agent (non-streaming)
        result = await supervisor.process_query(request.query)
        
        # Format response
        response_text = result.get("response", result.get("summary", "Processing complete"))
        
        # Format agent outputs for frontend
        agent_outputs = {}
        for agent_name, agent_result in result.get("agent_outputs", {}).items():
            if isinstance(agent_result, dict):
                agent_outputs[agent_name] = agent_result.get("formatted", str(agent_result))
            else:
                agent_outputs[agent_name] = str(agent_result)
        
        # Add supervisor message
        agent_outputs["supervisor"] = result.get("supervisor", "Query processed")
        
        return QueryResponse(
            response=response_text,
            agent_outputs=agent_outputs,
            message="Query processed successfully"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    # Use 127.0.0.1 for better Windows compatibility
    # This ensures localhost connections work properly
    uvicorn.run(app, host="127.0.0.1", port=8000)

