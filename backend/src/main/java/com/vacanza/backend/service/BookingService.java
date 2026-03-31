package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.DestinationSuggestionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.integration.booking.SerpApiAirportSuggestion;

import java.util.List;

public interface BookingService {

    List<AccommodationOptionDTO> searchAccommodations(AccommodationSearchRequestDTO request);

    List<TransportOptionDTO> searchTransportation(TransportSearchRequestDTO request);

    List<SerpApiAirportSuggestion> searchAirports(String query);

    /** Hotel destination autocomplete — reuses airport autocomplete data (zero extra SerpAPI calls). */
    List<DestinationSuggestionDTO> searchDestinations(String query);
}

