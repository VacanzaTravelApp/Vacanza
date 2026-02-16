package com.vacanza.backend.integration;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@Component
public class GeoapifyClient {

    private final WebClient webClient;

    public GeoapifyClient(@Qualifier("geoapifyWebClient") WebClient webClient) {
        this.webClient = webClient;
    }

        public Mono<GeoapifyResponse> search(
                        String filter,
                        List<String> categories,
                        int limit) {

                return webClient.get()
                                .uri(uriBuilder -> {
                                        uriBuilder.path("/places");

                                        uriBuilder.queryParam("filter", filter);
                                        uriBuilder.queryParam("limit", limit);

                                        List<String> safeCategories = (categories == null || categories.isEmpty())
                                                        ? List.of("tourism.sights")
                                                        : categories;

                                        uriBuilder.queryParam(
                                                        "categories",
                                                        String.join(",", safeCategories));

                                        return uriBuilder.build();
                                })
                                .retrieve()
                                .bodyToMono(GeoapifyResponse.class);
        }
}
