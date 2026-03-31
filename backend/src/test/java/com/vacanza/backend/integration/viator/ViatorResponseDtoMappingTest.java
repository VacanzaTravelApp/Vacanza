package com.vacanza.backend.integration.viator;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

import static org.assertj.core.api.Assertions.assertThat;

class ViatorResponseDtoMappingTest {

    private final ObjectMapper objectMapper = Jackson2ObjectMapperBuilder.json().build();

    @Test
    void freetextWire_mapsToAttractionData() throws Exception {
        var json = getClass().getResourceAsStream("/viator/freetext-attractions-sample.json");
        ViatorAttractionSearchResponse.ViatorFreetextSearchWire wire =
                objectMapper.readValue(json, ViatorAttractionSearchResponse.ViatorFreetextSearchWire.class);
        ViatorAttractionSearchResponse mapped = ViatorAttractionSearchResponse.fromFreetextWire(wire);
        assertThat(mapped.getData()).hasSize(1);
        assertThat(mapped.getData().get(0).getId()).isEqualTo(14159L);
        assertThat(mapped.getData().get(0).getName()).isEqualTo("Hagia Sophia Museum");
    }

    @Test
    void productsSearch_parsesTitlePricingAndUrl() throws Exception {
        var json = getClass().getResourceAsStream("/viator/products-search-sample.json");
        ViatorProductSearchResponse r = objectMapper.readValue(json, ViatorProductSearchResponse.class);
        assertThat(r.getProducts()).hasSize(1);
        var p = r.getProducts().get(0);
        assertThat(p.getTitle()).contains("Hagia Sophia");
        assertThat(p.getProductUrl()).startsWith("https://");
        assertThat(p.getPricing().getSummary().getFromPrice()).isEqualByComparingTo("45.0");
        assertThat(p.getPricing().getCurrency()).isEqualTo("USD");
    }
}
