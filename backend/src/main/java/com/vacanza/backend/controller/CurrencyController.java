package com.vacanza.backend.controller;

import com.vacanza.backend.dto.request.CurrencyConversionRequestDTO;
import com.vacanza.backend.dto.request.ForecastRequestDTO;
import com.vacanza.backend.dto.response.CurrencyConversionResponseDTO;
import com.vacanza.backend.dto.response.ForecastResponseDTO;
import com.vacanza.backend.service.ExchangeRateService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/currencies")
@RequiredArgsConstructor
@Validated
public class CurrencyController {

    private final ExchangeRateService exchangeRateService;

    @GetMapping("/convert")
    public ResponseEntity<CurrencyConversionResponseDTO> convert(
            @Valid @ModelAttribute CurrencyConversionRequestDTO request) {
        CurrencyConversionResponseDTO response = exchangeRateService.getConversionDetails(
                request.getAmount(), 
                request.getFromCurrency(), 
                request.getToCurrency()
        );
        return ResponseEntity.ok(response);
    }

    @PostMapping("/forecast")
    public ResponseEntity<ForecastResponseDTO> forecast(
            @Valid @RequestBody ForecastRequestDTO request) {
        ForecastResponseDTO response = exchangeRateService.processForecast(request);
        return ResponseEntity.ok(response);
    }
}
