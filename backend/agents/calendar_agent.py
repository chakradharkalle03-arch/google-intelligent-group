"""
Calendar Agent Implementation
Manages calendar events and bookings.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
import json


class CalendarAgent:
    """Agent for managing calendar events and bookings."""
    
    def __init__(self):
        # In-memory storage (replace with database in production)
        self.events: List[Dict[str, Any]] = []
    
    async def add_event(
        self,
        title: str,
        date: str,
        time: str,
        description: Optional[str] = None,
        location: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Add a new calendar event.
        
        Args:
            title: Event title
            date: Date in format YYYY-MM-DD or "tomorrow", "today"
            time: Time in format HH:MM (24-hour)
            description: Optional event description
            location: Optional event location
        
        Returns:
            Dictionary with event details
        """
        try:
            # Parse date
            event_date = self._parse_date(date)
            if not event_date:
                return {
                    "success": False,
                    "error": f"Invalid date format: {date}. Use YYYY-MM-DD, 'today', or 'tomorrow'"
                }
            
            # Parse time
            try:
                print(f"DEBUG: Calendar Agent received time: '{time}'")
                hour, minute = map(int, time.split(":"))
                print(f"DEBUG: Calendar Agent parsed - hour: {hour}, minute: {minute}")
                # Ensure hour is valid (0-23)
                if hour < 0 or hour > 23:
                    return {
                        "success": False,
                        "error": f"Invalid hour: {hour}. Hour must be between 0 and 23"
                    }
                # Create datetime with explicit time (remove any existing time components)
                event_datetime = event_date.replace(hour=hour, minute=minute, second=0, microsecond=0)
                print(f"DEBUG: Calendar Agent created datetime: {event_datetime.isoformat()}")
            except ValueError:
                return {
                    "success": False,
                    "error": f"Invalid time format: {time}. Use HH:MM (24-hour format)"
                }
            
            # Create event
            event = {
                "id": len(self.events) + 1,
                "title": title,
                "datetime": event_datetime.isoformat(),
                "date": event_date.strftime("%Y-%m-%d"),
                "time": time,
                "description": description or "",
                "location": location or "",
                "created_at": datetime.now().isoformat()
            }
            
            self.events.append(event)
            
            # Format time for display (convert 24-hour to 12-hour if needed)
            display_time = time
            try:
                hour, minute = map(int, time.split(":"))
                if hour == 0:
                    display_time = f"12:{minute:02d} AM"
                elif hour < 12:
                    display_time = f"{hour}:{minute:02d} AM"
                elif hour == 12:
                    display_time = f"12:{minute:02d} PM"
                else:
                    display_time = f"{hour-12}:{minute:02d} PM"
            except:
                pass  # Use original time if parsing fails
            
            return {
                "success": True,
                "event": event,
                "message": f"✅ Event '{title}' added to calendar for {event_date.strftime('%B %d, %Y')} at {display_time}"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e)
            }
    
    async def list_events(self, date: Optional[str] = None) -> Dict[str, Any]:
        """
        List calendar events.
        
        Args:
            date: Optional date filter (YYYY-MM-DD, 'today', 'tomorrow')
        
        Returns:
            Dictionary with list of events
        """
        try:
            if date:
                filter_date = self._parse_date(date)
                if filter_date:
                    filtered_events = [
                        e for e in self.events
                        if datetime.fromisoformat(e["datetime"]).date() == filter_date.date()
                    ]
                else:
                    filtered_events = self.events
            else:
                filtered_events = self.events
            
            # Sort by datetime
            filtered_events.sort(key=lambda x: x["datetime"])
            
            return {
                "success": True,
                "events": filtered_events,
                "count": len(filtered_events)
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "events": []
            }
    
    async def get_today_schedule(self) -> Dict[str, Any]:
        """Get today's schedule."""
        return await self.list_events("today")
    
    def _parse_date(self, date_str: str) -> Optional[datetime]:
        """Parse date string to datetime object."""
        try:
            # Get current date at midnight (no timezone)
            now = datetime.now()
            today = datetime(now.year, now.month, now.day, 0, 0, 0, 0)
            
            if date_str.lower() == "today":
                return today
            elif date_str.lower() == "tomorrow":
                return today + timedelta(days=1)
            elif date_str.lower() == "yesterday":
                return today - timedelta(days=1)
            else:
                # Try parsing as YYYY-MM-DD
                parsed = datetime.strptime(date_str, "%Y-%m-%d")
                # Ensure it's at midnight
                return datetime(parsed.year, parsed.month, parsed.day, 0, 0, 0, 0)
        except ValueError:
            return None
    
    def format_events(self, result: Dict[str, Any]) -> str:
        """Format events as a readable string."""
        if not result.get("success"):
            return f"❌ Error: {result.get('error', 'Unknown error')}"
        
        events = result.get("events", [])
        if not events:
            return "📅 No events found in calendar."
        
        formatted = f"📅 Calendar Events ({len(events)}):\n\n"
        
        for event in events:
            # Use the stored time string if available (more reliable than parsing datetime)
            if event.get("time"):
                # Parse the time string and format it
                try:
                    hour, minute = map(int, event["time"].split(":"))
                    # Convert to 12-hour format
                    if hour == 0:
                        time_str = f"12:{minute:02d} AM"
                    elif hour < 12:
                        time_str = f"{hour}:{minute:02d} AM"
                    elif hour == 12:
                        time_str = f"12:{minute:02d} PM"
                    else:
                        time_str = f"{hour-12}:{minute:02d} PM"
                except:
                    # Fallback to datetime parsing
                    event_dt = datetime.fromisoformat(event["datetime"])
                    time_str = event_dt.strftime('%I:%M %p')
            else:
                # Fallback to datetime parsing
                event_dt = datetime.fromisoformat(event["datetime"])
                time_str = event_dt.strftime('%I:%M %p')
            
            # Get date from datetime
            event_dt = datetime.fromisoformat(event["datetime"])
            date_str = event_dt.strftime('%B %d, %Y')
            
            formatted += f"• **{event['title']}**\n"
            formatted += f"  📅 {date_str} at {time_str}\n"
            if event.get("location"):
                formatted += f"  📍 Location: {event['location']}\n"
            if event.get("description"):
                formatted += f"  📝 {event['description']}\n"
            formatted += "\n"
        
        return formatted
