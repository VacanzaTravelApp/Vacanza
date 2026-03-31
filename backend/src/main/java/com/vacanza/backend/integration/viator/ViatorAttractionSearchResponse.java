package com.vacanza.backend.integration.viator;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

/**
 * Normalized attraction search result for app use: {@code data[].id}, {@code data[].name}.
 * <p>
 * Wire sources:
 * <ul>
 *   <li>{@code POST /search/freetext} — {@code attractions.results[]} (sandbox uses {@code id})</li>
 *   <li>{@code POST /attractions/search} — {@code attractions[]} items use {@code attractionId}</li>
 * </ul>
 */
@Getter
@Setter
@NoArgsConstructor
@JsonIgnoreProperties(ignoreUnknown = true)
public class ViatorAttractionSearchResponse {

    private List<AttractionRow> data = new ArrayList<>();

    public static ViatorAttractionSearchResponse empty() {
        return new ViatorAttractionSearchResponse();
    }

    public static ViatorAttractionSearchResponse fromFreetextWire(ViatorFreetextSearchWire wire) {
        ViatorAttractionSearchResponse out = new ViatorAttractionSearchResponse();
        if (wire == null || wire.getAttractions() == null || wire.getAttractions().getResults() == null) {
            return out;
        }
        out.setData(wire.getAttractions().getResults());
        return out;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AttractionRow {
        @JsonAlias("attractionId")
        private Long id;
        private String name;
    }

    /** Root JSON for {@code POST /search/freetext} (attractions branch). */
    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class ViatorFreetextSearchWire {
        private AttractionsBlock attractions;
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AttractionsBlock {
        private List<AttractionRow> results;
        private Integer totalCount;
    }
}
