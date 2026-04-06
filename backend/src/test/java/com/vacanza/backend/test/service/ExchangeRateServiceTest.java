package com.vacanza.backend.test.service;

import com.vacanza.backend.dto.request.ForecastItemDTO;
import com.vacanza.backend.dto.request.ForecastRequestDTO;
import com.vacanza.backend.dto.response.CurrencyConversionResponseDTO;
import com.vacanza.backend.dto.response.ForecastResponseDTO;
import com.vacanza.backend.integration.currency.FrankfurterClient;
import com.vacanza.backend.integration.currency.FrankfurterResponse;
import com.vacanza.backend.service.ExchangeRateService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import reactor.core.publisher.Mono;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class ExchangeRateServiceTest {

    @Mock
    private FrankfurterClient frankfurterClient;

    private ExchangeRateService exchangeRateService;

    @BeforeEach
    void setUp() {
        exchangeRateService = new ExchangeRateService(frankfurterClient);
    }

    @Test
    @DisplayName("Convert USD to EUR correctly")
    void testConvert_UsdToEur() {
        FrankfurterResponse mockResponse = new FrankfurterResponse();
        mockResponse.setAmount(BigDecimal.ONE);
        mockResponse.setBase("USD");
        mockResponse.setRates(Map.of("EUR", new BigDecimal("0.85")));

        when(frankfurterClient.getLatestRates("USD")).thenReturn(Mono.just(mockResponse));

        BigDecimal result = exchangeRateService.convert(new BigDecimal("100"), "USD", "EUR");
        assertEquals(new BigDecimal("85.00"), result);
        
        verify(frankfurterClient, times(1)).getLatestRates("USD");
    }

    @Test
    @DisplayName("Conversion details match DTO structure")
    void testGetConversionDetails() {
        FrankfurterResponse mockResponse = new FrankfurterResponse();
        mockResponse.setBase("USD");
        mockResponse.setRates(Map.of("GBP", new BigDecimal("0.75")));

        when(frankfurterClient.getLatestRates("USD")).thenReturn(Mono.just(mockResponse));

        CurrencyConversionResponseDTO details = exchangeRateService.getConversionDetails(new BigDecimal("200"), "USD", "GBP");

        assertEquals(new BigDecimal("200"), details.getOriginalAmount());
        assertEquals("USD", details.getOriginalCurrency());
        assertEquals("GBP", details.getTargetCurrency());
        assertEquals(new BigDecimal("150.00"), details.getConvertedAmount());
    }

    @Test
    @DisplayName("Process forecast payload successfully")
    void testProcessForecast() {
        FrankfurterResponse mockResponseEur = new FrankfurterResponse();
        mockResponseEur.setBase("EUR");
        mockResponseEur.setRates(Map.of("USD", new BigDecimal("1.10")));

        FrankfurterResponse mockResponseTry = new FrankfurterResponse();
        mockResponseTry.setBase("TRY");
        mockResponseTry.setRates(Map.of("USD", new BigDecimal("0.04")));

        when(frankfurterClient.getLatestRates("EUR")).thenReturn(Mono.just(mockResponseEur));
        when(frankfurterClient.getLatestRates("TRY")).thenReturn(Mono.just(mockResponseTry));

        ForecastItemDTO flightItem = new ForecastItemDTO();
        flightItem.setName("Flight");
        flightItem.setAmount(new BigDecimal("2000"));
        flightItem.setCurrency("TRY");

        ForecastItemDTO hotelItem = new ForecastItemDTO();
        hotelItem.setName("Hotel");
        hotelItem.setAmount(new BigDecimal("150"));
        hotelItem.setCurrency("EUR");

        ForecastRequestDTO request = new ForecastRequestDTO();
        request.setTargetCurrency("USD");
        request.setItems(List.of(flightItem, hotelItem));

        ForecastResponseDTO response = exchangeRateService.processForecast(request);

        assertEquals("USD", response.getTargetCurrency());
        assertEquals(new BigDecimal("245.00"), response.getTotalCost());
        assertEquals(2, response.getItems().size());
        
        // TRY 2000 * 0.04 = 80
        assertEquals(new BigDecimal("80.00"), response.getItems().get(0).getConvertedAmount());
        // EUR 150 * 1.10 = 165
        assertEquals(new BigDecimal("165.00"), response.getItems().get(1).getConvertedAmount());
    }
}
