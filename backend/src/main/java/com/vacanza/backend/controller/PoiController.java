package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;
import com.vacanza.backend.service.PoiSearchService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/pois")
@RequiredArgsConstructor
public class PoiController {

    private final PoiSearchService poiSearchService;

    @PostMapping("/search-in-area")
    public ResponseEntity<PoiSearchInAreaResponseDTO> searchInArea(@RequestBody PoiSearchInAreaRequestDTO req) {
        return new ResponseEntity<>(poiSearchService.searchInArea(req), HttpStatus.OK);
    }
}