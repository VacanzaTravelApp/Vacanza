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
import org.springframework.util.StringUtils;
import org.springframework.web.util.UriComponentsBuilder;
import reactor.netty.http.client.HttpClient;

@Slf4j
@Configuration
@EnableConfigurationProperties({ FoursquareProperties.class, AiServiceProperties.class,
        SerpApiProperties.class, MapboxProperties.class, TicketmasterProperties.class,
        OpenMeteoProperties.class, ViatorProperties.class })
public class WebClientConfig {

    @Bean
    @Qualifier("foursquareWebClient")
    public WebClient foursquareWebClient(FoursquareProperties props) {
        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .defaultHeader("Authorization", props.getApiKey())
                .filter(log4xx5xx("[FOURSQUARE]"))
                .build();
    }

    @Bean
    @Qualifier("mapboxGeocodingWebClient")
    public WebClient mapboxGeocodingWebClient(MapboxProperties props) {
        return WebClient.builder()
                .baseUrl("https://api.mapbox.com")
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(addMapboxAccessToken(props))
                .filter(log4xx5xx("[MAPBOX-GEOCODE]"))
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

    @Bean
    @Qualifier("ticketmasterWebClient")
    public WebClient ticketmasterWebClient(TicketmasterProperties props) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) props.getConnectTimeout().toMillis())
                .responseTimeout(props.getReadTimeout());

        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(log4xx5xx("[TICKETMASTER]"))
                .build();
    }

    @Bean
    @Qualifier("openMeteoWebClient")
    public WebClient openMeteoWebClient(OpenMeteoProperties props) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) props.getConnectTimeout().toMillis())
                .responseTimeout(props.getReadTimeout());

        return WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .defaultHeader(HttpHeaders.ACCEPT, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(log4xx5xx("[OPEN-METEO]"))
                .build();
    }

    @Bean
    @Qualifier("viatorWebClient")
    public WebClient viatorWebClient(ViatorProperties props) {
        HttpClient httpClient = HttpClient.create()
                .option(ChannelOption.CONNECT_TIMEOUT_MILLIS, (int) props.getConnectTimeout().toMillis())
                .responseTimeout(props.getReadTimeout());

        WebClient.Builder builder = WebClient.builder()
                .baseUrl(props.getBaseUrl())
                .clientConnector(new ReactorClientHttpConnector(httpClient))
                .codecs(configurer -> configurer.defaultCodecs().maxInMemorySize(2 * 1024 * 1024))
                .defaultHeader(HttpHeaders.ACCEPT, "application/json;version=2.0")
                .defaultHeader(HttpHeaders.CONTENT_TYPE, "application/json")
                .defaultHeader(HttpHeaders.USER_AGENT, "vacanza-backend")
                .filter(log4xx5xx("[VIATOR]"));
        if (StringUtils.hasText(props.getApiKey())) {
            builder.defaultHeader("exp-api-key", props.getApiKey());
        }
        return builder.build();
    }

    /**
     * Automatically appends ?access_token=... to every Mapbox request
     */
    private ExchangeFilterFunction addMapboxAccessToken(MapboxProperties props) {
        return (request, next) -> {
            var newUrl = UriComponentsBuilder
                    .fromUri(request.url())
                    .queryParam("access_token", props.getAccessToken())
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
}
