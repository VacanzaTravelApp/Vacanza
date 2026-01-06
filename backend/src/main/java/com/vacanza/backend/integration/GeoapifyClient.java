package com.vacanza.backend.integration;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.util.List;

@Component
@RequiredArgsConstructor
public class GeoapifyClient {

    @Qualifier("geoapifyWebClient")
    private final WebClient webClient;

    @Value("${GEOAPIFY_API_KEY}")
    private String apiKey = ""; // 🔥 ZORUNLU

    public Mono<GeoapifyResponse> search(
            String filter,
            List<String> categories,
            int limit
    ) {
        System.out.println("🔥 GEOAPIFY API KEY = [" + apiKey + "]");
        return webClient.get()
                .uri(uriBuilder -> {
                    uriBuilder.path("/places");

                    // 🔥 GEOMETRY FILTER
                    uriBuilder.queryParam("filter", filter);

                    // 🔥 LIMIT
                    uriBuilder.queryParam("limit", limit);

                    // 🔥 CATEGORIES (ASLA BOŞ DEĞİL)
                    List<String> safeCategories =
                            (categories == null || categories.isEmpty())
                                    ? List.of("tourism.sights")
                                    : categories;

                    uriBuilder.queryParam(
                            "categories",
                            String.join(",", safeCategories)
                    );

                    // 🔥🔥🔥 API KEY (EKSİK OLAN PARÇA)


                    return uriBuilder.build();
                })
                .retrieve()
                .bodyToMono(GeoapifyResponse.class);
    }
}
