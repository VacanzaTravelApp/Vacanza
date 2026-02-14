package com.vacanza.backend.service;

import com.vacanza.backend.dto.AutoCheckInRequestDTO;
import com.vacanza.backend.dto.CheckInResponseDTO;
import com.vacanza.backend.entity.CheckIn;
import com.vacanza.backend.entity.PointOfInterest;
import com.vacanza.backend.entity.User;
import com.vacanza.backend.entity.enums.CheckInSource;
import com.vacanza.backend.repo.CheckInRepository;
import com.vacanza.backend.repo.PointOfInterestRepository;
import com.vacanza.backend.service.impl.CheckInImpl;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class CheckInService implements CheckInImpl {

    private final CheckInRepository checkInRepository;
    private final PointOfInterestRepository poiRepository;

    private static final double MAX_DISTANCE_METERS = 50.0;

    @Override
    @Transactional
    public CheckInResponseDTO evaluateAutoCheckIn(User user, AutoCheckInRequestDTO request) {
        if (request.getCandidatePoiIds() == null || request.getCandidatePoiIds().isEmpty()) {
            return CheckInResponseDTO.builder()
                    .success(false)
                    .message("No candidate POIs provided")
                    .build();
        }

        List<PointOfInterest> candidates = poiRepository.findAllById(request.getCandidatePoiIds());

        // Find closest POI within range
        Optional<PointOfInterest> closestPoi = candidates.stream()
                .filter(poi -> calculateDistance(
                        request.getLatitude(), request.getLongitude(),
                        poi.getLatitude(), poi.getLongitude()) <= MAX_DISTANCE_METERS)
                .min(Comparator.comparingDouble(poi -> calculateDistance(
                        request.getLatitude(), request.getLongitude(),
                        poi.getLatitude(), poi.getLongitude())));

        if (closestPoi.isEmpty()) {
            return CheckInResponseDTO.builder()
                    .success(false)
                    .message("No valid POI found within " + MAX_DISTANCE_METERS + "m")
                    .build();
        }

        PointOfInterest targetPoi = closestPoi.get();

        // Check for duplicate check-in
        boolean alreadyCheckedIn = checkInRepository.existsByUserAndPointOfInterest(user, targetPoi);
        if (alreadyCheckedIn) {
            return CheckInResponseDTO.builder()
                    .success(true) // Should be success=true but with message? Or false? Requirement says: "without
                                   // error"
                    .poiId(targetPoi.getPoiId())
                    .poiName(targetPoi.getName())
                    .message("Already checked in")
                    .build();
        }

        // Create new CheckIn
        CheckIn checkIn = CheckIn.builder()
                .user(user)
                .pointOfInterest(targetPoi)
                .checkedInAt(Instant.now())
                .source(CheckInSource.AUTO)
                .build();

        CheckIn savedCheckIn = checkInRepository.save(checkIn);

        return CheckInResponseDTO.builder()
                .success(true)
                .checkInId(savedCheckIn.getCheckInId())
                .poiId(targetPoi.getPoiId())
                .poiName(targetPoi.getName())
                .checkedInAt(savedCheckIn.getCheckedInAt())
                .message("Successfully checked in")
                .build();
    }

    private double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Radius of the earth in km
        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);
        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        double distanceKm = R * c;
        return distanceKm * 1000; // convert to meters
    }
}
