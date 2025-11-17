"""
Supervisor Agent Implementation
Coordinates tasks across multiple specialized agents using LangChain and Gemini.
"""

import os
import re
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate

from .googlemap_agent import GoogleMapAgent
from .calendar_agent import CalendarAgent
from .telephone_agent import TelephoneAgent
from .research_agent import ResearchAgent

load_dotenv()


class SupervisorAgent:
    """Supervisor Agent that coordinates multiple specialized agents."""
    
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.3  # Lower temperature for more consistent task assignment
        )
        
        # Initialize sub-agents
        self.googlemap_agent = GoogleMapAgent()
        self.calendar_agent = CalendarAgent()
        self.telephone_agent = TelephoneAgent()
        self.research_agent = ResearchAgent()
    
    async def process_query(self, query: str) -> Dict[str, Any]:
        """
        Process a user query by coordinating appropriate agents.
        
        Args:
            query: User's query string
        
        Returns:
            Dictionary with processing results from all agents
        """
        try:
            # Step 1: Analyze query and determine which agents to use
            agent_plan = await self._plan_agent_usage(query)
            
            # Step 2: Execute agent tasks in logical order
            results = {
                "supervisor": f"Processing query: {query}",
                "plan": agent_plan,
                "agent_outputs": {},
                "execution_order": []
            }
            
            # Execute agents in order: GoogleMap -> Research -> Telephone -> Calendar
            # This ensures dependencies are met (e.g., GoogleMap results available for Telephone/Calendar)
            
            # 1. Execute GoogleMap Agent first (if needed) - provides location/phone data
            if agent_plan.get("use_googlemap"):
                try:
                    map_result = await self._execute_googlemap(query)
                    results["agent_outputs"]["googleMap"] = map_result
                    results["execution_order"].append("googleMap")
                except Exception as e:
                    results["agent_outputs"]["googleMap"] = {
                        "agent": "GoogleMap",
                        "success": False,
                        "error": str(e),
                        "formatted": f"❌ GoogleMap Agent Error: {str(e)}"
                    }
                    results["execution_order"].append("googleMap (failed)")
            
            # 2. Execute Research Agent (independent, can run in parallel)
            if agent_plan.get("use_research"):
                try:
                    research_result = await self._execute_research(query)
                    results["agent_outputs"]["research"] = research_result
                    results["execution_order"].append("research")
                except Exception as e:
                    results["agent_outputs"]["research"] = {
                        "agent": "Research",
                        "success": False,
                        "error": str(e),
                        "formatted": f"❌ Research Agent Error: {str(e)}"
                    }
                    results["execution_order"].append("research (failed)")
            else:
                # Research agent not needed - show status
                results["agent_outputs"]["research"] = {
                    "agent": "Research",
                    "success": True,
                    "formatted": "ℹ️ Research Agent: Not needed for this query. This agent is used for general information and research questions.",
                    "skipped": True
                }
            
            # 3. Execute Telephone Agent (may use GoogleMap results)
            # Also trigger if making reservation and GoogleMap found results
            should_call_telephone = agent_plan.get("use_telephone", False)
            
            # Auto-trigger telephone if making reservation and we have restaurant results
            if not should_call_telephone:
                if agent_plan.get("use_calendar") and results.get("agent_outputs", {}).get("googleMap", {}).get("data", {}).get("results"):
                    # Making a reservation with restaurant found - should call
                    should_call_telephone = True
            
            if should_call_telephone:
                try:
                    phone_result = await self._execute_telephone(query, results.get("agent_outputs", {}))
                    results["agent_outputs"]["telephone"] = phone_result
                    results["execution_order"].append("telephone")
                except Exception as e:
                    results["agent_outputs"]["telephone"] = {
                        "agent": "Telephone",
                        "success": False,
                        "error": str(e),
                        "formatted": f"❌ Telephone Agent Error: {str(e)}"
                    }
                    results["execution_order"].append("telephone (failed)")
            
            # 4. Execute Calendar Agent last (may use GoogleMap results)
            if agent_plan.get("use_calendar"):
                try:
                    calendar_result = await self._execute_calendar(query, results.get("agent_outputs", {}))
                    results["agent_outputs"]["calendar"] = calendar_result
                    results["execution_order"].append("calendar")
                except Exception as e:
                    results["agent_outputs"]["calendar"] = {
                        "agent": "Calendar",
                        "success": False,
                        "error": str(e),
                        "formatted": f"❌ Calendar Agent Error: {str(e)}"
                    }
                    results["execution_order"].append("calendar (failed)")
            
            # Step 3: Generate final summary
            try:
                summary = await self._generate_summary(query, results)
                results["summary"] = summary
                results["response"] = summary
            except Exception as e:
                # Fallback summary if LLM summary fails
                results["summary"] = self._create_fallback_summary(query, results)
                results["response"] = results["summary"]
            
            return results
            
        except Exception as e:
            import traceback
            error_trace = traceback.format_exc()
            return {
                "supervisor": f"Error processing query: {str(e)}",
                "error": str(e),
                "error_trace": error_trace,
                "agent_outputs": {}
            }
    
    async def _plan_agent_usage(self, query: str) -> Dict[str, bool]:
        """Use LLM to determine which agents should be used."""
        prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a task planning system. Analyze the user query and determine which agents should be used.

Available agents:
- googlemap: For finding locations, restaurants, businesses, places, searching for nearby places
- calendar: For scheduling, booking, adding events, checking schedule, managing appointments
- telephone: For making phone calls, calling businesses, contacting via phone. IMPORTANT: If the query involves making a reservation or booking, you should use telephone agent to call the business.
- research: For general information, facts, explanations, answering questions

IMPORTANT RULES:
- If query mentions "make a reservation", "book a table", or similar booking actions, use telephone agent
- If query involves finding a restaurant AND making a reservation, use both googlemap and telephone agents
- Return ONLY a valid JSON object with boolean values. No explanations, no markdown, just JSON.

Example format: {"use_googlemap": true, "use_calendar": false, "use_telephone": true, "use_research": false}"""),
            ("human", "Query: {query}")
        ])
        
        try:
            chain = prompt | self.llm
            response = await chain.ainvoke({"query": query})
            
            # Parse JSON response
            response_text = response.content.strip()
            
            # Remove markdown code blocks if present
            response_text = re.sub(r'```json\s*', '', response_text)
            response_text = re.sub(r'```\s*', '', response_text)
            
            # Extract JSON object (more robust pattern)
            json_match = re.search(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', response_text)
            if json_match:
                import json
                plan = json.loads(json_match.group())
                
                # Validate and ensure all keys are present
                required_keys = ["use_googlemap", "use_calendar", "use_telephone", "use_research"]
                for key in required_keys:
                    if key not in plan:
                        plan[key] = False
                    # Ensure boolean type
                    plan[key] = bool(plan[key])
                
                return plan
            else:
                # Fallback: simple keyword matching
                return self._fallback_plan(query)
        except Exception as e:
            # If LLM planning fails, use fallback
            return self._fallback_plan(query)
    
    def _fallback_plan(self, query: str) -> Dict[str, bool]:
        """Fallback planning using keyword matching."""
        query_lower = query.lower()
        
        # More comprehensive keyword matching
        use_googlemap = any(word in query_lower for word in [
            "find", "search", "restaurant", "near", "location", "place", "business", 
            "cafe", "hotel", "shop", "store", "bar", "bakery", "nearby", "around"
        ])
        
        use_calendar = any(word in query_lower for word in [
            "schedule", "book", "reservation", "reserve", "appointment", "calendar", "tomorrow", 
            "today", "add", "event", "meeting", "make", "evening", "dinner", "lunch"
        ]) or "make a" in query_lower
        
        # Telephone agent should be used for:
        # 1. Explicit call requests
        # 2. Making reservations (typically requires calling)
        # 3. Booking appointments (may require calling)
        use_telephone = any(word in query_lower for word in [
            "call", "phone", "telephone", "contact", "ring", "dial"
        ]) or any(phrase in query_lower for phrase in [
            "make a reservation", "make reservation", "book a table", "book table",
            "reserve a table", "reserve table"
        ])
        
        use_research = any(word in query_lower for word in [
            "what", "how", "why", "explain", "information", "tell me about", 
            "research", "about", "describe", "define"
        ])
        
        return {
            "use_googlemap": use_googlemap,
            "use_calendar": use_calendar,
            "use_telephone": use_telephone,
            "use_research": use_research
        }
    
    async def _execute_googlemap(self, query: str) -> Dict[str, Any]:
        """Execute GoogleMap Agent task."""
        try:
            # Extract location from query
            location = self._extract_location(query)
            
            # Build search query - preserve cuisine types and search terms
            # Extract cuisine types and search terms more intelligently
            query_lower = query.lower()
            search_query_parts = []
            
            # Extract cuisine types (Indian, Italian, Chinese, etc.)
            cuisine_types = ["indian", "italian", "chinese", "japanese", "thai", "korean", 
                           "mexican", "french", "american", "taiwanese", "vietnamese"]
            for cuisine in cuisine_types:
                if cuisine in query_lower:
                    search_query_parts.append(cuisine)
                    break
            
            # Extract business types
            business_types = ["restaurant", "cafe", "hotel", "store", "shop", "bar", "bakery"]
            for business in business_types:
                if business in query_lower:
                    search_query_parts.append(business)
                    break
            
            # If no specific terms found, use the full query or default to "restaurant"
            if search_query_parts:
                search_query = " ".join(search_query_parts)
            else:
                # Use a more intelligent default - try to extract key terms from query
                # Remove common words and keep meaningful terms
                common_words = ["find", "near", "by", "nearby", "close", "to", "the", "a", "an"]
                words = [w for w in query.split() if w.lower() not in common_words]
                if words:
                    search_query = " ".join(words[:5])  # Take first 5 meaningful words
                else:
                    search_query = "restaurant"  # Final fallback
            
            # Add location to search query if not already geocoded
            if location and location not in search_query:
                search_query = f"{search_query} near {location}"
            
            result = await self.googlemap_agent.search_nearby(
                query=search_query,
                location=location,
                max_results=5
            )
            
            return {
                "agent": "GoogleMap",
                "success": result.get("success", False),
                "formatted": self.googlemap_agent.format_results(result),
                "data": result
            }
        except Exception as e:
            return {
                "agent": "GoogleMap",
                "success": False,
                "error": str(e),
                "formatted": f"❌ GoogleMap Agent Error: {str(e)}"
            }
    
    async def _execute_calendar(self, query: str, previous_results: Dict[str, Any] = None) -> Dict[str, Any]:
        """Execute Calendar Agent task."""
        try:
            # Extract event details from query
            event_info = self._extract_event_info(query)
            
            if event_info.get("action") == "add":
                # Get restaurant information from GoogleMap results if available
                restaurant_name = ""
                restaurant_address = ""
                restaurant_phone = ""
                
                if previous_results and previous_results.get("googleMap", {}).get("data", {}).get("results"):
                    first_result = previous_results["googleMap"]["data"]["results"][0]
                    restaurant_name = first_result.get("name", "")
                    restaurant_address = first_result.get("address", "")
                    restaurant_phone = first_result.get("phone_number", "")
                
                # Build location string
                location = event_info.get("location")
                if not location:
                    if restaurant_name:
                        location = restaurant_name
                        if restaurant_address and restaurant_address != "N/A":
                            location = f"{restaurant_name}, {restaurant_address}"
                    else:
                        # Try to extract restaurant name from query
                        location = self._extract_restaurant_name(query)
                
                # Build title with restaurant name if available
                title = event_info.get("title", "Event")
                if restaurant_name:
                    if "reservation" in title.lower():
                        title = f"{title} at {restaurant_name}"
                    else:
                        title = f"{title} - {restaurant_name}"
                elif not title or title == "Event":
                    title = "Restaurant Reservation"
                
                # Build description with restaurant details
                description = event_info.get("description", "")
                if restaurant_name:
                    desc_parts = [f"Restaurant: {restaurant_name}"]
                    if restaurant_address and restaurant_address != "N/A":
                        desc_parts.append(f"Address: {restaurant_address}")
                    if restaurant_phone and restaurant_phone != "N/A":
                        desc_parts.append(f"Phone: {restaurant_phone}")
                    if description:
                        desc_parts.insert(0, description)
                    description = "\n".join(desc_parts)
                
                # Get time from event_info - ensure it's correct
                event_time = event_info.get("time", "19:00")
                # Debug: Verify time is correct before passing to calendar
                print(f"DEBUG: Supervisor passing time to Calendar Agent: {event_time}")
                print(f"DEBUG: Event info: {event_info}")
                
                result = await self.calendar_agent.add_event(
                    title=title,
                    date=event_info.get("date", "tomorrow"),
                    time=event_time,
                    description=description,
                    location=location
                )
                formatted = result.get("message", str(result))
            else:
                result = await self.calendar_agent.list_events(event_info.get("date"))
                formatted = self.calendar_agent.format_events(result)
            
            return {
                "agent": "Calendar",
                "success": result.get("success", False),
                "formatted": formatted,
                "data": result
            }
        except Exception as e:
            return {
                "agent": "Calendar",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Calendar Agent Error: {str(e)}"
            }
    
    async def _execute_telephone(self, query: str, previous_results: Dict[str, Any]) -> Dict[str, Any]:
        """Execute Telephone Agent task."""
        try:
            # Extract phone number from query or previous results
            phone_number = self._extract_phone_number(query)
            
            # If no phone in query, try to get from GoogleMap results
            if not phone_number and previous_results.get("googleMap", {}).get("data", {}).get("results"):
                first_result = previous_results["googleMap"]["data"]["results"][0]
                phone_number = first_result.get("phone_number", "")
                if phone_number == "N/A":
                    phone_number = None
            
            if not phone_number:
                return {
                    "agent": "Telephone",
                    "success": False,
                    "error": "No phone number found",
                    "formatted": "❌ Telephone Agent: No phone number found in query or search results"
                }
            
            result = await self.telephone_agent.make_call(
                phone_number=phone_number,
                message=f"Calling regarding: {query}"
            )
            
            return {
                "agent": "Telephone",
                "success": result.get("success", False),
                "formatted": self.telephone_agent.format_result(result),
                "data": result
            }
        except Exception as e:
            return {
                "agent": "Telephone",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Telephone Agent Error: {str(e)}"
            }
    
    async def _execute_research(self, query: str) -> Dict[str, Any]:
        """Execute Research Agent task."""
        try:
            result = await self.research_agent.research(query)
            
            return {
                "agent": "Research",
                "success": result.get("success", False),
                "formatted": self.research_agent.format_result(result),
                "data": result
            }
        except Exception as e:
            return {
                "agent": "Research",
                "success": False,
                "error": str(e),
                "formatted": f"❌ Research Agent Error: {str(e)}"
            }
    
    async def _generate_summary(self, query: str, results: Dict[str, Any]) -> str:
        """Generate a final summary of all agent results."""
        try:
            agent_outputs = results.get("agent_outputs", {})
            
            # Collect formatted outputs
            formatted_outputs = []
            for agent_name, agent_result in agent_outputs.items():
                if isinstance(agent_result, dict) and agent_result.get("formatted"):
                    formatted_outputs.append(f"{agent_name}: {agent_result['formatted']}")
            
            # Use LLM to create a cohesive summary
            summary_prompt = f"""You are a helpful assistant summarizing the results of a multi-agent system.

User Query: {query}

Agent Results:
{chr(10).join(formatted_outputs) if formatted_outputs else 'No agent results available.'}

Create a clear, concise, and user-friendly summary that:
1. Acknowledges what the user asked for
2. Summarizes what each agent accomplished
3. Provides a cohesive final answer

Keep it natural and conversational."""
            
            chain = ChatPromptTemplate.from_messages([
                ("system", "You are a helpful assistant that summarizes multi-agent system results in a clear, user-friendly way."),
                ("human", summary_prompt)
            ]) | self.llm
            
            llm_summary = await chain.ainvoke({})
            return llm_summary.content if hasattr(llm_summary, 'content') else str(llm_summary)
            
        except Exception as e:
            # Fallback to simple summary
            return self._create_fallback_summary(query, results)
    
    def _create_fallback_summary(self, query: str, results: Dict[str, Any]) -> str:
        """Create a fallback summary without LLM."""
        agent_outputs = results.get("agent_outputs", {})
        
        summary_parts = [f"📋 Query: {query}\n"]
        summary_parts.append("\n🤖 Results:\n")
        
        for agent_name, agent_result in agent_outputs.items():
            if isinstance(agent_result, dict):
                if agent_result.get("formatted"):
                    summary_parts.append(f"{agent_result['formatted']}\n")
                elif agent_result.get("success"):
                    summary_parts.append(f"✅ {agent_name}: Task completed successfully\n")
                else:
                    error_msg = agent_result.get("error", "Unknown error")
                    summary_parts.append(f"❌ {agent_name}: {error_msg}\n")
        
        summary_parts.append("\n✅ Processing complete.")
        return "\n".join(summary_parts)
    
    def _extract_location(self, query: str) -> Optional[str]:
        """Extract location from query."""
        # Simple pattern matching for common location phrases
        patterns = [
            r"near\s+([A-Za-z0-9\s]+)",
            r"in\s+([A-Za-z0-9\s]+)",
            r"at\s+([A-Za-z0-9\s]+)",
        ]
        for pattern in patterns:
            match = re.search(pattern, query, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        return None
    
    def _extract_search_terms(self, query: str, keywords: List[str]) -> Optional[str]:
        """Extract search terms from query."""
        query_lower = query.lower()
        for keyword in keywords:
            if keyword in query_lower:
                return keyword
        return None
    
    def _extract_event_info(self, query: str) -> Dict[str, Any]:
        """Extract event information from query."""
        query_lower = query.lower()
        
        info = {
            "action": "add" if any(word in query_lower for word in ["book", "add", "schedule", "reserve", "reservation", "make"]) else "list",
            "title": "Event",
            "date": "tomorrow",
            "time": "19:00",  # Default to 7 PM
            "description": ""
        }
        
        # Extract date - handle "tomorrow", "today", "evening", "night"
        if "tomorrow" in query_lower:
            info["date"] = "tomorrow"
        elif "today" in query_lower:
            info["date"] = "today"
        elif "friday" in query_lower:
            info["date"] = "friday"
        elif "saturday" in query_lower:
            info["date"] = "saturday"
        elif "sunday" in query_lower:
            info["date"] = "sunday"
        elif "monday" in query_lower:
            info["date"] = "monday"
        elif "tuesday" in query_lower:
            info["date"] = "tuesday"
        elif "wednesday" in query_lower:
            info["date"] = "wednesday"
        elif "thursday" in query_lower:
            info["date"] = "thursday"
        
        # Extract time - ONLY from explicit time mentions (AM/PM or 24-hour format)
        # Do NOT use context words like "morning", "evening", "night" to infer time
        # Pattern 1: "7:00 PM", "7 PM", "10 AM", "15:00", "17:00" etc.
        # Match time patterns like "6:00 PM", "6 PM", "10 AM", "17:00" but NOT "101" or other numbers
        time_match = re.search(r"\b(\d{1,2}):?(\d{2})?\s*(am|pm|AM|PM)\b", query, re.IGNORECASE)
        if time_match:
            hour = int(time_match.group(1))
            minute = int(time_match.group(2) or 0)
            am_pm = time_match.group(3)
            
            # Validate hour is reasonable (1-12 for AM/PM format)
            if hour < 1 or hour > 12:
                print(f"DEBUG: Invalid hour {hour} for AM/PM format, skipping")
            else:
                # Handle PM/AM conversion
                am_pm_lower = am_pm.lower()
                original_hour = hour  # Store original for debugging
                
                if am_pm_lower == "pm":
                    if hour == 12:
                        # 12 PM stays 12 (noon)
                        final_hour = 12
                    else:
                        # 1 PM → 13, 2 PM → 14, ..., 6 PM → 18, 11 PM → 23
                        final_hour = hour + 12
                elif am_pm_lower == "am":
                    if hour == 12:
                        # 12 AM → 0 (midnight)
                        final_hour = 0
                    else:
                        # 1 AM → 1, 2 AM → 2, ..., 11 AM → 11
                        final_hour = hour
                else:
                    final_hour = hour
                
                # Set time from explicit AM/PM
                final_time = f"{final_hour:02d}:{minute:02d}"
                info["time"] = final_time
                # Debug logging
                print(f"DEBUG: Time extraction - Matched '{time_match.group(0)}' → '{original_hour}:{minute:02d} {am_pm}' → {final_time} (hour={final_hour})")
        else:
            # Try pattern for 24-hour format (e.g., "15:00", "17:00", "09:00")
            # Only match if hour is > 12 OR if it's clearly a time format (has :MM)
            time_match_24 = re.search(r"\b(\d{1,2}):(\d{2})\b", query)
            if time_match_24:
                hour = int(time_match_24.group(1))
                minute = int(time_match_24.group(2))
                
                # Only accept if hour is 0-23 and minute is 0-59
                if 0 <= hour <= 23 and 0 <= minute <= 59:
                    # If hour > 12, it's clearly 24-hour format
                    # If hour <= 12, only accept if it looks like a time (not a date or other number)
                    # Check if it's followed by something that suggests it's a time, or if hour > 12
                    if hour > 12 or (hour <= 12 and re.search(r"\d{1,2}:\d{2}\s*(?:am|pm|AM|PM|o'clock|oclock|hrs|hours)?", query, re.IGNORECASE)):
                        info["time"] = f"{hour:02d}:{minute:02d}"
                        print(f"DEBUG: Time extraction - 24-hour format '{hour:02d}:{minute:02d}'")
                    elif hour <= 12:
                        # For hours <= 12 without AM/PM, we can't be sure, so skip it
                        # User must specify AM/PM or use 24-hour format (13-23)
                        print(f"DEBUG: Time extraction - Ambiguous time '{hour:02d}:{minute:02d}' without AM/PM, skipping")
            # If no explicit time found, keep default (19:00) but log it
            if "time" not in info or info["time"] == "19:00":
                print(f"DEBUG: Time extraction - No explicit time found, using default 19:00")
        
        # Extract title - more comprehensive
        if "reservation" in query_lower:
            if "dinner" in query_lower:
                info["title"] = "Dinner Reservation"
            elif "lunch" in query_lower:
                info["title"] = "Lunch Reservation"
            elif "breakfast" in query_lower:
                info["title"] = "Breakfast Reservation"
            else:
                info["title"] = "Restaurant Reservation"
        elif "dinner" in query_lower:
            info["title"] = "Dinner"
        elif "lunch" in query_lower:
            info["title"] = "Lunch"
        elif "breakfast" in query_lower:
            info["title"] = "Breakfast"
        elif "meeting" in query_lower:
            info["title"] = "Meeting"
        elif "appointment" in query_lower:
            info["title"] = "Appointment"
        
        # Extract description if available
        if "restaurant" in query_lower:
            # Try to extract restaurant type
            cuisine_types = ["indian", "italian", "chinese", "japanese", "thai", "korean", "mexican", "french"]
            for cuisine in cuisine_types:
                if cuisine in query_lower:
                    info["description"] = f"{cuisine.capitalize()} restaurant reservation"
                    break
        
        return info
    
    def _extract_phone_number(self, query: str) -> Optional[str]:
        """Extract phone number from query."""
        # Pattern for phone numbers
        phone_pattern = r'\+?\d{1,4}[-.\s]?\(?\d{1,4}\)?[-.\s]?\d{1,4}[-.\s]?\d{1,9}'
        match = re.search(phone_pattern, query)
        if match:
            return match.group(0).strip()
        return None
    
    def _extract_restaurant_name(self, query: str) -> Optional[str]:
        """Extract restaurant name from query."""
        # Look for patterns like "restaurant X" or "X restaurant"
        patterns = [
            r'(?:restaurant|place|location)\s+([A-Za-z0-9\s]+?)(?:\s+near|\s+at|$)',
            r'([A-Za-z0-9\s]+?)\s+restaurant',
        ]
        for pattern in patterns:
            match = re.search(pattern, query, re.IGNORECASE)
            if match:
                name = match.group(1).strip()
                # Remove common words
                name = re.sub(r'\b(near|at|the|a|an)\b', '', name, flags=re.IGNORECASE).strip()
                if name:
                    return name
        return None
