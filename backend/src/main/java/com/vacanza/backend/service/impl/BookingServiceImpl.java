package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.request.AccommodationSearchRequestDTO;
import com.vacanza.backend.dto.request.TransportSearchRequestDTO;
import com.vacanza.backend.dto.response.AccommodationOptionDTO;
import com.vacanza.backend.dto.response.TransportOptionDTO;
import com.vacanza.backend.entity.enums.SortCriteria;
import com.vacanza.backend.integration.booking.SerpApiClient;
import com.vacanza.backend.service.BookingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BookingServiceImpl implements BookingService {

        private final SerpApiClient serpApiClient;

        @Override
        public List<AccommodationOptionDTO> searchAccommodations(AccommodationSearchRequestDTO request) {
                log.info("Searching accommodations: query={}, budget={}, currency={}, sort={}",
                                request.getQuery(), request.getBudget(),
                                request.getCurrency(), request.getSortBy());

                // SerpApi handles max_price filtering server-side
                List<AccommodationOptionDTO> results = serpApiClient.searchHotels(request);

                // Apply sorting (SerpApi sort may differ from our enum)
                results = sortAccommodations(results, request.getSortBy());

                log.info("Returning {} accommodation results after filtering", results.size());
                return results;
        }

        @Override
        public List<TransportOptionDTO> searchTransportation(TransportSearchRequestDTO request) {
                log.info("Searching transportation: {} -> {}, budget={}, sort={}",
                                request.getOrigin(), request.getDestination(),
                                request.getBudget(), request.getSortBy());

                List<TransportOptionDTO> results = serpApiClient.searchFlights(request);

                // Apply budget filter (SerpApi Google Flights doesn't support max price)
                if (request.getBudget() != null) {
                        results = results.stream()
                                        .filter(opt -> opt.getPrice() != null
                                                        && opt.getPrice().compareTo(request.getBudget()) <= 0)
                                        .collect(Collectors.toList());
                }

                // Apply sorting
                results = sortTransportation(results, request.getSortBy());

                log.info("Returning {} transportation results after filtering", results.size());
                return results;
        }

        private List<AccommodationOptionDTO> sortAccommodations(
                        List<AccommodationOptionDTO> results, SortCriteria sortBy) {

                if (sortBy == null) {
                        return results;
                }

                Comparator<AccommodationOptionDTO> comparator = switch (sortBy) {
                        case PRICE_ASC -> Comparator.comparing(
                                        AccommodationOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.naturalOrder()));
                        case PRICE_DESC -> Comparator.comparing(
                                        AccommodationOptionDTO::getPrice,
                                        Comparator.nullsLast(Comparator.reverseOrder()));
                        case RATING_DESC -> Comparator.comparing(
                                        AccommodationOptionDTO::getRating,
                                        Comparator.nullsLast(Comparator.reverseOrder()));
                };

                return results.stream().sorted(comparator).collect(Collectors.toList());
        }

        private List<TransportOptionDTO> sortTransportation(
                        List<TransportOptionDTO> results, SortCriteria sortBy) {

                if (sortBy == null) {
                        return results;
                }

                Comparator<TransportOptionDTO> comparator = switch (sortBy) {
                        case PRICE_ASC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice, Comparator.nullsLast(Comparator.naturalOrder()));
                        case PRICE_DESC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice, Comparator.nullsLast(Comparator.reverseOrder()));
                        case RATING_DESC -> Comparator.comparing(
                                        TransportOptionDTO::getPrice, Comparator.nullsLast(Comparator.naturalOrder()));
                        // Flights don't have rating, fallback to price asc
                };

                return results.stream().sorted(comparator).collect(Collectors.toList());
        }
}
