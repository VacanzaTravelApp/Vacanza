/*
package com.vacanza.backend.runner;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

@Component
@RequiredArgsConstructor
@Profile("dev")
public class geoapifyRunner {
    @Qualifier("geoapifyWebClient")
    private final WebClient geoapifyWebClient;

    @PostConstruct
    public void testGeoapify() {
        geoapifyWebClient.get()
                .uri(uriBuilder -> uriBuilder
                        .path("/places")
                        .queryParam("categories", "tourism.sights")
                        .queryParam("filter", "rect:32.80,39.85,32.90,39.95")
                        .queryParam("limit", 1)
                        .build()
                )
                .retrieve()
                .bodyToMono(String.class)
                .doOnNext(body -> {
                    System.out.println("✅ GEOAPIFY OK");
                    System.out.println(body);
                })
                .doOnError(err -> {
                    System.err.println("❌ GEOAPIFY FAIL");
                    err.printStackTrace();
                })
                .subscribe();
    }
}
*/