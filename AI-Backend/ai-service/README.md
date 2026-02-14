# Vacanza AI Service

Python microservice for AI-powered features (FastAPI + LangChain + OpenAI).

## Setup

1. Copy the environment template and add your OpenAI API key:
   - **macOS / Linux:** `cp .env.example .env`
   - **Windows:** `copy .env.example .env`
   - Edit `.env` and set `OPENAI_API_KEY`

### macOS / Linux

```bash
cd AI-Backend/ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### Windows (PowerShell)

```powershell
cd AI-Backend\ai-service
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Windows (Command Prompt)

```cmd
cd AI-Backend\ai-service
python -m venv .venv
.venv\Scripts\activate.bat
pip install -r requirements.txt
```

## Run

### macOS / Linux

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Windows (PowerShell / Command Prompt)

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

> **Note:** The `uvicorn` command is the same on all platforms once the virtual environment is activated.

## Endpoints

- `GET /health` — Health check (returns 200)
