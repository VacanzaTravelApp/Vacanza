package com.vacanza.backend.config;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.web.reactive.function.client.ClientRequest;
import org.springframework.web.reactive.function.client.ExchangeFilterFunction;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.core.publisher.Mono;
import reactor.util.retry.Retry;

import java.time.Duration;
/*
@Configuration
@EnableConfigurationProperties({OverpassProperties.class})
public class WebClientConfig {

    @Bean
    public WebClient overpassWebClient(OverpassProperties props) {
        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend-dev")
                .filter(log4xx5xx("[OVERPASS]"))
                .filter(retryOn429And5xx()) // Overpass da bazen 429/5xx verebilir
                .build();
    }

    private ExchangeFilterFunction log4xx5xx(String tag) {
        return (request, next) -> next.exchange(request)
                .doOnNext(resp -> {
                    int code = resp.statusCode().value();
                    if (code >= 400) {
                        System.out.println(tag + " " + request.method() + " " + request.url() + " -> " + code);
                    }
                });
    }

    private ExchangeFilterFunction retryOn429And5xx() {
        return (request, next) -> next.exchange(request)
                .flatMap(resp -> {
                    if (!resp.statusCode().isError()) return Mono.just(resp);

                    return resp.bodyToMono(String.class)
                            .defaultIfEmpty("")
                            .flatMap(body -> Mono.error(new WebClientResponseException(
                                    "Overpass error " + resp.statusCode().value(),
                                    resp.statusCode().value(),
                                    resp.statusCode().toString(),
                                    resp.headers().asHttpHeaders(),
                                    body.getBytes(),
                                    null
                            )));
                })
                .retryWhen(
                        Retry.backoff(2, Duration.ofSeconds(1))
                                .maxBackoff(Duration.ofSeconds(5))
                                .filter(ex -> {
                                    if (ex instanceof WebClientResponseException w) {
                                        int s = w.getStatusCode().value();
                                        return s == 429 || (s >= 500 && s <= 599);
                                    }
                                    return false;
                                })
                );
    }
}*/

@Configuration
@EnableConfigurationProperties(GeoapifyProperties.class)
public class WebClientConfig {

    @Bean
    @Qualifier("geoapifyWebClient")
    public WebClient geoapifyWebClient(GeoapifyProperties props) {
        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(addApiKey(props))
                .filter(log4xx5xx("[GEOAPIFY]"))
                .filter(retryOn429And5xx())
                .build();
    }

    /**
     * Automatically appends ?apiKey=... to every request
     */
    private ExchangeFilterFunction addApiKey(GeoapifyProperties props) {
        System.out.println("GEOAPIFY KEY=" + props.getApiKey());
        return (request, next) -> {
            var newUrl = UriComponentsBuilder
                    .fromUri(request.url())
                    .queryParam("apiKey", props.getApiKey())
                    .build(false)
                    .toUri();
            System.out.println("🔥 FINAL GEOAPIFY URL = " + newUrl);
            var newRequest = ClientRequest
                    .from(request)
                    .url(newUrl)
                    .build();

            return next.exchange(newRequest);
        };
    }

    private ExchangeFilterFunction log4xx5xx(String tag) {
        return (request, next) -> next.exchange(request)
                .doOnNext(resp -> {
                    int code = resp.statusCode().value();
                    if (code >= 400) {
                        System.out.println(
                                tag + " " + request.method() + " " + request.url() + " -> " + code
                        );
                    }
                });
    }

    private ExchangeFilterFunction retryOn429And5xx() {
        return (request, next) -> next.exchange(request)
                .flatMap(resp -> {
                    if (!resp.statusCode().isError()) {
                        return Mono.just(resp);
                    }

                    return resp.bodyToMono(String.class)
                            .defaultIfEmpty("")
                            .flatMap(body -> Mono.error(
                                    new WebClientResponseException(
                                            "Geoapify error " + resp.statusCode().value(),
                                            resp.statusCode().value(),
                                            resp.statusCode().toString(),
                                            resp.headers().asHttpHeaders(),
                                            body.getBytes(),
                                            null
                                    )
                            ));
                })
                .retryWhen(
                        Retry.backoff(2, Duration.ofSeconds(1))
                                .maxBackoff(Duration.ofSeconds(5))
                                .filter(ex -> {
                                    if (ex instanceof WebClientResponseException w) {
                                        int s = w.getStatusCode().value();
                                        return s == 429 || (s >= 500 && s <= 599);
                                    }
                                    return false;
                                })
                );
    }
}
