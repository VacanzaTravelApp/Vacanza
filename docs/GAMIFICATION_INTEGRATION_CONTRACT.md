# Gamification Integration Contract

## 1. Overview

This document defines the integration contract between **Vacanza Mobile** and the **Backend** for the Gamification feature. It is intended for Backend engineers, DevOps, and QA to verify that the gamification endpoint, response schema, and authentication behavior are compatible with what mobile expects. Mobile expectations are derived from the monorepo; backend must implement accordingly.

---

## 2. Base URL & Ports

- **Mobile base URL:** `http://165.232.69.83:9002` (configured in `mobile/lib/core/network/app_dio.dart`)
- **Backend internal port:** `8080` (configured in `backend/src/main/resources/application.yaml`)
- **Context path:** None (not configured in backend)
- **Port 9002 → 8080 mapping:** *Assumption / External environment* — no Docker Compose or proxy config found in the repo. This mapping is managed externally on the hosting environment. Paths pass through 1:1 with no rewriting.

---

## 3. Authentication

- All gamification requests include the header `Authorization: Bearer <Firebase ID Token>`.
- The token is attached automatically by a network interceptor on the mobile side.
- **If the server is reachable but the token is missing/invalid/expired**, expect HTTP **401**. Mobile may refresh the token once and retry (depending on interceptor rules).
- **If the server is NOT reachable** (connection refused, DNS failure, timeout, `status=null`), this is a **network/infrastructure issue** — not an endpoint or DTO problem. Check: port mapping, container status, firewall rules.
- If backend returns **403**, mobile treats it as an authorization error (profile shows error state with retry option).

---

## 4. Endpoints

### GET /gamification/profile

| Item | Value |
|------|-------|
| Method | GET |
| Path | `/gamification/profile` |
| Auth | Required (`Authorization: Bearer <token>`) |
| Request body | None |
| Query params | None |
| Success | HTTP 200 with JSON body |

### Check-in → Gamification Refresh

The `POST /checkins/auto` response includes a boolean field `gamificationTriggered`. When a new check-in is created (`checkInId` present) and `gamificationTriggered` is `true`, mobile automatically re-fetches `GET /gamification/profile` to update the UI. No additional endpoint is needed for this.

---

## 5. Response Contract

### Gamification Profile (root object)

| Field | Type | Notes |
|-------|------|-------|
| `roleText` | string | Displayed as-is (e.g. "Urban Adventurer") |
| `levelText` | string | Displayed as-is (e.g. "Level 5") |
| `totalXp` | int | Total accumulated XP |
| `xpProgressPercent` | int | 0–100, mobile clamps to this range |
| `xpToNextLevel` | int | XP remaining to next level |
| `badgesSectionTitle` | string | Section heading for badge grid |
| `stats` | array | List of stat items (see below) |
| `badges` | array | List of badge items (see below) |

### Stat item (inside `stats` array)

| Field | Type |
|-------|------|
| `label` | string |
| `value` | int |

### Badge item (inside `badges` array)

| Field | Type | Notes |
|-------|------|-------|
| `id` | int | Unique identifier |
| `title` | string | Display name |
| `key` | string | Used for icon mapping (see Section 6) |
| `earned` | boolean | `true` = colored, `false` = greyed out |

### Example Response (Plain JSON)

> {
>   "roleText": "Urban Adventurer",
>   "levelText": "Level 5",
>   "totalXp": 1225,
>   "xpProgressPercent": 45,
>   "xpToNextLevel": 500,
>   "badgesSectionTitle": "Achievement Badges",
>   "stats": [
>     { "label": "Places", "value": 12 },
>     { "label": "Countries", "value": 3 }
>   ],
>   "badges": [
>     { "id": 1, "title": "Speed Demon", "key": "speed", "earned": true },
>     { "id": 2, "title": "Food Explorer", "key": "foodie", "earned": false }
>   ]
> }

All field names are **case-sensitive** and must match exactly. Missing or `null` fields are handled with safe defaults on mobile (empty strings, zeros, empty arrays), but all fields should be present for full UI rendering.

---

## 6. Badge Key List

Mobile maps the following `key` values to specific icons. These should be present in backend seed data:

| Key | Icon meaning |
|-----|-------------|
| `speed` | Lightning bolt |
| `foodie` | Restaurant |
| `culture` | Museum |
| `nature` | Park / tree |
| `explorer` | Compass |

Unknown keys are **safe** — they render with a generic trophy icon and default colors. However, the five keys above are recommended for the initial seed to ensure the intended visual presentation.

---

## 7. Compatibility Checklist

**Reachability**
- [ ] Server reachable on `http://165.232.69.83:9002`
- [ ] Unauthenticated `GET /gamification/profile` returns **401** (not connection refused)

**Authentication**
- [ ] With a valid Firebase token, `GET /gamification/profile` returns **200**

**Response contract**
- [ ] Response is a JSON object containing all fields listed in Section 5
- [ ] Field names match exactly (case-sensitive)
- [ ] `stats` and `badges` are arrays (empty array `[]` is acceptable)
- [ ] `xpProgressPercent` is an integer between 0 and 100
- [ ] Badge items include `key` field with seed values from Section 6

**Check-in integration**
- [ ] `POST /checkins/auto` response includes `gamificationTriggered` boolean

---

## 8. Known Failure Modes

| Symptom | Likely cause | Category |
|---------|-------------|----------|
| HTTP **401** | Token missing, invalid, or expired | Auth / token issue — server is reachable |
| Connection refused / `status=null` / timeout | Container not running, port not mapped, firewall blocking | Infrastructure / network — not an endpoint or DTO problem |
| HTTP **404** | Endpoint not deployed, path mismatch, or wrong base URL routing (proxy/path rewrite) | Backend deployment / routing |
| HTTP **200** but UI shows defaults | Field names don't match contract (case mismatch, missing fields) | DTO contract mismatch |
