package com.vacanza.backend.service;

import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.GeoapifyClient;
import com.vacanza.backend.integration.GeoapifyResponse;
import com.vacanza.backend.repo.PointOfInterestRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class PoiIngestService {

    private final GeoapifyClient geoapifyClient;
    private final PointOfInterestRepository poiRepository;

    /**
     * Geoapify'den area (rect veya polygon filter) içinde POI çekip DB'ye kaydeder.
     *
     * IMPORTANT:
     * - geoapifyCategories genelde 1 adet category ile çağrılmalı (loop ile).
     * - DB'de sakladığımız category INTERNAL category olmalı: museum/restaurant/market/cafe/other
     */
    @Transactional
    public int ingestFromGeoapifyArea(String filter, List<String> geoapifyCategories, int limit) {

        // Geoapify "categories" parametresi boşsa default verelim
        List<String> safeGeoapifyCategories =
                (geoapifyCategories == null || geoapifyCategories.isEmpty())
                        ? List.of("tourism.sights")
                        : geoapifyCategories;

        // Bu ingest çağrısında "biz neyi arattık?" (Geoapify taxonomy)
        // Örn: "entertainment.museum" veya "catering.restaurant"
        String requestedGeoapifyCategory = safeGeoapifyCategories.get(0);

        // "Biz neyi arattık?" → INTERNAL fallback (museum/restaurant/...)
        // Geoapify response category null gelirse bunu kullanacağız.
        String fallbackInternalCategory = mapRequestedGeoapifyCategoryToInternal(requestedGeoapifyCategory);

        GeoapifyResponse resp = geoapifyClient
                .search(filter, safeGeoapifyCategories, limit)
                .block();

        if (resp == null || resp.getFeatures() == null || resp.getFeatures().isEmpty()) {
            return 0;
        }

        int saved = 0;

        for (GeoapifyResponse.Feature f : resp.getFeatures()) {
            if (f == null || f.getProperties() == null || f.getGeometry() == null) {
                continue;
            }

            // Geoapify coords: [lng, lat]
            List<Double> coords = f.getGeometry().getCoordinates();
            if (coords == null || coords.size() < 2 || coords.get(0) == null || coords.get(1) == null) {
                continue;
            }

            double lng = coords.get(0);
            double lat = coords.get(1);

            // external id (place_id) null olursa bunu skip et (idempotency için şart)
            String externalId = f.getProperties().getPlace_id();
            if (externalId == null || externalId.isBlank()) {
                continue;
            }

            // Duplicate kontrolü (DB zaten unique ise yine iyi ama burada da koruyalım)
            if (poiRepository.existsByExternalId(externalId)) {
                continue;
            }

            // Name null gelirse default
            String name = f.getProperties().getName();
            if (name == null || name.isBlank()) {
                name = "Unnamed";
            }

            // 🔥 EN ÖNEMLİ YER:
            // Geoapify'nin döndürdüğü category bazen null geliyor.
            // O zaman "biz ne arattıysak" (fallbackInternalCategory) onu DB'ye yazıyoruz.
            String geoapifyCategoryFromResponse = f.getProperties().getCategory();
            String internalCategory = mapGeoapifyResponseCategoryToInternal(
                    geoapifyCategoryFromResponse,
                    fallbackInternalCategory
            );

            PointOfInterest poi = new PointOfInterest();
            poi.setExternalId(externalId);
            poi.setName(name);
            poi.setCategory(internalCategory);

            poi.setLatitude(lat);
            poi.setLongitude(lng);

            // Opsiyonel alanlar
            poi.setRating(f.getProperties().getRating());
            poi.setPriceLevel(f.getProperties().getPrice_level());

            // description vs. varsa burada set edebilirsin
            // poi.setDescription(...);

            poiRepository.save(poi);
            saved++;
        }

        return saved;
    }

    /**
     * "Biz request'te hangi Geoapify category ile arattık?" → INTERNAL category.
     * Bu fallback olarak kullanılacak (Geoapify response category null gelirse).
     */
    private String mapRequestedGeoapifyCategoryToInternal(String requestedGeoapifyCategory) {
        if (requestedGeoapifyCategory == null) return "other";

        // requested category zaten Geoapify taxonomy
        if (requestedGeoapifyCategory.startsWith("entertainment.museum")) return "museum";
        if (requestedGeoapifyCategory.startsWith("catering.restaurant")) return "restaurant";
        if (requestedGeoapifyCategory.startsWith("catering.cafe")) return "cafe";
        if (requestedGeoapifyCategory.startsWith("commercial.supermarket")) return "market";

        // tourism.sights gibi geniş şeyler geldiğinde:
        if (requestedGeoapifyCategory.startsWith("tourism.")) return "other";

        return "other";
    }

    /**
     * Geoapify response category → INTERNAL category.
     * Eğer response category null/unknown gelirse fallbackInternalCategory kullanılır.
     */
    private String mapGeoapifyResponseCategoryToInternal(String geoapifyCategoryFromResponse,
                                                         String fallbackInternalCategory) {

        if (fallbackInternalCategory == null || fallbackInternalCategory.isBlank()) {
            fallbackInternalCategory = "other";
        }

        // response category yoksa => fallback
        if (geoapifyCategoryFromResponse == null || geoapifyCategoryFromResponse.isBlank()) {
            return fallbackInternalCategory;
        }

        // response category varsa onu daha doğru eşle
        if (geoapifyCategoryFromResponse.startsWith("entertainment.museum")) return "museum";
        if (geoapifyCategoryFromResponse.startsWith("catering.restaurant")) return "restaurant";
        if (geoapifyCategoryFromResponse.startsWith("catering.cafe")) return "cafe";
        if (geoapifyCategoryFromResponse.startsWith("commercial.supermarket")) return "market";

        // başka şey geldiyse, yine fallback’e dön (biz ne arattıysak o)
        return fallbackInternalCategory;
    }


}
