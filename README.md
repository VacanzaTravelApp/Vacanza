# Vacanza — AI-Powered Travel Planning Platform

Vacanza is a full-stack travel planning platform that generates personalized multi-day trip itineraries using AI. Users describe their destination, travel style, and preferences in natural language; the system produces a route on an interactive map complete with waypoints, weather forecasts, hotel suggestions, live event recommendations, and activity booking options.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [API Integrations](#api-integrations)
- [Getting Started](#getting-started)
- [Environment Variables](#environment-variables)

---

## Overview

A user opens the app, types something like *"3-day trip to Rome in May, I like history and local food"*, and Vacanza:

1. Extracts preferences from the message using an LLM
2. Generates a day-by-day itinerary with scored, diverse POIs
3. Renders the route on a Mapbox map with waypoint markers
4. Attaches real-time weather forecasts, hotel suggestions, and nearby events
5. Lets the user adjust the plan via follow-up chat messages
6. Exports the final itinerary to a calendar (ICS) or shares it

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Clients                              │
│   Flutter Mobile (iOS/Android)    React Web App             │
│   React Admin Dashboard                                     │
└─────────────┬───────────────────────────┬───────────────────┘
              │ REST / SSE                │ REST / SSE
┌─────────────▼───────────────────────────▼───────────────────┐
│              Spring Boot Backend  (Java 17)                  │
│  Auth · Routes · POI Search · Bookings · Events · Weather   │
│  Gamification · Check-ins · User Preferences · Admin        │
└──────────┬──────────────────────────────┬────────────────────┘
           │ Internal HTTP                │ External APIs
┌──────────▼──────────┐    ┌─────────────▼────────────────────┐
│  FastAPI AI Service │    │  Mapbox · Foursquare · OpenMeteo  │
│   (Python)          │    │  Ticketmaster · SerpApi (flights  │
│  GPT-4o-mini · RAG  │    │  & hotels) · Viator · Frankfurter │
│  pgvector embeddings│    └──────────────────────────────────┘
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│   PostgreSQL + pgvector                                      │
│  (shared between Spring Boot and AI service)                 │
└─────────────────────┘
```

---

## Features

### AI Chat & Route Generation
- Conversational interface: users describe their trip in plain language (English or Turkish)
- LLM extracts destination, travel dates, budget, interests, and pace from free-text input
- Multi-day itinerary generated with ordered, time-slotted waypoints
- Follow-up messages allow incremental adjustments (add a day, swap a POI, change pace)
- Itinerary adjustment logs track every AI-driven change with severity classification

### Interactive Map
- Mapbox-powered map with animated route lines and custom POI markers
- Draggable route bottom sheet with tabbed Plan / Events / Weather views
- Draw-area mode: users draw a polygon on the map to discover POIs inside it
- AR mode (mobile): camera overlay with compass-based directional POI markers
- Route mini-pill for quick day navigation

### Points of Interest (POI)
- Multi-source POI search combining Foursquare and Mapbox geocoding
- Scoring pipeline: preference matching, category diversity, dwell time rules, feedback signal
- Personalized selection based on user travel style, budget, and past interactions
- User feedback (thumbs up/down) per waypoint fed back into future recommendations
- Saved POIs panel for bookmarked locations

### Events
- Live event recommendations from Ticketmaster integrated into route cards
- Dual-API routing: EU markets (`app.ticketmaster.eu`) for DE, AT, NL, DK, BE, NO, CH, ES, SE, FI, PL; US Discovery API for all other destinations
- Geo-coordinate fallback for countries with limited Ticketmaster inventory (IT, FR, TR, etc.)
- AI re-ranks fetched events against user preferences before display
- Day-level filtering: events shown for the specific trip day the user is viewing

### Weather
- OpenMeteo daily and day-part forecasts for each trip day
- Weather summary embedded in the route card and used by AI to adjust itinerary suggestions
- Weather alert scheduler for automated condition monitoring

### Bookings
- Hotel search via SerpApi with airport/city autocomplete
- Viator activity pricing for waypoints (attraction booking links)
- Flight search with SerpApi Google Flights integration
- Hotel card attached per route with check-in/check-out dates

### User Profiles & Preferences
- Structured preferences: travel style, budget, transport, climate, activity level, trip pace
- AI-extracted preferences from chat history stored as key-value pairs with confidence scores
- Preference evolution: chat messages continuously refine the user profile
- Category affinity scores updated from interaction and feedback signals

### Gamification
- Points, levels, and badges awarded for check-ins, route completions, and engagement
- Level definitions with XP thresholds and badge unlock conditions
- User gamification profile with leaderboard-ready stats

### Check-ins
- Location-based check-in to visited waypoints (GPS or manual)
- Check-in history linked to trips and POIs
- XP awarded on check-in via gamification service

### Trip Calendar & ICS Export
- Trip calendar events stored per route day
- ICS file export for import into Google Calendar, Apple Calendar, Outlook
- Calendar modal on web for viewing/editing trip dates

### Travel Stats
- Aggregate stats per user: countries visited, total distance, trip count
- Stats surfaced on profile screen

### Currency
- Live exchange rates via Frankfurter API
- Used in booking and budget display

### Admin Dashboard (React)
- User management with role assignment
- System monitoring: API health, error rates, response times per integration
- Analytics page with usage metrics
- Separate authentication flow from the main app

### Security
- Firebase Authentication (email/password + Google OAuth)
- JWT validation via Firebase Admin SDK on every backend request
- Dev profile with relaxed CORS for local development
- Separate `SecurityConfig` for dev vs. production environments

---

## Tech Stack

### Mobile (iOS & Android)
| Layer | Technology |
|---|---|
| Framework | Flutter 3 / Dart |
| State management | flutter_bloc + Cubit |
| Map | Mapbox Maps Flutter SDK |
| HTTP | Dio |
| Auth | Firebase Auth |
| AR | ar_flutter_plugin_engine + flutter_compass + camera |
| Storage | shared_preferences + flutter_secure_storage |
| Calendar export | ICS generation + open_filex |

### Web App
| Layer | Technology |
|---|---|
| Framework | React 19 |
| Build tool | Vite |
| UI library | Ant Design 6 |
| Map | Mapbox GL JS + react-map-gl |
| Draw tools | @mapbox/mapbox-gl-draw |
| HTTP | Axios |
| State | TanStack Query |
| Auth | Firebase JS SDK |

### Backend (Spring Boot)
| Layer | Technology |
|---|---|
| Language | Java 17 |
| Framework | Spring Boot 3.5 |
| Web / Async | Spring WebFlux (WebClient) + Spring MVC |
| Database | PostgreSQL via Spring Data JPA / Hibernate |
| Auth | Firebase Admin SDK + custom token filter |
| Cache | Caffeine |
| Realtime | Server-Sent Events (SSE) for streaming AI responses |
| Containerization | Docker (multi-stage Maven build) |

### AI Service
| Layer | Technology |
|---|---|
| Language | Python 3.11+ |
| Framework | FastAPI + Uvicorn |
| LLM | OpenAI GPT-4o-mini via LangChain |
| Embeddings | pgvector + PostgreSQL for RAG |
| ORM | SQLAlchemy |
| Retry | Tenacity |

### Infrastructure
| Component | Technology |
|---|---|
| Primary database | PostgreSQL (shared) |
| Vector search | pgvector extension |
| Containerization | Docker + Docker Compose |

---

## Project Structure

```
Vacanza/
├── backend/                    # Spring Boot backend (Java 17)
│   └── src/main/java/com/vacanza/backend/
│       ├── controller/         # REST endpoints (25+ controllers)
│       ├── service/            # Business logic layer
│       ├── integration/        # External API clients (TM, Foursquare, Mapbox, etc.)
│       ├── entity/             # JPA entities
│       ├── dto/                # Request/response DTOs
│       ├── config/             # WebClient, Security, Firebase config
│       ├── security/           # Firebase token filter
│       ├── scheduler/          # Background jobs (weather alerts, cache cleanup)
│       └── util/               # Helpers (country parser, etc.)
│
├── AI-Backend/
│   └── ai-service/             # FastAPI AI service (Python)
│       └── app/
│           ├── api/routes/     # Endpoints: chat, events, AI, conversations
│           ├── services/       # chat, embedding, event recommendation, moderation
│           └── core/           # Settings, logging
│
├── mobile/                     # Flutter app (iOS + Android)
│   └── lib/
│       └── features/
│           ├── ai/             # Chat screen, route cards, AI API client
│           ├── map/            # Mapbox map, route sheet, draw area, AR
│           ├── auth/           # Login, register, Firebase auth BLoC
│           ├── gamification/   # Badges, levels, XP
│           ├── checkin/        # GPS-based check-ins
│           ├── trip_calendar/  # Calendar view + ICS export
│           ├── booking/        # Hotel & flight search UI
│           ├── behavior/       # POI feedback, saved POIs, interactions
│           └── profile/        # User profile, preferences, stats
│
├── web/                        # React web app
│   └── src/
│       ├── features/
│       │   ├── ai/             # Chat, route panel, event cards, map interaction
│       │   └── booking/        # Booking sheet
│       ├── pages/              # MapPage, CalendarModal, auth pages
│       └── api/                # API client modules
│
├── admin_web/                  # React admin dashboard
│   └── src/pages/
│       ├── Home.jsx
│       ├── UserManagement.jsx
│       ├── Monitoring.jsx      # API health dashboard
│       └── Analytics.jsx
│
└── DB_Config/                  # PostgreSQL init scripts and setup guides
```

---

## API Integrations

| Service | Purpose | Endpoint |
|---|---|---|
| **Mapbox** | Geocoding, directions, map tiles, POI search | `api.mapbox.com` |
| **Foursquare** | POI discovery and place details | `api.foursquare.com` |
| **OpenMeteo** | Free weather forecasts (no API key required) | `api.open-meteo.com` |
| **Ticketmaster US** | Events for US, CA, GB, IE, AU, NZ, MX | `app.ticketmaster.com/discovery/v2` |
| **Ticketmaster EU** | Events for DE, AT, NL, DK, BE, NO, CH, ES, SE, FI, PL | `app.ticketmaster.eu/mfxapi/v2` |
| **SerpApi** | Hotel and flight search via Google Hotels/Flights | `serpapi.com` |
| **Viator** | Activity and attraction pricing/booking | `api.viator.com` |
| **Frankfurter** | Live currency exchange rates | `api.frankfurter.app` |
| **OpenAI** | GPT-4o-mini for itinerary generation and preference extraction | `api.openai.com` |
| **Firebase** | Authentication (email, Google OAuth) | Firebase Admin SDK |

---

## Getting Started

### Prerequisites

- Java 17
- Maven 3.9+
- Flutter 3.x
- Python 3.11+
- PostgreSQL 15+ with pgvector extension
- Docker (optional, for containerized setup)
- Node.js 20+ (for web and admin)

### 1. Database

```bash
# Create databases
psql -U postgres -c "CREATE DATABASE vacanza;"
psql -U postgres -c "CREATE DATABASE vacanza_ai;"

# Enable pgvector
psql -U postgres -d vacanza_ai -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

See `DB_Config/` for the full initialization scripts.

### 2. AI Service

```bash
cd AI-Backend/ai-service
python -m venv venv && source venv/bin/activate
pip install -r requirements.txt

# Copy and fill in .env
cp .env.example .env

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Backend

```bash
cd backend
# Copy and fill in environment variables (see section below)
./mvnw spring-boot:run -Dspring-boot.run.profiles=dev
```

### 4. Web App

```bash
cd web
npm install
npm run dev     # runs on http://localhost:9002
```

### 5. Admin Dashboard

```bash
cd admin_web
npm install
npm run dev
```

### 6. Mobile

```bash
cd mobile
flutter pub get
flutter run
```

### Docker (Backend only)

```bash
docker build -t vacanza-backend .
docker run -p 8080:8080 --env-file .env vacanza-backend
```

---

## Environment Variables

### Backend (`backend/src/main/resources/application.yaml` + env)

| Variable | Description |
|---|---|
| `SPRING_DATASOURCE_URL` | PostgreSQL JDBC URL |
| `SPRING_DATASOURCE_USERNAME` | DB username |
| `SPRING_DATASOURCE_PASSWORD` | DB password |
| `MAPBOX_ACCESS_TOKEN` | Mapbox API key |
| `FOURSQUARE_API_KEY` | Foursquare Places API key |
| `TICKETMASTER_API_KEY` | Ticketmaster Developer API key (used for both US and EU APIs) |
| `SERPAPI_API_KEY` | SerpApi key (hotels + flights) |
| `VIATOR_API_KEY` | Viator Partner API key |
| `AI_SERVICE_BASE_URL` | URL of the FastAPI AI service (e.g. `http://localhost:8000`) |
| `FIREBASE_SERVICE_ACCOUNT` | Path or JSON content of Firebase service account credentials |

### AI Service (`.env`)

| Variable | Description |
|---|---|
| `OPENAI_API_KEY` | OpenAI API key |
| `OPENAI_MODEL` | Model name (default: `gpt-4o-mini`) |
| `DATABASE_URL` | PostgreSQL connection string for `vacanza_ai` |
