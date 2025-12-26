package com.vacanza.backend.service;

import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.GeoapifyClient;
import com.vacanza.backend.integration.GeoapifyResponse;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PoiIngestService {

    private final GeoapifyClient geoapifyClient;
    private final PointOfInterestRepository poiRepository;

    public int ingestFromGeoapifyArea(
            String filter,
            List<String> categories,
            int limit
    ) {
        try {
            GeoapifyResponse resp = geoapifyClient
                    .search(filter, categories, limit)
                    .block();

            if (resp == null || resp.getFeatures() == null) return 0;

            int saved = 0;

            for (var f : resp.getFeatures()) {
                if (f.getGeometry() == null) continue;
                if (f.getGeometry().getCoordinates() == null) continue;

                Double lng = f.getGeometry().getCoordinates().get(0);
                Double lat = f.getGeometry().getCoordinates().get(1);

                String externalId = "geoapify:" + f.getProperties().getPlace_id();

                PointOfInterest poi = poiRepository
                        .findByExternalId(externalId)
                        .orElseGet(PointOfInterest::new);

                poi.setExternalId(externalId);
                poi.setName(
                        f.getProperties().getName() != null
                                ? f.getProperties().getName()
                                : "Unnamed"
                );
                poi.setCategory(f.getProperties().getCategory());
                poi.setLatitude(lat);
                poi.setLongitude(lng);
                poi.setRating(f.getProperties().getRating());
                poi.setPriceLevel(f.getProperties().getPrice_level());

                poiRepository.save(poi);
                saved++;
            }

            return saved;

        } catch (Exception e) {
            e.printStackTrace();
            return 0; // ingest fail => API 500 olmasın
        }
    }

//    private final OverpassClient overpassClient;
//    private final PointOfInterestRepository poiRepository;
//
//    /**
//     * Fetch POIs from OSM Overpass within the given bbox and persist them into DB.
//     *
//     * Returns:
//     * - number of saved/updated records
//     * - 0 if Overpass returns empty or any error happens (so API won't 500)
//     */
//    public int ingestFromOverpassBbox(
//            double minLat,
//            double minLng,
//            double maxLat,
//            double maxLng,
//            List<String> normalizedCategories,
//            int limit
//    ) {
//        try {
//            System.out.println("INGEST start (OSM) bbox={minLat=" + minLat
//                    + ", minLng=" + minLng
//                    + ", maxLat=" + maxLat
//                    + ", maxLng=" + maxLng + "} cats=" + normalizedCategories);
//
//            OverpassResponse resp = overpassClient.searchByBbox(
//                    minLat, minLng, maxLat, maxLng, normalizedCategories, limit
//            );
//
//            if (resp == null || resp.getElements() == null) {
//                System.out.println("INGEST saved=0 (resp/elements null)");
//                return 0;
//            }
//
//            int saved = 0;
//
//            for (var el : resp.getElements()) {
//                if (el == null) continue;
//                if (el.getId() == null) continue;
//
//                // şimdilik sadece node
//                if (!"node".equalsIgnoreCase(el.getType())) continue;
//                if (el.getLat() == null || el.getLon() == null) continue;
//
//                Map<String, String> tags = el.getTags();
//                String name = (tags != null) ? tags.get("name") : null;
//                if (name == null || name.isBlank()) name = "Unnamed";
//
//                // category: tags içinde öncelik amenity/tourism/leisure
//                String category = extractCategory(tags);
//                category = (category == null || category.isBlank())
//                        ? "unknown"
//                        : category.trim().toLowerCase(Locale.ROOT);
//
//                // externalId: OSM node id
//                String externalId = "osm:node:" + el.getId();
//
//                PointOfInterest entity = poiRepository.findByExternalId(externalId)
//                        .orElseGet(PointOfInterest::new);
//
//                entity.setExternalId(externalId);
//                entity.setName(name);
//                entity.setCategory(category);
//                entity.setLatitude(el.getLat());
//                entity.setLongitude(el.getLon());
//
//                // OSM'de rating/price yok → null bırak
//                // entity.setRating(null);
//                // entity.setPriceLevel(null);
//
//                poiRepository.save(entity);
//                saved++;
//            }
//
//            System.out.println("INGEST saved=" + saved);
//            return saved;
//
//        } catch (Exception e) {
//            System.out.println("INGEST failed -> return 0");
//            e.printStackTrace();
//            return 0;
//        }
//    }
//
//    private String extractCategory(Map<String, String> tags) {
//        if (tags == null) return null;
//        if (tags.get("amenity") != null) return tags.get("amenity");
//        if (tags.get("tourism") != null) return tags.get("tourism");
//        if (tags.get("leisure") != null) return tags.get("leisure");
//        if (tags.get("shop") != null) return tags.get("shop");
//        return null;
//    }
}