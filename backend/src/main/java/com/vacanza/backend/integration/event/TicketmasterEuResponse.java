package com.vacanza.backend.integration.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.response.EventDTO;
import lombok.Data;

import java.util.Collections;
import java.util.List;

/**
 * Jackson POJOs for the Ticketmaster International Discovery API (app.ticketmaster.eu/mfxapi/v2).
 *
 * Response structure differs from the US Discovery API:
 *   { "events": [ ... ], "pagination": { ... } }
 *
 * Official reference: https://developer.ticketmaster.com/products-and-docs/apis/international-discovery/v2/
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TicketmasterEuResponse {

    private List<Event> events;
    private Pagination pagination;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Pagination {
        private int start;
        private int rows;
        private int total;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Event {
        private String id;
        private String domain;
        private String name;
        private String url;
        private EventDate eventdate;
        private String timezone;
        private Venue venue;
        private List<Category> categories;
        private List<Attraction> attractions;

        @JsonProperty("price_ranges")
        private PriceRanges priceRanges;

        private String currency;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class EventDate {
        private String format;
        private String value;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Venue {
        private String id;
        private String name;
        private Location location;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Location {
        private Address address;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Address {
        private String address;

        @JsonProperty("postal_code")
        private String postalCode;

        private String city;
        private String country;

        @JsonProperty("long")
        private Double longitude;

        @JsonProperty("lat")
        private Double latitude;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Category {
        private String name;
        private Integer id;
        private List<SubCategory> subcategories;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SubCategory {
        private String name;
        private Integer id;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Attraction {
        private Object id;
        private String name;
        private String url;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PriceRanges {
        @JsonProperty("excluding_ticket_fees")
        private PriceRange excludingTicketFees;

        @JsonProperty("including_ticket_fees")
        private PriceRange includingTicketFees;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PriceRange {
        private Double min;
        private Double max;
    }

    // ──────────────────────────────────────────────────────────────
    // Conversion: EU response → List<EventDTO>
    // ──────────────────────────────────────────────────────────────

    public static List<EventDTO> toEventDTOs(TicketmasterEuResponse response) {
        if (response == null || response.getEvents() == null) {
            return Collections.emptyList();
        }
        return response.getEvents().stream()
                .map(TicketmasterEuResponse::mapEvent)
                .toList();
    }

    private static EventDTO mapEvent(Event event) {
        EventDTO.EventDTOBuilder builder = EventDTO.builder()
                .id(event.getId())
                .name(event.getName())
                .link(event.getUrl())
                .ticketLink(event.getUrl());

        if (event.getEventdate() != null) {
            builder.startTime(event.getEventdate().getValue());
        }

        if (event.getVenue() != null) {
            builder.venueName(event.getVenue().getName());
            Location loc = event.getVenue().getLocation();
            if (loc != null && loc.getAddress() != null) {
                Address addr = loc.getAddress();
                builder.city(addr.getCity());
                builder.country(addr.getCountry());
                builder.fullAddress(addr.getAddress());
                if (addr.getLatitude() != null) {
                    builder.latitude(addr.getLatitude());
                }
                if (addr.getLongitude() != null) {
                    builder.longitude(addr.getLongitude());
                }
            }
        }

        if (event.getCategories() != null && !event.getCategories().isEmpty()) {
            Category primary = event.getCategories().get(0);
            String category = primary.getName() != null ? primary.getName() : "";
            if (primary.getSubcategories() != null && !primary.getSubcategories().isEmpty()) {
                String sub = primary.getSubcategories().get(0).getName();
                if (sub != null && !sub.isBlank()) {
                    category += " / " + sub;
                }
            }
            builder.category(category);
        }

        builder.isVirtual(false);
        if (event.getVenue() != null && event.getVenue().getName() != null) {
            String venueLower = event.getVenue().getName().toLowerCase();
            builder.isVirtual(venueLower.contains("online") || venueLower.contains("virtual"));
        }

        return builder.build();
    }
}
