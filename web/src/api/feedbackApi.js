import http from "./http";

/**
 * POST /api/feedback/poi-events — requires Firebase Bearer (see http.js).
 * @param {{ eventType: string, mapboxId?: string|null, foursquareId?: string|null, categoryKeys?: string[]|null, waypointName?: string|null, latitude?: number|null, longitude?: number|null }} body
 */
export async function postPoiFeedbackEvent(body) {
  await http.post("/api/feedback/poi-events", body);
}

/**
 * POST /api/feedback/route — thumbs on a saved ai_routes row.
 * @param {{ routeId: string, eventType: 'THUMBS_UP' | 'THUMBS_DOWN' }} body
 */
export async function postRouteFeedback(body) {
  await http.post("/api/feedback/route", body);
}

/** GET /api/feedback/affinity — current user's aggregated scores (for thumb state). */
export async function fetchFeedbackAffinity() {
  const { data } = await http.get("/api/feedback/affinity");
  return data;
}

/** GET /api/feedback/saved-pois — liked POIs with display info, sorted by recency. */
export async function fetchSavedPois() {
  const { data } = await http.get("/api/feedback/saved-pois");
  return data;
}
