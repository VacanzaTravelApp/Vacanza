package com.vacanza.backend.integration;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

/**
 * Foursquare Places API v3 client.
 *
 * <p>Used for cache-first POI enrichment: when a POI has a Foursquare external ID
 * from Mapbox but no DB record exists, this client fetches the details and the
 * enrichment service writes them to the DB for future cache hits.
 *
 * <p>API docs: https://docs.foursquare.com/developer/reference/place-details
 */
@Slf4j
@Component
public class FoursquareClient {

    private static final String FIELDS =
            "fsq_id,name,categories,rating,hours,price,location,description";

    private final WebClient webClient;

    public FoursquareClient(@Qualifier("foursquareWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    /**
     * Fetch place detail by Foursquare place ID.
     * Returns {@link Mono#empty()} on any error (404, auth failure, timeout, etc.)
     * so the caller can gracefully degrade.
     *
     * @param fsqId Foursquare place ID (e.g. "4b058764f964a520b5dc22e3")
     */
    public Mono<FoursquarePlaceDetail> getPlaceDetail(String fsqId) {
        if (fsqId == null || fsqId.isBlank()) {
            return Mono.empty();
        }
        log.info("[FOURSQUARE] Fetching place detail: fsqId={}", fsqId);
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/places/{fsqId}")
                        .queryParam("fields", FIELDS)
                        .build(fsqId))
                .retrieve()
                .bodyToMono(FoursquarePlaceDetail.class)
                .doOnNext(d -> log.info("[FOURSQUARE] Got detail for fsqId={}: name={}, rating={}",
                        fsqId, d.getName(), d.getRating()))
                .onErrorResume(e -> {
                    log.warn("[FOURSQUARE] Failed for fsqId={}: {}", fsqId, e.getMessage());
                    return Mono.empty();
                });
    }

    // ─── Response POJOs ───────────────────────────────────────────────────────

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FoursquarePlaceDetail {

        @JsonProperty("fsq_id")
        private String fsqId;

        private String name;

        /** Aggregate score 0–10. */
        private Double rating;

        /** 1=cheap, 2=moderate, 3=expensive, 4=very expensive. */
        private Integer price;

        private List<FsqCategory> categories;

        private Hours hours;

        private String description;

        private Location location;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class FsqCategory {
        private Integer id;
        private String name;

        @JsonProperty("short_name")
        private String shortName;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Hours {
        @JsonProperty("open_now")
        private Boolean openNow;

        /** List of weekday descriptors, e.g. ["Monday: 8:00 AM – 10:00 PM", ...] */
        @JsonProperty("display")
        private List<String> display;

        /** Structured regular hours — list of day+open+close entries. */
        private List<RegularHour> regular;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class RegularHour {
        /** Day: 1=Mon … 7=Sun */
        private Integer day;
        /** "HHmm" format, e.g. "0800" */
        private String open;
        /** "HHmm" format, e.g. "2200" */
        private String close;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Location {
        private String address;
        private String country;
        private String locality;
    }
}
