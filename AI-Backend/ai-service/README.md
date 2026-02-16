# Vacanza AI Service

Python microservice for AI-powered features (FastAPI + LangChain + OpenAI).

## Setup

1. Copy environment template:
   - **macOS / Linux:** `cp .env.example .env`
   - **Windows:** `copy .env.example .env`
2. Edit `.env` and set `OPENAI_API_KEY` and `DATABASE_URL`.

### Dependencies

```bash
cd AI-Backend/ai-service
python3 -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Run

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Endpoints

- `GET /health` — Health check
- `GET /ai/test` — OpenAI connection test

---

## Local (Docker Compose)

PostgreSQL için:

```bash
docker compose -f docker-compose.db.yml up -d
```

`.env` içinde: `DATABASE_URL=postgresql://vacanza:vacanza@localhost:5432/vacanza_ai`

---

## Server (Command Line)

### 1. PostgreSQL (pgvector)

```bash
docker run -d \
  --name vacanza-ai-postgres \
  -e POSTGRES_USER=vacanza \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=vacanza_ai_prod \
  -p 5433:5432 \
  -v ai_postgres_data:/var/lib/postgresql/data \
  pgvector/pgvector:pg16
```

### 2. pgvector extension

```bash
docker exec vacanza-ai-postgres psql -U vacanza -d vacanza_ai_prod -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

### 3. AI Service

`.env` ile: `DATABASE_URL=postgresql://vacanza:your_password@localhost:5433/vacanza_ai_prod`

```bash
# Docker ile
docker build -t vacanza-ai .
docker run -d --name vacanza-ai-service -p 8000:8000 --env-file .env vacanza-ai

# Veya uvicorn ile
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

---

## Tests

```bash
pytest tests/ -v
```
