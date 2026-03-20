package com.vacanza.backend.dto.internal;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PoiResult {
    private String name;
    private String category;
    private double lat;
    private double lon;
}

