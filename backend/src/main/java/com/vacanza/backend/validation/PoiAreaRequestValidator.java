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
        require(req != null, HttpStatus.BAD_REQUEST, "REQ_NULL", "request body is required");
        require(req.getSelectionType() != null, HttpStatus.BAD_REQUEST, "SELECTION_TYPE_REQUIRED", "selectionType is required");

        int page = req.getPage() == null ? 0 : req.getPage();
        int limit = req.getLimit() == null ? DEFAULT_LIMIT : req.getLimit();

        require(page >= 0, HttpStatus.BAD_REQUEST, "PAGE_INVALID", "page must be >= 0");
        require(limit > 0, HttpStatus.BAD_REQUEST, "LIMIT_INVALID", "limit must be > 0");
        require(limit <= MAX_LIMIT, HttpStatus.UNPROCESSABLE_ENTITY, "LIMIT_TOO_LARGE", "limit must be <= " + MAX_LIMIT);

        if (req.getSelectionType() == PoiSearchInAreaRequestDTO.SelectionType.BBOX) {
            validateBbox(req.getBbox());
        } else {
            validatePolygon(req.getPolygon());
        }
    }

    private void validateBbox(PoiSearchInAreaRequestDTO.Bbox b) {
        require(b != null, HttpStatus.BAD_REQUEST, "BBOX_REQUIRED", "bbox is required for selectionType=BBOX");

        require(b.getMinLat() != null && b.getMinLng() != null && b.getMaxLat() != null && b.getMaxLng() != null,
                HttpStatus.BAD_REQUEST, "BBOX_FIELDS_REQUIRED", "bbox fields (minLat,minLng,maxLat,maxLng) are required");

        validateLatLng(b.getMinLat(), b.getMinLng());
        validateLatLng(b.getMaxLat(), b.getMaxLng());

        require(b.getMinLat() <= b.getMaxLat() && b.getMinLng() <= b.getMaxLng(),
                HttpStatus.BAD_REQUEST, "BBOX_RANGE_INVALID", "bbox min values must be <= max values");
    }

    private void validatePolygon(List<PoiSearchInAreaRequestDTO.LatLng> polygon) {
        require(polygon != null && polygon.size() >= 3,
                HttpStatus.BAD_REQUEST, "POLYGON_REQUIRED", "polygon (min 3 points) is required for selectionType=POLYGON");

        require(polygon.size() <= MAX_POLYGON_VERTICES,
                HttpStatus.UNPROCESSABLE_ENTITY, "POLYGON_TOO_MANY_VERTICES", "polygon vertex count must be <= " + MAX_POLYGON_VERTICES);

        for (PoiSearchInAreaRequestDTO.LatLng p : polygon) {
            require(p != null, HttpStatus.BAD_REQUEST, "POLYGON_POINT_NULL", "polygon point cannot be null");
            validateLatLng(p.getLat(), p.getLng());
        }

        // İstersen burada “polygon closed mu?” kontrolü de eklenebilir (FE kapatmayabilir, biz kapatmak zorunda değiliz)
        // self-intersect kontrolü şu an yok (MVP)
    }

    private void validateLatLng(Double lat, Double lng) {
        require(lat != null && lng != null, HttpStatus.BAD_REQUEST, "LAT_LNG_REQUIRED", "lat/lng cannot be null");
        require(lat >= -90 && lat <= 90, HttpStatus.UNPROCESSABLE_ENTITY, "LAT_OUT_OF_RANGE", "lat must be between -90 and 90");
        require(lng >= -180 && lng <= 180, HttpStatus.UNPROCESSABLE_ENTITY, "LNG_OUT_OF_RANGE", "lng must be between -180 and 180");
    }

    private void require(boolean condition, HttpStatus status, String code, String message) {
        if (!condition) {
            // FE için “hata kodu” gibi okunabilir bir prefix ekliyoruz
            throw new ResponseStatusException(status, code + ": " + message);
        }
    }
}