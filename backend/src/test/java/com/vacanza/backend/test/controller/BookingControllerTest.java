package com.vacanza.backend.test.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.vacanza.backend.controller.BookingController;
import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion;
import com.vacanza.backend.service.BookingService;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = BookingController.class, excludeFilters = @ComponentScan.Filter(type = FilterType.ASSIGNABLE_TYPE, classes = com.vacanza.backend.security.FirebaseTokenFilter.class))
@AutoConfigureMockMvc(addFilters = false)
public class BookingControllerTest {

        @Autowired
        private MockMvc mockMvc;

        @MockitoBean
        private BookingService bookingService;

        @Autowired
        private ObjectMapper objectMapper;

        // ──────────────────────────────────────────────────────────────
        // Accommodation search
        // ──────────────────────────────────────────────────────────────

        @Test
        @DisplayName("POST /bookings/accommodations/search — 200 with valid request")
        void searchAccommodations_Success() throws Exception {
                AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
                request.setQuery("Hotels in Paris");
                request.setCheckInDate(LocalDate.of(2025, 7, 1));
                request.setCheckOutDate(LocalDate.of(2025, 7, 5));
                request.setAdults(2);

                List<AccommodationOptionDTO> mockResults = List.of(
                                AccommodationOptionDTO.builder()
                                                .providerName("Google Hotels")
                                                .hotelName("Hotel Le Marais")
                                                .hotelId("token123")
                                                .price(new BigDecimal("185.50"))
                                                .pricePerNight(new BigDecimal("46.38"))
                                                .currency("USD")
                                                .rating(4.2)
                                                .totalReviews(320)
                                                .hotelClass(4)
                                                .externalBookingUrl(
                                                                "https://www.google.com/travel/hotels?q=Hotel+Le+Marais")
                                                .build());

                when(bookingService.searchAccommodations(any())).thenReturn(mockResults);

                mockMvc.perform(post("/bookings/accommodations/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].hotelName").value("Hotel Le Marais"))
                                .andExpect(jsonPath("$[0].providerName").value("Google Hotels"))
                                .andExpect(jsonPath("$[0].price").value(185.50))
                                .andExpect(jsonPath("$[0].rating").value(4.2))
                                .andExpect(jsonPath("$[0].totalReviews").value(320))
                                .andExpect(jsonPath("$[0].externalBookingUrl").isNotEmpty());
        }

        @Test
        @DisplayName("POST /bookings/accommodations/search — 400 when query is missing")
        void searchAccommodations_MissingQuery() throws Exception {
                AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
                request.setCheckInDate(LocalDate.of(2025, 7, 1));
                request.setCheckOutDate(LocalDate.of(2025, 7, 5));
                // query deliberately missing

                mockMvc.perform(post("/bookings/accommodations/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("POST /bookings/accommodations/search — 200 with empty results")
        void searchAccommodations_EmptyResults() throws Exception {
                AccommodationSearchRequestDTO request = new AccommodationSearchRequestDTO();
                request.setQuery("Hotels in Unknown City");
                request.setCheckInDate(LocalDate.of(2025, 7, 1));
                request.setCheckOutDate(LocalDate.of(2025, 7, 5));

                when(bookingService.searchAccommodations(any())).thenReturn(List.of());

                mockMvc.perform(post("/bookings/accommodations/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$").isEmpty());
        }

        // ──────────────────────────────────────────────────────────────
        // Transportation search
        // ──────────────────────────────────────────────────────────────

        @Test
        @DisplayName("POST /bookings/transportation/search — 200 with valid request")
        void searchTransportation_Success() throws Exception {
                TransportSearchRequestDTO request = new TransportSearchRequestDTO();
                request.setOrigin("IST");
                request.setDestination("PAR");
                request.setDepartureDate(LocalDate.of(2025, 7, 1));
                request.setAdults(1);

                List<TransportOptionDTO> mockResults = List.of(
                                TransportOptionDTO.builder()
                                                .carrier("Turkish Airlines")
                                                .airlineLogo("https://www.gstatic.com/flights/airline_logos/70px/TK.png")
                                                .flightNumber("TK 1829")
                                                .travelClass("Economy")
                                                .origin("IST")
                                                .destination("CDG")
                                                .departureTime("2025-07-01 08:30")
                                                .arrivalTime("2025-07-01 11:45")
                                                .duration("3h 15m")
                                                .price(new BigDecimal("320.00"))
                                                .currency("USD")
                                                .stops(0)
                                                .externalBookingUrl(
                                                                "https://www.google.com/travel/flights?q=IST+to+CDG")
                                                .build());

                when(bookingService.searchTransportation(any())).thenReturn(mockResults);

                mockMvc.perform(post("/bookings/transportation/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].carrier").value("Turkish Airlines"))
                                .andExpect(jsonPath("$[0].flightNumber").value("TK 1829"))
                                .andExpect(jsonPath("$[0].origin").value("IST"))
                                .andExpect(jsonPath("$[0].price").value(320.00))
                                .andExpect(jsonPath("$[0].stops").value(0))
                                .andExpect(jsonPath("$[0].airlineLogo").isNotEmpty());
        }

        @Test
        @DisplayName("POST /bookings/transportation/search — 400 when origin is missing")
        void searchTransportation_MissingOrigin() throws Exception {
                TransportSearchRequestDTO request = new TransportSearchRequestDTO();
                request.setDestination("PAR");
                request.setDepartureDate(LocalDate.of(2025, 7, 1));
                // origin deliberately missing

                mockMvc.perform(post("/bookings/transportation/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("POST /bookings/transportation/search — 400 when departureDate is missing")
        void searchTransportation_MissingDepartureDate() throws Exception {
                TransportSearchRequestDTO request = new TransportSearchRequestDTO();
                request.setOrigin("IST");
                request.setDestination("PAR");
                // departureDate deliberately missing

                mockMvc.perform(post("/bookings/transportation/search")
                                .contentType(MediaType.APPLICATION_JSON)
                                .content(objectMapper.writeValueAsString(request)))
                                .andExpect(status().isBadRequest());
        }

        // ──────────────────────────────────────────────────────────────
        // Airport autocomplete
        // ──────────────────────────────────────────────────────────────

        @Test
        @DisplayName("GET /bookings/airports/search — 200 with valid query")
        void searchAirports_Success() throws Exception {
                SerpApiAirportSuggestion ist = new SerpApiAirportSuggestion();
                ist.setIataCode("IST");
                ist.setName("Istanbul Airport");
                ist.setCity("Istanbul");
                ist.setCountry("Turkey");

                SerpApiAirportSuggestion saw = new SerpApiAirportSuggestion();
                saw.setIataCode("SAW");
                saw.setName("Istanbul Sabiha Gokcen Airport");
                saw.setCity("Istanbul");
                saw.setCountry("Turkey");

                when(bookingService.searchAirports(anyString())).thenReturn(List.of(ist, saw));

                mockMvc.perform(get("/bookings/airports/search")
                                .param("q", "istanbul"))
                                .andExpect(status().isOk())
                                .andExpect(jsonPath("$[0].iataCode").value("IST"))
                                .andExpect(jsonPath("$[0].name").value("Istanbul Airport"))
                                .andExpect(jsonPath("$[0].city").value("Istanbul"))
                                .andExpect(jsonPath("$[0].country").value("Turkey"))
                                .andExpect(jsonPath("$[1].iataCode").value("SAW"));
        }

        @Test
        @DisplayName("GET /bookings/airports/search — 400 when query is too short (1 char)")
        void searchAirports_QueryTooShort() throws Exception {
                mockMvc.perform(get("/bookings/airports/search")
                                .param("q", "i"))
                                .andExpect(status().isBadRequest());
        }

        @Test
        @DisplayName("GET /bookings/airports/search — 400 when q parameter is missing")
        void searchAirports_MissingParam() throws Exception {
                mockMvc.perform(get("/bookings/airports/search"))
                                .andExpect(status().isBadRequest());
        }
}
