/**
 * Category-to-color mapping for route waypoints.
 * Matches UI_CATEGORIES ring colors where applicable.
 */
const CATEGORY_COLORS = {
  restaurant: "#FFB020",
  cafe: "#6F4E37",
  museum: "#9B51E0",
  monument: "#FF7A45",
  monuments: "#FF7A45",
  park: "#27AE60",
  parks: "#27AE60",
  beach: "#0EA5E9",
  landmark: "#F59E0B",
  market: "#84CC16",
  nightlife: "#8B5CF6",
  hotel: "#EC4899",
  mosque: "#14B8A6",
  church: "#6366F1",
  palace: "#F97316",
  square: "#22C55E",
  bridge: "#3B82F6",
  theater: "#A855F7",
  zoo: "#10B981",
  aquarium: "#06B6D4",
  spa: "#EC4899",
  sports: "#EF4444",
};

const DEFAULT_COLOR = "#F97316";

export function getCategoryColor(category) {
  if (!category || typeof category !== "string") return DEFAULT_COLOR;
  const key = String(category).trim().toLowerCase();
  return CATEGORY_COLORS[key] || DEFAULT_COLOR;
}
