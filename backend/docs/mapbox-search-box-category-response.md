# Mapbox Search Box: `/v1/category/{id}` response (Vacanza)

Official reference: [Search Box API — Search for POIs by category](https://docs.mapbox.com/api/search/search-box/#retrieve-pois-by-category).

## What we use

The endpoint returns a GeoJSON `FeatureCollection`. Each **Feature** has:

- `geometry.type` = `Point`
- `geometry.coordinates` = `[longitude, latitude]` (fallback if `properties.coordinates` is missing)
- `properties.name` (required)
- `properties.mapbox_id` (required) — stable id; stored in `PoiResult.mapboxId`
- `properties.coordinates.latitude` / `longitude` (required in practice for POIs)
- `properties.maki` (optional)
- `properties.poi_category_ids` (optional) — canonical category strings; copied to `PoiResult.poiCategoryIds`
- `properties.external_ids` (optional) — map of source → id; we copy to `PoiResult.externalIds` and set `PoiResult.externalId` from `foursquare` when present (for `PointOfInterest.externalId` join)

## What we do not get from this endpoint

Per Mapbox documentation, the category response does **not** include aggregate **rating** or **review count**. Those remain `null` on `PoiResult` unless filled by **DB enrichment** (`PoiResultEnrichmentService` → `points_of_interest`).

Opening hours are not modeled in the category payload; `openingHoursUnknown` stays `true` until DB provides `start_time` / `end_time`.

## Version note

Mapbox may add fields; inner DTOs use `@JsonIgnoreProperties(ignoreUnknown = true)` so unknown properties are ignored safely.
