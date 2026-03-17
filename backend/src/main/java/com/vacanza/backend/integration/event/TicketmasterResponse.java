package com.vacanza.backend.integration.event;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.response.EventDTO;
import lombok.Data;

import java.util.Collections;
import java.util.List;

/**
 * Jackson-annotated POJOs for deserializing the Ticketmaster Discovery API response.
 *
 * Ticketmaster API response structure:
 *   { "_embedded": { "events": [ ... ] }, "page": { ... } }
 *
 * Each event has: name, dates, _embedded.venues, images, classifications, url, etc.
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class TicketmasterResponse {

    @JsonProperty("_embedded")
    private Embedded embedded;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Embedded {
        private List<Event> events;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Event {
        private String id;
        private String name;
        private String url;
        private String info;
        private List<Image> images;
        private Dates dates;
        private Sales sales;

        @JsonProperty("_embedded")
        private EventEmbedded embedded;

        private List<Classification> classifications;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Image {
        private String url;
        private int width;
        private int height;
        private String ratio;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Dates {
        private Start start;
        private End end;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Start {
        private String localDate;
        private String localTime;
        private String dateTime;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class End {
        private String localDate;
        private String localTime;
        private String dateTime;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Sales {
        @JsonProperty("public")
        private PublicSales publicSales;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PublicSales {
        private String startDateTime;
        private String endDateTime;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class EventEmbedded {
        private List<Venue> venues;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Venue {
        private String name;
        private String url;
        private Address address;
        private City city;
        private Country country;
        private Location location;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Address {
        private String line1;
        private String line2;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class City {
        private String name;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Country {
        private String name;
        private String countryCode;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Location {
        private String longitude;
        private String latitude;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Classification {
        private boolean primary;
        private Segment segment;
        private Genre genre;
        private SubGenre subGenre;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Segment {
        private String id;
        private String name;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Genre {
        private String id;
        private String name;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class SubGenre {
        private String id;
        private String name;
    }

    // ──────────────────────────────────────────────────────────────
    // Conversion: Ticketmaster response → List<EventDTO>
    // ──────────────────────────────────────────────────────────────

    /**
     * Converts the raw Ticketmaster API response into a list of EventDTOs.
     */
    public static List<EventDTO> toEventDTOs(TicketmasterResponse response) {
        if (response == null || response.getEmbedded() == null
                || response.getEmbedded().getEvents() == null) {
            return Collections.emptyList();
        }

        return response.getEmbedded().getEvents().stream()
                .map(TicketmasterResponse::mapEvent)
                .toList();
    }

    private static EventDTO mapEvent(Event event) {
        EventDTO.EventDTOBuilder builder = EventDTO.builder()
                .id(event.getId())
                .name(event.getName())
                .description(event.getInfo())
                .link(event.getUrl())
                .ticketLink(event.getUrl());

        // Thumbnail — pick the first image with 16:9 ratio, or fallback to first image
        if (event.getImages() != null && !event.getImages().isEmpty()) {
            String thumbnail = event.getImages().stream()
                    .filter(img -> "16_9".equals(img.getRatio()))
                    .map(Image::getUrl)
                    .findFirst()
                    .orElse(event.getImages().get(0).getUrl());
            builder.thumbnail(thumbnail);
        }

        // Dates
        if (event.getDates() != null) {
            if (event.getDates().getStart() != null) {
                builder.startTime(event.getDates().getStart().getDateTime() != null
                        ? event.getDates().getStart().getDateTime()
                        : event.getDates().getStart().getLocalDate());
            }
            if (event.getDates().getEnd() != null) {
                builder.endTime(event.getDates().getEnd().getDateTime() != null
                        ? event.getDates().getEnd().getDateTime()
                        : event.getDates().getEnd().getLocalDate());
            }
        }

        // Venue info
        if (event.getEmbedded() != null && event.getEmbedded().getVenues() != null
                && !event.getEmbedded().getVenues().isEmpty()) {
            Venue venue = event.getEmbedded().getVenues().get(0);
            builder.venueName(venue.getName());

            if (venue.getCity() != null) {
                builder.city(venue.getCity().getName());
            }
            if (venue.getCountry() != null) {
                builder.country(venue.getCountry().getName());
            }
            if (venue.getAddress() != null) {
                String address = venue.getAddress().getLine1();
                if (venue.getAddress().getLine2() != null) {
                    address += ", " + venue.getAddress().getLine2();
                }
                builder.fullAddress(address);
            }
            if (venue.getLocation() != null) {
                try {
                    builder.latitude(Double.parseDouble(venue.getLocation().getLatitude()));
                    builder.longitude(Double.parseDouble(venue.getLocation().getLongitude()));
                } catch (NumberFormatException e) {
                    // Skip coordinates if parsing fails
                }
            }
        }

        // Category from primary classification
        if (event.getClassifications() != null && !event.getClassifications().isEmpty()) {
            Classification primary = event.getClassifications().stream()
                    .filter(Classification::isPrimary)
                    .findFirst()
                    .orElse(event.getClassifications().get(0));

            String category = "";
            if (primary.getSegment() != null) {
                category = primary.getSegment().getName();
            }
            if (primary.getGenre() != null) {
                category += " / " + primary.getGenre().getName();
            }
            builder.category(category);
        }

        // Virtual event detection — Ticketmaster doesn't have a direct flag,
        // so we check if the venue name contains "online" or "virtual"
        builder.isVirtual(false);
        if (event.getEmbedded() != null && event.getEmbedded().getVenues() != null) {
            boolean isVirtual = event.getEmbedded().getVenues().stream()
                    .anyMatch(v -> v.getName() != null
                            && (v.getName().toLowerCase().contains("online")
                                    || v.getName().toLowerCase().contains("virtual")));
            builder.isVirtual(isVirtual);
        }

        return builder.build();
    }
}
