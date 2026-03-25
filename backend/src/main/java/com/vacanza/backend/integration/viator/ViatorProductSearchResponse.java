package com.vacanza.backend.integration.viator;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Response shape for {@code POST /products/search} (product summaries).
 */
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class ViatorProductSearchResponse {

    private List<ProductRow> products = new ArrayList<>();
    private Integer totalCount;

    public static ViatorProductSearchResponse empty() {
        return new ViatorProductSearchResponse();
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProductRow {
        private String title;
        private ProductPricing pricing;
        private String productUrl;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ProductPricing {
        private PricingSummary summary;
        /** Denomination for summary prices (Partner API). */
        private String currency;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PricingSummary {
        private BigDecimal fromPrice;
    }
}
