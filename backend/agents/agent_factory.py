"""
Agent Factory - Creates LangChain Agents for each sub-agent
"""

import os
from typing import List
from langchain.agents import create_agent
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate
from dotenv import load_dotenv

from .tools import (
    GOOGLEMAP_TOOLS,
    CALENDAR_TOOLS,
    TELEPHONE_TOOLS,
    RESEARCH_TOOLS
)

load_dotenv()


def create_googlemap_agent():
    """Create GoogleMap Agent with LangChain."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found")
    
    model = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.3
    )
    
    system_prompt = """You are a Google Maps search assistant. Your role is to help users find nearby places, restaurants, businesses, and locations.

When searching:
- Extract location information from the query (e.g., "near Taipei 101", "in New York")
- Extract search terms (e.g., "Indian restaurant", "coffee shop")
- Use the search_nearby_places tool with appropriate parameters
- Present results clearly with name, address, phone number, and rating

Always provide helpful, accurate location information."""
    
    return create_agent(
        model=model,
        tools=GOOGLEMAP_TOOLS,
        system_prompt=system_prompt
    )


def create_calendar_agent():
    """Create Calendar Agent with LangChain."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found")
    
    model = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.3
    )
    
    system_prompt = """You are a calendar management assistant. Your role is to help users manage their schedule and events.

When adding events:
- Extract event details: title, date, time, description, location
- Parse dates: "today", "tomorrow", or YYYY-MM-DD format
- Parse times: Convert to 24-hour format (HH:MM). For example:
  * "7:00 PM" or "7 PM" → "19:00"
  * "6:00 PM" or "6 PM" → "18:00"
  * "10:00 AM" or "10 AM" → "10:00"
  * "12:00 PM" or "noon" → "12:00"
  * "12:00 AM" or "midnight" → "00:00"
- Use the add_calendar_event tool with correct parameters
- Confirm event creation clearly

Always use 24-hour format (HH:MM) when calling the tool, even if the user specifies 12-hour format."""
    
    return create_agent(
        model=model,
        tools=CALENDAR_TOOLS,
        system_prompt=system_prompt
    )


def create_telephone_agent():
    """Create Telephone Agent with LangChain."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found")
    
    model = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.3
    )
    
    system_prompt = """You are a telephone assistant. Your role is to help users make phone calls via Fonoster.

When making calls:
- Extract phone numbers from the query or context
- Format phone numbers properly (include country code if needed)
- Create appropriate call messages/scripts
- Use the make_phone_call tool
- Report call status clearly

Always confirm call initiation and provide call details."""
    
    return create_agent(
        model=model,
        tools=TELEPHONE_TOOLS,
        system_prompt=system_prompt
    )


def create_research_agent():
    """Create Research Agent with LangChain."""
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise ValueError("GEMINI_API_KEY not found")
    
    model = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        google_api_key=api_key,
        temperature=0.7
    )
    
    system_prompt = """You are a research assistant. Your role is to provide accurate, well-structured information on various topics.

When researching:
- Understand the query clearly
- Use the research_query tool to get information
- Present findings in a clear, organized manner
- Cite sources when possible
- Provide comprehensive answers

Always provide helpful, accurate research results."""
    
    return create_agent(
        model=model,
        tools=RESEARCH_TOOLS,
        system_prompt=system_prompt
    )

