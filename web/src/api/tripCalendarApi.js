import http from "./http";

/**
 * Trip calendar: liked routes pinned to a calendar day (GET/POST/DELETE /users/me/trip-calendar/events).
 * @param {number} year
 * @param {number} month 1–12
 */
export async function listTripCalendarEvents(year, month) {
  const { data } = await http.get("/users/me/trip-calendar/events", {
    params: { year, month },
  });
  return Array.isArray(data) ? data : [];
}

/**
 * @param {{ routeId: string, eventDate: string }} body eventDate ISO date YYYY-MM-DD (first trip day)
 * @returns {Promise<Array<object>>} one row per itinerary day
 */
export async function createTripCalendarEvent(body) {
  const { data } = await http.post("/users/me/trip-calendar/events", body);
  return Array.isArray(data) ? data : [];
}

export async function deleteTripCalendarEvent(eventId) {
  await http.delete(`/users/me/trip-calendar/events/${eventId}`);
}

/** Removes every calendar day for this route (multi-day trip). */
export async function deleteTripCalendarEventsByRoute(routeId) {
  await http.delete(`/users/me/trip-calendar/events/by-route/${routeId}`);
}

/**
 * Exports a registered route as an .ics file.
 * Requires the route to be registered via createTripCalendarEvent first.
 */
export async function exportRouteICS(routeId) {
  const { data } = await http.get(`/users/me/trip-calendar/export/route/${routeId}`, {
    responseType: "blob",
  });
  return data;
}
