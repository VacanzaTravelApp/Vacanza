package com.vacanza.backend.validation;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Component
public class PoiAreaRequestValidator {

    private static final int DEFAULT_LIMIT = 200;
    private static final int MAX_LIMIT = 500;
    private static final int MAX_POLYGON_VERTICES = 200;

    public void validate(PoiSearchInAreaRequestDTO req) {
        if (req == null || req.getSelectionType() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "selectionType is required");
        }

        int page = req.getPage() == null ? 0 : req.getPage();
        int limit = req.getLimit() == null ? DEFAULT_LIMIT : req.getLimit();

        if (page < 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "page must be >= 0");
        if (limit <= 0) throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "limit must be > 0");
        if (limit > MAX_LIMIT) throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "limit is too large");

        if (req.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            if (req.getBbox() == null) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bbox is required for BBOX selectionType");
            }
            validateBbox(req.getBbox());
        } else {
            List<PoiSearchInAreaRequestDTO.LatLng> polygon = req.getPolygon();
            if (polygon == null || polygon.size() < 3) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "polygon (min 3 points) is required for POLYGON selectionType");
            }
            if (polygon.size() > MAX_POLYGON_VERTICES) {
                throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "polygon has too many vertices");
            }
            for (var p : polygon) validateLatLng(p.getLat(), p.getLng());
        }
    }

    private void validateBbox(PoiSearchInAreaRequestDTO.Bbox b) {
        if (b.getMinLat() == null || b.getMinLng() == null || b.getMaxLat() == null || b.getMaxLng() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bbox fields are required");
        }
        validateLatLng(b.getMinLat(), b.getMinLng());
        validateLatLng(b.getMaxLat(), b.getMaxLng());

        if (b.getMinLat() > b.getMaxLat() || b.getMinLng() > b.getMaxLng()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "bbox min values must be <= max values");
        }
    }

    private void validateLatLng(Double lat, Double lng) {
        if (lat == null || lng == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "lat/lng cannot be null");
        }
        if (lat < -90 || lat > 90) throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "lat out of range");
        if (lng < -180 || lng > 180) throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY, "lng out of range");
    }
}