# Agent Code Explanation
## Google Intelligent Group Multi-Agent System

This document provides a comprehensive explanation of the agent architecture and code implementation for the Google Intelligent Group Multi-Agent System.

---

## Table of Contents
1. [System Architecture Overview](#system-architecture-overview)
2. [Supervisor Agent (LangGraph)](#supervisor-agent-langgraph)
3. [Sub-Agents Implementation](#sub-agents-implementation)
4. [Tool Definitions](#tool-definitions)
5. [Agent Factory](#agent-factory)
6. [Workflow Execution](#workflow-execution)
7. [State Management](#state-management)
8. [Code Examples](#code-examples)

---

## System Architecture Overview

### High-Level Design

The system uses a **Supervisor-driven Multi-Agent Architecture** where:

1. **Supervisor Agent** coordinates and orchestrates all sub-agents
2. **Sub-Agents** are specialized agents that perform specific tasks:
   - **GoogleMap Agent**: Location and place searches
   - **Calendar Agent**: Calendar event management
   - **Telephone Agent**: Phone call operations
   - **Research Agent**: General information and research

3. **LangGraph** manages the workflow as a Directed Acyclic Graph (DAG)
4. **LangChain Tools** provide the actual functionality for each agent

### Architecture Diagram

```
User Query
    ↓
Supervisor Agent (LangGraph)
    ↓
Planning Node → Determines which agents to use
    ↓
Routing Logic → Supervisor-driven task assignment
    ↓
Agent Execution Nodes:
    ├── GoogleMap Node → Uses search_nearby_places tool
    ├── Calendar Node → Uses add_calendar_event tool
    ├── Telephone Node → Uses make_phone_call tool
    └── Research Node → Uses research_query tool
    ↓
Summarize Node → Generates final summary
    ↓
Response to User
```

---

## Supervisor Agent (LangGraph)

### File: `backend/agents/supervisor_langgraph.py`

### Purpose
The Supervisor Agent is the central orchestrator that:
- Analyzes user queries
- Plans which agents to use
- Routes tasks to appropriate agents
- Coordinates agent execution
- Generates comprehensive summaries

### Key Components

#### 1. AgentState (TypedDict)

```python
class AgentState(TypedDict):
    """State schema for the supervisor agent."""
    messages: Annotated[List, add_messages]
    agent_outputs: Dict[str, Any]
    execution_order: List[str]
    query: str
    plan: Dict[str, Any]
    summary: Optional[str]
    response: Optional[str]
```

**Explanation:**
- `messages`: Conversation history for the LLM
- `agent_outputs`: Results from each sub-agent
- `execution_order`: Track which agents have executed
- `query`: Original user query
- `plan`: Execution plan (which agents to use)
- `summary`: Final summary text
- `response`: Final response (same as summary)

#### 2. Planning Node (`_plan_node`)

**Purpose:** Analyzes the user query and determines which agents are needed.

**How it works:**
1. Receives the user query
2. Uses Gemini LLM to analyze the query
3. Determines which agents should be used (googlemap, calendar, telephone, research)
4. Creates an execution plan
5. Initializes agent outputs

**Code Flow:**
```python
async def _plan_node(self, state: AgentState) -> AgentState:
    query = state.get("query", "")
    
    # Create planning prompt
    plan_prompt = f"""You are a supervisor agent...
    Analyze the query and determine which agents should be used."""
    
    # Get LLM response
    response = await self.supervisor_llm.ainvoke([HumanMessage(content=plan_prompt)])
    
    # Parse JSON plan
    plan = json.loads(content)
    
    # Store plan in state
    state["plan"] = plan
    return state
```

**Example Plan Output:**
```json
{
    "use_googlemap": true,
    "use_calendar": true,
    "use_telephone": true,
    "use_research": false,
    "reasoning": "Query involves finding restaurant and making reservation"
}
```

#### 3. Routing Logic (`_route_after_plan`)

**Purpose:** Supervisor-driven routing that evaluates state and decides the next agent to execute.

**How it works:**
1. Evaluates current state (plan, execution_order, agent_outputs)
2. Determines which agents are still needed
3. Checks dependencies (e.g., GoogleMap must run before Telephone)
4. Prioritizes agents based on workflow context
5. Returns the next agent to execute

**Code Flow:**
```python
def _route_after_plan(self, state: AgentState) -> str:
    plan = state.get("plan", {})
    execution_order = state.get("execution_order", [])
    agent_outputs = state.get("agent_outputs", {})
    
    # Supervisor evaluates: What agents are still needed?
    needed_agents = []
    
    # Check each agent with priority
    if plan.get("use_googlemap") and "googleMap" not in execution_order:
        needed_agents.append(("googlemap", 1))  # Priority 1
    
    # Sort by priority and return highest priority
    if needed_agents:
        needed_agents.sort(key=lambda x: x[1])
        return needed_agents[0][0]
    
    # All done, go to summarize
    return "summarize"
```

**Key Features:**
- **Dependency-aware**: Ensures GoogleMap runs before Telephone (needs phone number)
- **Workflow-aware**: For reservations, Calendar runs before Telephone
- **State-aware**: Checks what's already been executed
- **Priority-based**: Uses priority system for intelligent routing

#### 4. Agent Execution Nodes

Each agent has its own execution node that:
1. Receives state from LangGraph
2. Extracts relevant information (query, previous agent outputs)
3. Invokes the LangChain agent with tools
4. Processes and formats the result
5. Updates state with the output

**Example: GoogleMap Node**
```python
async def _googlemap_node(self, state: AgentState) -> AgentState:
    query = state.get("query", "")
    
    # Create enhanced query that encourages tool use
    enhanced_query = f"""You need to search for places using the search_nearby_places tool.
    User query: {query}
    IMPORTANT: You MUST use the search_nearby_places tool..."""
    
    # Invoke agent
    result = await self.googlemap_agent.ainvoke({"messages": [HumanMessage(content=enhanced_query)]})
    
    # Extract and format output
    agent_output = {
        "agent": "GoogleMap",
        "success": True,
        "result": content,
        "formatted": content
    }
    
    # Update state
    state["agent_outputs"]["googleMap"] = agent_output
    state["execution_order"].append("googleMap")
    
    return state
```

#### 5. Summarize Node (`_summarize_node`)

**Purpose:** Generates a comprehensive summary from all agent outputs.

**How it works:**
1. Extracts clean text from all agent outputs
2. Builds a detailed prompt with agent summaries
3. Uses Gemini LLM to generate a natural-language summary
4. Stores summary in state

**Code Flow:**
```python
async def _summarize_node(self, state: AgentState) -> AgentState:
    query = state.get("query", "")
    agent_outputs = state.get("agent_outputs", {})
    
    # Extract clean text from outputs
    formatted_outputs = {}
    for agent_name, agent_result in agent_outputs.items():
        formatted_outputs[agent_name] = extract_clean_text(agent_result)
    
    # Build comprehensive prompt
    summary_prompt = f"""You are a supervisor agent...
    USER QUERY: {query}
    AGENT RESULTS: {agent_summary}
    Write a comprehensive, natural-language summary..."""
    
    # Generate summary
    response = await self.supervisor_llm.ainvoke([HumanMessage(content=summary_prompt)])
    summary = response.content.strip()
    
    # Store in state
    state["summary"] = summary
    state["response"] = summary
    
    return state
```

#### 6. Graph Construction (`_build_graph`)

**Purpose:** Builds the LangGraph workflow with nodes and edges.

**Structure:**
```
START → plan → [routing] → googlemap → [routing] → calendar → [routing] → telephone → [routing] → research → [routing] → summarize → END
```

**Code:**
```python
def _build_graph(self):
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
    
    # Add conditional edges (routing)
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
    
    # Add edges from agents back to routing
    workflow.add_conditional_edges("googlemap", self._route_after_plan, {...})
    workflow.add_conditional_edges("calendar", self._route_after_plan, {...})
    # ... etc
    
    # Summarize always ends
    workflow.add_edge("summarize", END)
    
    return workflow.compile()
```

---

## Sub-Agents Implementation

### Agent Factory Pattern

**File:** `backend/agents/agent_factory.py`

**Purpose:** Centralizes the creation of LangChain agents with their respective tools.

**How it works:**
1. Each agent is created using `create_agent` from LangChain
2. Agents are configured with:
   - System prompt (defines agent's role and behavior)
   - Tools (functionality the agent can use)
   - LLM (Gemini 2.5 Flash)

**Example: GoogleMap Agent Creation**
```python
def create_googlemap_agent(llm: ChatGoogleGenerativeAI) -> Runnable:
    system_prompt = """You are a GoogleMap Agent specialized in finding locations, restaurants, and places.
    You have access to the search_nearby_places tool to search for places.
    Always use the tool when the user asks about locations, restaurants, or places."""
    
    tools = GOOGLEMAP_TOOLS  # [search_nearby_places]
    
    agent = create_agent(
        llm=llm,
        tools=tools,
        system_prompt=system_prompt
    )
    
    return agent
```

**Why this pattern?**
- **Separation of concerns**: Agent creation logic is isolated
- **Reusability**: Easy to create multiple instances
- **Maintainability**: Changes to agent configuration are centralized
- **Testability**: Easy to test agent creation independently

---

## Tool Definitions

### File: `backend/agents/tools.py`

### Purpose
Tools are the actual functions that agents can call. They're decorated with `@tool` to make them available to LangChain agents.

### Tool Structure

Each tool follows this pattern:
```python
@tool
def tool_name(param1: str, param2: int) -> str:
    """
    Tool description for the LLM.
    
    Args:
        param1: Description of param1
        param2: Description of param2
    
    Returns:
        JSON string with results
    """
    try:
        # Tool implementation
        result = perform_action(param1, param2)
        return json.dumps(result, ensure_ascii=False)
    except Exception as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False)
```

### Available Tools

#### 1. `search_nearby_places`
**Purpose:** Search for places using Google Maps API

**Parameters:**
- `query`: Search term (e.g., "Indian restaurant")
- `location`: Location to search near (e.g., "Taipei 101")

**Returns:** JSON string with restaurant details (name, address, phone, rating)

**Implementation:**
```python
@tool
def search_nearby_places(query: str, location: str) -> str:
    """Search for nearby places using Google Maps API."""
    try:
        # Call GoogleMapAgent's search method
        agent = GoogleMapAgent()
        result = await agent.search_nearby(query, location)
        return json.dumps(result, ensure_ascii=False)
    except Exception as e:
        return json.dumps({"error": str(e)}, ensure_ascii=False)
```

#### 2. `add_calendar_event`
**Purpose:** Add an event to the calendar

**Parameters:**
- `title`: Event title
- `date`: Event date
- `time`: Event time (24-hour format)
- `location`: Event location
- `description`: Event description

**Returns:** JSON string with calendar event details

#### 3. `make_phone_call`
**Purpose:** Make a phone call via Fonoster

**Parameters:**
- `phone_number`: Phone number to call
- `message`: Message/context for the call

**Returns:** JSON string with call status

#### 4. `research_query`
**Purpose:** Perform research using Gemini LLM

**Parameters:**
- `query`: Research question

**Returns:** JSON string with research results

---

## Workflow Execution

### How a Query is Processed

#### Step 1: User Submits Query
```python
# Frontend sends query to backend
POST /query
{
    "query": "Find Indian restaurant near Taipei 101 and make reservation for tomorrow at 7 PM",
    "stream": true
}
```

#### Step 2: Backend Receives Query
```python
# backend/blueprints/query.py
@query_bp.route("/query", methods=["POST"])
async def process_query():
    data = await request.get_json()
    query = data["query"]
    
    # Stream processing
    return Response(stream_query_processing(query), mimetype="text/event-stream")
```

#### Step 3: Supervisor Processes Query
```python
# supervisor_langgraph.py
async def process_query(self, query: str):
    # Initialize state
    state = {
        "query": query,
        "messages": [HumanMessage(content=query)],
        "agent_outputs": {},
        "execution_order": []
    }
    
    # Stream execution
    async for chunk in self.graph.astream(state):
        yield chunk
```

#### Step 4: Planning Phase
```
1. _plan_node executes
2. LLM analyzes query
3. Plan created: {use_googlemap: true, use_calendar: true, use_telephone: true}
4. State updated with plan
```

#### Step 5: Agent Execution Phase
```
1. _route_after_plan evaluates state
2. Determines: googlemap should run first (priority 1)
3. Routes to _googlemap_node
4. GoogleMap agent executes, uses search_nearby_places tool
5. Results stored in state["agent_outputs"]["googleMap"]
6. _route_after_plan evaluates again
7. Determines: calendar should run next (has GoogleMap data)
8. Routes to _calendar_node
9. Calendar agent executes, uses add_calendar_event tool
10. Process continues for telephone agent
```

#### Step 6: Summarization Phase
```
1. All agents completed
2. _route_after_plan returns "summarize"
3. _summarize_node executes
4. LLM generates comprehensive summary
5. Summary stored in state["summary"]
```

#### Step 7: Response Streaming
```python
# Backend streams results to frontend
async for chunk in supervisor.stream_query(query):
    # Send task status updates
    yield f"data: {json.dumps({'type': 'task', 'status': 'executing', ...})}\n\n"
    
    # Send agent outputs
    yield f"data: {json.dumps({'type': 'agent_output', ...})}\n\n"
    
    # Send final summary
    yield f"data: {json.dumps({'type': 'complete', 'response': summary})}\n\n"
```

---

## State Management

### State Flow Through Graph

```
Initial State:
{
    "query": "Find restaurant...",
    "messages": [HumanMessage(...)],
    "agent_outputs": {},
    "execution_order": [],
    "plan": {},
    "summary": None,
    "response": None
}

After Planning:
{
    "query": "Find restaurant...",
    "plan": {
        "use_googlemap": true,
        "use_calendar": true,
        "use_telephone": true,
        "use_research": false
    },
    "agent_outputs": {
        "research": {"skipped": true, ...}
    },
    "execution_order": []
}

After GoogleMap Execution:
{
    "agent_outputs": {
        "googleMap": {
            "agent": "GoogleMap",
            "success": true,
            "result": "Restaurant list...",
            "formatted": "Restaurant list..."
        },
        "research": {...}
    },
    "execution_order": ["googleMap"]
}

After All Agents:
{
    "agent_outputs": {
        "googleMap": {...},
        "calendar": {...},
        "telephone": {...},
        "research": {...}
    },
    "execution_order": ["googleMap", "calendar", "telephone"]
}

After Summarization:
{
    "summary": "I've successfully processed your request...",
    "response": "I've successfully processed your request..."
}
```

---

## Code Examples

### Example 1: Complete Query Flow

**User Query:** "Find Indian restaurant near Taipei 101 and make reservation for tomorrow at 7 PM"

**Execution Flow:**
1. **Planning:**
   ```python
   plan = {
       "use_googlemap": True,
       "use_calendar": True,
       "use_telephone": True,
       "use_research": False
   }
   ```

2. **GoogleMap Agent:**
   ```python
   # Agent calls tool
   result = search_nearby_places("Indian restaurant", "Taipei 101")
   # Returns: List of restaurants with phone numbers
   ```

3. **Calendar Agent:**
   ```python
   # Agent calls tool with data from GoogleMap
   result = add_calendar_event(
       title="Dinner Reservation at Oye Punjabi",
       date="2025-11-19",
       time="19:00",
       location="No. 121號, Yanji St...",
       description="Phone: 02 2775 2065"
   )
   ```

4. **Telephone Agent:**
   ```python
   # Agent calls tool with phone from GoogleMap
   result = make_phone_call(
       phone_number="+886227752065",
       message="Make reservation for tomorrow at 7 PM"
   )
   ```

5. **Summary:**
   ```python
   summary = """Hello! I've coordinated with my specialized agents...
   GoogleMap Agent: Found Oye Punjabi Indian Restaurant...
   Calendar Agent: Added calendar event...
   Telephone Agent: Attempted call...
   In summary: Restaurant found, calendar event created..."""
   ```

---

## Key Design Patterns

### 1. Supervisor-Driven Architecture
- Supervisor evaluates state after each agent
- Makes intelligent routing decisions
- Handles dependencies and priorities

### 2. Tool-Based Agent Design
- Agents use LangChain tools for actual functionality
- Tools are reusable and testable
- Clear separation between agent logic and tool implementation

### 3. State Management with LangGraph
- TypedDict ensures type safety
- State flows through graph nodes
- Each node can read and update state

### 4. Streaming Responses
- Real-time updates to frontend
- Task-by-task execution visibility
- Better user experience

---

## Best Practices

### 1. Error Handling
- All tools have try-except blocks
- Errors are formatted and returned as JSON
- State tracks failed agents

### 2. Tool Design
- Tools return JSON strings (not objects)
- Tools handle their own errors
- Tools are idempotent when possible

### 3. Agent Prompts
- Clear system prompts define agent behavior
- Enhanced queries encourage tool use
- Prompts include context from previous agents

### 4. State Updates
- Always update execution_order
- Store both raw and formatted outputs
- Maintain state consistency

---

## Testing the Agents

### Test Individual Agent
```python
# Test GoogleMap agent
from agents.agent_factory import create_googlemap_agent
from langchain_google_genai import ChatGoogleGenerativeAI

llm = ChatGoogleGenerativeAI(model="gemini-2.5-flash", ...)
agent = create_googlemap_agent(llm)

result = await agent.ainvoke({
    "messages": [HumanMessage(content="Find Indian restaurant near Taipei 101")]
})
```

### Test Supervisor
```python
# Test Supervisor workflow
from agents.supervisor_langgraph import SupervisorAgentLangGraph

supervisor = SupervisorAgentLangGraph()
result = await supervisor.process_query("Find restaurant and make reservation")
```

---

## Conclusion

The Google Intelligent Group Multi-Agent System uses a sophisticated Supervisor-driven architecture with LangGraph for workflow orchestration. Each agent is a proper LangChain agent with tools, and the Supervisor coordinates them intelligently based on state evaluation.

**Key Takeaways:**
- Supervisor evaluates state and routes intelligently
- Agents use LangChain tools for functionality
- LangGraph manages workflow as a DAG
- State flows through nodes with type safety
- Streaming provides real-time updates

---

**Last Updated:** November 2025

