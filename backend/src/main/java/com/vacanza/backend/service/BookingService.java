package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;

import java.util.List;

public interface BookingService {

    List<AccommodationOptionDTO> searchAccommodations(AccommodationSearchRequestDTO request);

    List<TransportOptionDTO> searchTransportation(TransportSearchRequestDTO request);
}
