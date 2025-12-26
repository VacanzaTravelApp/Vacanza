package com.vacanza.backend.integration;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@Component
@RequiredArgsConstructor
public class GeoapifyClient {

    @Qualifier("geoapifyWebClient")
    private final WebClient webClient;

    public Mono<GeoapifyResponse> search(
            String filter,
            List<String> categories,
            int limit
    ) {
        return webClient.get()
                .uri(uriBuilder -> {
                    uriBuilder.path("/places");
                    uriBuilder.queryParam("filter", filter);
                    uriBuilder.queryParam("limit", limit);

                    if (categories != null && !categories.isEmpty()) {
                        uriBuilder.queryParam(
                                "categories",
                                String.join(",", categories)
                        );
                    }

                    return uriBuilder.build();
                })
                .retrieve()
                .bodyToMono(GeoapifyResponse.class);
    }
}
