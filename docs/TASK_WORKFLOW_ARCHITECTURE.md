# Task Workflow Architecture Documentation

## Overview

This document explains how the Multi-Agent System coordinates tasks using LangGraph and a Supervisor-driven architecture.

## Architecture Pattern: Supervisor-Driven Task Assignment

Our system uses a **Supervisor-driven task assignment** pattern, where the Supervisor Agent evaluates the state after each sub-agent completes a task and decides which agent to call next.

## Workflow Structure

### 1. Initial Planning Phase

The workflow begins with a **planning node** (`_plan_node`) that:
- Analyzes the user query using the Supervisor LLM
- Determines which agents are needed (GoogleMap, Calendar, Telephone, Research)
- Creates an initial execution plan stored in the state

### 2. Supervisor-Driven Routing

After each agent completes its task, control returns to the Supervisor via `_route_after_plan`, which:
- Evaluates the current state (plan, execution_order, agent_outputs)
- Determines the next logical agent to execute based on:
  - The original plan
  - Which agents have already executed
  - Dependencies between agents (e.g., Calendar before Telephone for reservations)
- Routes to the next agent or to summarization

### 3. Agent Execution Flow

```
User Query
    ↓
[Plan Node] → Analyzes query, creates execution plan
    ↓
[Supervisor Routing] → Evaluates state, decides next agent
    ↓
[Agent Node] → Executes task, returns result to state
    ↓
[Supervisor Routing] → Evaluates updated state, decides next step
    ↓
[Next Agent / Summarize] → Continues until all agents complete
    ↓
[Summarize Node] → Generates final comprehensive summary
    ↓
[END]
```

## Key Design Decisions

### Why Supervisor-Driven?

1. **Centralized Control**: The Supervisor maintains full visibility of the workflow state
2. **Dynamic Adaptation**: Can adjust routing based on agent results (e.g., if GoogleMap fails, skip dependent agents)
3. **State Evaluation**: Each routing decision is based on complete state evaluation, not just agent completion
4. **Flexibility**: Can handle complex dependencies and conditional workflows

### Routing Logic

The `_route_after_plan` function implements intelligent routing:

1. **Dependency-Aware**: Ensures GoogleMap executes before Telephone/Calendar (provides phone numbers)
2. **Workflow-Aware**: For reservations, ensures Calendar executes before Telephone
3. **State-Aware**: Checks execution_order to avoid duplicate executions
4. **Completion-Aware**: Routes to summarize when all needed agents have executed

### State Management

The `AgentState` TypedDict maintains:
- `messages`: Conversation history
- `agent_outputs`: Results from each agent
- `execution_order`: Track which agents have run
- `plan`: Original execution plan
- `query`: Original user query
- `summary`: Final summary (populated by summarize node)
- `response`: Final response (same as summary)

## Agent Execution Pattern

Each agent node follows this pattern:

1. **Receive State**: Gets current state from LangGraph
2. **Extract Context**: Pulls relevant information (query, previous agent outputs)
3. **Execute Agent**: Invokes LangChain agent with tools
4. **Process Result**: Extracts and formats agent output
5. **Update State**: Stores result in `agent_outputs` and updates `execution_order`
6. **Return State**: Returns updated state for next routing decision

## Example Workflow: Restaurant Reservation

```
Query: "Find Indian restaurant near Taipei 101 and make reservation for tomorrow at 7 PM"

1. [Plan Node]
   → Plan: {use_googlemap: true, use_calendar: true, use_telephone: true, use_research: false}

2. [Supervisor Routing]
   → State: plan exists, no agents executed
   → Decision: Route to "googlemap"

3. [GoogleMap Node]
   → Executes: search_nearby_places("Indian restaurant", "Taipei 101")
   → Result: Restaurant list with phone numbers
   → State: agent_outputs["googleMap"] = result, execution_order = ["googleMap"]

4. [Supervisor Routing]
   → State: googleMap executed, calendar and telephone still needed
   → Decision: Route to "calendar" (reservation workflow: calendar before telephone)

5. [Calendar Node]
   → Executes: add_calendar_event(...)
   → Result: Calendar event created
   → State: agent_outputs["calendar"] = result, execution_order = ["googleMap", "calendar"]

6. [Supervisor Routing]
   → State: calendar executed, telephone still needed
   → Decision: Route to "telephone"

7. [Telephone Node]
   → Executes: make_phone_call(phone_number from googleMap result)
   → Result: Call initiated
   → State: agent_outputs["telephone"] = result, execution_order = ["googleMap", "calendar", "telephone"]

8. [Supervisor Routing]
   → State: All needed agents executed
   → Decision: Route to "summarize"

9. [Summarize Node]
   → Generates comprehensive summary from all agent outputs
   → State: summary = "...", response = "..."

10. [END]
```

## Benefits of This Architecture

1. **Clear Separation**: Supervisor handles coordination, agents handle execution
2. **Maintainability**: Easy to add new agents or modify routing logic
3. **Testability**: Each component can be tested independently
4. **Scalability**: Can handle complex multi-step workflows
5. **Observability**: Full state tracking enables debugging and monitoring

## Future Improvements

- Add retry logic for failed agents
- Implement parallel agent execution where possible
- Add agent result validation before routing
- Implement dynamic plan adjustment based on intermediate results

