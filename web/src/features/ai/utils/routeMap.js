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
