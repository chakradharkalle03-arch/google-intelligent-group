"""
Telephone Agent Implementation
Makes calls using Fonoster API.
"""

import os
import httpx
from typing import Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()


class TelephoneAgent:
    """Agent for making phone calls via Fonoster."""
    
    def __init__(self):
        self.fonoster_url = os.getenv("FONOSTER_SERVER_URL", "http://localhost:3001")
    
    async def make_call(
        self,
        phone_number: str,
        message: Optional[str] = None,
        context: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Make a phone call via Fonoster.
        
        Args:
            phone_number: Phone number to call (e.g., +886912345678)
            message: Optional message/script for the call
            context: Optional context about the call purpose
        
        Returns:
            Dictionary with call result
        """
        try:
            # Call Fonoster server
            url = f"{self.fonoster_url}/api/call/make"
            payload = {
                "phoneNumber": phone_number,
                "message": message or "Call initiated by Telephone Agent"
            }
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
                result = response.json()
            
            return {
                "success": True,
                "call_id": result.get("callId"),
                "phone_number": result.get("phoneNumber", phone_number),
                "status": result.get("status", "initiated"),
                "message": result.get("message", "Call initiated"),
                "timestamp": result.get("timestamp"),
                "note": result.get("note", "Call initiated successfully via Fonoster server.")
            }
            
        except httpx.RequestError as e:
            return {
                "success": False,
                "error": f"Failed to connect to Fonoster server: {str(e)}",
                "phone_number": phone_number,
                "note": "Make sure Fonoster server is running on " + self.fonoster_url
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "phone_number": phone_number
            }
    
    def format_result(self, result: Dict[str, Any]) -> str:
        """Format call result as a readable string."""
        if not result.get("success"):
            error_msg = result.get('error', 'Unknown error')
            phone = result.get('phone_number', 'N/A')
            
            # Provide helpful message for Fonoster connection errors
            if "Failed to connect" in error_msg or "connection" in error_msg.lower():
                return (f"⚠️ Phone Call Service Unavailable\n"
                       f"   Phone Number: {phone}\n"
                       f"   Note: Fonoster server is not running. Phone calls require Fonoster server.\n"
                       f"   You can manually call: {phone}")
            
            return f"❌ Call Error: {error_msg}\n   Phone: {phone}"
        
        formatted = f"☎️ Call Status: {result.get('status', 'unknown')}\n"
        formatted += f"   📞 Phone Number: {result.get('phone_number', 'N/A')}\n"
        if result.get('call_id'):
            formatted += f"   🆔 Call ID: {result.get('call_id')}\n"
        formatted += f"   💬 Message: {result.get('message', 'N/A')}\n"
        if result.get("timestamp"):
            formatted += f"   ⏰ Time: {result.get('timestamp')}\n"
        if result.get("note"):
            formatted += f"   ℹ️ Note: {result.get('note')}\n"
        
        return formatted
