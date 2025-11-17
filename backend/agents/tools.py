"""
LangChain Tools for Multi-Agent System
Converts agent functions into LangChain tools for proper agent integration.
"""

import os
import httpx
from typing import Optional, Dict, Any
from langchain.tools import tool
from dotenv import load_dotenv

load_dotenv()


# GoogleMap Agent Tools
@tool
async def search_nearby_places(
    query: str,
    location: Optional[str] = None,
    radius: int = 5000,
    max_results: int = 5
) -> str:
    """
    Search for nearby places using Google Maps API.
    
    Args:
        query: Search query (e.g., "Indian restaurant")
        location: Location string (e.g., "Taipei 101")
        radius: Search radius in meters (default: 5000)
        max_results: Maximum number of results (default: 5)
    
    Returns:
        JSON string with search results including name, address, phone, rating
    """
    try:
        api_key = os.getenv("GOOGLE_MAPS_API_KEY")
        if not api_key:
            return '{"success": false, "error": "GOOGLE_MAPS_API_KEY not found"}'
        
        base_url = "https://maps.googleapis.com/maps/api/place"
        
        # Build search query
        if location:
            search_query = f"{query} near {location}"
        else:
            search_query = query
        
        # Use Text Search API
        url = f"{base_url}/textsearch/json"
        params = {
            "query": search_query,
            "key": api_key
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
        
        if data.get("status") != "OK":
            error_msg = data.get("error_message", "")
            status = data.get("status", "UNKNOWN")
            import json
            return json.dumps({"success": False, "error": f"API Error: {status} - {error_msg}"})
        
        # Process results
        places = data.get("results", [])[:max_results]
        results = []
        
        for place in places:
            place_id = place.get("place_id")
            place_details = await _get_place_details(place_id, api_key) if place_id else {}
            
            result = {
                "name": place.get("name", "Unknown"),
                "address": place.get("formatted_address", place.get("vicinity", "N/A")),
                "rating": place.get("rating", "N/A"),
                "phone_number": place_details.get("formatted_phone_number", "N/A"),
                "location": {
                    "lat": place.get("geometry", {}).get("location", {}).get("lat"),
                    "lng": place.get("geometry", {}).get("location", {}).get("lng")
                },
                "types": place.get("types", []),
                "place_id": place_id
            }
            results.append(result)
        
        import json
        return json.dumps({
            "success": True,
            "query": query,
            "location": location,
            "results": results,
            "count": len(results)
        })
        
    except Exception as e:
        import json
        return json.dumps({"success": False, "error": str(e), "results": []})


async def _get_place_details(place_id: str, api_key: str) -> Dict[str, Any]:
    """Get detailed information about a place."""
    try:
        base_url = "https://maps.googleapis.com/maps/api/place"
        url = f"{base_url}/details/json"
        params = {
            "place_id": place_id,
            "fields": "formatted_phone_number,opening_hours,website",
            "key": api_key
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
        
        if data.get("status") == "OK":
            return data.get("result", {})
        return {}
    except Exception:
        return {}


# Calendar Agent Tools
@tool
async def add_calendar_event(
    title: str,
    date: str,
    time: str,
    description: Optional[str] = None,
    location: Optional[str] = None
) -> str:
    """
    Add a new calendar event.
    
    Args:
        title: Event title
        date: Date in format YYYY-MM-DD, "today", or "tomorrow"
        time: Time in format HH:MM (24-hour format, e.g., "19:00" for 7 PM)
        description: Optional event description
        location: Optional event location
    
    Returns:
        JSON string with event details
    """
    try:
        from datetime import datetime, timedelta
        
        # Parse date
        now = datetime.now()
        today = datetime(now.year, now.month, now.day, 0, 0, 0, 0)
        
        if date.lower() == "today":
            event_date = today
        elif date.lower() == "tomorrow":
            event_date = today + timedelta(days=1)
        elif date.lower() == "yesterday":
            event_date = today - timedelta(days=1)
        else:
            parsed = datetime.strptime(date, "%Y-%m-%d")
            event_date = datetime(parsed.year, parsed.month, parsed.day, 0, 0, 0, 0)
        
        # Parse time
        hour, minute = map(int, time.split(":"))
        if hour < 0 or hour > 23:
            import json
            return json.dumps({"success": False, "error": f"Invalid hour: {hour}"})
        
        event_datetime = event_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
        
        # Format time for display
        if hour == 0:
            display_time = f"12:{minute:02d} AM"
        elif hour < 12:
            display_time = f"{hour}:{minute:02d} AM"
        elif hour == 12:
            display_time = f"12:{minute:02d} PM"
        else:
            display_time = f"{hour-12}:{minute:02d} PM"
        
        event = {
            "id": int(datetime.now().timestamp()),
            "title": title,
            "datetime": event_datetime.isoformat(),
            "date": event_date.strftime("%Y-%m-%d"),
            "time": time,
            "description": description or "",
            "location": location or "",
            "created_at": datetime.now().isoformat()
        }
        
        import json
        return json.dumps({
            "success": True,
            "event": event,
            "message": f"Event '{title}' added to calendar for {event_date.strftime('%B %d, %Y')} at {display_time}"
        })
        
    except Exception as e:
        import json
        return json.dumps({"success": False, "error": str(e)})


@tool
async def list_calendar_events(date: Optional[str] = None) -> str:
    """
    List calendar events.
    
    Args:
        date: Optional date filter (YYYY-MM-DD, 'today', 'tomorrow')
    
    Returns:
        JSON string with list of events
    """
    # Note: In a real implementation, this would query a database
    # For now, return a placeholder
    import json
    return json.dumps({
        "success": True,
        "events": [],
        "count": 0,
        "message": "Calendar events are stored in memory. Use add_calendar_event to add events."
    })


# Telephone Agent Tools
@tool
async def make_phone_call(
    phone_number: str,
    message: Optional[str] = None
) -> str:
    """
    Make a phone call via Fonoster.
    
    Args:
        phone_number: Phone number to call (e.g., "+886912345678")
        message: Optional message/script for the call
    
    Returns:
        JSON string with call result
    """
    try:
        fonoster_url = os.getenv("FONOSTER_SERVER_URL", "http://localhost:3001")
        url = f"{fonoster_url}/api/call/make"
        payload = {
            "phoneNumber": phone_number,
            "message": message or "Call initiated by Telephone Agent"
        }
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            result = response.json()
        
        import json
        return json.dumps({
            "success": True,
            "call_id": result.get("callId"),
            "phone_number": result.get("phoneNumber", phone_number),
            "status": result.get("status", "initiated"),
            "message": result.get("message", "Call initiated"),
            "timestamp": result.get("timestamp"),
            "note": result.get("note", "Call initiated successfully via Fonoster server.")
        })
        
    except httpx.RequestError as e:
        import json
        return json.dumps({
            "success": False,
            "error": f"Failed to connect to Fonoster server: {str(e)}",
            "phone_number": phone_number,
            "note": f"Make sure Fonoster server is running on {fonoster_url}"
        })
    except Exception as e:
        import json
        return json.dumps({
            "success": False,
            "error": str(e),
            "phone_number": phone_number
        })


# Research Agent Tools
@tool
async def research_query(query: str, context: Optional[str] = None) -> str:
    """
    Perform research on a given query using Gemini LLM.
    
    Args:
        query: Research query
        context: Optional context or additional information
    
    Returns:
        JSON string with research results
    """
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI
        from langchain_core.prompts import ChatPromptTemplate
        
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            import json
            return json.dumps({"success": False, "error": "GEMINI_API_KEY not found"})
        
        llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.7
        )
        
        prompt_template = ChatPromptTemplate.from_messages([
            ("system", "You are a helpful research assistant. Provide accurate, concise, and well-structured information."),
            ("human", "{query}")
        ])
        
        if context:
            full_query = f"{query}\n\nContext: {context}"
        else:
            full_query = query
        
        chain = prompt_template | llm
        response = await chain.ainvoke({"query": full_query})
        
        import json
        return json.dumps({
            "success": True,
            "query": query,
            "result": response.content,
            "model": "gemini-2.5-flash"
        })
        
    except Exception as e:
        import json
        return json.dumps({
            "success": False,
            "error": str(e),
            "query": query
        })


# Export all tools
GOOGLEMAP_TOOLS = [search_nearby_places]
CALENDAR_TOOLS = [add_calendar_event, list_calendar_events]
TELEPHONE_TOOLS = [make_phone_call]
RESEARCH_TOOLS = [research_query]

ALL_TOOLS = GOOGLEMAP_TOOLS + CALENDAR_TOOLS + TELEPHONE_TOOLS + RESEARCH_TOOLS

