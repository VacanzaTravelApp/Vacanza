package com.vacanza.backend.integration.viator;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.Ticker;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

import static org.assertj.core.api.Assertions.assertThat;
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
        Cache<String, ViatorWaypointPrice> cache = Caffeine.newBuilder()
                .maximumSize(5000)
                .expireAfterWrite(Duration.ofMinutes(60))
                .recordStats()
                .build();
        service = new ViatorWaypointPriceService(cache, viatorClient);
    }

    @Test
    void secondRequestForSameAttractionDoesNotCallViatorApi() {
        var row = new ViatorProductSearchResponse.ProductRow();
        row.setTitle("Tour");
        row.setProductUrl("https://viator.example/t");
        var pricing = new ViatorProductSearchResponse.ProductPricing();
        var summary = new ViatorProductSearchResponse.PricingSummary();
        summary.setFromPrice(new BigDecimal("42.00"));
        pricing.setSummary(summary);
        pricing.setCurrency("USD");
        row.setPricing(pricing);

        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));

        when(viatorClient.searchProducts(7L, "USD")).thenReturn(resp);

        ViatorWaypointPrice first = service.getMinPriceForAttraction(7L, "USD");
        ViatorWaypointPrice second = service.getMinPriceForAttraction(7L, "USD");

        assertThat(first.minPrice()).isEqualByComparingTo("42.00");
        assertThat(second.minPrice()).isEqualByComparingTo("42.00");
        verify(viatorClient, times(1)).searchProducts(7L, "USD");
    }

    @Test
    void afterTtlExpiresSecondLoadCallsViatorAgain() {
        AtomicLong nanos = new AtomicLong();
        Ticker ticker = nanos::get;
        Cache<String, ViatorWaypointPrice> cache = Caffeine.newBuilder()
                .ticker(ticker)
                .maximumSize(5000)
                .expireAfterWrite(1, TimeUnit.NANOSECONDS)
                .recordStats()
                .build();
        ViatorWaypointPriceService svc = new ViatorWaypointPriceService(cache, viatorClient);

        var row = new ViatorProductSearchResponse.ProductRow();
        row.setTitle("T");
        row.setProductUrl("https://x");
        var pricing = new ViatorProductSearchResponse.ProductPricing();
        var summary = new ViatorProductSearchResponse.PricingSummary();
        summary.setFromPrice(BigDecimal.ONE);
        pricing.setSummary(summary);
        pricing.setCurrency("USD");
        row.setPricing(pricing);
        var resp = new ViatorProductSearchResponse();
        resp.setProducts(List.of(row));
        when(viatorClient.searchProducts(2L, "USD")).thenReturn(resp);

        svc.getMinPriceForAttraction(2L, "USD");
        nanos.addAndGet(1L);
        svc.getMinPriceForAttraction(2L, "USD");

        verify(viatorClient, times(2)).searchProducts(2L, "USD");
    }
}
