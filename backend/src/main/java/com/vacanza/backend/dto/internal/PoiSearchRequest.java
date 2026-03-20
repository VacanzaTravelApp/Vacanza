package com.vacanza.backend.dto.internal;

import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@NoArgsConstructor
public class PoiSearchRequest {
    private String destination;
    private List<String> categories;
}

