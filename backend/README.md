# Backend - Google Intelligent Group

Python FastAPI backend server for the Multi-Agent System.

## Setup Instructions

1. Create a virtual environment:
```bash
python -m venv venv
```

2. Activate virtual environment:
```bash
# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Set up environment variables:
```bash
# Copy .env.example to .env
cp .env.example .env

# Edit .env and add your API keys
# - GEMINI_API_KEY
# - GOOGLE_MAPS_API_KEY
```

5. Run the server:
```bash
python main.py
# Or using uvicorn directly:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

6. API will be available at [http://localhost:8000](http://localhost:8000)
7. API documentation at [http://localhost:8000/docs](http://localhost:8000/docs)

## API Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `POST /query` - Process user query through Supervisor Agent

## Tech Stack

- FastAPI
- LangChain 1.0
- Google Gemini (via langchain-google-genai)
- Uvicorn

## Next Steps

- Integrate LangChain Supervisor Agent
- Implement SubAgents (GoogleMap, Calendar, Telephone, Research)
- Connect to Fonoster server for telephony

