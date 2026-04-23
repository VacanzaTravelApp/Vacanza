package com.vacanza.backend.integration.currency;

import lombok.Data;
import java.math.BigDecimal;
import java.util.Map;

@Data
public class FrankfurterResponse {
    private BigDecimal amount;
    private String base;
    private String date;
    private Map<String, BigDecimal> rates;
}
