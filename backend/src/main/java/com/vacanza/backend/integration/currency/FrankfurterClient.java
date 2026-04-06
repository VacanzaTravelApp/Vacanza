package com.vacanza.backend.integration.currency;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
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
                .bodyToMono(FrankfurterResponse.class)
                .doOnError(e -> log.warn("Frankfurter API fetch failed for base={}: {}", baseCurrency, e.getMessage()))
                .onErrorResume(e -> Mono.empty());
    }
}
