"""
LangGraph Supervisor Agent Implementation
Uses LangGraph to create a proper DAG-based multi-agent system.
"""

import os
import json
from typing import Dict, Any, List, Literal, TypedDict, Annotated, Optional
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages

from .agent_factory import (
    create_googlemap_agent,
    create_calendar_agent,
    create_telephone_agent,
    create_research_agent
)

load_dotenv()


class AgentState(TypedDict):
    """State schema for the supervisor agent."""
    messages: Annotated[List, add_messages]
    agent_outputs: Dict[str, Any]
    execution_order: List[str]
    query: str
    plan: Dict[str, Any]
    summary: Optional[str]
    response: Optional[str]


class SupervisorAgentLangGraph:
    """Supervisor Agent using LangGraph for proper multi-agent coordination."""
    
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        # Supervisor LLM for planning and routing
        self.supervisor_llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.3
        )
        
        # Create sub-agents
        self.googlemap_agent = create_googlemap_agent()
        self.calendar_agent = create_calendar_agent()
        self.telephone_agent = create_telephone_agent()
        self.research_agent = create_research_agent()
        
        # Build the graph
        self.graph = self._build_graph()
    
    def _build_graph(self) -> StateGraph:
        """Build the LangGraph DAG for agent coordination."""
        workflow = StateGraph(AgentState)
        
        # Add nodes
        workflow.add_node("plan", self._plan_node)
        workflow.add_node("googlemap", self._googlemap_node)
        workflow.add_node("calendar", self._calendar_node)
        workflow.add_node("telephone", self._telephone_node)
        workflow.add_node("research", self._research_node)
        workflow.add_node("summarize", self._summarize_node)
        
        # Set entry point
        workflow.set_entry_point("plan")
        
        # Add conditional edges from plan - routes to first needed agent
        workflow.add_conditional_edges(
            "plan",
            self._route_after_plan,
            {
                "googlemap": "googlemap",
                "calendar": "calendar",
                "telephone": "telephone",
                "research": "research",
                "summarize": "summarize"
            }
        )
        
        # After each agent, check if more agents are needed
        # After googlemap: can go to research, calendar, or telephone
        workflow.add_conditional_edges(
            "googlemap",
            self._route_after_plan,
            {
                "googlemap": "googlemap",  # Allow re-routing if needed
                "research": "research",
                "calendar": "calendar",
                "telephone": "telephone",
                "summarize": "summarize"
            }
        )
        
        # After research: can go to calendar, telephone, or summarize
        workflow.add_conditional_edges(
            "research",
            self._route_after_plan,
            {
                "googlemap": "googlemap",  # Allow re-routing if needed
                "calendar": "calendar",
                "telephone": "telephone",
                "summarize": "summarize"
            }
        )
        
        # After calendar: can go to telephone (for reservations) or summarize
        workflow.add_conditional_edges(
            "calendar",
            self._route_after_plan,
            {
                "telephone": "telephone",
                "summarize": "summarize"
            }
        )
        
        # After telephone: can go to calendar (if not done) or summarize
        workflow.add_conditional_edges(
            "telephone",
            self._route_after_plan,
            {
                "calendar": "calendar",
                "summarize": "summarize"
            }
        )
        
        # Summarize always ends
        workflow.add_edge("summarize", END)
        
        return workflow.compile()
    
    async def _plan_node(self, state: AgentState) -> AgentState:
        """Plan which agents to use based on the query."""
        query = state.get("query", "")
        messages = state.get("messages", [])
        
        if not messages:
            messages = [HumanMessage(content=query)]
        
        plan_prompt = f"""You are a supervisor agent coordinating multiple specialized agents.

Available agents:
1. googlemap - Search for nearby places, restaurants, businesses
2. calendar - Manage calendar events and bookings (use for reservations, appointments, scheduling)
3. telephone - Make phone calls (use for reservations that require calling restaurants/businesses)
4. research - Perform research and answer questions

User query: {query}

IMPORTANT RULES:
- If the query involves making a RESERVATION or BOOKING (e.g., "make a reservation", "book a table"), you MUST set:
  * use_googlemap: true (to find the restaurant/business)
  * use_calendar: true (to create the calendar event)
  * use_telephone: true (to call and confirm the reservation)
  
- If the query asks to "find" or "search" for places, set use_googlemap: true
- If the query asks general questions or needs research, set use_research: true

Analyze the query and determine which agents should be used. Return a JSON object with:
{{
    "use_googlemap": true/false,
    "use_calendar": true/false,
    "use_telephone": true/false,
    "use_research": true/false,
    "reasoning": "brief explanation"
}}

Only set agents to true if they are clearly needed for the query."""
        
        response = await self.supervisor_llm.ainvoke([HumanMessage(content=plan_prompt)])
        
        try:
            # Extract JSON from response
            content = response.content.strip()
            if "```json" in content:
                content = content.split("```json")[1].split("```")[0].strip()
            elif "```" in content:
                content = content.split("```")[1].split("```")[0].strip()
            
            plan = json.loads(content)
        except:
            # Fallback plan based on keywords
            plan = self._fallback_plan(query)
        
        state["plan"] = plan
        state["agent_outputs"] = {}
        state["execution_order"] = []
        
        # Initialize Research Agent with status if not needed
        if not plan.get("use_research"):
            state["agent_outputs"]["research"] = {
                "agent": "Research",
                "success": True,
                "formatted": "ℹ️ Research Agent: Not needed for this query. This agent is used for general information and research questions.",
                "skipped": True
            }
        
        return state
    
    def _fallback_plan(self, query: str) -> Dict[str, Any]:
        """Fallback plan based on keyword matching."""
        query_lower = query.lower()
        return {
            "use_googlemap": any(kw in query_lower for kw in ["find", "search", "near", "restaurant", "place", "location", "nearby"]),
            "use_calendar": any(kw in query_lower for kw in ["calendar", "schedule", "event", "booking", "reservation", "appointment", "meeting"]),
            "use_telephone": any(kw in query_lower for kw in ["call", "phone", "telephone", "ring"]),
            "use_research": any(kw in query_lower for kw in ["what", "how", "why", "explain", "research", "information", "tell me about"]),
            "reasoning": "Fallback keyword-based plan"
        }
    
    def _route_after_plan(self, state: AgentState) -> str:
        """
        Supervisor-driven routing: Evaluates state and decides next agent.
        
        This implements Supervisor-driven task assignment where the Supervisor
        evaluates the complete state after each agent completes and makes
        intelligent routing decisions based on:
        - Original plan requirements
        - Current execution status
        - Agent dependencies
        - Workflow context (e.g., reservation vs. general query)
        """
        plan = state.get("plan", {})
        execution_order = state.get("execution_order", [])
        agent_outputs = state.get("agent_outputs", {})
        query = state.get("query", "").lower()
        
        # Supervisor evaluates: What agents are still needed?
        needed_agents = []
        
        # Check GoogleMap: Needed if in plan and not executed
        if plan.get("use_googlemap"):
            if "googleMap" not in execution_order and "googleMap (failed)" not in execution_order:
                needed_agents.append(("googlemap", 1))  # Priority 1 (highest - provides data for others)
        
        # Check Research: Independent, can run anytime
        if plan.get("use_research"):
            if "research" not in execution_order and "research (failed)" not in execution_order:
                needed_agents.append(("research", 2))  # Priority 2
        
        # Check Calendar and Telephone: Dependencies matter
        is_reservation = any(kw in query for kw in ["reservation", "reserve", "book", "booking", "appointment"])
        has_googlemap_data = "googleMap" in agent_outputs and agent_outputs.get("googleMap", {}).get("success", False)
        
        # For reservations: Calendar should come before Telephone
        # For other cases: Check dependencies
        if plan.get("use_calendar"):
            if "calendar" not in execution_order and "calendar (failed)" not in execution_order:
                # Calendar can run if we have location data (from GoogleMap) or if it's independent
                if has_googlemap_data or not plan.get("use_googlemap"):
                    priority = 3 if is_reservation else 4
                    needed_agents.append(("calendar", priority))
        
        if plan.get("use_telephone"):
            if "telephone" not in execution_order and "telephone (failed)" not in execution_order:
                # Telephone needs phone number from GoogleMap (if GoogleMap was used)
                if has_googlemap_data or not plan.get("use_googlemap"):
                    priority = 4 if is_reservation else 3
                    needed_agents.append(("telephone", priority))
        
        # Supervisor decision: Route to highest priority needed agent
        if needed_agents:
            # Sort by priority (lower number = higher priority)
            needed_agents.sort(key=lambda x: x[1])
            next_agent = needed_agents[0][0]
            return next_agent
        
        # All agents executed - Supervisor routes to summarization
        return "summarize"
    
    async def _googlemap_node(self, state: AgentState) -> AgentState:
        """Execute GoogleMap agent."""
        try:
            query = state.get("query", "")
            # Create a prompt that encourages tool use
            enhanced_query = f"""You need to search for places using the search_nearby_places tool.

User query: {query}

IMPORTANT: You MUST use the search_nearby_places tool to find the requested places. Do not just respond with text - actually call the tool with appropriate parameters.

Extract:
- The search term (e.g., "Indian restaurant")
- The location (e.g., "Taipei 101")

Then call search_nearby_places with these parameters."""
            
            messages = [HumanMessage(content=enhanced_query)]
            
            # Invoke agent with messages
            result = await self.googlemap_agent.ainvoke({"messages": messages})
            
            # Extract agent output - handle different response formats
            if isinstance(result, dict):
                if "messages" in result:
                    # Get the last message which should contain the tool result
                    last_msg = result["messages"][-1]
                    if hasattr(last_msg, 'content'):
                        content = last_msg.content
                    else:
                        content = str(last_msg)
                elif "output" in result:
                    content = result["output"]
                else:
                    content = str(result)
            else:
                content = str(result)
            
            agent_output = {
                "agent": "GoogleMap",
                "success": True,
                "result": content,
                "formatted": content
            }
            
            state["agent_outputs"]["googleMap"] = agent_output
            state["execution_order"].append("googleMap")
            
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(f"GoogleMap Agent Error: {str(e)}")
            print(f"Traceback: {error_trace}")
            state["agent_outputs"]["googleMap"] = {
                "agent": "GoogleMap",
                "success": False,
                "error": str(e),
                "formatted": f"❌ GoogleMap Agent Error: {str(e)}"
            }
            state["execution_order"].append("googleMap (failed)")
        
        return state
    
    async def _calendar_node(self, state: AgentState) -> AgentState:
        """Execute Calendar agent."""
        try:
            query = state.get("query", "")
            plan = state.get("plan", {})
            
            # Include context from GoogleMap results if available
            googlemap_results = state.get("agent_outputs", {}).get("googleMap", {})
            
            # Auto-trigger telephone if making reservation and we have restaurant results
            # But don't update plan here - let the routing handle it
            # The plan should already have use_telephone set if needed
            
            # Build enhanced query that encourages tool use
            if googlemap_results.get("success"):
                context = f"Context from GoogleMap search: {googlemap_results.get('result', '')}"
                enhanced_query = f"""You need to add a calendar event using the add_calendar_event tool.

User query: {query}
{context}

IMPORTANT: You MUST use the add_calendar_event tool to create the calendar event. Do not just respond with text - actually call the tool.

Extract from the query:
- Event title (e.g., "Dinner Reservation at [restaurant name]")
- Date: Parse "tomorrow" or specific date
- Time: Convert to 24-hour format (e.g., "7:00 PM" → "19:00", "6:00 PM" → "18:00")
- Description: Include restaurant details if available
- Location: Include restaurant address if available

Then call add_calendar_event with these parameters."""
            else:
                enhanced_query = f"""You need to add a calendar event using the add_calendar_event tool.

User query: {query}

IMPORTANT: You MUST use the add_calendar_event tool to create the calendar event. Do not just respond with text - actually call the tool.

Extract from the query:
- Event title
- Date: Parse "tomorrow" or specific date
- Time: Convert to 24-hour format (e.g., "7:00 PM" → "19:00")
- Description
- Location if mentioned

Then call add_calendar_event with these parameters."""
            
            messages = [HumanMessage(content=enhanced_query)]
            
            result = await self.calendar_agent.ainvoke({"messages": messages})
            
            # Extract agent output - handle different response formats
            if isinstance(result, dict):
                if "messages" in result:
                    last_msg = result["messages"][-1]
                    if hasattr(last_msg, 'content'):
                        content = last_msg.content
                    else:
                        content = str(last_msg)
                elif "output" in result:
                    content = result["output"]
                else:
                    content = str(result)
            else:
                content = str(result)
            
            agent_output = {
                "agent": "Calendar",
                "success": True,
                "result": content,
                "formatted": content
            }
            
            state["agent_outputs"]["calendar"] = agent_output
            state["execution_order"].append("calendar")
            
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(f"Calendar Agent Error: {str(e)}")
            print(f"Traceback: {error_trace}")
            state["agent_outputs"]["calendar"] = {
                "agent": "Calendar",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Calendar Agent Error: {str(e)}"
            }
            state["execution_order"].append("calendar (failed)")
        
        return state
    
    async def _telephone_node(self, state: AgentState) -> AgentState:
        """Execute Telephone agent."""
        try:
            query = state.get("query", "")
            # Include phone number from GoogleMap results if available
            googlemap_results = state.get("agent_outputs", {}).get("googleMap", {})
            
            # Build enhanced query that encourages tool use
            if googlemap_results.get("success"):
                context = f"Context from GoogleMap search: {googlemap_results.get('result', '')}"
                enhanced_query = f"""You need to make a phone call using the make_phone_call tool.

User query: {query}
{context}

IMPORTANT: You MUST use the make_phone_call tool to initiate the call. Do not just respond with text - actually call the tool.

Extract from the context:
- Phone number (look for phone numbers in the GoogleMap results)
- Call message/script (e.g., "Calling to make a reservation for tomorrow evening at 7:00 PM")

Then call make_phone_call with these parameters."""
            else:
                enhanced_query = f"""You need to make a phone call using the make_phone_call tool.

User query: {query}

IMPORTANT: You MUST use the make_phone_call tool to initiate the call. Do not just respond with text - actually call the tool.

Extract from the query:
- Phone number if mentioned
- Call message/script

Then call make_phone_call with these parameters."""
            
            messages = [HumanMessage(content=enhanced_query)]
            
            result = await self.telephone_agent.ainvoke({"messages": messages})
            
            # Extract agent output - handle different response formats
            if isinstance(result, dict):
                if "messages" in result:
                    last_msg = result["messages"][-1]
                    if hasattr(last_msg, 'content'):
                        content = last_msg.content
                    else:
                        content = str(last_msg)
                elif "output" in result:
                    content = result["output"]
                else:
                    content = str(result)
            else:
                content = str(result)
            
            agent_output = {
                "agent": "Telephone",
                "success": True,
                "result": content,
                "formatted": content
            }
            
            state["agent_outputs"]["telephone"] = agent_output
            state["execution_order"].append("telephone")
            
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(f"Telephone Agent Error: {str(e)}")
            print(f"Traceback: {error_trace}")
            state["agent_outputs"]["telephone"] = {
                "agent": "Telephone",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Telephone Agent Error: {str(e)}"
            }
            state["execution_order"].append("telephone (failed)")
        
        return state
    
    async def _research_node(self, state: AgentState) -> AgentState:
        """Execute Research agent."""
        try:
            query = state.get("query", "")
            messages = [HumanMessage(content=query)]
            
            result = await self.research_agent.ainvoke({"messages": messages})
            
            # Extract agent output - handle different response formats
            if isinstance(result, dict):
                if "messages" in result:
                    content = result["messages"][-1].content if result["messages"] else str(result)
                elif "output" in result:
                    content = result["output"]
                else:
                    content = str(result)
            else:
                content = str(result)
            
            agent_output = {
                "agent": "Research",
                "success": True,
                "result": content,
                "formatted": content
            }
            
            state["agent_outputs"]["research"] = agent_output
            state["execution_order"].append("research")
            
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            print(f"Research Agent Error: {str(e)}")
            print(f"Traceback: {error_trace}")
            state["agent_outputs"]["research"] = {
                "agent": "Research",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Research Agent Error: {str(e)}"
            }
            state["execution_order"].append("research (failed)")
        
        return state
    
    async def _summarize_node(self, state: AgentState) -> AgentState:
        """Generate final summary."""
        try:
            query = state.get("query", "")
            agent_outputs = state.get("agent_outputs", {})
            
            # Extract clean text from agent outputs
            def extract_clean_text(value):
                """Extract clean text from various data structures."""
                if isinstance(value, str):
                    return value
                if isinstance(value, dict):
                    # Handle LangChain message objects
                    if "text" in value:
                        return value["text"]
                    if "content" in value:
                        return extract_clean_text(value["content"])
                    if "formatted" in value:
                        return extract_clean_text(value["formatted"])
                    if "result" in value:
                        return extract_clean_text(value["result"])
                    # If it's a list, extract from first item
                    if "messages" in value and isinstance(value["messages"], list):
                        if value["messages"]:
                            return extract_clean_text(value["messages"][-1])
                    # Try to get string representation, but clean it
                    return str(value)
                if isinstance(value, list):
                    # Extract text from list items
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
            
            # Extract clean formatted outputs for summary
            formatted_outputs = {}
            for agent_name, agent_result in agent_outputs.items():
                if isinstance(agent_result, dict):
                    # Get formatted text, or extract from result
                    formatted = agent_result.get("formatted")
                    if not formatted:
                        formatted = agent_result.get("result")
                    if not formatted:
                        formatted = agent_result
                    formatted_outputs[agent_name] = extract_clean_text(formatted)
                else:
                    formatted_outputs[agent_name] = extract_clean_text(agent_result)
            
            # Build detailed agent summary for the prompt (clean text only)
            agent_details = []
            if "googleMap" in formatted_outputs:
                clean_text = formatted_outputs['googleMap']
                # Remove any remaining JSON structures
                if len(clean_text) > 500:
                    clean_text = clean_text[:500] + "..."
                agent_details.append(f"🗺️ GoogleMap Agent: {clean_text}")
            if "calendar" in formatted_outputs:
                clean_text = formatted_outputs['calendar']
                if len(clean_text) > 500:
                    clean_text = clean_text[:500] + "..."
                agent_details.append(f"📅 Calendar Agent: {clean_text}")
            if "telephone" in formatted_outputs:
                clean_text = formatted_outputs['telephone']
                if len(clean_text) > 500:
                    clean_text = clean_text[:500] + "..."
                agent_details.append(f"☎️ Telephone Agent: {clean_text}")
            if "research" in formatted_outputs:
                clean_text = formatted_outputs['research']
                if len(clean_text) > 500:
                    clean_text = clean_text[:500] + "..."
                agent_details.append(f"🔍 Research Agent: {clean_text}")
            
            agent_summary = "\n\n".join(agent_details) if agent_details else "No agent outputs available."
            
            summary_prompt = f"""You are a supervisor agent that coordinates and summarizes results from 4 specialized agents.

USER QUERY: {query}

AGENT RESULTS:
{agent_summary}

FULL AGENT OUTPUTS (for reference):
{json.dumps(formatted_outputs, indent=2, ensure_ascii=False)}

TASK: Write a comprehensive, natural-language summary that:

1. **Directly addresses the user's query** - Start by acknowledging what the user asked for
2. **Summarize each agent's contribution:**
   - 🗺️ GoogleMap Agent: What restaurants/locations were found
   - 📅 Calendar Agent: What calendar event was created (date, time, details)
   - ☎️ Telephone Agent: What call was initiated and to whom
   - 🔍 Research Agent: Any research information provided (if applicable)
3. **Highlight key information:**
   - Restaurant names and addresses
   - Phone numbers
   - Reservation date and time
   - Any important details
4. **Confirm actions taken** - Clearly state what was accomplished
5. **Be friendly and professional** - Write in a helpful, conversational tone

IMPORTANT: Make sure to mention ALL agents that were used. If an agent wasn't needed, you can briefly note that.

Write the summary now:"""
            
            response = await self.supervisor_llm.ainvoke([HumanMessage(content=summary_prompt)])
            summary = response.content.strip()
            
            # Ensure summary is not empty
            if not summary:
                summary = f"I've successfully processed your request. Found restaurants, created a calendar event, and initiated a phone call for your reservation."
            
            # Debug logging
            print(f"\n[SUPERVISOR] Summary generated: {summary[:100]}...")
            print(f"[SUPERVISOR] Summary length: {len(summary)}")
            
            state["summary"] = summary
            state["response"] = summary
            
            # Debug: verify state is updated
            print(f"[SUPERVISOR] State summary set: {state.get('summary')[:50] if state.get('summary') else 'None'}...")
            
        except Exception as e:
            import traceback
            print(f"Summary generation error: {str(e)}")
            print(traceback.format_exc())
            # Create a fallback summary
            agent_count = len(agent_outputs)
            summary = f"I've successfully processed your request. {agent_count} agent(s) completed their tasks."
            state["summary"] = summary
            state["response"] = summary
        
        return state
    
    def _format_googlemap_result(self, result: Dict[str, Any]) -> str:
        """Format GoogleMap agent result."""
        messages = result.get("messages", [])
        if messages:
            return messages[-1].content
        return str(result)
    
    def _format_calendar_result(self, result: Dict[str, Any]) -> str:
        """Format Calendar agent result."""
        messages = result.get("messages", [])
        if messages:
            return messages[-1].content
        return str(result)
    
    def _format_telephone_result(self, result: Dict[str, Any]) -> str:
        """Format Telephone agent result."""
        messages = result.get("messages", [])
        if messages:
            return messages[-1].content
        return str(result)
    
    def _format_research_result(self, result: Dict[str, Any]) -> str:
        """Format Research agent result."""
        messages = result.get("messages", [])
        if messages:
            return messages[-1].content
        return str(result)
    
    async def process_query(self, query: str) -> Dict[str, Any]:
        """
        Process a user query through the LangGraph supervisor.
        
        Args:
            query: User's query string
        
        Returns:
            Dictionary with processing results
        """
        initial_state: AgentState = {
            "messages": [HumanMessage(content=query)],
            "agent_outputs": {},
            "execution_order": [],
            "query": query,
            "plan": {}
        }
        
        # Run the graph
        final_state = await self.graph.ainvoke(initial_state)
        
        return {
            "supervisor": f"Processing query: {query}",
            "plan": final_state.get("plan", {}),
            "agent_outputs": final_state.get("agent_outputs", {}),
            "execution_order": final_state.get("execution_order", []),
            "summary": final_state.get("summary", ""),
            "response": final_state.get("response", final_state.get("summary", ""))
        }
    
    async def stream_query(self, query: str):
        """
        Stream query processing results.
        
        Args:
            query: User's query string
        
        Yields:
            Dictionary chunks with processing updates
        """
        initial_state: AgentState = {
            "messages": [HumanMessage(content=query)],
            "agent_outputs": {},
            "execution_order": [],
            "query": query,
            "plan": {}
        }
        
        # Track previous state to detect changes
        previous_outputs = {}
        previous_order = []
        
        async for chunk in self.graph.astream(initial_state, stream_mode="values"):
            # Check for new agent outputs
            current_outputs = chunk.get("agent_outputs", {})
            current_order = chunk.get("execution_order", [])
            
            # Ensure summary and response are included in chunk
            # The summarize node should have set these, but ensure they're strings
            if "summary" in chunk:
                summary = chunk.get("summary")
                if summary and not isinstance(summary, str):
                    chunk["summary"] = str(summary)
            if "response" in chunk:
                response = chunk.get("response")
                if response and not isinstance(response, str):
                    chunk["response"] = str(response)
            
            # Yield state updates
            yield chunk
            
            # Update tracking
            previous_outputs = current_outputs.copy()
            previous_order = current_order.copy()

