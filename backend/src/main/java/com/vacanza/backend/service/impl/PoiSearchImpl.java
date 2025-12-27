package com.vacanza.backend.service.impl;

import com.vacanza.backend.dto.request.PoiSearchInAreaRequestDTO;
import com.vacanza.backend.dto.response.PoiSearchInAreaResponseDTO;

public interface PoiSearchImpl {
    PoiSearchInAreaResponseDTO searchInArea(PoiSearchInAreaRequestDTO request);
}
