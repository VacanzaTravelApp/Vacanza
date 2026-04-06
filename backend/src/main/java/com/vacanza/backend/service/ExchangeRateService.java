package com.vacanza.backend.service;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.vacanza.backend.dto.request.ForecastItemDTO;
import com.vacanza.backend.dto.request.ForecastRequestDTO;
import com.vacanza.backend.dto.response.CurrencyConversionResponseDTO;
import com.vacanza.backend.dto.response.ForecastResponseDTO;
import com.vacanza.backend.dto.response.ForecastResponseItemDTO;
import com.vacanza.backend.integration.currency.FrankfurterClient;
import com.vacanza.backend.integration.currency.FrankfurterResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Service
public class ExchangeRateService {

    private final FrankfurterClient frankfurterClient;
    private final Cache<String, FrankfurterResponse> ratesCache;

    public ExchangeRateService(FrankfurterClient frankfurterClient) {
        this.frankfurterClient = frankfurterClient;
        // Cache rates for 12 hours since exchange rates generally update once a day
        this.ratesCache = Caffeine.newBuilder()
                .maximumSize(100)
                .expireAfterWrite(Duration.ofHours(12))
                .recordStats()
                .build();
    }

    /**
     * Converts an amount from one currency to another using cached exchange rates.
     */
    public BigDecimal convert(BigDecimal amount, String fromCurrency, String toCurrency) {
        if (fromCurrency.equalsIgnoreCase(toCurrency)) {
            return amount.setScale(2, RoundingMode.HALF_UP);
        }

        String baseCurrency = fromCurrency.toUpperCase();
        FrankfurterResponse response = ratesCache.get(baseCurrency,
                key -> frankfurterClient.getLatestRates(key).block());

        if (response == null || response.getRates() == null) {
            log.warn("Could not fetch exchange rates for {}", baseCurrency);
            throw new RuntimeException("Exchange rates unavailable for " + baseCurrency);
        }

        String targetCurrency = toCurrency.toUpperCase();
        BigDecimal rate = response.getRates().get(targetCurrency);
        if (rate == null) {
            throw new RuntimeException("Target currency " + targetCurrency + " not supported from " + baseCurrency);
        }

        return amount.multiply(rate).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Generates a conversion response DTO.
     */
    public CurrencyConversionResponseDTO getConversionDetails(BigDecimal amount, String fromCurrency,
            String toCurrency) {
        BigDecimal convertedAmount = convert(amount, fromCurrency, toCurrency);
        return CurrencyConversionResponseDTO.builder()
                .originalAmount(amount)
                .originalCurrency(fromCurrency.toUpperCase())
                .convertedAmount(convertedAmount)
                .targetCurrency(toCurrency.toUpperCase())
                .build();
    }

    /**
     * Processes a forecast request, returning converted individual items and total
     * sum.
     */
    public ForecastResponseDTO processForecast(ForecastRequestDTO request) {
        String targetCurrency = request.getTargetCurrency().toUpperCase();
        BigDecimal totalCost = BigDecimal.ZERO;
        List<ForecastResponseItemDTO> responseItems = new ArrayList<>();

        for (ForecastItemDTO item : request.getItems()) {
            BigDecimal convertedAmount = convert(item.getAmount(), item.getCurrency(), targetCurrency);

            responseItems.add(ForecastResponseItemDTO.builder()
                    .name(item.getName())
                    .originalAmount(item.getAmount())
                    .originalCurrency(item.getCurrency().toUpperCase())
                    .convertedAmount(convertedAmount)
                    .build());

            totalCost = totalCost.add(convertedAmount);
        }

        return ForecastResponseDTO.builder()
                .targetCurrency(targetCurrency)
                .totalCost(totalCost.setScale(2, RoundingMode.HALF_UP))
                .items(responseItems)
                .build();
    }
}
