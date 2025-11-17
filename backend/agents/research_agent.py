"""
Research Agent Implementation
Performs research tasks using Gemini LLM.
"""

import os
from typing import Dict, Any, Optional
from dotenv import load_dotenv
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.prompts import ChatPromptTemplate

load_dotenv()


class ResearchAgent:
    """Agent for performing research tasks using Gemini LLM."""
    
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            raise ValueError("GEMINI_API_KEY not found in environment variables")
        
        self.llm = ChatGoogleGenerativeAI(
            model="gemini-2.5-flash",
            google_api_key=api_key,
            temperature=0.7
        )
    
    async def research(self, query: str, context: Optional[str] = None) -> Dict[str, Any]:
        """
        Perform research on a given query.
        
        Args:
            query: Research query
            context: Optional context or additional information
        
        Returns:
            Dictionary with research results
        """
        try:
            prompt_template = ChatPromptTemplate.from_messages([
                ("system", "You are a helpful research assistant. Provide accurate, concise, and well-structured information."),
                ("human", "{query}")
            ])
            
            if context:
                full_query = f"{query}\n\nContext: {context}"
            else:
                full_query = query
            
            chain = prompt_template | self.llm
            
            # Run the chain
            response = await chain.ainvoke({"query": full_query})
            
            return {
                "success": True,
                "query": query,
                "result": response.content,
                "model": "gemini-2.5-flash"
            }
            
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "query": query
            }
    
    async def summarize(self, text: str, max_length: int = 200) -> Dict[str, Any]:
        """
        Summarize a given text.
        
        Args:
            text: Text to summarize
            max_length: Maximum length of summary
        
        Returns:
            Dictionary with summary
        """
        query = f"Please provide a concise summary of the following text in approximately {max_length} words:\n\n{text}"
        return await self.research(query)
    
    def format_result(self, result: Dict[str, Any]) -> str:
        """Format research result as a readable string."""
        if not result.get("success"):
            return f"❌ Research Error: {result.get('error', 'Unknown error')}"
        
        formatted = f"🔍 Research Results for: '{result.get('query', '')}'\n\n"
        formatted += f"{result.get('result', 'No results')}\n"
        
        return formatted
