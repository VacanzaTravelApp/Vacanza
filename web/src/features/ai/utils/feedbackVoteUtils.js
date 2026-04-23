import { getWaypointCategory } from "./routeMap";

/** FNV-1a 64 over UTF-8 bytes; must match {@code PoiFeedbackKeyUtil.fnv1a64Utf8} (Java). */
function fnv1a64Utf8(str) {
  let h = 14695981039346656037n;
  const prime = 1099511628211n;
  const enc = new TextEncoder();
  for (const b of enc.encode(str)) {
    h ^= BigInt(b);
    h = (h * prime) & 0xffffffffffffffffn;
  }
  return h;
}

/**
 * Stable POI key when Foursquare / Mapbox ids are absent (AI waypoints, map discoveries).
 * @param {string|null|undefined} name raw name (trimmed + lowercased inside)
 * @param {number|null|undefined} lat
 * @param {number|null|undefined} lon
 * @returns {string|null}
 */
export function waypointIdentityPoiKey(name, lat, lon) {
  const la = lat != null ? Number(lat) : NaN;
  const lo = lon != null ? Number(lon) : NaN;
  if (!Number.isFinite(la) || !Number.isFinite(lo)) return null;
  const n = name == null ? "" : String(name).trim().toLowerCase();
  const payload = `${n}|${la.toFixed(6)}|${lo.toFixed(6)}`;
  const h = fnv1a64Utf8(payload);
  return `wp:${h.toString(16)}`;
}

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

/** Keys aligned with backend {@code PoiFeedbackKeyUtil} (fs → mb → wp). */
export function poiKeysForWaypoint(wp) {
  const keys = [];
  const { mapboxId, foursquareId } = pickWaypointIds(wp);
  if (foursquareId && String(foursquareId).trim()) {
    keys.push(`fs:${String(foursquareId).trim()}`);
  }
  if (mapboxId && String(mapboxId).trim()) {
    keys.push(`mb:${String(mapboxId).trim()}`);
  }
  const rawName = wp?.name != null ? String(wp.name).trim() : "";
  const lat = wp.latitude ?? wp.lat;
  const lon = wp.longitude ?? wp.lon;
  const wk = waypointIdentityPoiKey(rawName, lat, lon);
  if (wk) keys.push(wk);
  return keys;
}

/** True when feedback can be tied to a specific POI row in DB (including waypoint identity). */
export function hasPoiFeedbackKeys(wp) {
  return poiKeysForWaypoint(wp).length > 0;
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

/** Keys for Discover / map list POIs (same order as backend lookup). */
export function poiKeysForMapPoi(p) {
  const keys = [];
  const fs = p?.foursquare_id ?? p?.foursquareId ?? p?.external_id ?? p?.externalId ?? null;
  if (fs && String(fs).trim()) keys.push(`fs:${String(fs).trim()}`);
  const mb = p?.mapbox_id ?? p?.mapboxId ?? null;
  if (mb && String(mb).trim()) keys.push(`mb:${String(mb).trim()}`);
  const rawName = p?.name != null ? String(p.name).trim() : "";
  const lat = p?.latitude ?? p?.lat;
  const lon = p?.longitude ?? p?.lon;
  const wk = waypointIdentityPoiKey(rawName, lat, lon);
  if (wk) keys.push(wk);
  return keys;
}

/**
 * @param affinity {{ poiScores?: Record<string, number> }|null|undefined}
 */
export function deriveMapPoiFavorited(affinity, p) {
  if (!affinity || !p) return false;
  const ps = affinity.poiScores || {};
  let sum = 0;
  for (const k of poiKeysForMapPoi(p)) {
    const v = ps[k];
    if (v != null && Number.isFinite(Number(v))) sum += Number(v);
  }
  return sum > 0.01;
}

/** Body for POST /api/feedback/poi-events from a map / Discover list row. */
export function buildMapPoiFeedbackPayload(p) {
  const rawName = p?.name != null ? String(p.name).trim() : "";
  const lat = Number(p?.latitude ?? p?.lat);
  const lon = Number(p?.longitude ?? p?.lon);
  const mapboxId = p?.mapbox_id ?? p?.mapboxId ?? null;
  const foursquareId = p?.foursquare_id ?? p?.foursquareId ?? p?.external_id ?? p?.externalId ?? null;
  const cats = normalizeCategoryKeysFromString(p?.category);
  return {
    mapboxId: mapboxId || null,
    foursquareId: foursquareId || null,
    categoryKeys: cats.length ? cats : null,
    waypointName: rawName || null,
    latitude: Number.isFinite(lat) ? lat : null,
    longitude: Number.isFinite(lon) ? lon : null,
  };
}
