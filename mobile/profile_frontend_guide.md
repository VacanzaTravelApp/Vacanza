# Frontend Integration Guide — Profile Screen

Base URL: `{API_BASE_URL}/users/me`
Authentication: All endpoints require `Authorization: Bearer <firebase_id_token>` header.

---

## Profile Screen — UI Layout

The profile screen consists of the following sections. Each section maps to a specific endpoint.

### Header Area
Source: GET /users/me/profile

The user sees:
- Profile photo (from profileImageUrl, show placeholder if null)
- Display name (large text, prominent)
- Email (smaller text, below display name)
- Join date (formatted, e.g. "Member since January 2026")

### Basic Info Section
Source: GET /users/me/profile

The user sees a card/section with:
- First name, middle name, last name
- Preferred name (if set, note that this is used as display name)
- Country
- Birth date (formatted)
- Gender

All fields above are editable. Tapping "Edit Profile" opens an edit form.
On save, call PUT /users/me/profile with only the changed fields.

### Travel Preferences Section
Source: GET /users/me/preferences

The user sees a card/section with:
- Travel style (single select)
- Favorite categories (multi-select chips, e.g. "museum", "park")
- Activity level (single select)
- Cuisine preferences (multi-select chips)
- Dietary restrictions / allergens (multi-select chips — important for AI)
- Accessibility needs (multi-select chips)
- Trip pace (single select)
- Accommodation type (single select)
- Transport preference (single select)
- Daily budget + currency
- Preferred language
- Spoken languages (multi-select)

All fields are editable. Tapping "Edit Preferences" opens an edit form.
On save, call PUT /users/me/preferences with only the changed fields.

### Gamification Section
Source: GET /users/me/gamification

The user sees:
- Level title and number (e.g. "Traveler — Level 3")
- XP progress bar (filled to xpProgressPercent, show "X XP to next level")
- Stat cards in a row: Places visited, Badges earned, Days active
- Badge grid: each badge shows icon (mapped from key), title, description
  - Earned badges: highlighted / full color
  - Unearned badges: grayed out / locked appearance

### Travel Statistics Section
Source: GET /users/me/stats

The user sees:
- Total places visited (number)
- Last visited place name and date
- Favorite category
- Number of different categories explored

If the user has no check-ins, show an empty state message.

### Check-in History Section
Source: GET /users/me/checkins

The user sees a list of visited places:
- Each item shows: POI name, category, visit date
- Optionally: small map preview using latitude/longitude
- List is sorted by most recent first

If the user has no check-ins, show an empty state message.

### Account Settings
- Edit Profile button -> opens edit form, calls PUT /users/me/profile
- Edit Preferences button -> opens edit form, calls PUT /users/me/preferences
- Logout button -> handled client-side via Firebase SDK

---

## Endpoint Details

Below are the full endpoint specifications with field types and example responses.

---

## 1. User Profile

### GET /users/me/profile

Read-only fields (display only):
- `email` (String) — user's email address
- `displayName` (String) — backend-computed: preferredName if set, otherwise firstName + lastName
- `joinDate` (Instant, ISO 8601) — account creation date

Editable fields (shown in edit form):
- `firstName` (String, required on first registration)
- `middleName` (String, optional)
- `lastName` (String, required on first registration)
- `preferredName` (String, optional) — if set, becomes the displayName
- `country` (String, optional)
- `birthDate` (LocalDate, "YYYY-MM-DD", optional)
- `gender` (Enum, optional) — MALE | FEMALE | OTHER | PREFER_NOT_TO_SAY
- `profileImageUrl` (String, optional) — URL to profile photo

Hidden fields (not shown to user):
- `infoId` (UUID)
- `userId` (UUID)

Example response:

```json
{
  "infoId": "a1b2c3d4-...",
  "userId": "e5f6g7h8-...",
  "email": "user@example.com",
  "firstName": "Ahmet",
  "middleName": null,
  "lastName": "Yilmaz",
  "preferredName": "Memo",
  "displayName": "Memo",
  "country": "Turkey",
  "birthDate": "1995-03-15",
  "gender": "MALE",
  "profileImageUrl": "https://storage.example.com/photos/abc.jpg",
  "joinDate": "2026-01-15T10:30:00Z"
}
```

### PUT /users/me/profile

Partial update: only send the fields you want to change. Null/missing fields are ignored.

Example request (updating only country):

```json
{
  "country": "Germany"
}
```

Response: same structure as GET with updated values.

---

## 2. User Preferences

### GET /users/me/preferences

Travel style and interests:
- `travelStyle` (Enum) — RELAXED | ADVENTURE | LUXURY | BACKPACKER | CULTURAL
- `favoriteCategories` (List of String) — e.g. ["museum", "park", "cafe"]
- `activityLevel` (Enum) — LOW | MODERATE | HIGH
- `cuisinePreferences` (List of String) — e.g. ["turkish", "italian"]

Trip preferences:
- `preferredClimate` (Enum) — TROPICAL | TEMPERATE | COLD | DESERT | ANY
- `tripPace` (Enum) — SLOW | MODERATE | FAST
- `accommodationType` (Enum) — HOTEL | HOSTEL | AIRBNB | RESORT | CAMPING
- `transportPreference` (Enum) — WALKING | PUBLIC_TRANSPORT | CAR | BICYCLE | ANY

Constraints and accessibility:
- `dietaryRestrictions` (List of String) — allergens, e.g. ["gluten", "peanuts"]
- `accessibilityNeeds` (List of String)
- `avoidCategories` (List of String) — e.g. ["nightclub"]

Budget details:
- `dailyBudget` (BigDecimal) — e.g. 150.00
- `budgetCurrency` (String, 3 chars) — e.g. "EUR"
- `splurgeCategories` (List of String) — categories user is willing to spend more on

Language:
- `preferredLanguage` (String) — e.g. "en"
- `spokenLanguages` (List of String) — e.g. ["tr", "en", "de"]

Hidden fields:
- `preferencesId` (UUID)
- `userId` (UUID)
- `createdAt` (Instant)
- `updatedAt` (Instant) — can optionally be shown as "Last updated"

All fields are editable and nullable. All List fields support multi-select.

Example response:

```json
{
  "preferencesId": "...",
  "userId": "...",
  "travelStyle": "ADVENTURE",
  "favoriteCategories": ["museum", "park", "cafe"],
  "activityLevel": "HIGH",
  "cuisinePreferences": ["turkish", "italian"],
  "preferredClimate": "TEMPERATE",
  "tripPace": "MODERATE",
  "accommodationType": "HOTEL",
  "transportPreference": "WALKING",
  "dietaryRestrictions": ["gluten", "peanuts"],
  "accessibilityNeeds": [],
  "avoidCategories": ["nightclub"],
  "dailyBudget": 150.00,
  "budgetCurrency": "EUR",
  "splurgeCategories": ["restaurant"],
  "preferredLanguage": "en",
  "spokenLanguages": ["tr", "en", "de"],
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": "2026-03-01T08:00:00Z"
}
```

### PUT /users/me/preferences

Partial update: only send the fields you want to change.

Response: same structure as GET with updated values.

---

## 3. Gamification

### GET /users/me/gamification

Level and XP:
- `roleText` (String) — level title, e.g. "Traveler"
- `levelText` (String) — level label, e.g. "Level 3"
- `totalXp` (int) — total XP earned
- `xpProgressPercent` (int, 0-100) — progress bar fill percentage
- `xpToNextLevel` (int) — XP remaining for next level (0 if max level)

Stats (array of stat cards):
- `stats` — list of `{ label: String, value: long }`
  - "Places" — total check-ins
  - "Badges" — earned badge count
  - "Days" — days since registration

Badges (array of badge items):
- `badges` — list of badge objects:
  - `id` (Long) — hidden
  - `title` (String) — badge name, e.g. "Foodie"
  - `key` (String) — frontend maps this to an icon asset, e.g. "foodie"
  - `description` (String, nullable) — badge explanation text
  - `earned` (boolean) — true = highlight/unlocked, false = grayed/locked

Other:
- `badgesSectionTitle` (String) — section header text

Example response:

```json
{
  "roleText": "Traveler",
  "levelText": "Level 3",
  "xpProgressPercent": 65,
  "xpToNextLevel": 150,
  "totalXp": 350,
  "badgesSectionTitle": "Achievement Badges",
  "stats": [
    { "label": "Places", "value": 12 },
    { "label": "Badges", "value": 3 },
    { "label": "Days", "value": 45 }
  ],
  "badges": [
    {
      "id": 1,
      "title": "First Step",
      "key": "first_step",
      "description": "Complete your first check-in",
      "earned": true
    },
    {
      "id": 2,
      "title": "Foodie",
      "key": "foodie",
      "description": "Check in at 3 restaurants or cafes",
      "earned": false
    }
  ]
}
```

---

## 4. Check-in History

### GET /users/me/checkins

Returns array of check-in objects, sorted by most recent first.

Each check-in object:
- `checkInId` (UUID) — hidden
- `poiId` (UUID) — hidden, use for navigation to POI detail
- `poiName` (String) — place name to display
- `category` (String) — category label or icon
- `checkedInAt` (Instant) — visit date/time
- `latitude` (Double) — for map marker
- `longitude` (Double) — for map marker

Example response:

```json
[
  {
    "checkInId": "...",
    "poiId": "...",
    "poiName": "Topkapi Palace",
    "category": "museum",
    "checkedInAt": "2026-03-05T14:30:00Z",
    "latitude": 41.0115,
    "longitude": 28.9833
  },
  {
    "checkInId": "...",
    "poiId": "...",
    "poiName": "Grand Bazaar",
    "category": "landmark",
    "checkedInAt": "2026-03-04T11:00:00Z",
    "latitude": 41.0106,
    "longitude": 28.9680
  }
]
```

---

## 5. Travel Statistics

### GET /users/me/stats

- `visitedPoisCount` (long) — total places visited
- `lastVisitDate` (Instant, nullable) — most recent check-in date
- `lastVisitPoiName` (String, nullable) — most recent check-in place name
- `favoriteCategory` (String, nullable) — most frequently visited category
- `distinctCategoriesCount` (long) — number of different categories explored

All nullable fields are null when the user has no check-ins.

Example response:

```json
{
  "visitedPoisCount": 12,
  "lastVisitDate": "2026-03-05T14:30:00Z",
  "lastVisitPoiName": "Topkapi Palace",
  "favoriteCategory": "museum",
  "distinctCategoriesCount": 5
}
```

---

## 6. Auto Check-in (Reference)

### POST /users/me/checkins/auto

Request body:
- `latitude` (Double, required)
- `longitude` (Double, required)
- `candidatePoiIds` (List of UUID, required)

Response:
- `checkInId` (UUID, null if failed)
- `poiId` (UUID, null if failed)
- `poiName` (String, null if failed)
- `checkedInAt` (Instant, null if failed)
- `message` (String) — status message
- `success` (boolean)
- `gamificationTriggered` (boolean) — true if XP/badge evaluation was fired

---

## 7. Account Settings

- Edit profile: PUT /users/me/profile
- Change preferences: PUT /users/me/preferences
- Logout: handled client-side via Firebase SDK

---

## Endpoint Summary

- GET /users/me/profile — get user profile
- PUT /users/me/profile — update user profile
- GET /users/me/preferences — get travel preferences
- PUT /users/me/preferences — update travel preferences
- GET /users/me/gamification — get gamification profile
- GET /users/me/checkins — get check-in history
- POST /users/me/checkins/auto — create auto check-in
- GET /users/me/stats — get travel statistics
- POST /auth/register — register (create profile)
- GET /auth/login — login / session restore
- GET /auth/me — get authenticated user info
