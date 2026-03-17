package com.vacanza.backend.service;

import com.vacanza.backend.dto.request.EventSearchRequestDTO;
import com.vacanza.backend.dto.response.EventDTO;

import java.util.List;

/**
 * Service interface for event search operations.
 */
public interface EventService {

    /**
     * Search for events based on city, date range, and category.
     *
     * @param request search parameters
     * @return list of matching events
     */
    List<EventDTO> searchEvents(EventSearchRequestDTO request);
}
