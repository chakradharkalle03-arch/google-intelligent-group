"""
Query processing blueprint.
"""

import json
from quart import Blueprint, request, Response
from pydantic import BaseModel, ValidationError
from typing import Optional, Dict, Any
from agents.supervisor_langgraph import SupervisorAgentLangGraph

query_bp = Blueprint("query", __name__)

# Initialize supervisor (will be set by app)
supervisor: Optional[SupervisorAgentLangGraph] = None


def set_supervisor(sup: SupervisorAgentLangGraph):
    """Set the supervisor instance."""
    global supervisor
    supervisor = sup


class QueryRequest(BaseModel):
    query: str
    stream: Optional[bool] = False


async def stream_query_processing(query: str):
    """Stream query processing results from LangGraph supervisor with detailed task execution."""
    try:
        # Send initial status
        yield f"data: {json.dumps({'type': 'task', 'status': 'started', 'message': 'Initializing Supervisor Agent...', 'agent': 'supervisor'})}\n\n"
        
        # Track which agents have been processed
        processed_agents = set()
        task_list = []
        
        # Track if we've seen the summarize node
        summary_sent = False
        
        # Stream from LangGraph
        async for chunk in supervisor.stream_query(query):
            agent_outputs = chunk.get("agent_outputs", {})
            execution_order = chunk.get("execution_order", [])
            
            # Handle plan node - Show detailed planning steps
            if "plan" in chunk and chunk.get("plan"):
                plan = chunk.get("plan", {})
                yield f"data: {json.dumps({'type': 'task', 'status': 'executing', 'message': 'Analyzing user query and creating execution plan...', 'agent': 'supervisor'})}\n\n"
                
                # Show detailed planning steps
                tasks_to_execute = []
                if plan.get("use_googlemap"):
                    tasks_to_execute.append("🗺️ Search for locations using GoogleMap Agent")
                    yield f"data: {json.dumps({'type': 'task', 'status': 'planned', 'message': 'Task planned: Search for locations using GoogleMap Agent', 'agent': 'googleMap'})}\n\n"
                if plan.get("use_research"):
                    tasks_to_execute.append("🔍 Perform research using Research Agent")
                    yield f"data: {json.dumps({'type': 'task', 'status': 'planned', 'message': 'Task planned: Perform research using Research Agent', 'agent': 'research'})}\n\n"
                if plan.get("use_calendar"):
                    tasks_to_execute.append("📅 Manage calendar events using Calendar Agent")
                    yield f"data: {json.dumps({'type': 'task', 'status': 'planned', 'message': 'Task planned: Manage calendar events using Calendar Agent', 'agent': 'calendar'})}\n\n"
                if plan.get("use_telephone"):
                    tasks_to_execute.append("☎️ Make phone call using Telephone Agent")
                    yield f"data: {json.dumps({'type': 'task', 'status': 'planned', 'message': 'Task planned: Make phone call using Telephone Agent', 'agent': 'telephone'})}\n\n"
                
                yield f"data: {json.dumps({'type': 'task', 'status': 'completed', 'message': f'Execution plan created. {len(tasks_to_execute)} task(s) scheduled.', 'agent': 'supervisor'})}\n\n"
            
            # Check for new agent outputs - Show detailed execution steps
            for agent_name in ["googleMap", "research", "telephone", "calendar"]:
                if agent_name in agent_outputs and agent_name not in processed_agents:
                    output = agent_outputs[agent_name]
                    processed_agents.add(agent_name)
                    
                    # Send detailed task execution steps
                    agent_tasks = {
                        "googleMap": [
                            "Executing GoogleMap Agent...",
                            "Calling search_nearby_places tool...",
                            "Processing location data...",
                            "Formatting results..."
                        ],
                        "research": [
                            "Executing Research Agent...",
                            "Analyzing query...",
                            "Generating research response..."
                        ],
                        "calendar": [
                            "Executing Calendar Agent...",
                            "Extracting event information...",
                            "Calling add_calendar_event tool...",
                            "Creating calendar event..."
                        ],
                        "telephone": [
                            "Executing Telephone Agent...",
                            "Extracting phone number...",
                            "Calling make_phone_call tool...",
                            "Initiating call via Fonoster..."
                        ]
                    }
                    
                    # Send status message (skip for research if it was skipped)
                    if isinstance(output, dict) and output.get("skipped"):
                        # Research agent was skipped - just send the output
                        formatted = output.get("formatted", str(output))
                        yield f"data: {json.dumps({'type': 'task', 'status': 'skipped', 'message': f'{agent_name} Agent: Not needed for this query', 'agent': agent_name})}\n\n"
                        yield f"data: {json.dumps({'type': 'agent_output', 'agent': agent_name, 'output': formatted})}\n\n"
                    else:
                        # Active agent - send detailed task steps
                        tasks = agent_tasks.get(agent_name, ["Processing..."])
                        for i, task_msg in enumerate(tasks):
                            if i < len(tasks) - 1:
                                yield f"data: {json.dumps({'type': 'task', 'status': 'executing', 'message': task_msg, 'agent': agent_name})}\n\n"
                            else:
                                yield f"data: {json.dumps({'type': 'task', 'status': 'completed', 'message': task_msg, 'agent': agent_name})}\n\n"
                        
                        # Send agent output
                        if isinstance(output, dict):
                            formatted = output.get("formatted", str(output))
                        else:
                            formatted = str(output)
                        yield f"data: {json.dumps({'type': 'agent_output', 'agent': agent_name, 'output': formatted})}\n\n"
            
            # Check for summary - improved detection (check multiple fields and ensure it's a string)
            summary_text = None
            if "summary" in chunk:
                summary_text = chunk.get("summary")
                if summary_text and not isinstance(summary_text, str):
                    summary_text = str(summary_text)
                # Debug logging
                if summary_text:
                    print(f"\n[STREAM] Found summary in chunk: {summary_text[:100]}...")
            elif "response" in chunk:
                summary_text = chunk.get("response")
                if summary_text and not isinstance(summary_text, str):
                    summary_text = str(summary_text)
                # Debug logging
                if summary_text:
                    print(f"\n[STREAM] Found response in chunk: {summary_text[:100]}...")
            
            # Debug: log chunk keys
            if not summary_sent:
                chunk_keys = list(chunk.keys())
                print(f"[STREAM] Chunk keys: {chunk_keys}")
                if "summary" in chunk or "response" in chunk:
                    print(f"[STREAM] Summary value: {chunk.get('summary', chunk.get('response', 'None'))[:100]}")
            
            # Check if summary exists and is not empty
            if summary_text and summary_text.strip() and not summary_sent:
                summary_sent = True
                summary_text = summary_text.strip()
                
                yield f"data: {json.dumps({'type': 'task', 'status': 'executing', 'message': 'Generating final summary from all agent results...', 'agent': 'supervisor'})}\n\n"
                
                # Format agent outputs for final response
                final_agent_outputs = {}
                for agent_name, agent_result in agent_outputs.items():
                    if isinstance(agent_result, dict):
                        final_agent_outputs[agent_name] = agent_result.get("formatted", str(agent_result))
                    else:
                        final_agent_outputs[agent_name] = str(agent_result)
                
                # Ensure supervisor is set with the summary
                final_agent_outputs["supervisor"] = summary_text
                
                final_response = {
                    "type": "complete",
                    "response": summary_text,
                    "agent_outputs": final_agent_outputs,
                    "message": "Query processed successfully"
                }
                yield f"data: {json.dumps(final_response)}\n\n"
                break  # Exit loop after summary
        
        # If no summary was found but we have agent outputs, generate a comprehensive fallback
        if not summary_sent and processed_agents:
            yield f"data: {json.dumps({'type': 'task', 'status': 'executing', 'message': 'Generating final summary from all agent results...', 'agent': 'supervisor'})}\n\n"
            
            # Helper function to extract clean text
            def extract_clean_text(value):
                """Extract clean text from various data structures."""
                if isinstance(value, str):
                    return value
                if isinstance(value, dict):
                    if "text" in value:
                        return value["text"]
                    if "content" in value:
                        return extract_clean_text(value["content"])
                    if "formatted" in value:
                        return extract_clean_text(value["formatted"])
                    if "result" in value:
                        return extract_clean_text(value["result"])
                    if "messages" in value and isinstance(value["messages"], list):
                        if value["messages"]:
                            return extract_clean_text(value["messages"][-1])
                    return str(value)
                if isinstance(value, list):
                    texts = []
                    for item in value:
                        if isinstance(item, dict):
                            if "text" in item:
                                texts.append(item["text"])
                            elif "content" in item:
                                texts.append(extract_clean_text(item["content"]))
                            else:
                                texts.append(str(item))
                        else:
                            texts.append(str(item))
                    return "\n".join(texts)
                return str(value)
            
            # Format agent outputs with clean text extraction
            final_agent_outputs = {}
            agent_summaries = []
            
            for agent_name, agent_result in agent_outputs.items():
                if isinstance(agent_result, dict):
                    formatted = agent_result.get("formatted")
                    if not formatted:
                        formatted = agent_result.get("result", agent_result)
                    clean_text = extract_clean_text(formatted)
                    final_agent_outputs[agent_name] = clean_text
                    
                    # Build summary parts with clean text
                    if agent_name == "googleMap" and clean_text:
                        summary_text = clean_text[:200] + "..." if len(clean_text) > 200 else clean_text
                        agent_summaries.append(f"🗺️ Found restaurants: {summary_text}")
                    elif agent_name == "calendar" and clean_text:
                        summary_text = clean_text[:200] + "..." if len(clean_text) > 200 else clean_text
                        agent_summaries.append(f"📅 Created calendar event: {summary_text}")
                    elif agent_name == "telephone" and clean_text:
                        summary_text = clean_text[:200] + "..." if len(clean_text) > 200 else clean_text
                        agent_summaries.append(f"☎️ Initiated phone call: {summary_text}")
                    elif agent_name == "research" and clean_text and not agent_result.get("skipped"):
                        summary_text = clean_text[:200] + "..." if len(clean_text) > 200 else clean_text
                        agent_summaries.append(f"🔍 Research completed: {summary_text}")
                else:
                    clean_text = extract_clean_text(agent_result)
                    final_agent_outputs[agent_name] = clean_text
            
            # Create a comprehensive summary
            if agent_summaries:
                summary_text = f"I've successfully processed your request. Here's what was accomplished:\n\n" + "\n\n".join(agent_summaries)
            else:
                summary_text = f"Query processed successfully. {len(processed_agents)} agent(s) executed: {', '.join(processed_agents)}."
            
            final_agent_outputs["supervisor"] = summary_text
            
            final_response = {
                "type": "complete",
                "response": summary_text,
                "agent_outputs": final_agent_outputs,
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


@query_bp.route("/query", methods=["POST"])
async def process_query():
    """
    Process user query through Supervisor Agent and return response.
    Uses LangChain Supervisor Agent to coordinate multiple specialized agents.
    Supports both streaming and non-streaming responses.
    """
    try:
        data = await request.get_json()
        if not data:
            return {"error": "No JSON data provided"}, 400
        
        # Validate request
        try:
            query_request = QueryRequest(**data)
        except ValidationError as e:
            return {"error": "Invalid request", "details": str(e)}, 400
        
        if query_request.stream:
            # Return streaming response
            return Response(
                stream_query_processing(query_request.query),
                mimetype="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "Connection": "keep-alive",
                    "X-Accel-Buffering": "no"
                }
            )
        else:
            # Process query through Supervisor Agent (non-streaming)
            result = await supervisor.process_query(query_request.query)
            
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
            
            return {
                "response": response_text,
                "agent_outputs": agent_outputs,
                "message": "Query processed successfully"
            }
    except Exception as e:
        return {"error": f"Error processing query: {str(e)}"}, 500

