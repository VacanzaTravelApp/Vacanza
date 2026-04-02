package com.vacanza.backend.integration.booking;

import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion.AutocompleteResponse;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion.AirportEntry;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion.SubAirport;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for flight search mapping fixes:
 * 1. SerpApiFlightResponse — externalBookingUrl uses airport names, not IATA codes
 * 2. SerpApiAirportSuggestion — sub-airport kgmid mapping
 */
class FlightSearchMappingTest {

    // ═══════════════════════════════════════════════════
    // 1) externalBookingUrl tests
    // ═══════════════════════════════════════════════════

    @Nested
    @DisplayName("SerpApiFlightResponse — externalBookingUrl")
    class BookingUrlTests {

        @Test
        @DisplayName("URL should contain airport names, not IATA codes")
        void urlUsesAirportNames() {
            SerpApiFlightResponse response = buildFlightResponse(
                    "Istanbul Airport", "IST", "2025-07-01 08:30",
                    "Paris Charles de Gaulle Airport", "CDG", "2025-07-01 12:45",
                    250);

            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(response, "USD");

            assertFalse(results.isEmpty(), "Should have at least one result");
            TransportOptionDTO dto = results.get(0);
            String url = dto.getExternalBookingUrl();

            assertNotNull(url, "Booking URL should not be null");
            assertTrue(url.contains("Istanbul"), "URL should contain origin airport name, got: " + url);
            assertTrue(url.contains("Charles+de+Gaulle") || url.contains("Charles%20de%20Gaulle"),
                    "URL should contain destination airport name (URL encoded), got: " + url);
            assertFalse(url.matches(".*[?&]q=IST.*"), "URL should NOT contain raw IATA code as query start");
        }

        @Test
        @DisplayName("URL should be properly URL-encoded")
        void urlIsEncoded() {
            SerpApiFlightResponse response = buildFlightResponse(
                    "São Paulo–Guarulhos", "GRU", "2025-08-15 14:00",
                    "Frankfurt am Main", "FRA", "2025-08-16 06:30",
                    800);

            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(response, "EUR");
            String url = results.get(0).getExternalBookingUrl();

            assertTrue(url.startsWith("https://www.google.com/travel/flights?q="),
                    "URL should start with Google Travel base");
            // URL-encoded characters: spaces as +, special chars as %XX
            assertFalse(url.contains(" "), "URL should not contain raw spaces");
        }

        @Test
        @DisplayName("URL handles null airport names gracefully (falls back to ID)")
        void urlFallsBackToIdWhenNameNull() {
            SerpApiFlightResponse response = buildFlightResponse(
                    null, "IST", "2025-07-01 08:30",
                    null, "CDG", "2025-07-01 12:45",
                    300);

            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(response, "USD");
            String url = results.get(0).getExternalBookingUrl();

            assertNotNull(url, "URL should still be generated when names are null");
            assertTrue(url.contains("IST"), "Should fall back to IATA code when name is null");
        }

        @Test
        @DisplayName("URL handles null departure time")
        void urlHandlesNullDepartureTime() {
            SerpApiFlightResponse response = buildFlightResponse(
                    "Istanbul Airport", "IST", null,
                    "London Heathrow", "LHR", "2025-07-01 18:00",
                    450);

            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(response, "USD");
            String url = results.get(0).getExternalBookingUrl();

            assertNotNull(url, "URL should handle null departure time");
            assertTrue(url.contains("Istanbul"), "Should still have origin name");
        }

        @Test
        @DisplayName("Null response returns empty list")
        void nullResponseReturnsEmpty() {
            List<TransportOptionDTO> results = SerpApiFlightResponse.toTransportOptions(null, "USD");
            assertTrue(results.isEmpty());
        }
    }

    // ═══════════════════════════════════════════════════
    // 2) SerpApiAirportSuggestion kgmid tests
    // ═══════════════════════════════════════════════════

    @Nested
    @DisplayName("SerpApiAirportSuggestion — kgmid mapping")
    class KgmidMappingTests {

        @Test
        @DisplayName("Sub-airport with IATA id gets iataCode set, kgmid null")
        void subAirportWithIataCode() {
            AutocompleteResponse response = buildCityCluster(
                    "/m/0203v", "Istanbul",
                    List.of(subAirport("IST", "Istanbul Airport"),
                            subAirport("SAW", "Sabiha Gökçen Airport")));

            List<SerpApiAirportSuggestion> suggestions = SerpApiAirportSuggestion.fromResponse(response);

            // Find the IST sub-airport
            SerpApiAirportSuggestion ist = suggestions.stream()
                    .filter(s -> "IST".equals(s.getIataCode()))
                    .findFirst().orElseThrow();

            assertEquals("IST", ist.getIataCode());
            assertNull(ist.getKgmid(), "IATA-based sub-airport should not have kgmid");
            assertEquals("Istanbul Airport", ist.getName());
        }

        @Test
        @DisplayName("Sub-airport with kgmid gets kgmid set, iataCode null")
        void subAirportWithKgmid() {
            AutocompleteResponse response = buildCityCluster(
                    "/m/0203v", "Istanbul",
                    List.of(subAirport("/m/abc123", "Some Regional Airport"),
                            subAirport("IST", "Istanbul Airport")));

            List<SerpApiAirportSuggestion> suggestions = SerpApiAirportSuggestion.fromResponse(response);

            SerpApiAirportSuggestion regional = suggestions.stream()
                    .filter(s -> "Some Regional Airport".equals(s.getName()))
                    .findFirst().orElseThrow();

            assertNull(regional.getIataCode(), "kgmid-based sub-airport should not have iataCode");
            assertEquals("/m/abc123", regional.getKgmid(), "kgmid should be set for kgmid-based sub-airport");
        }

        @Test
        @DisplayName("City-level 'All airports' entry gets kgmid set")
        void cityLevelKgmidSet() {
            AutocompleteResponse response = buildCityCluster(
                    "/m/0203v", "Istanbul",
                    List.of(subAirport("IST", "Istanbul Airport")));

            List<SerpApiAirportSuggestion> suggestions = SerpApiAirportSuggestion.fromResponse(response);

            SerpApiAirportSuggestion allAirports = suggestions.stream()
                    .filter(s -> s.getName() != null && s.getName().startsWith("All airports"))
                    .findFirst().orElseThrow();

            assertEquals("/m/0203v", allAirports.getKgmid());
            assertNull(allAirports.getIataCode(), "City-level kgmid should not set iataCode");
        }

        @Test
        @DisplayName("Direct airport entry with kgmid id")
        void directAirportWithKgmid() {
            AutocompleteResponse response = new AutocompleteResponse();
            AirportEntry entry = new AirportEntry();
            entry.setId("/m/xyz789");
            entry.setName("Small Regional Airport");
            entry.setCity("SomeCity");
            entry.setCountry("SomeCountry");
            entry.setAirports(null); // no sub-airports
            response.setAirports(List.of(entry));

            List<SerpApiAirportSuggestion> suggestions = SerpApiAirportSuggestion.fromResponse(response);

            assertEquals(1, suggestions.size());
            SerpApiAirportSuggestion s = suggestions.get(0);
            assertNull(s.getIataCode());
            assertEquals("/m/xyz789", s.getKgmid());
        }

        @Test
        @DisplayName("Null response returns empty list")
        void nullResponseReturnsEmpty() {
            assertTrue(SerpApiAirportSuggestion.fromResponse(null).isEmpty());
        }

        @Test
        @DisplayName("Entries with blank name are filtered out")
        void blankNamesFiltered() {
            AutocompleteResponse response = new AutocompleteResponse();
            AirportEntry entry = new AirportEntry();
            entry.setId("IST");
            entry.setName("   ");
            entry.setAirports(null);
            response.setAirports(List.of(entry));

            List<SerpApiAirportSuggestion> suggestions = SerpApiAirportSuggestion.fromResponse(response);
            assertTrue(suggestions.isEmpty(), "Blank-name entries should be filtered out");
        }
    }

    // ═══════════════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════════════

    private static SerpApiFlightResponse buildFlightResponse(
            String depName, String depId, String depTime,
            String arrName, String arrId, String arrTime,
            int price) {

        SerpApiFlightResponse.Airport depAirport = new SerpApiFlightResponse.Airport();
        depAirport.setName(depName);
        depAirport.setId(depId);
        depAirport.setTime(depTime);

        SerpApiFlightResponse.Airport arrAirport = new SerpApiFlightResponse.Airport();
        arrAirport.setName(arrName);
        arrAirport.setId(arrId);
        arrAirport.setTime(arrTime);

        SerpApiFlightResponse.Flight flight = new SerpApiFlightResponse.Flight();
        flight.setDepartureAirport(depAirport);
        flight.setArrivalAirport(arrAirport);
        flight.setDuration(135);
        flight.setAirline("Test Airlines");
        flight.setFlightNumber("TA100");
        flight.setTravelClass("Economy");

        SerpApiFlightResponse.FlightGroup group = new SerpApiFlightResponse.FlightGroup();
        group.setFlights(List.of(flight));
        group.setTotalDuration(135);
        group.setPrice(price);
        group.setBookingToken("test-token");

        SerpApiFlightResponse response = new SerpApiFlightResponse();
        response.setBestFlights(List.of(group));
        return response;
    }

    private static AutocompleteResponse buildCityCluster(
            String cityId, String cityName, List<SubAirport> subAirports) {
        AirportEntry entry = new AirportEntry();
        entry.setId(cityId);
        entry.setName(cityName);
        entry.setCity(cityName);
        entry.setCountry("Turkey");
        entry.setAirports(subAirports);

        AutocompleteResponse response = new AutocompleteResponse();
        response.setAirports(List.of(entry));
        return response;
    }

    private static SubAirport subAirport(String id, String name) {
        SubAirport sub = new SubAirport();
        sub.setId(id);
        sub.setName(name);
        return sub;
    }
}
