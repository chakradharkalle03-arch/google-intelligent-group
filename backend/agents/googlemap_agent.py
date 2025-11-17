"""
GoogleMap Agent Implementation
Searches nearby businesses using Google Maps API.
"""

import os
import httpx
from typing import List, Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()


class GoogleMapAgent:
    """Agent for searching nearby places using Google Maps Places API."""
    
    def __init__(self):
        self.api_key = os.getenv("GOOGLE_MAPS_API_KEY")
        if not self.api_key:
            raise ValueError("GOOGLE_MAPS_API_KEY not found in environment variables")
        
        self.base_url = "https://maps.googleapis.com/maps/api/place"
    
    async def search_nearby(
        self,
        query: str,
        location: Optional[str] = None,
        radius: int = 5000,
        max_results: int = 5
    ) -> Dict[str, Any]:
        """
        Search for nearby places.
        
        Args:
            query: Search query (e.g., "Italian restaurant")
            location: Location string (e.g., "Taipei 101") or lat,lng
            radius: Search radius in meters (default: 5000)
            max_results: Maximum number of results to return
        
        Returns:
            Dictionary with search results
        """
        try:
            # First, geocode the location if provided as text
            lat, lng = None, None
            if location:
                geocode_result = await self._geocode_location(location)
                if geocode_result:
                    lat = geocode_result["lat"]
                    lng = geocode_result["lng"]
            
            # Prefer Text Search API as it's more flexible for specific queries
            # Text Search works better for queries like "Indian restaurant near Taipei 101"
            if location:
                # Include location in search query for better results
                search_query = f"{query} near {location}"
            else:
                search_query = query
            
            # Use Text Search API (better for specific cuisine/type searches)
            url = f"{self.base_url}/textsearch/json"
            params = {
                "query": search_query,
                "key": self.api_key
            }
            
            # If we have coordinates, we can optionally add them for better relevance
            # But Text Search handles location names well, so coordinates are optional
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
            
            if data.get("status") != "OK":
                error_msg = data.get("error_message", "")
                status = data.get("status", "UNKNOWN")
                error_detail = f"API Error: {status}"
                if error_msg:
                    error_detail += f" - {error_msg}"
                
                # Provide helpful suggestions for common errors
                if status == "REQUEST_DENIED":
                    if "referer restrictions" in error_msg.lower():
                        error_detail += "\n💡 Fix: Remove HTTP referrer restrictions from your API key in Google Cloud Console"
                    elif "legacy API" in error_msg.lower() or "not enabled" in error_msg.lower():
                        error_detail += "\n💡 Fix: Enable Places API in Google Cloud Console:"
                        error_detail += "\n   1. Go to: https://console.cloud.google.com/apis/library"
                        error_detail += "\n   2. Search for 'Places API'"
                        error_detail += "\n   3. Click 'Enable' button"
                        error_detail += "\n   4. Wait 1-2 minutes for API to activate"
                    else:
                        error_detail += "\n💡 Fix: Check API key restrictions and ensure Places API and Geocoding API are enabled"
                
                return {
                    "success": False,
                    "error": error_detail,
                    "status": status,
                    "results": []
                }
            
            # Process results
            places = data.get("results", [])[:max_results]
            results = []
            
            for place in places:
                place_id = place.get("place_id")
                place_details = await self._get_place_details(place_id) if place_id else {}
                
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
            
            return {
                "success": True,
                "query": query,
                "location": location,
                "results": results,
                "count": len(results)
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "results": []
            }
    
    async def _geocode_location(self, location: str) -> Optional[Dict[str, float]]:
        """Geocode a location string to coordinates."""
        try:
            url = "https://maps.googleapis.com/maps/api/geocode/json"
            params = {
                "address": location,
                "key": self.api_key
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, timeout=10.0)
                response.raise_for_status()
                data = response.json()
            
            if data.get("status") == "OK" and data.get("results"):
                location_data = data["results"][0]["geometry"]["location"]
                return {
                    "lat": location_data["lat"],
                    "lng": location_data["lng"]
                }
            
            # Log error for debugging
            if data.get("status") != "OK":
                error_msg = data.get("error_message", "")
                print(f"Geocoding API Error: {data.get('status')} - {error_msg}")
            
            return None
        except Exception:
            return None
    
    async def _get_place_details(self, place_id: str) -> Dict[str, Any]:
        """Get detailed information about a place."""
        try:
            url = f"{self.base_url}/details/json"
            params = {
                "place_id": place_id,
                "fields": "formatted_phone_number,opening_hours,website",
                "key": self.api_key
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
    
    def format_results(self, search_result: Dict[str, Any]) -> str:
        """Format search results as a readable string."""
        if not search_result.get("success"):
            return f"❌ Error: {search_result.get('error', 'Unknown error')}"
        
        results = search_result.get("results", [])
        if not results:
            return f"🔍 No results found for '{search_result.get('query', '')}'"
        
        formatted = f"🗺️ Found {len(results)} result(s) for '{search_result.get('query', '')}':\n\n"
        
        for i, place in enumerate(results, 1):
            formatted += f"{i}. **{place['name']}**\n"
            formatted += f"   📍 Address: {place['address']}\n"
            if place.get('rating') != 'N/A':
                formatted += f"   ⭐ Rating: {place['rating']}/5.0\n"
            if place.get('phone_number') != 'N/A':
                formatted += f"   ☎️ Phone: {place['phone_number']}\n"
            formatted += "\n"
        
        return formatted
