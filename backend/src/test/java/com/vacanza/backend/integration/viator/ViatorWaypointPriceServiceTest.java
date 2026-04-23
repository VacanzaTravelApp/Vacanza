package com.vacanza.backend.integration.viator;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ViatorWaypointPriceServiceTest {

    @Mock
    private ViatorClient viatorClient;

    private ViatorWaypointPriceService service;

    @BeforeEach
    void setUp() {
        service = new ViatorWaypointPriceService(viatorClient);
    }

    // ── category filtering ────────────────────────────────────────────────────

    @Test
    void restaurantCategorySkipsViatorCall() {
        ViatorWaypointPrice result = service.getPrice("Fogo de Chão", "restaurant", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void cafeCategorySkipsViatorCall() {
        ViatorWaypointPrice result = service.getPrice("Sightglass Coffee", "coffee_shop", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void fastFoodCategorySkipsViatorCall() {
        ViatorWaypointPrice result = service.getPrice("In-N-Out Burger", "fast_food", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    // ── title relevance filtering ─────────────────────────────────────────────

    @Test
    void productWithIrrelevantTitleIsDiscarded() {
        var row = makeRow("San Francisco Food Tour", "https://viator.example/food", "80.00", "USD");
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProductsByName("In-N-Out Burger", "USD")).thenReturn(resp);

        // category null → not skipped by category filter, but title "San Francisco Food Tour"
        // contains no token from "In-N-Out Burger" (length ≥ 4, non-stop-word) → discarded
        ViatorWaypointPrice result = service.getPrice("In-N-Out Burger", null, "USD");

        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void productWithRelevantTitleIsKept() {
        var row = makeRow("Chinatown Walking Tour San Francisco", "https://viator.example/chinatown", "20.00", "USD");
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProductsByName("Chinatown San Francisco", "USD")).thenReturn(resp);

        ViatorWaypointPrice result = service.getPrice("Chinatown San Francisco", "neighborhood", "USD");

        assertThat(result.hasPrice()).isTrue();
        assertThat(result.minPrice()).isEqualByComparingTo("20.00");
    }

    // ── zero price filtering ──────────────────────────────────────────────────

    @Test
    void zeroPriceProductIsDiscarded() {
        var row = makeRow("SFMOMA Self-Guided Tour", "https://viator.example/sfmoma", "0.00", "USD");
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProductsByName("San Francisco Museum of Modern Art", "USD")).thenReturn(resp);

        ViatorWaypointPrice result = service.getPrice(
                "San Francisco Museum of Modern Art", "museum", "USD");

        assertThat(result.hasPrice()).isFalse();
    }

    // ── each call hits the API (no cache) ────────────────────────────────────

    @Test
    void eachCallFetchesFromViatorApi() {
        var row = makeRow("Fisherman's Wharf Bay Cruise", "https://viator.example/fw", "5.00", "USD");
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProductsByName("Fisherman's Wharf", "USD")).thenReturn(resp);

        service.getPrice("Fisherman's Wharf", "landmark", "USD");
        service.getPrice("Fisherman's Wharf", "landmark", "USD");

        verify(viatorClient, times(2)).searchProductsByName("Fisherman's Wharf", "USD");
    }

    // ── isTitleRelevant unit tests ────────────────────────────────────────────

    // ── name-token filter ─────────────────────────────────────────────────────

    @Test
    void bridgeInNameSkipsViatorEvenWhenCategoryIsLandmark() {
        ViatorWaypointPrice result = service.getPrice("Golden Gate Bridge", "landmark", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void streetInNameSkipsViator() {
        ViatorWaypointPrice result = service.getPrice("Lombard Street", "landmark", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void parkInNameSkipsViator() {
        ViatorWaypointPrice result = service.getPrice("Central Park", null, "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    @Test
    void parkInNameDoesNotSkipWhenCategoryIsAmusementPark() {
        var row = makeRow("Disneyland Park Tour", "https://viator.example/disney", "120.00", "USD");
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProductsByName("Disneyland Park", "USD")).thenReturn(resp);

        ViatorWaypointPrice result = service.getPrice("Disneyland Park", "amusement_park", "USD");

        assertThat(result.hasPrice()).isTrue();
    }

    @Test
    void turkishStreetNameSkipsViator() {
        ViatorWaypointPrice result = service.getPrice("İstiklal Caddesi", "landmark", "USD");

        verify(viatorClient, never()).searchProductsByName(any(), any());
        assertThat(result.hasPrice()).isFalse();
    }

    // ── hasNonTicketableNameToken unit tests ──────────────────────────────────

    @Test
    void nameTokenChecks() {
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("Golden Gate Bridge")).isTrue();
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("Lombard Street")).isTrue();
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("Central Park")).isTrue();
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("İstiklal Caddesi")).isTrue();
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("SFMOMA")).isFalse();
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("Chinatown San Francisco")).isFalse();
        // Wharf/pier areas have legitimate boat/walking tours — should NOT be blocked by name
        assertThat(ViatorWaypointPriceService.hasNonTicketableNameToken("Fisherman's Wharf")).isFalse();
    }

    // ── isTitleRelevant unit tests ────────────────────────────────────────────

    @Test
    void titleRelevanceChecks() {
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "Lombard Street Walking Tour", "Lombard Street")).isTrue();
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "San Francisco Food Tour", "In-N-Out Burger")).isFalse();
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "Golden Gate Bridge Bike Tour", "Golden Gate Bridge")).isTrue();
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "Chinatown Walking Food Tour SF", "Chinatown San Francisco")).isTrue();
        // Turkish: "İstiklal Caddesi" search should NOT match "Pizza Atölyesi Istanbul"
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "Pizza Atolyesi Istanbul Tour", "İstiklal Caddesi")).isFalse();
        // Turkish: "İstiklal Caddesi" should match a title containing "Istiklal"
        assertThat(ViatorWaypointPriceService.isTitleRelevant(
                "Istiklal Avenue Walking Tour", "İstiklal Caddesi")).isTrue();
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private static ViatorProductSearchResponse.ProductRow makeRow(
            String title, String url, String price, String currency) {
        var row = new ViatorProductSearchResponse.ProductRow();
        row.setTitle(title);
        row.setProductUrl(url);
        var pricing = new ViatorProductSearchResponse.ProductPricing();
        var summary = new ViatorProductSearchResponse.PricingSummary();
        summary.setFromPrice(new BigDecimal(price));
        pricing.setSummary(summary);
        pricing.setCurrency(currency);
        row.setPricing(pricing);
        return row;
    }
}
