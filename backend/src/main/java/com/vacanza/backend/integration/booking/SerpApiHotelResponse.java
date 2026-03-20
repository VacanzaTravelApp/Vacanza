package com.vacanza.backend.integration.booking;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;

/**
 * Jackson POJOs for deserializing SerpApi Google Hotels response.
 *
 * GET
 * /search.json?engine=google_hotels&q=...&check_in_date=...&check_out_date=...
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class SerpApiHotelResponse {

    private List<Property> properties;

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Property {
        private String type;
        private String name;
        private String description;
        private String link;
        @JsonProperty("property_token")
        private String propertyToken;
        @JsonProperty("gps_coordinates")
        private GpsCoordinates gpsCoordinates;
        @JsonProperty("check_in_time")
        private String checkInTime;
        @JsonProperty("check_out_time")
        private String checkOutTime;
        @JsonProperty("rate_per_night")
        private Rate ratePerNight;
        @JsonProperty("total_rate")
        private Rate totalRate;
        @JsonProperty("hotel_class")
        private String hotelClass;
        @JsonProperty("extracted_hotel_class")
        private Integer extractedHotelClass;
        @JsonProperty("overall_rating")
        private Double overallRating;
        private Integer reviews;
        private List<Image> images;
        private List<String> amenities;
        private List<PriceSource> prices;
        @JsonProperty("nearby_places")
        private List<NearbyPlace> nearbyPlaces;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class GpsCoordinates {
        private Double latitude;
        private Double longitude;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Rate {
        private String lowest;
        @JsonProperty("extracted_lowest")
        private Double extractedLowest;
        @JsonProperty("before_taxes_fees")
        private String beforeTaxesFees;
        @JsonProperty("extracted_before_taxes_fees")
        private Double extractedBeforeTaxesFees;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Image {
        private String thumbnail;
        @JsonProperty("original_image")
        private String originalImage;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class PriceSource {
        private String source;
        private String logo;
        @JsonProperty("rate_per_night")
        private Rate ratePerNight;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class NearbyPlace {
        private String name;
    }

    // --- Mapping ---

    public static List<AccommodationOptionDTO> toAccommodationOptions(
            SerpApiHotelResponse response, String currency) {
        if (response == null || response.getProperties() == null) {
            return Collections.emptyList();
        }

        return response.getProperties().stream()
                .filter(p -> p.getRatePerNight() != null
                        && p.getRatePerNight().getExtractedLowest() != null)
                .map(p -> {
                    BigDecimal pricePerNight = BigDecimal.valueOf(
                            p.getRatePerNight().getExtractedLowest());

                    BigDecimal totalPrice = null;
                    if (p.getTotalRate() != null
                            && p.getTotalRate().getExtractedLowest() != null) {
                        totalPrice = BigDecimal.valueOf(
                                p.getTotalRate().getExtractedLowest());
                    }

                    String imageUrl = null;
                    if (p.getImages() != null && !p.getImages().isEmpty()) {
                        imageUrl = p.getImages().get(0).getOriginalImage();
                        if (imageUrl == null) {
                            imageUrl = p.getImages().get(0).getThumbnail();
                        }
                    }

                    // Build external booking URL — use property link if
                    // available, otherwise Google Hotels search
                    String bookingUrl = p.getLink();
                    if (bookingUrl == null || bookingUrl.isBlank()) {
                        bookingUrl = String.format(
                                "https://www.google.com/travel/hotels?q=%s",
                                p.getName() != null
                                        ? p.getName().replace(" ", "+")
                                        : "");
                    }

                    return AccommodationOptionDTO.builder()
                            .providerName("Google Hotels")
                            .hotelName(p.getName())
                            .hotelId(p.getPropertyToken())
                            .description(p.getDescription())
                            .address(null) // Google Hotels doesn't return
                                           // street address in list view
                            .price(totalPrice)
                            .pricePerNight(pricePerNight)
                            .currency(currency)
                            .rating(p.getOverallRating())
                            .totalReviews(p.getReviews())
                            .hotelClass(p.getExtractedHotelClass())
                            .imageUrl(imageUrl)
                            .latitude(p.getGpsCoordinates() != null
                                    ? p.getGpsCoordinates().getLatitude()
                                    : null)
                            .longitude(p.getGpsCoordinates() != null
                                    ? p.getGpsCoordinates().getLongitude()
                                    : null)
                            .externalBookingUrl(bookingUrl)
                            .build();
                })
                .toList();
    }
}
