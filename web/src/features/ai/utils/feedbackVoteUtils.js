import { getWaypointCategory } from "./routeMap";

/** @returns {{ mapboxId: string|null, foursquareId: string|null }} */
export function pickWaypointIds(wp) {
  if (!wp) {
    return { mapboxId: null, foursquareId: null };
  }
  const mapboxId = wp.mapbox_id ?? wp.mapboxId ?? null;
  const foursquareId =
    wp.foursquare_id ?? wp.foursquareId ?? wp.external_id ?? wp.externalId ?? null;
  return { mapboxId, foursquareId };
}

/** Keys aligned with backend {@code PoiFeedbackKeyUtil}. */
export function poiKeysForWaypoint(wp) {
  const keys = [];
  const { mapboxId, foursquareId } = pickWaypointIds(wp);
  if (foursquareId && String(foursquareId).trim()) {
    keys.push(`fs:${String(foursquareId).trim()}`);
  }
  if (mapboxId && String(mapboxId).trim()) {
    keys.push(`mb:${String(mapboxId).trim()}`);
  }
  return keys;
}

function normalizeCategoryKeysFromString(category) {
  if (category == null || String(category).trim() === "") return [];
  return [String(category).toLowerCase().trim().replace(/-/g, "_")];
}

/**
 * @param affinity {{ poiScores?: Record<string, number>, categoryScores?: Record<string, number> }|null|undefined}
 * @returns {'up'|'down'|null}
 */
export function deriveWaypointVote(affinity, wp) {
  if (!affinity || !wp) return null;
  const ps = affinity.poiScores || {};
  const cs = affinity.categoryScores || {};
  let poiSum = 0;
  for (const k of poiKeysForWaypoint(wp)) {
    const v = ps[k];
    if (v != null && Number.isFinite(Number(v))) poiSum += Number(v);
  }
  if (Math.abs(poiSum) > 0.01) return poiSum > 0 ? "up" : "down";
  const cats = normalizeCategoryKeysFromString(getWaypointCategory(wp));
  let catSum = 0;
  for (const k of cats) {
    const v = cs[k];
    if (v != null && Number.isFinite(Number(v))) catSum += Number(v);
  }
  if (Math.abs(catSum) > 0.01) return catSum > 0 ? "up" : "down";
  return null;
}

/**
 * @param categoryKeys normalized keys (same as collectRouteCategoryKeys output)
 */
export function deriveRouteVote(affinity, categoryKeys) {
  if (!affinity || !categoryKeys?.length) return null;
  const cs = affinity.categoryScores || {};
  let sum = 0;
  let n = 0;
  for (const k of categoryKeys) {
    const v = cs[k];
    if (v != null && Number.isFinite(Number(v))) {
      sum += Number(v);
      n++;
    }
  }
  if (n === 0) return null;
  const avg = sum / n;
  if (avg > 0.01) return "up";
  if (avg < -0.01) return "down";
  return null;
}
