# SPRINT UC1.8 — Booking Integration (Mobile / Flutter)

> **Epic:** EPIC2 — Accommodation & Transportation Integration  
> **Project:** Vacanza Mobile (Flutter)  
> **Dependencies:** UC1.1 (Auth), Backend UC1.8 tasks complete  
> **Contract:** [`booking_api_frontend_guide.md`](booking_api_frontend_guide.md)

---

## 1 · Overview

UC1.8 adds **hotel and flight search** to the Vacanza mobile app.  
Users tap a Booking icon on the Home/Map screen → a bottom sheet opens with three states:

| State | Purpose |
|---|---|
| **Search** | Choose Hotels or Flights, enter parameters, submit |
| **Results** | Display backend results as cards, open external booking URL |
| **Filters** | Adjust budget + sort, apply/reset, re-run search |

### Definition of "Done"

- User can search hotels and flights from the map screen.
- Results render with all backend fields (nullable-safe).
- Filters re-run the search with updated parameters.
- External booking URLs open in the device browser.
- Errors (400 / 401 / 502 / network) show user-friendly messages with retry.
- Empty results show a clear "No results" state.
- All repository + state + utility tests pass.

---

## 2 · Backend ↔ Mobile Contract Summary

> Source of truth: [`booking_api_frontend_guide.md`](booking_api_frontend_guide.md)

### 2.1 Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/bookings/accommodations/search` | POST | Hotel search |
| `/bookings/transportation/search` | POST | Flight search |

### 2.2 Auth

```
Authorization: Bearer <firebase_id_token>
```

Handled by the existing `JwtInterceptor` on the shared `Dio` instance. No new auth work required.

**401 behavior (existing in repo):** `JwtInterceptor` force-refreshes the Firebase ID token and retries the request once. If the retry still returns 401, the interceptor calls `_forceLogout()` — clears the session, signs out of Firebase, and navigates to the login screen. The booking layer does **not** need to handle 401 itself; the interceptor resolves or logs out before `DioException` reaches the repository.

Dev profile allows unauthenticated access.

### 2.3 Accommodation Search

**Request:**

```json
{
  "cityCode": "PAR",          // Required — IATA city code
  "checkInDate": "2025-07-01", // Required — YYYY-MM-DD
  "checkOutDate": "2025-07-05",// Required — YYYY-MM-DD, after checkIn
  "adults": 2,                 // Optional — default 1, min 1
  "budget": 200.00,            // Optional — max price, null = no limit
  "currency": "USD",           // Optional — default "USD"
  "sortBy": "PRICE_ASC"        // Optional — PRICE_ASC | PRICE_DESC | RATING_DESC
}
```

**Response `200 OK`:** `List<AccommodationOption>`

| Field | Type | Nullable | Notes |
|---|---|---|---|
| hotelName | String | No | |
| hotelId | String | No | Amadeus hotel ID |
| address | String | No | May be empty string |
| price | double | No | Total price |
| currency | String | No | |
| rating | double | **Yes** | Can be `null` |
| externalBookingUrl | String | No | Opens Booking.com |

### 2.4 Transportation Search

**Request:**

```json
{
  "origin": "IST",             // Required — IATA code
  "destination": "PAR",        // Required — IATA code
  "departureDate": "2025-07-01",// Required — YYYY-MM-DD
  "returnDate": "2025-07-10",  // Optional — null = one-way
  "adults": 1,                 // Optional — default 1, min 1
  "budget": 500.00,            // Optional — max price, null = no limit
  "currency": "USD",           // Optional — default "USD"
  "sortBy": "PRICE_ASC"        // Optional — PRICE_ASC | PRICE_DESC
}
```

**Response `200 OK`:** `List<TransportOption>`

| Field | Type | Nullable | Notes |
|---|---|---|---|
| carrier | String | No | Airline IATA code |
| origin | String | No | Departure airport |
| destination | String | No | Arrival airport |
| departureTime | String | No | ISO 8601 local datetime |
| arrivalTime | String | No | ISO 8601 local datetime |
| duration | String | No | ISO 8601 duration (`PT3H15M`) |
| price | double | No | Total price |
| currency | String | No | |
| stops | int | No | 0 = direct |
| externalBookingUrl | String | No | Opens Google Flights |

### 2.5 Error Responses

| Status | Meaning | Mobile Action |
|---|---|---|
| 400 | Validation error (missing/invalid field) | Show `message` from response body |
| 401 | Unauthorized (token missing/expired) | Handled by `JwtInterceptor`: auto-refresh + retry, then force logout if still 401. Booking layer receives this only if interceptor's retry also fails (edge case — user is already being logged out). |
| 502 | Amadeus provider error | Show "Search service temporarily unavailable" |
| Timeout / Network | Connection failure | Show network error + retry |

### 2.6 Sort Criteria Mapping

| UI Label | API Value | Available for |
|---|---|---|
| Price: Low → High | `PRICE_ASC` | Hotels, Flights |
| Price: High → Low | `PRICE_DESC` | Hotels, Flights |
| Rating: High → Low | `RATING_DESC` | Hotels only |

---

## 3 · Task Execution Plan

### File Structure Preview

All new files live under `lib/features/booking/`:

```
lib/features/booking/
├── data/
│   ├── api/
│   │   └── booking_api_client.dart
│   ├── models/
│   │   ├── accommodation_search_request.dart
│   │   ├── accommodation_option.dart
│   │   ├── transport_search_request.dart
│   │   ├── transport_option.dart
│   │   └── sort_criteria.dart
│   └── repositories/
│       └── booking_repository.dart
└── presentation/
    ├── cubit/
    │   ├── booking_cubit.dart
    │   └── booking_state.dart
    ├── screens/           (empty — entry is bottom sheet)
    └── widgets/
        ├── booking_bottom_sheet.dart
        ├── booking_search_view.dart
        ├── booking_results_view.dart
        ├── booking_filters_view.dart
        ├── hotel_card.dart
        ├── flight_card.dart
        └── booking_empty_state.dart
```

Modified files:

```
lib/features/map/presentation/widgets/home_map/action_bar.dart          [MODIFY]
lib/features/map/presentation/widgets/home_map/home_map_scaffold.dart   [MODIFY]
lib/main.dart                                                           [MODIFY]
pubspec.yaml                                                            [MODIFY]
```

---

### UC1.8-MOB1 — Add Booking Entry Point on Home/Map

#### Goal

Add a "Booking" icon to the existing right-side action stack on the Home/Map screen. On tap, open the Booking bottom sheet (default state: Search). Support close via backdrop tap + close button. Do not change the existing map layout/UI.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| Existing `ActionBar` widget (`lib/features/map/presentation/widgets/home_map/action_bar.dart`) | New `Icons.luggage` button in action bar |
| Existing `HomeMapScaffold` widget (`lib/features/map/presentation/widgets/home_map/home_map_scaffold.dart`) | `showModalBottomSheet` call opening `BookingBottomSheet` |

#### Implementation Plan

- **`action_bar.dart`** `[MODIFY]` — Add a new callback `VoidCallback onOpenBooking` to `ActionBar`.
  - Add an `ActionIconButton` with `Icons.luggage` tooltip `'Booking'` between the Filter POIs button and the 2D/3D button.
  - Wire `onPressed: onOpenBooking`.
- **`home_map_scaffold.dart`** `[MODIFY]` — Pass an `onOpenBooking` callback to `ActionBar`.
  - In the callback, call `showModalBottomSheet(...)` with:
    - `isScrollControlled: true`
    - `isDismissible: true` (backdrop close)
    - `enableDrag: true`
    - `backgroundColor: Colors.transparent`
    - `builder: (_) => BookingBottomSheet()`
  - Wrap `BookingBottomSheet` with `BlocProvider<BookingCubit>` created from context.
- **`booking_bottom_sheet.dart`** `[NEW]` — Stateless shell widget at `lib/features/booking/presentation/widgets/`.
  - `DraggableScrollableSheet` wrapper with close button (`IconButton` top-right).
  - Renders child from `BookingCubit` state: Search / Results / Filters view.

#### Walkthrough

1. Launch app → log in → land on Home/Map.
2. Observe the right-side action bar now has a **luggage icon** between Filter POIs and 2D/3D.
3. Tap the luggage icon → bottom sheet slides up showing the Search form.
4. Tap backdrop (outside sheet) → sheet dismisses.
5. Re-open sheet → tap X button → sheet dismisses.
6. Map is fully interactive underneath (pan, zoom) when sheet is closed.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Rapid double-tap on booking icon | `showModalBottomSheet` is modal; second tap is a no-op |
| Backdrop dismiss while loading | Cubit continues; re-opening shows fresh Search state |
| Keyboard open when sheet opens | Sheet should not be obscured — `isScrollControlled: true` handles this |

#### Definition of Done

- [ ] Luggage icon visible in action bar on Home/Map
- [ ] Tap opens bottom sheet with Search view as default
- [ ] Backdrop tap dismisses sheet
- [ ] Close button dismisses sheet
- [ ] No changes to existing map layout/behavior
- [ ] No compile errors

---

### UC1.8-MOB2 — Booking Sheet Flow Controller (Search / Results / Filters)

#### Goal

Implement a single `BookingCubit` to manage booking type (Hotels / Flights), view state (Search / Results / Filters), and loading / empty / error states. "Apply filters" re-runs search; "Reset filters" clears budget and resets sort to default.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| User actions (search, filter, retry) | `BookingState` emissions driving UI |
| `BookingRepository` (MOB5) | State transitions: Search → Loading → Results / Empty / Error |

#### Implementation Plan

- **`booking_state.dart`** `[NEW]` — Sealed state hierarchy (follows existing `GamificationState` pattern with typed payloads):

```dart
enum BookingType { hotels, flights }

sealed class BookingState {
  const BookingState();
}

class BookingSearch extends BookingState {
  final BookingType type;
  const BookingSearch({this.type = BookingType.hotels});
}

class BookingLoading extends BookingState {
  final BookingType type;
  const BookingLoading({required this.type});
}

class BookingHotelResults extends BookingState {
  final List<AccommodationOption> results;
  final String summary;        // "PAR · Jul 1–5 · 2 adults"
  final double? budget;
  final SortCriteria? sortBy;
  const BookingHotelResults({...});
}

class BookingFlightResults extends BookingState {
  final List<TransportOption> results;
  final String summary;
  final double? budget;
  final SortCriteria? sortBy;
  const BookingFlightResults({...});
}

class BookingEmpty extends BookingState {
  final BookingType type;
  final String summary;
  const BookingEmpty({...});
}

class BookingError extends BookingState {
  final BookingType type;
  final String message;
  const BookingError({...});
}

class BookingFilters extends BookingState {
  final BookingType type;
  final double? currentBudget;
  final SortCriteria? currentSort;
  // retain previous results for back-navigation (typed via BookingType)
  const BookingFilters({...});
}
```

> **Note:** Using separate `BookingHotelResults` and `BookingFlightResults` states avoids `List<dynamic>` and keeps results fully typed, consistent with how the repo's other sealed states hold typed payloads (e.g., `GamificationLoaded` holds `GamificationProfileDto`).

- **`booking_cubit.dart`** `[NEW]` — Extends `Cubit<BookingState>`:
  - `switchType(BookingType)` — emits `BookingSearch(type)`.
  - `searchHotels(AccommodationSearchRequest)` — emits Loading → calls repo → emits `BookingHotelResults` / Empty / Error.
  - `searchFlights(TransportSearchRequest)` — emits Loading → calls repo → emits `BookingFlightResults` / Empty / Error.
  - `openFilters()` — emits `BookingFilters` preserving current results + params.
  - `applyFilters(budget, sortBy)` — re-runs search with updated params.
  - `resetFilters()` — clears budget, resets sort to `null`, re-runs search.
  - `retry()` — re-runs last search.
  - `backToResults()` — emits previous results state from `BookingFilters`.
  - `backToSearch()` — emits `BookingSearch(currentType)`.
  - Stores last request internally for retry/filter-apply use.

#### Walkthrough

1. Open booking sheet → state is `BookingSearch(hotels)`.
2. Toggle to Flights → state emits `BookingSearch(flights)`.
3. Fill search form, tap Search → `BookingLoading` → `BookingHotelResults` or `BookingFlightResults` (or `BookingEmpty` / `BookingError`).
4. Tap filter icon in results header → `BookingFilters`.
5. Change budget to 100, tap Apply → `BookingLoading` → results with budget=100 sent.
6. Tap Reset → `BookingLoading` → results with no budget filter sent.
7. From error state, tap Retry → re-runs last search.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Search while already loading | Guard: if state is `BookingLoading`, ignore |
| Apply filters with no change | Still re-runs search (backend is idempotent) |
| Toggle type while results are shown | Goes back to `BookingSearch(newType)` |
| Repository throws `BookingException` | Catch in cubit → emit `BookingError(message)` |

#### Definition of Done

- [ ] `BookingCubit` compiles and emits correct states
- [ ] Search → Loading → Results/Empty/Error flow works
- [ ] Results states are fully typed (`BookingHotelResults` / `BookingFlightResults`)
- [ ] Filters → Apply re-runs search with new params
- [ ] Reset clears budget and sort
- [ ] Retry from error re-runs last search
- [ ] Type switching resets to Search state

---

### UC1.8-MOB3 — Create Booking Request/Response Models (DTOs)

#### Goal

Create Dart DTOs aligned to the backend contract for hotel and flight search request/response payloads, plus a `SortCriteria` enum.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| [`booking_api_frontend_guide.md`](booking_api_frontend_guide.md) contract | `AccommodationSearchRequest`, `AccommodationOption`, `TransportSearchRequest`, `TransportOption`, `SortCriteria` |

#### Implementation Plan

- **`sort_criteria.dart`** `[NEW]` at `lib/features/booking/data/models/`:

```dart
enum SortCriteria {
  priceAsc('PRICE_ASC'),
  priceDesc('PRICE_DESC'),
  ratingDesc('RATING_DESC');

  final String apiValue;
  const SortCriteria(this.apiValue);
}
```

- **`accommodation_search_request.dart`** `[NEW]`:
  - Fields: `String cityCode`, `String checkInDate`, `String checkOutDate`, `int adults`, `double? budget`, `String currency`, `SortCriteria? sortBy`.
  - `Map<String, dynamic> toJson()` method mapping fields to API keys. Omit `budget` and `sortBy` if null. Send `sortBy` as `sortBy.apiValue`.

- **`transport_search_request.dart`** `[NEW]`:
  - Fields: `String origin`, `String destination`, `String departureDate`, `String? returnDate`, `int adults`, `double? budget`, `String currency`, `SortCriteria? sortBy`.
  - `Map<String, dynamic> toJson()` — same pattern; omit nulls.

- **`accommodation_option.dart`** `[NEW]`:
  - Fields: `String hotelName`, `String hotelId`, `String address`, `double price`, `String currency`, `double? rating`, `String externalBookingUrl`.
  - `factory AccommodationOption.fromJson(Map<String, dynamic> json)`.

- **`transport_option.dart`** `[NEW]`:
  - Fields: `String carrier`, `String origin`, `String destination`, `String departureTime`, `String arrivalTime`, `String duration`, `double price`, `String currency`, `int stops`, `String externalBookingUrl`.
  - `factory TransportOption.fromJson(Map<String, dynamic> json)`.
  - `departureTime` / `arrivalTime` stored as ISO strings; UI formatting in MOB10.

- All dates stored as `String` in YYYY-MM-DD format internally.
- All DTOs use `const` constructors where possible.

#### Walkthrough

1. Write a unit test: `AccommodationSearchRequest(cityCode: 'PAR', ...).toJson()` → verify JSON keys match API spec.
2. Write a unit test: `AccommodationOption.fromJson({...})` → verify all fields populate (including `null` rating).
3. Write a unit test: `TransportOption.fromJson({...})` → verify `duration` keeps raw ISO string, `stops` is `int`.
4. Verify `SortCriteria.priceAsc.apiValue == 'PRICE_ASC'`.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| `rating` is `null` in JSON | `double? rating` — `fromJson` reads `json['rating'] as double?` |
| `address` is empty string | DTO stores as-is; UI can show fallback text |
| `budget` not provided by user | `toJson()` omits the key entirely |
| `returnDate` null (one-way) | `toJson()` omits the key |
| Unknown `sortBy` value from UI | Enum is compile-time safe; no runtime mapping issue |

#### Definition of Done

- [ ] All 5 model files created under `lib/features/booking/data/models/`
- [ ] `toJson()` output matches API contract exactly
- [ ] `fromJson()` handles all fields including nullables
- [ ] `SortCriteria` enum has correct `apiValue` strings
- [ ] Dates stored as `String` in YYYY-MM-DD format
- [ ] No compile errors

---

### UC1.8-MOB4 — Implement Booking API Calls (Dio) for Hotels + Flights Search

#### Goal

Implement POST requests to `/bookings/accommodations/search` and `/bookings/transportation/search` using the shared `Dio` instance. Handle responses and error codes.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `AccommodationSearchRequest` / `TransportSearchRequest` | `List<AccommodationOption>` / `List<TransportOption>` |
| Shared `Dio` instance (via `RepositoryProvider`) | `DioException` on 400/502/network errors |

#### Implementation Plan

- **`booking_api_client.dart`** `[NEW]` at `lib/features/booking/data/api/`:
  - Constructor takes `Dio _dio` (same pattern as `GamificationApiClient`).
  - **`Future<List<AccommodationOption>> searchAccommodations(AccommodationSearchRequest request)`**:
    - `_dio.post('/bookings/accommodations/search', data: request.toJson())`
    - Parse `response.data` as `List` → map each to `AccommodationOption.fromJson(item)`.
    - Log with `[BOOKING_API]` tag: URL, status, result count.
  - **`Future<List<TransportOption>> searchFlights(TransportSearchRequest request)`**:
    - `_dio.post('/bookings/transportation/search', data: request.toJson())`
    - Same parse + log pattern.
  - Auth header is automatically attached by `JwtInterceptor` — **no manual Bearer token handling**.
  - 401 is handled entirely by `JwtInterceptor` (refresh + retry or force logout). The API client never sees a 401 under normal flow.
  - On other `DioException` types, let them propagate to the repository layer (MOB5).

#### Walkthrough

1. With backend running, manually construct a request in a test/debug screen.
2. Call `searchAccommodations` with `cityCode: 'PAR'` → verify response is parsed into `List<AccommodationOption>`.
3. Call `searchFlights` with `origin: 'IST', destination: 'PAR'` → verify `List<TransportOption>`.
4. Send invalid request (missing `cityCode`) → verify `DioException` with `statusCode == 400` propagates.
5. Stop backend → send request → verify timeout `DioException`.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Response is `[]` (empty list) | Returns `List.empty()` — not an error |
| Response data is not a List | Throw `FormatException('Expected List')` |
| 400 bad request | `DioException` with `response.statusCode == 400` propagates |
| 401 unauthorized | Handled by `JwtInterceptor` before reaching this layer (refresh + retry or logout) |
| 502 provider error | `DioException` with `statusCode == 502` propagates |
| Network timeout | `DioExceptionType.connectionTimeout` / `.receiveTimeout` propagates |

#### Definition of Done

- [ ] `BookingApiClient` created with `searchAccommodations` and `searchFlights`
- [ ] Uses shared `Dio` instance (no new `Dio()` creation)
- [ ] Auth token automatically attached by `JwtInterceptor`
- [ ] Response correctly parsed to typed DTOs
- [ ] Errors propagate as `DioException` (not swallowed)
- [ ] Logging present with `[BOOKING_API]` tag

---

### UC1.8-MOB5 — Implement Booking Repository (Domain Wrapper)

#### Goal

Wrap `BookingApiClient` with repository methods that return either a results list or a typed `BookingException`. Empty list returns as an "empty results" success outcome, not an error.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `BookingApiClient` | `List<AccommodationOption>` or `List<TransportOption>` |
| `DioException` from API layer | `BookingException` (typed failure) |

#### Implementation Plan

- **`booking_repository.dart`** `[NEW]` at `lib/features/booking/data/repositories/`:

```dart
/// Domain-level exception for booking operations.
class BookingException implements Exception {
  final String message;
  const BookingException(this.message);

  @override
  String toString() => 'BookingException: $message';
}
```

- **`BookingRepository`** class (follows `GamificationRepository` pattern):
  - Constructor: `BookingRepository({required BookingApiClient apiClient})`.
  - **`Future<List<AccommodationOption>> searchHotels(AccommodationSearchRequest request)`**:
    - `try { return await _apiClient.searchAccommodations(request); }`
    - Catch `DioException` → map to `BookingException`:
      - `connectionError / connectionTimeout / sendTimeout / receiveTimeout` → `'Network error'`
      - `status == 400` → extract `message` from response body if available, else `'Invalid search parameters'`
      - `status == 401` → `'Session expired'` (edge case — interceptor normally handles this)
      - `status == 502` → `'Search service temporarily unavailable'`
      - Else → `'Request failed (status: $status)'`
    - Catch `FormatException` → `BookingException('Invalid response')`.
    - Log with `[BOOKING_REPO]` tag.
  - **`Future<List<TransportOption>> searchFlights(TransportSearchRequest request)`** — identical pattern.
  - **Empty list is a valid success return** (not mapped to error).

#### Walkthrough

1. Call `searchHotels(validRequest)` → returns `List<AccommodationOption>` (possibly empty).
2. Call `searchHotels(invalidRequest)` → throws `BookingException('Invalid search parameters')`.
3. Disconnect network → call any method → throws `BookingException('Network error')`.
4. Backend returns 502 → throws `BookingException('Search service temporarily unavailable')`.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| API returns `[]` | Return empty `List` — caller shows empty state, not error |
| 400 with message body | Extract `message` field from response JSON if available |
| 401 after interceptor retry failed | `BookingException('Session expired')` — user is likely being logged out simultaneously by `JwtInterceptor._forceLogout()` |
| Unknown status code | `BookingException('Request failed (status: $status)')` |
| `DioException` with no response | `BookingException('Network error')` |

#### Definition of Done

- [ ] `BookingRepository` wraps `BookingApiClient`
- [ ] `DioException` mapped to `BookingException` with human-readable messages
- [ ] Empty list returned as success (not error)
- [ ] Error mapping covers 400, 401 (edge case), 502, timeout, network
- [ ] Follows `GamificationRepository` pattern
- [ ] Logging with `[BOOKING_REPO]` tag

---

### UC1.8-MOB6 — Implement Search State UI Wiring (Hotels/Flights Form → Request)

#### Goal

Wire the Search UI inputs into request models with validation. On "Search" click, dispatch to `BookingCubit` which triggers Loading → Results/Empty/Error.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| User-entered form fields | `AccommodationSearchRequest` or `TransportSearchRequest` |
| `BookingCubit` | State transition: Search → Loading → Results |

#### Implementation Plan

- **`booking_search_view.dart`** `[NEW]` at `lib/features/booking/presentation/widgets/`:
  - Renders inside `BookingBottomSheet` when state is `BookingSearch`.
  - **Hotels/Flights toggle** — `ToggleButtons` or segmented control. On change → `cubit.switchType(...)`.
  - **Hotels form fields:**
    - City Code (`TextFormField`): forced uppercase via `TextInputFormatter`, min 3 chars validation.
    - Check-in Date / Check-out Date: `showDatePicker(...)` → stored as `YYYY-MM-DD` string.
    - Adults: numeric input, min 1 validation.
    - Budget (optional): numeric input, nullable.
    - Currency: default `'USD'`, dropdown if needed.
  - **Flights form fields:**
    - Origin / Destination (`TextFormField`): forced uppercase, min 3 chars.
    - Departure Date: date picker → `YYYY-MM-DD`.
    - Return Date (optional): date picker → `YYYY-MM-DD`.
    - Adults: numeric, min 1.
    - Budget (optional): numeric.
    - Currency: default `'USD'`.
  - **Search button:**
    - Validate form (`_formKey.currentState!.validate()`).
    - Build request DTO from form values.
    - Call `cubit.searchHotels(request)` or `cubit.searchFlights(request)`.
  - IATA uppercase enforced via `FilteringTextInputFormatter` + `.toUpperCase()`.

#### Walkthrough

1. Open booking sheet → see Hotels tab selected.
2. Tap Flights → form switches to flight fields (origin/destination instead of city code).
3. Enter city code "par" → auto-converts to "PAR".
4. Enter "PA" only (2 chars) → tap Search → validation error "Minimum 3 characters".
5. Enter adults as 0 → validation error "Minimum 1 adult".
6. Fill valid form → tap Search → sheet shows loading spinner → results appear.
7. Leave budget empty → search works without budget filter.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| IATA code < 3 chars | Form validation prevents submission |
| Adults set to 0 | Form validation: "Minimum 1 adult" |
| Check-out before check-in | Date picker constrains: check-out `firstDate` = check-in + 1 day |
| Budget non-numeric | `TextInputType.number` prevents non-numeric input |
| Empty city code | Required field validation |
| Return date before departure | Date picker constrains: return `firstDate` = departure date |
| Keyboard overlaps Search button | `isScrollControlled: true` on sheet + `SingleChildScrollView` |

#### Definition of Done

- [ ] Hotels/Flights toggle switches form fields
- [ ] All IATA inputs forced to uppercase and validated (min 3)
- [ ] Date fields use date picker, stored as YYYY-MM-DD
- [ ] Adults validated min 1
- [ ] Budget is optional
- [ ] Search button builds correct DTO and dispatches to cubit
- [ ] Form validation prevents invalid submissions
- [ ] Currency defaults to "USD"

---

### UC1.8-MOB7 — Implement Results List UI Wiring (Render Backend Results)

#### Goal

Render hotel/flight cards using backend fields only. Display rating only if non-null. Show summary header, loading skeleton, empty state, error banner, and retry action.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `BookingHotelResults` / `BookingFlightResults` / `BookingEmpty` / `BookingError` / `BookingLoading` states | Rendered list of `HotelCard` or `FlightCard` widgets |
| `AccommodationOption` / `TransportOption` DTOs | Tappable "Open booking" CTA |

#### Implementation Plan

- **`booking_results_view.dart`** `[NEW]`:
  - Renders when state is `BookingHotelResults` or `BookingFlightResults`.
  - **Header row:** Summary text (e.g., "PAR · Jul 1–5 · 2 adults"), back arrow → `cubit.backToSearch()`, filter icon → `cubit.openFilters()`.
  - **Body:** `ListView.builder` of cards.
  - For `BookingHotelResults` → `HotelCard`, for `BookingFlightResults` → `FlightCard`.
  - When state is `BookingLoading` → show shimmer / skeleton placeholders (3–4 card-shaped containers).
  - When state is `BookingEmpty` → show `BookingEmptyState` widget ("No results found").
  - When state is `BookingError` → show error banner with message + "Retry" button → `cubit.retry()`.

- **`hotel_card.dart`** `[NEW]`:
  - Displays: `hotelName`, `address`, `price` + `currency`, `rating` (only if non-null, e.g., "★ 4.2").
  - "Open booking" button → triggers external URL open (MOB9).

- **`flight_card.dart`** `[NEW]`:
  - Displays: `carrier`, `origin` → `destination`, `departureTime` → `arrivalTime` (formatted via MOB10), `duration` (formatted via MOB10), `price` + `currency`, `stops` (e.g., "Direct" or "1 stop").
  - "Open in Google Flights" button → triggers external URL open (MOB9).

- **`booking_empty_state.dart`** `[NEW]`:
  - Icon + "No results found" message + "Try different search criteria" hint + "New search" button → `cubit.backToSearch()`.

#### Walkthrough

1. Search hotels → results appear as cards with hotel name, address, price, and rating star.
2. Search with city having no hotels → "No results found" appears.
3. Stop backend → search → error banner shows "Search service temporarily unavailable" with Retry button.
4. Tap Retry → loading → results.
5. Verify a hotel with `null` rating does not show the rating line.
6. Results header shows correct summary string.
7. Tap back arrow → returns to search form.
8. Tap filter icon → opens filters view.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| `rating` is `null` | Hide rating display (conditional render) |
| `address` is empty string | Show "Address not available" fallback or hide |
| Long hotel name | `TextOverflow.ellipsis` with `maxLines: 2` |
| Very long list (50+ items) | `ListView.builder` handles lazy rendering |
| Currency symbol | Display raw string (e.g., "USD 185.50") |
| `stops == 0` | Show "Direct" label |
| `stops == 1` | Show "1 stop" |
| `stops > 1` | Show "N stops" |

#### Definition of Done

- [ ] Hotel cards display all non-null fields from DTO
- [ ] Flight cards display all fields with formatted duration
- [ ] Rating conditionally shown (nullable safe)
- [ ] Results header shows summary + back + filter icons
- [ ] Loading state shows skeleton
- [ ] Empty state shows "No results found" with new search action
- [ ] Error state shows message + Retry button
- [ ] Cards have "Open booking" CTA

---

### UC1.8-MOB8 — Implement Filters State UI Wiring (Budget + Sort)

#### Goal

Open Filters view from Results header filter icon (inline, same sheet). Hotels support budget + sort (3 values), Flights support budget + sort (2 values). Apply re-runs search; Reset clears budget and resets sort.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `BookingFilters` state (includes current budget, sort, booking type) | Updated `AccommodationSearchRequest` / `TransportSearchRequest` |
| User-adjusted budget + sort selection | `cubit.applyFilters(budget, sortBy)` or `cubit.resetFilters()` |

#### Implementation Plan

- **`booking_filters_view.dart`** `[NEW]`:
  - Renders when state is `BookingFilters`.
  - **Header:** "Filters" title + close icon → `cubit.backToResults()`.
  - **Budget field:** `TextFormField` pre-filled with current budget (or empty). Numeric input.
  - **Sort dropdown / chip group:**
    - Hotels: 3 options — "Price ↑", "Price ↓", "Rating ↓" → maps to `SortCriteria` enum.
    - Flights: 2 options — "Price ↑", "Price ↓" (no `RATING_DESC`).
  - **Apply button:** Calls `cubit.applyFilters(budget, sortBy)` which re-runs search with updated params sent to backend.
  - **Reset button:** Calls `cubit.resetFilters()` → clears budget to `null`, sort to `null` (default), re-runs search.
  - Pre-fill fields from `BookingFilters.currentBudget` and `BookingFilters.currentSort`.

#### Walkthrough

1. Search hotels → get results → tap filter icon.
2. See Filters view with empty budget and no sort selected.
3. Enter budget 150 → select "Price ↑" → tap Apply.
4. Loading → results now reflect backend response with budget=150 and sortBy=PRICE_ASC sent.
5. Tap filter icon again → budget shows 150, sort shows "Price ↑".
6. Tap Reset → Loading → results reflect search without budget/sort params.
7. Switch to Flights → filter icon → only 2 sort options shown (no Rating).

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Budget = 0 | Treat as "no budget" (null) — 0 is not useful |
| Budget negative | Validation: "Budget must be positive" |
| Non-numeric budget input | `TextInputType.number` prevents |
| Apply with no changes | Still re-runs search (idempotent) |
| Close filters without applying | Returns to previous results unchanged |

#### Definition of Done

- [ ] Filters view opens from results filter icon
- [ ] Hotels show 3 sort options; Flights show 2
- [ ] Budget field is numeric and optional
- [ ] Apply re-runs search with new params sent to backend
- [ ] Reset clears budget and sort, re-runs search
- [ ] Pre-fills current filter values
- [ ] Close without apply returns to previous results

---

### UC1.8-MOB9 — External Redirect: Open `externalBookingUrl`

#### Goal

On "Open booking" / "Open in Google Flights" tap, open `externalBookingUrl` via URL launcher. If URL is missing/invalid, disable CTA or show non-blocking error.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `externalBookingUrl` from DTO | Device browser opens URL |
| `url_launcher` package | Graceful error on invalid/missing URL |

#### Implementation Plan

- **`pubspec.yaml`** `[MODIFY]` — Add dependency:
  ```yaml
  url_launcher: ^6.2.0
  ```
  Run `flutter pub get`.

- **Hotel card / Flight card "Open" button handler:**
  - Call `launchUrl(Uri.parse(option.externalBookingUrl), mode: LaunchMode.externalApplication)`.
  - Wrap in try-catch.
  - Before launching, validate URL:
    ```dart
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      // Show SnackBar: "Booking link unavailable"
      return;
    }
    ```
  - If `canLaunchUrl(uri)` returns false → show SnackBar: "Cannot open booking link".

- Can extract a utility function `openBookingUrl(BuildContext context, String url)` in `lib/features/booking/presentation/widgets/` or a shared utils file.

#### Walkthrough

1. Search hotels → get results → tap "Open booking" on a card.
2. Device browser opens the Booking.com URL.
3. Return to app → booking sheet is still visible with results.
4. Search flights → tap "Open in Google Flights" → device browser opens Google Flights.
5. If a card has an invalid URL (test with mock) → "Booking link unavailable" SnackBar appears, button appears disabled.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| `externalBookingUrl` is empty string | Disable button or show "Link unavailable" |
| URL is malformed (no scheme) | `Uri.tryParse` fails → show SnackBar, no crash |
| No browser installed (rare) | `canLaunchUrl` returns false → show SnackBar |
| URL opens but page 404s | Out of scope — user sees external site error |
| Rapid taps on "Open" button | Debounce or disable button during launch |

#### Definition of Done

- [ ] `url_launcher` added to `pubspec.yaml` and `flutter pub get` runs clean
- [ ] Tapping "Open booking" on hotel card opens URL in device browser
- [ ] Tapping "Open in Google Flights" on flight card opens URL in device browser
- [ ] Invalid/empty URL shows non-blocking SnackBar error
- [ ] App does not crash on any URL edge case
- [ ] Button disabled or hidden when URL is invalid

---

### UC1.8-MOB10 — Utilities: Duration Parsing + Date Formatting

#### Goal

Parse ISO 8601 duration strings (`PT3H15M`) into human-readable format (`3h 15m`). Format ISO date strings (`YYYY-MM-DD`) into readable UI labels. Ensure all nullable fields render safely.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| `"PT3H15M"`, `"PT12H0M"`, `"PT0H45M"` | `"3h 15m"`, `"12h"`, `"45m"` |
| `"2025-07-01"` | `"Jul 1, 2025"` or `"Jul 1"` |

#### Implementation Plan

- **`booking_utils.dart`** `[NEW]` at `lib/features/booking/data/models/` (or `lib/features/booking/presentation/`):

```dart
/// Parses ISO 8601 duration "PT3H15M" → "3h 15m".
/// Handles: PT3H15M, PT3H, PT15M, PT0H45M.
/// Returns raw string if parsing fails.
String formatDuration(String isoDuration) {
  final match = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?').firstMatch(isoDuration);
  if (match == null) return isoDuration;
  final hours = match.group(1);
  final minutes = match.group(2);
  final parts = <String>[];
  if (hours != null && hours != '0') parts.add('${hours}h');
  if (minutes != null && minutes != '0') parts.add('${minutes}m');
  return parts.isEmpty ? '0m' : parts.join(' ');
}

/// Formats "2025-07-01" → "Jul 1, 2025".
/// Returns raw string if parsing fails.
String formatDate(String isoDate) {
  try {
    final date = DateTime.parse(isoDate);
    return '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';
  } catch (_) {
    return isoDate;
  }
}

/// Formats "2025-07-01T08:30:00" → "08:30".
String formatTime(String isoDateTime) {
  try {
    final dt = DateTime.parse(isoDateTime);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return isoDateTime;
  }
}

/// Null-safe rating display.
String? formatRating(double? rating) {
  if (rating == null) return null;
  return '★ ${rating.toStringAsFixed(1)}';
}

/// Stops label.
String formatStops(int stops) {
  if (stops == 0) return 'Direct';
  if (stops == 1) return '1 stop';
  return '$stops stops';
}
```

#### Walkthrough

1. `formatDuration('PT3H15M')` → `'3h 15m'` ✓
2. `formatDuration('PT12H0M')` → `'12h'` ✓
3. `formatDuration('PT0H45M')` → `'45m'` ✓
4. `formatDuration('INVALID')` → `'INVALID'` (graceful fallback) ✓
5. `formatDate('2025-07-01')` → `'Jul 1, 2025'` ✓
6. `formatTime('2025-07-01T08:30:00')` → `'08:30'` ✓
7. `formatRating(null)` → `null` ✓
8. `formatRating(4.2)` → `'★ 4.2'` ✓
9. `formatStops(0)` → `'Direct'` ✓

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Duration has only hours (`PT3H`) | Show `"3h"` |
| Duration has only minutes (`PT45M`) | Show `"45m"` |
| Duration is `PT0H0M` | Show `"0m"` |
| Unparseable duration string | Return raw string (no crash) |
| Invalid date string | Return raw string (no crash) |
| `rating` is `null` | `formatRating` returns `null`; UI hides rating widget |
| `rating` is `0.0` | Shows `"★ 0.0"` (valid edge case) |

#### Definition of Done

- [ ] `formatDuration` handles H-only, M-only, H+M, and invalid cases
- [ ] `formatDate` converts YYYY-MM-DD to "Mon D, Year"
- [ ] `formatTime` converts ISO datetime to "HH:mm"
- [ ] `formatRating` is null-safe
- [ ] `formatStops` returns "Direct" / "1 stop" / "N stops"
- [ ] All functions return graceful fallbacks on invalid input
- [ ] No crashes on null or unexpected values

---

### UC1.8-MOB11 — Tests (Repo + State Flow)

#### Goal

Write tests for repository (success, empty, error mapping), BLoC/Cubit (state transitions), and utility functions.

#### Inputs / Outputs

| Inputs | Outputs |
|---|---|
| Mock `BookingApiClient` | Repository test coverage |
| Mock `BookingRepository` | Cubit test coverage |
| Hardcoded strings | Utility test coverage |

#### Implementation Plan

- **`test/features/booking/`** `[NEW]` — Test directory structure:

```
test/features/booking/
├── data/
│   └── repositories/
│       └── booking_repository_test.dart
├── presentation/
│   └── cubit/
│       └── booking_cubit_test.dart
└── utils/
    └── booking_utils_test.dart
```

- **`booking_repository_test.dart`**:
  - Mock `BookingApiClient` (use manual `Fake` class — no `mockito` in current dev deps).
  - Test cases:
    - ✅ `searchHotels` returns list of 2 hotels → returns `List<AccommodationOption>` length 2.
    - ✅ `searchHotels` returns `[]` → returns empty list (not error).
    - ✅ `searchHotels` throws `DioException` with 400 → throws `BookingException` with validation message.
    - ✅ `searchHotels` throws `DioException` with 401 → throws `BookingException('Session expired')`.
    - ✅ `searchHotels` throws `DioException` with 502 → throws `BookingException('Search service temporarily unavailable')`.
    - ✅ `searchHotels` throws `DioException` with timeout → throws `BookingException('Network error')`.
    - ✅ Same test set for `searchFlights`.

- **`booking_cubit_test.dart`**:
  - Mock `BookingRepository`.
  - Test cases:
    - ✅ Initial state is `BookingSearch(hotels)`.
    - ✅ `switchType(flights)` → emits `BookingSearch(flights)`.
    - ✅ `searchHotels(request)` → emits `[BookingLoading, BookingHotelResults]`.
    - ✅ `searchHotels(request)` with empty result → emits `[BookingLoading, BookingEmpty]`.
    - ✅ `searchHotels(request)` with error → emits `[BookingLoading, BookingError]`.
    - ✅ `searchFlights(request)` → emits `[BookingLoading, BookingFlightResults]`.
    - ✅ `retry()` from error state → re-runs last search.
    - ✅ `openFilters()` → emits `BookingFilters` with current params.
    - ✅ `applyFilters(budget, sort)` → emits `[BookingLoading, BookingHotelResults]`.
    - ✅ `resetFilters()` → emits `[BookingLoading, BookingHotelResults]` with null budget/sort.

- **`booking_utils_test.dart`**:
  - Test `formatDuration` with all patterns (H+M, H-only, M-only, invalid).
  - Test `formatDate` with valid and invalid strings.
  - Test `formatTime` with valid and invalid strings.
  - Test `formatRating` with `null`, `0.0`, `4.2`.
  - Test `formatStops` with `0`, `1`, `3`.

#### Walkthrough

1. Run `flutter test test/features/booking/` → all tests pass.
2. Run `flutter test` → existing tests still pass (no regression).
3. Check coverage: repository tests cover all error codes + success + empty.
4. Check coverage: cubit tests cover full Search → Loading → Results/Empty/Error → Retry flow.

#### Edge Cases & Error Handling

| Case | Handling |
|---|---|
| Mock setup for `DioException` without response | Test `DioExceptionType.connectionError` with `response: null` |
| Cubit test race conditions | Use `bloc_test` pattern or manual `expectLater` with streams |
| No `mockito` in project deps | Use manual `Fake` classes or add `mockito` to `dev_dependencies` |

#### Definition of Done

- [ ] Repository tests: success list, empty list, 400/401/502/timeout mapping
- [ ] Cubit tests: Search → Loading → Results/Empty/Error, Retry, Apply/Reset filters
- [ ] Utility tests: all `formatDuration`, `formatDate`, `formatTime`, `formatRating`, `formatStops` cases
- [ ] `flutter test` passes all new and existing tests
- [ ] No test file causes compile errors

---

## 4 · DI / main.dart Wiring

Before the UI tasks can work end-to-end, the following must be added to `main.dart`:

```dart
// In MultiRepositoryProvider.providers:

/// Booking API client (UC1.8)
RepositoryProvider<BookingApiClient>(
  create: (ctx) => BookingApiClient(ctx.read<Dio>()),
),

/// Booking repository (UC1.8)
RepositoryProvider<BookingRepository>(
  create: (ctx) => BookingRepository(
    apiClient: ctx.read<BookingApiClient>(),
  ),
),
```

`BookingCubit` is provided **locally** in `home_map_scaffold.dart` when the bottom sheet opens (not app-wide), because it is scoped to the booking sheet lifecycle.

---

## 5 · QA Checklist

### Functional

- [ ] Booking icon visible on Home/Map action bar
- [ ] Bottom sheet opens on tap; closes on backdrop tap and close button
- [ ] Hotels/Flights toggle switches form correctly
- [ ] All form validations work (IATA 3 chars, adults ≥ 1, dates order)
- [ ] Search returns results and renders hotel/flight cards
- [ ] Empty results show "No results found" state
- [ ] Error states show user-friendly message + Retry button
- [ ] Retry re-runs the last search successfully
- [ ] Filter icon opens filters view
- [ ] Budget param is sent to backend and affects results per contract
- [ ] Sort options work (PRICE_ASC, PRICE_DESC, RATING_DESC for hotels)
- [ ] Apply filters re-runs search with new params sent to backend
- [ ] Reset filters clears budget + sort and re-runs
- [ ] "Open booking" opens device browser with correct URL
- [ ] Invalid/empty URL shows SnackBar, no crash
- [ ] Rating hidden when null; displayed when present
- [ ] Duration formatted ("3h 15m"), not raw ISO
- [ ] Stops show "Direct" / "1 stop" / "N stops"
- [ ] Dates formatted for display

### Auth

- [ ] Requests include Bearer token (verified in network logs via `JwtInterceptor`)
- [ ] 401 handled by `JwtInterceptor` (auto-refresh + retry, or force logout)
- [ ] Dev profile works without auth

### Error Scenarios

- [ ] Backend down → "Search service temporarily unavailable" + Retry
- [ ] No internet → "Network error" + Retry
- [ ] 400 invalid request → descriptive error message
- [ ] Malformed response → "Invalid response" error

### Regression

- [ ] Existing map functionality unchanged (pan, zoom, markers, drawing)
- [ ] Existing POI search works
- [ ] Existing gamification works
- [ ] Existing auth flow works
- [ ] No new compile warnings

---

## 6 · Demo Script (2–3 Minutes)

### Setup
- Backend running with Amadeus credentials configured.
- App installed and user logged in.

### Demo Steps

| Step | Time | Action | Expected |
|---|---|---|---|
| 1 | 0:00 | Show Home/Map screen | Map visible with action bar on right |
| 2 | 0:10 | Point out the luggage icon in action bar | New booking entry point visible |
| 3 | 0:15 | Tap luggage icon | Bottom sheet slides up with hotel search form |
| 4 | 0:20 | Type "PAR" in city code, select dates, adults = 2 | Form fields populate correctly |
| 5 | 0:30 | Tap Search | Loading spinner → hotel results appear as cards |
| 6 | 0:40 | Scroll through results, note rating stars & prices | Cards show name, address, price, rating |
| 7 | 0:50 | Tap "Open booking" on first hotel | Device browser opens Booking.com |
| 8 | 1:00 | Return to app, tap filter icon | Filters view opens with budget + sort options |
| 9 | 1:10 | Set budget to 150, sort by Price ↑, tap Apply | Loading → results reflect budget=150 & sort=PRICE_ASC sent to backend |
| 10 | 1:15 | Tap Reset | Loading → results without budget/sort params |
| 11 | 1:20 | Toggle to Flights tab | Search form switches to flight fields |
| 12 | 1:25 | Enter IST → PAR, select date, tap Search | Loading → flight results with carrier, duration, stops |
| 13 | 1:35 | Note a "Direct" flight and a "1 stop" flight | Duration shows "3h 15m" format |
| 14 | 1:40 | Tap "Open in Google Flights" | Device browser opens Google Flights |
| 15 | 1:50 | Return to app, tap backdrop | Bottom sheet dismisses, map fully accessible |
| 16 | 2:00 | Show map interactions (pan, zoom) still work | No regression |

### Error Demo (Optional +30s)

| Step | Action | Expected |
|---|---|---|
| E1 | Search with city code "XX" (no results) | "No results found" empty state |
| E2 | Disconnect network, tap Retry | "Network error" message + Retry button |
| E3 | Reconnect, tap Retry | Results load successfully |

---

## 7 · Implementation Order & Dependencies

```
MOB3 (DTOs) ──────────────────────┐
                                  ├──→ MOB4 (API Client) ──→ MOB5 (Repository) ──┐
MOB10 (Utilities) ───────────────┘                                                │
                                                                                  │
MOB2 (Cubit) ──────────────────────────────────────────────────→ wires to MOB5 ──┤
                                                                                  │
MOB1 (Entry Point) ───────────────────────────────────────────────────────────────┤
                                                                                  │
                   ┌──── MOB6 (Search UI) ◄───────────────────────────────────────┤
                   ├──── MOB7 (Results UI) ◄──────────────────────────────────────┤
                   ├──── MOB8 (Filters UI) ◄──────────────────────────────────────┤
                   └──── MOB9 (URL Launcher) ◄────────────────────────────────────┘
                                                                                  
MOB11 (Tests) ◄───────── all above complete ──────────────────────────────────────
```

**Recommended execution order:**

1. **MOB3** — DTOs (no dependencies)
2. **MOB10** — Utilities (no dependencies)
3. **MOB4** — API Client (depends on MOB3)
4. **MOB5** — Repository (depends on MOB4)
5. **MOB2** — Cubit (depends on MOB5)
6. **MOB1** — Entry Point (depends on MOB2 shell)
7. **MOB9** — URL Launcher (add dependency, create util)
8. **MOB6** — Search UI wiring (depends on MOB2, MOB3)
9. **MOB7** — Results UI wiring (depends on MOB2, MOB3, MOB10, MOB9)
10. **MOB8** — Filters UI wiring (depends on MOB2, MOB7)
11. **MOB11** — Tests (all above complete)
