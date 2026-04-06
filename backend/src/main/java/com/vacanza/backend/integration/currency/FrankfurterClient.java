package com.vacanza.backend.integration.currency;

import com.vacanza.backend.exceptions.CurrencyException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientRequestException;
import reactor.core.publisher.Mono;

@Slf4j
@Component
public class FrankfurterClient {

    private final WebClient webClient;

    public FrankfurterClient(@Qualifier("frankfurterWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

    public Mono<FrankfurterResponse> getLatestRates(String baseCurrency) {
        return webClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/v1/latest")
                        .queryParam("base", baseCurrency)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::is4xxClientError, response -> 
                    Mono.error(new CurrencyException(HttpStatus.BAD_REQUEST, 
                        "Invalid currency code provided: " + baseCurrency)))
                .onStatus(HttpStatusCode::is5xxServerError, response -> 
                    Mono.error(new CurrencyException(HttpStatus.SERVICE_UNAVAILABLE, 
                        "Exchange rate service (Frankfurter) is currently down")))
                .bodyToMono(FrankfurterResponse.class)
                .doOnError(e -> log.warn("Frankfurter API fetch failed for base={}: {}", baseCurrency, e.getMessage()))
                .onErrorMap(WebClientRequestException.class, e -> 
                    new CurrencyException(HttpStatus.SERVICE_UNAVAILABLE, 
                        "Exchange rate service (Frankfurter) is currently unreachable"));
    }
}
