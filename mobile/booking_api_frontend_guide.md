# UC1.8 — Booking API Frontend Integration Guide

Base URL: `http://localhost:8080` (dev) | `https://api.vacanza.com` (prod)
Auth: Bearer token required (non-dev). Dev profile allows unauthenticated access.

---

## Endpoint 1: Accommodation Search

`POST /bookings/accommodations/search`

### Request Body

```json
{
  "cityCode": "PAR",
  "checkInDate": "2025-07-01",
  "checkOutDate": "2025-07-05",
  "adults": 2,
  "budget": 200.00,
  "currency": "USD",
  "sortBy": "PRICE_ASC"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| cityCode | String | Yes | IATA city code (IST, PAR, LON, NYC) |
| checkInDate | String (YYYY-MM-DD) | Yes | |
| checkOutDate | String (YYYY-MM-DD) | Yes | Must be after checkInDate |
| adults | Integer | No | Default: 1, min: 1 |
| budget | Number | No | Max price per night. Null = no limit |
| currency | String | No | Default: "USD" |
| sortBy | String | No | PRICE_ASC, PRICE_DESC, RATING_DESC. Null = default order |

### Response (200 OK)

```json
[
  {
    "hotelName": "Hotel Le Marais",
    "hotelId": "HSPARMAR",
    "address": "15 Rue de Rivoli, Paris",
    "price": 185.50,
    "currency": "USD",
    "rating": 4.2,
    "externalBookingUrl": "https://www.booking.com/searchresults.html?ss=Hotel+Le+Marais"
  },
  {
    "hotelName": "Ibis Paris Centre",
    "hotelId": "HSPARIBC",
    "address": "22 Avenue de la Republique",
    "price": 95.00,
    "currency": "USD",
    "rating": 3.8,
    "externalBookingUrl": "https://www.booking.com/searchresults.html?ss=Ibis+Paris+Centre"
  }
]
```

| Field | Type | Always present | Notes |
|---|---|---|---|
| hotelName | String | Yes | |
| hotelId | String | Yes | Amadeus hotel ID |
| address | String | Yes | May be empty string |
| price | Number | Yes | Total price (not per night) |
| currency | String | Yes | |
| rating | Number | No | Can be null |
| externalBookingUrl | String | Yes | Opens external booking site |

---

## Endpoint 2: Transportation (Flight) Search

`POST /bookings/transportation/search`

### Request Body

```json
{
  "origin": "IST",
  "destination": "PAR",
  "departureDate": "2025-07-01",
  "returnDate": "2025-07-10",
  "adults": 1,
  "budget": 500.00,
  "currency": "USD",
  "sortBy": "PRICE_ASC"
}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| origin | String | Yes | IATA airport/city code |
| destination | String | Yes | IATA airport/city code |
| departureDate | String (YYYY-MM-DD) | Yes | |
| returnDate | String (YYYY-MM-DD) | No | Null = one-way |
| adults | Integer | No | Default: 1, min: 1 |
| budget | Number | No | Max total price. Null = no limit |
| currency | String | No | Default: "USD" |
| sortBy | String | No | PRICE_ASC, PRICE_DESC. Null = default |

### Response (200 OK)

```json
[
  {
    "carrier": "TK",
    "origin": "IST",
    "destination": "CDG",
    "departureTime": "2025-07-01T08:30:00",
    "arrivalTime": "2025-07-01T11:45:00",
    "duration": "PT3H15M",
    "price": 320.00,
    "currency": "USD",
    "stops": 0,
    "externalBookingUrl": "https://www.google.com/travel/flights?q=IST+to+CDG"
  },
  {
    "carrier": "AF",
    "origin": "IST",
    "destination": "CDG",
    "departureTime": "2025-07-01T14:00:00",
    "arrivalTime": "2025-07-01T19:30:00",
    "duration": "PT7H30M",
    "price": 245.00,
    "currency": "USD",
    "stops": 1,
    "externalBookingUrl": "https://www.google.com/travel/flights?q=IST+to+CDG"
  }
]
```

| Field | Type | Always present | Notes |
|---|---|---|---|
| carrier | String | Yes | Airline IATA code (TK, AF, LH) |
| origin | String | Yes | Departure airport IATA |
| destination | String | Yes | Arrival airport IATA |
| departureTime | String (ISO 8601) | Yes | Local time |
| arrivalTime | String (ISO 8601) | Yes | Local time |
| duration | String | Yes | ISO 8601 duration (PT3H15M) |
| price | Number | Yes | Total price |
| currency | String | Yes | |
| stops | Integer | Yes | 0 = direct |
| externalBookingUrl | String | Yes | Opens Google Flights |

---

## Error Responses

### 400 — Validation Error
```json
{
  "timestamp": "2025-07-01T12:00:00.000+00:00",
  "status": 400,
  "error": "Bad Request",
  "message": "City code is required (e.g. IST, PAR, LON)"
}
```

### 401 — Unauthorized (non-dev only)
Token missing or invalid.

### 502 — Provider Error
Amadeus API returned an error. Frontend should show "Search service temporarily unavailable" message.

---

## Frontend Notes

- **externalBookingUrl**: Open in new tab (`window.open(url, '_blank')` or `Linking.openURL(url)` on mobile)
- **Empty results**: API returns `[]` — show "No results found" in UI
- **duration format**: ISO 8601 duration. Parse with library or regex: `PT3H15M` → "3h 15m"
- **sortBy**: Send from UI dropdown. If not sent, results come in API default order
- **budget**: User enters max price, backend filters out anything above it
- **Auth header**: `Authorization: Bearer <firebase_id_token>`

## Sample curl

```bash
# Accommodation search (dev, no auth needed)
curl -X POST http://localhost:8080/bookings/accommodations/search \
  -H "Content-Type: application/json" \
  -d '{"cityCode":"PAR","checkInDate":"2025-07-01","checkOutDate":"2025-07-05","adults":2}'

# Flight search
curl -X POST http://localhost:8080/bookings/transportation/search \
  -H "Content-Type: application/json" \
  -d '{"origin":"IST","destination":"PAR","departureDate":"2025-07-01","adults":1}'
```
