package com.vacanza.backend.service;

import com.vacanza.backend.dto.internal.PoiCategoryFamily;
import com.vacanza.backend.dto.internal.PoiResult;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.integration.FoursquareCategoryMapper;
import com.vacanza.backend.integration.FoursquareClient;
import com.vacanza.backend.integration.FoursquareClient.FoursquarePlaceDetail;
import com.vacanza.backend.integration.FoursquareClient.FsqCategory;
import com.vacanza.backend.repo.PointOfInterestRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PoiResultEnrichmentServiceTest {

    @Mock
    private PointOfInterestRepository poiRepository;
    @Mock
    private PoiCategoryFamilyResolver categoryFamilyResolver;
    @Mock
    private FoursquareClient foursquareClient;
    @Mock
    private FoursquareCategoryMapper foursquareCategoryMapper;

    @InjectMocks
    private PoiResultEnrichmentService enrichmentService;

    // ──────────────────────────────────────────────────────────────────────────
    // DB hit → merge from DB, Foursquare NOT called
    // ──────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("DB hit: merges rating/priceLevel and does NOT call Foursquare")
    void dbHit_mergesFields_noFoursquareCall() {
        PoiResult poi = poiWithFsqId("fsq123");

        PointOfInterest entity = PointOfInterest.builder()
                .poiId(UUID.randomUUID())
                .name(poi.getName())
                .category("cafe")
                .latitude(poi.getLat())
                .longitude(poi.getLon())
                .externalId("fsq123")
                .rating(4.5)
                .priceLevel("$$")
                .build();

        when(poiRepository.findByExternalId("fsq123")).thenReturn(Optional.of(entity));

        enrichmentService.enrichAll(List.of(poi));

        assertThat(poi.getRating()).isEqualTo(4.5);
        assertThat(poi.getPriceLevel()).isEqualTo("$$");
        verifyNoInteractions(foursquareClient);
    }

    // ──────────────────────────────────────────────────────────────────────────
    // DB miss + Foursquare hit → enrich and persist
    // ──────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("DB miss + Foursquare hit: persists to DB and merges rating")
    void dbMiss_foursquareHit_persistsAndMerges() {
        PoiResult poi = poiWithFsqId("fsq456");

        when(poiRepository.findByExternalId("fsq456")).thenReturn(Optional.empty());
        when(poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());

        FsqCategory cafeCategory = new FsqCategory();
        cafeCategory.setId(13032);
        cafeCategory.setName("Café");
        cafeCategory.setShortName("Café");

        FoursquarePlaceDetail detail = new FoursquarePlaceDetail();
        detail.setFsqId("fsq456");
        detail.setName("Mandabatmaz");
        detail.setRating(9.0); // Foursquare 0-10 scale
        detail.setPrice(2);    // "$$"
        detail.setCategories(List.of(cafeCategory));

        when(foursquareClient.getPlaceDetail("fsq456")).thenReturn(Mono.just(detail));
        when(foursquareCategoryMapper.resolveSubcategory(any())).thenReturn("cafe");
        when(foursquareCategoryMapper.resolveCuisineLabel(any())).thenReturn("Café");
        when(foursquareCategoryMapper.resolveFamily(any())).thenReturn(PoiCategoryFamily.FOOD);

        PointOfInterest saved = PointOfInterest.builder()
                .poiId(UUID.randomUUID())
                .name("Mandabatmaz")
                .category("cafe")
                .latitude(poi.getLat())
                .longitude(poi.getLon())
                .externalId("fsq456")
                .rating(4.5) // 9.0 / 2.0
                .priceLevel("$$")
                .cuisineType("Café")
                .build();

        when(poiRepository.save(any())).thenReturn(saved);

        enrichmentService.enrichAll(List.of(poi));

        verify(foursquareClient).getPlaceDetail("fsq456");
        verify(poiRepository).save(any(PointOfInterest.class));
        assertThat(poi.getRating()).isEqualTo(4.5);
        assertThat(poi.getPriceLevel()).isEqualTo("$$");
        assertThat(poi.getCategoryFamily()).isEqualTo(PoiCategoryFamily.FOOD);
        assertThat(poi.getCategory()).isEqualTo("cafe");
    }

    // ──────────────────────────────────────────────────────────────────────────
    // DB miss + no Foursquare ID → no API call, no crash
    // ──────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("DB miss + no FSQ ID: gracefully skips, no Foursquare call")
    void dbMiss_noFsqId_gracefulSkip() {
        PoiResult poi = new PoiResult("Unnamed Place", "tourism", 41.0, 28.0);
        // No external IDs, no externalId

        when(poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());

        enrichmentService.enrichAll(List.of(poi));

        verifyNoInteractions(foursquareClient);
        assertThat(poi.getRating()).isNull();
    }

    // ──────────────────────────────────────────────────────────────────────────
    // DB miss + Foursquare failure → graceful degradation, no exception
    // ──────────────────────────────────────────────────────────────────────────

    @Test
    @DisplayName("DB miss + Foursquare error: POI remains unenriched, no exception thrown")
    void dbMiss_foursquareError_gracefulDegrade() {
        PoiResult poi = poiWithFsqId("fsq789");

        when(poiRepository.findByExternalId("fsq789")).thenReturn(Optional.empty());
        when(poiRepository.findByLatitudeBetweenAndLongitudeBetween(
                anyDouble(), anyDouble(), anyDouble(), anyDouble()))
                .thenReturn(List.of());

        when(foursquareClient.getPlaceDetail("fsq789")).thenReturn(Mono.empty());

        enrichmentService.enrichAll(List.of(poi));

        assertThat(poi.getRating()).isNull();
        verify(foursquareClient).getPlaceDetail("fsq789");
        verify(poiRepository, never()).save(any());
    }

    // ──────────────────────────────────────────────────────────────────────────
    // Helper
    // ──────────────────────────────────────────────────────────────────────────

    private static PoiResult poiWithFsqId(String fsqId) {
        PoiResult poi = new PoiResult("Test Cafe", "cafe", 41.0082, 28.9784);
        poi.setExternalId(fsqId);
        poi.setExternalIds(Map.of("foursquare", fsqId));
        return poi;
    }
}
