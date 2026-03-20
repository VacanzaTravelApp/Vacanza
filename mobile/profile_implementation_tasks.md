# Profile Feature — Implementation Tasks

Source of truth for scope and API: [`profile_frontend_guide.md`](profile_frontend_guide.md).  
UI reference: Figma — Header + Gamification existing; new sections below; edit flows via in-phone bottom sheets.  
Mobile UI language: **English only**.

---

## Scope (summary)

- **Profile screen:** Header (existing) → Gamification (existing) → Travel Preferences summary → Travel Statistics → Check-in History preview → Account actions.
- **Edit flows:** Edit Preferences sheet (Basics visible, Advanced collapsed); Edit Profile sheet. Long lists use searchable picker sheets; summaries show max 3 chips + “+N”.
- **APIs:** GET/PUT `/users/me/profile`, GET/PUT `/users/me/preferences`, GET `/users/me/stats`, GET `/users/me/checkins`.

---

## Task list (order of implementation)

Tasks are implemented in this order. Before each task: **implementation plan** → your approval → code → **walkthrough**.

---

### Task 1 — Add Profile Models/DTOs + Repository Layer

**Name:** Add Profile Models/DTOs + Repository Layer

**Description:**
- Create Flutter models + DTO/mappers for UserProfile, UserPreferences, TravelStats, CheckIn.
- Implement ProfileRemoteDataSource + ProfileRepository for:
  - GET /users/me/profile, GET /users/me/preferences, GET /users/me/stats, GET /users/me/checkins
  - PUT /users/me/profile and PUT /users/me/preferences (send only changed fields, don’t send nulls).
- Add date parsing + null-safe defaults (empty lists).

---

### Task 2 — Implement ProfileBloc (Load/Refresh + Section States)

**Name:** Implement ProfileBloc (Load/Refresh + Section States)

**Description:**
- Add ProfileBloc with section-based loading/error states (profile / preferences / stats / checkins).
- Implement events: ProfileStarted, ProfileRefreshed, retry per section.
- Wire bloc into ProfileScreen without changing existing header/gamification UI.

---

### Task 3 — Build Profile Screen Sections (Preferences/Stats/Check-ins/Account)

**Name:** Build Profile Screen Sections (Preferences/Stats/Check-ins/Account)

**Description:**
- Append sections below Gamification in order:
  - Travel Preferences summary card (max 3 chips + “+N”).
  - Travel Statistics card (with empty state).
  - Check-in History preview (last 3–5 + “See all” placeholder).
  - Account actions (Edit Profile, Edit Preferences, Logout).
- Connect UI to ProfileBloc states (loading / error / empty).

---

### Task 4 — Implement Edit Preferences Bottom Sheet + Searchable Pickers

**Name:** Implement Edit Preferences Bottom Sheet + Searchable Pickers

**Description:**
- Add EditPreferencesSheet as `showModalBottomSheet` (in-phone, dim backdrop, scrollable).
- Basics always visible; Advanced collapsed by default.
- Implement searchable picker sheets for long lists: categories, cuisines, dietary, accessibility, spoken languages.
- Save triggers optimistic update + PUT /users/me/preferences; rollback/refetch on failure.

---

### Task 5 — Implement Edit Profile Bottom Sheet (Basic Info Editing)

**Name:** Implement Edit Profile Bottom Sheet (Basic Info Editing)

**Description:**
- Add EditProfileSheet bottom sheet with editable: first/middle/last/preferred name, country (search picker), birth date, gender, profile image URL.
- Email + join date read-only.
- Apply displayName rule: preferredName else firstName+lastName.
- Save triggers optimistic update + PUT /users/me/profile; rollback/refetch on failure.

---

### Task 6 — Add Tests + Polish for Profile Feature

**Name:** Add Tests + Polish for Profile Feature

**Description:**
- Unit tests for DTO mapping (null/optional fields).
- Bloc tests for load success/error and optimistic update rollback.
- UI polish: ensure English-only text, chip limit respected, smooth bottom-sheet behavior, `flutter analyze` clean.

---

*End of task list.*
