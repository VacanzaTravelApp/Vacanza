# UC1.11 Overview
- **What UC1.11 is:** Explore in AR Mode allows the traveler to use their mobile device’s camera and sensors to view nearby points of interest (POIs) overlaid on the real world, providing an immersive way to explore attractions around their current location.
- **Related requirements and use cases:** This use case is primarily driven by FReq10 (Augmented Reality Exploration) and is closely connected to UC1.2 (Map Interaction and Filtering), UC1.3 (Area Selection and POI Integration), UC1.7 (Location-Based Check-in), UC1.9 (Earn Badges & XP), and the broader geospatial/map services (WP3.x) and advanced mobile features (WP6.x) defined in the SPMP.
- **Scope of work (mobile/backend/integration):** UC1.11 is mainly a mobile feature (Flutter client with AR camera overlay and UI), but it also depends on backend geospatial data and APIs (for POIs and geofence verification) and requires dedicated integration and testing work to validate end-to-end behavior and performance on real devices.

# Task Breakdown

## Mobile / Frontend Tasks

### MOB-1- Implement AR Camera View and Sensor Integration (UC1.11 Mobile Shell)
- **Description:**
  - Set up the AR camera view within the Flutter mobile app, integrating device camera access and sensor data (compass, gyroscope, GPS) needed for basic AR overlays.
  - Define a dedicated navigation entry point for AR Mode from the existing map or route screens, following current mobile navigation patterns.
  - Handle the AR view lifecycle correctly (init, pause/resume, dispose) to avoid crashes, memory leaks, or camera lock issues when switching between map and AR.
- **Dependencies:**
  - Mobile app core navigation and authentication flows (UC1.1) already in place.
  - Agreement on AR toolkit / plugin choice for Flutter (e.g., platform-specific AR wrapper).
- **Notes:**
  - Exact AR toolkit (e.g., ARCore/ARKit bindings) and minimum OS/device requirements should be clarified with the advisor and team before implementation.
  - Keep the initial implementation as a minimal “camera + reticle” shell, so further AR features can be added iteratively.

### MOB-2- Design and Implement AR POI Overlay Rendering
- **Description:**
  - Define the AR POI overlay model (fields like name, category, distance, bearing, icon color) aligned with existing POI structures used in map views (UC1.2, UC1.3).
  - Implement visual overlays (markers, labels) anchored in 3D/AR space based on user heading and distance, including basic occlusion and size/opacity rules for readability.
  - Support category-based styling (e.g., hotels, restaurants, monuments, events) consistent with the current map legend to keep visual language coherent.
- **Dependencies:**
  - Backend or local service that provides POIs with enough metadata (coordinates, category, title, optional rating) for AR display.
  - Completion of the AR camera view and sensor integration task.
- **Notes:**
  - Start with a simple projection (e.g., screen-space mapping based on bearing and distance buckets) if full 3D/world-anchored placement is too complex for the prototype.
  - Document any visual limitations (e.g., vertical accuracy, overlap behavior) in the prototype notes.

### MOB-3- Implement AR Mode POI Fetching and Filtering Logic
- **Description:**
  - Implement a mobile service to fetch nearby POIs for AR Mode based on the current GPS location and optional filters (categories, radius), reusing existing map/area selection logic where possible.
  - Ensure AR Mode respects the same category filters as the map (UC1.2) and, when applicable, the currently selected area (UC1.3) so that the experience feels consistent across views.
  - Implement caching and refresh policies (e.g., minimum distance threshold before refetch, manual “refresh” action) to avoid unnecessary API calls and performance issues.
- **Dependencies:**
  - Existing Map Services & Geospatial Core (WP3.x) APIs for POI listing and area selection.
  - Backend changes (if needed) to expose AR-optimized POI endpoints or query parameters.
- **Notes:**
  - If the backend cannot be adapted for AR-specific queries within scope, implement a thin client-side filtering layer over existing POI endpoints and document the compromise.
  - Consider prototype constraints for external APIs (Mapbox, travel data) and respect rate limits.

### MOB-4- Add AR Mode UI Controls and User Guidance
- **Description:**
  - Design and implement AR-specific UI controls (e.g., category filter chips, recenter/compass button, “Back to Map” button, help/tooltip) consistent with existing mobile design patterns.
  - Provide onboarding/help text or a brief overlay explaining how to use AR Mode, including any safety messages (e.g., “Be aware of your surroundings while using AR”).
  - Implement clear empty/error states (no POIs found, location disabled, sensors not available) with actionable guidance (e.g., “Enable location services”, “Move phone slowly to calibrate”).
- **Dependencies:**
  - Core AR Mode shell and overlay rendering available in the mobile client.
  - Design guidelines or existing Figma prototypes for Vacanza mobile to align layout and components.
- **Notes:**
  - Keep control layout simple and thumb-accessible to reduce cognitive load while the user is physically moving.
  - Coordinate labels and terminology with other parts of the app (e.g., reuse “Nearby” vs “Around You” consistently).

### MOB-5- Integrate AR Mode with Location-Based Check-in and Gamification Hooks
- **Description:**
  - Add hooks in AR Mode to trigger check-in actions when the user is within a configured geofence radius and explicitly interacts with a POI (e.g., “Check in here” button).
  - Surface gamification feedback (e.g., XP/badge earned banners) within AR Mode when UC1.9-related events fire, using non-intrusive overlays.
  - Ensure AR-triggered check-ins and rewards are consistent with existing map or list-based check-in flows, sharing the same backend endpoints and rules.
- **Dependencies:**
  - Implementation of location-based check-in (UC1.7) and gamification logic (WP7.x) on backend and mobile.
  - Backend API for geofence verification and XP/badge updates (WP6.1.3, WP7.1.2 equivalents).
- **Notes:**
  - If full gamification/UI is not yet implemented, stub the hooks and log events so they can be wired later.
  - Coordinate with backend team on idempotency and rate limiting for AR-triggered check-ins.

### MOB-6- Implement Permissions, Fallback Behavior, and Device Capability Handling for AR
- **Description:**
  - Implement robust permission handling for camera, location, and motion sensors, including first-time requests, denial flows, and “open settings” guidance.
  - Detect basic device capability (e.g., OS version, AR framework availability) and fall back to a non-AR experience (e.g., map-based “around me” view) when AR is not supported.
  - Add logging/telemetry from the mobile side for AR Mode usage (enter/exit events, errors) to support later monitoring and debugging.
- **Dependencies:**
  - Core mobile permission handling infrastructure used elsewhere in the app (e.g., location for map).
  - Clarified minimum supported OS/device matrix for AR features.
- **Notes:**
  - Clearly document which devices/OS versions are supported in AR Mode for grading/demo purposes.
  - Consider grouping AR error/permission messages under a shared localization scheme if the app supports multiple languages.

## Backend Tasks

### BACKEND-1- Provide AR-Optimized POI Data Endpoint
- **Description:**
  - Analyze existing POI-related endpoints (used by UC1.2 and UC1.3) and define a backend contract optimized for AR Mode (e.g., limited radius, key fields only, category filters).
  - Implement or adapt a backend endpoint that returns nearby POIs around a given coordinate, including fields needed for AR overlays (id, name, type, latitude/longitude, optional rating/metadata).
  - Ensure the endpoint enforces appropriate query limits and uses database indexes to keep response times acceptable, aligned with NFReq2 (Performance).
- **Dependencies:**
  - Map Services & Geospatial Core (WP3.x) and existing POI database schema.
  - Agreement with mobile team on the required response shape and maximum result size.
- **Notes:**
  - If a dedicated AR endpoint is too costly to implement, extend an existing list endpoint with optional AR-specific query parameters and document the shared usage.
  - Consider future reuse for other “nearby” experiences beyond AR Mode to avoid duplication.

### BACKEND-2- Implement Geofence Verification Support for AR-Based Check-ins
- **Description:**
  - Design and implement server-side geofence verification logic that can validate if a user’s current location is within an allowed radius of a POI for UC1.7/UC1.11 check-ins.
  - Expose an authenticated API endpoint that AR Mode can call to request check-in validation and record successful check-ins, reusing existing gamification and check-in tables.
  - Add audit fields (timestamp, device/platform, source = “AR_MODE”) to recorded check-ins to distinguish AR-triggered events from other flows.
- **Dependencies:**
  - Existing location-based check-in schema and APIs (UC1.7) and gamification backend logic (WP7.1.x).
  - Firebase authentication and user identification already working end-to-end.
- **Notes:**
  - Pay attention to precision and drift in GPS readings; allow a configurable radius and maybe snap to nearest POI to avoid user frustration.
  - Log rejected check-ins with reasons (e.g., out of radius, duplicate) for later debugging.

### BACKEND-3- Add AR Mode Telemetry and Basic Monitoring Hooks
- **Description:**
  - Define minimal backend telemetry events related to AR Mode (e.g., AR_POI_QUERY, AR_CHECKIN_ATTEMPT, AR_CHECKIN_SUCCESS, AR_ERROR) and store them in logs or analytics tables.
  - Integrate these events with existing admin/analytics infrastructure (WP8.x) where feasible, so that AR usage can be inspected during demos or troubleshooting.
  - Ensure no sensitive user data is logged while still capturing enough context (user id, timestamp, location bucket, device/platform) to debug issues.
- **Dependencies:**
  - Administrative monitoring and analytics framework (UC2.1/UC2.2, WP8.1.x).
  - Finalized AR Mode API contracts and mobile integration points.
- **Notes:**
  - For the prototype, prioritize simple, queryable logs over a full analytics dashboard if time is constrained.
  - Coordinate naming conventions with existing metrics to avoid fragmentation.

## Integration / Testing Tasks

### End-to-End AR Mode Functional Testing (UC1.11)
- **Description:**
  - Define test scenarios covering the main UC1.11 flows: entering AR Mode from the map, seeing nearby POIs, tapping a POI for details, and (where implemented) initiating a check-in.
  - Execute manual end-to-end tests on at least two different devices/OS versions, documenting observed behavior, issues, and any visual inconsistencies with the map view.
  - Verify that AR Mode interactions correctly call backend endpoints (POI fetch, geofence verification) and that failures are handled gracefully in the UI.
- **Dependencies:**
  - Mobile AR Mode implementation complete (camera view, overlays, fetching, basic UI).
  - Backend AR POI and geofence/check-in endpoints deployed to a shared test environment.
- **Notes:**
  - Capture screenshots or short screencasts for inclusion in prototype/demo documentation.
  - Coordinate with the advisor about which scenarios are most important to demonstrate in evaluations.

### AR Mode Performance, Stability, and Usability Testing
- **Description:**
  - Perform focused tests on AR Mode performance (e.g., initial load time, POI refresh time, frame rate under typical usage) against NFReq2’s responsiveness expectations.
  - Observe stability under stress conditions (e.g., rapid device movement, loss/reacquisition of GPS, switching between AR and map repeatedly) and log crashes or severe slowdowns.
  - Collect qualitative usability feedback from team members or pilot users on clarity of overlays, control layout, and motion/comfort, and summarize recommendations for improvements.
- **Dependencies:**
  - Functional AR Mode already in place and roughly feature-complete.
  - Basic logging/telemetry added on both mobile and backend sides.
- **Notes:**
  - Document known limitations that are acceptable for the academic prototype (e.g., occasional jitter, limited range) so they are clearly communicated in reports.
  - If major performance problems are found, open follow-up Jira tasks rather than trying to optimize everything inside this testing task.

### Cross-Feature Regression Testing for AR, Map, and Check-in/Gamification Flows
- **Description:**
  - Define regression test cases to ensure that adding AR Mode does not break existing map interaction (UC1.2, UC1.3), location-based check-in (UC1.7), or gamification earning flows (UC1.9).
  - Run these regression tests after integrating AR Mode into the main branch, focusing on navigation between screens, shared filters, and consistency of check-in and XP/badge state.
  - Log and track any regressions found in Jira, linking them to UC1.11-related changes for traceability.
- **Dependencies:**
  - Existing test suites for map and check-in/gamification flows (WP9.x) available as a baseline.
  - AR Mode merged into the integration/test environment.
- **Notes:**
  - Prioritize regressions that affect core first-increment features (auth, map interaction) since they are critical to overall demoability.
  - Coordinate with the team on scheduling this regression pass near the end of Milestone 3 to align with final integration and acceptance testing.

