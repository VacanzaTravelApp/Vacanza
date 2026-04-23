/**
 * Category on waypoints may come as category, poi_category, or mixed casing from AI/JSON.
 */
export function getWaypointCategory(wp) {
  if (!wp || typeof wp !== "object") return null;
  const raw =
    wp.category ??
    wp.Category ??
    wp.poi_category ??
    wp.poiCategory ??
    wp.poi_category_id ??
    null;
  if (raw == null || String(raw).trim() === "") return null;
  return String(raw).trim();
}

/**
 * Normalize route for map: ensure every waypoint has numeric latitude/longitude (backend may send either key style).
 */
export function normalizeRouteForMap(route) {
  if (!route) return null;
  const days = (route.days || []).map((d) => ({
    ...d,
    waypoints: (d.waypoints || []).map((w) => {
      const lat = Number(w.latitude ?? w.lat ?? NaN);
      const lon = Number(w.longitude ?? w.lon ?? NaN);
      return { ...w, latitude: lat, longitude: lon };
    }),
  }));
  return { ...route, days };
}
