package com.vacanza.backend.config;

import io.netty.channel.ChannelOption;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.client.reactive.ReactorClientHttpConnector;
import org.springframework.web.reactive.function.client.ClientRequest;
import org.springframework.web.reactive.function.client.ExchangeFilterFunction;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.core.publisher.Mono;
import reactor.netty.http.client.HttpClient;
import reactor.util.retry.Retry;

import java.time.Duration;

@Slf4j
@Configuration
@EnableConfigurationProperties({ GeoapifyProperties.class, AiServiceProperties.class,
        SerpApiProperties.class })
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

    @Bean
    @Qualifier("aiWebClient")
    public WebClient aiWebClient(AiServiceProperties props) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) props.getConnectTimeout().toMillis())
                .responseTimeout(props.getReadTimeout());

        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(log4xx5xx("[AI-SERVICE]"))
                .build();
    }

    @Bean
    @Qualifier("serpApiWebClient")
    public WebClient serpApiWebClient(SerpApiProperties props) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) props.getConnectTimeout().toMillis())
                .responseTimeout(props.getReadTimeout());

        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(log4xx5xx("[SERPAPI]"))
                .build();
    }

    /**
     * Automatically appends ?apiKey=... to every request
     */
    private ExchangeFilterFunction addApiKey(GeoapifyProperties props) {
        return (request, next) -> {
            var newUrl = UriComponentsBuilder
                    .fromUri(request.url())
                    .queryParam("apiKey", props.getApiKey())
                    .build(false)
                    .toUri();
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
                        log.warn("{} {} {} -> {}", tag, request.method(), request.url(), code);
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
                                            null)));
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
                                }));
    }
}
