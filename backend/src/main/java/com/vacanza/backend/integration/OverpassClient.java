package com.vacanza.backend.integration;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Component
@RequiredArgsConstructor
public class OverpassClient {

    private final WebClient overpassWebClient;

    /**
     * Overpass API:
     * POST /interpreter
     * body: data=<overpass query>
     *
     * bbox order: (south,west,north,east) = (minLat,minLng,maxLat,maxLng)
     */
    public OverpassResponse searchByBbox(
            double minLat,
            double minLng,
            double maxLat,
            double maxLng,
            List<String> normalizedCategories,
            int limit
    ) {
        String query = OverpassQueryBuilder.build(minLat, minLng, maxLat, maxLng, normalizedCategories, limit);

        // Overpass interpreter expects form-encoded: data=<query>
        String body = "data=" + URLEncoder.encode(query, StandardCharsets.UTF_8);

        return overpassWebClient.post()
                .uri(uri -> uri.path("/interpreter").build())
                .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                .bodyValue(body)
                .retrieve()
                .bodyToMono(OverpassResponse.class)
                .block();
    }

    /**
     * Small helper to build Overpass QL.
     */
    static class OverpassQueryBuilder {

        /**
         * Very simple category -> OSM tag mapping.
         * You can expand later.
         */
        static String build(double minLat, double minLng, double maxLat, double maxLng, List<String> cats, int limit) {
            String bbox = "(" + minLat + "," + minLng + "," + maxLat + "," + maxLng + ")";

            String filters;
            if (cats == null || cats.isEmpty()) {
                // default “POI-ish” set
                filters = """
                        (
                          node["amenity"]%s;
                          node["tourism"]%s;
                          node["leisure"]%s;
                        )
                        """.formatted(bbox, bbox, bbox);
            } else {
                // build OR-like union for each mapped tag
                StringBuilder sb = new StringBuilder();
                sb.append("(\n");
                for (String c : cats) {
                    if (c == null || c.isBlank()) continue;

                    // mapping
                    if (c.equals("cafe")) {
                        sb.append("  node[\"amenity\"=\"cafe\"]").append(bbox).append(";\n");
                    } else if (c.equals("restaurant")) {
                        sb.append("  node[\"amenity\"=\"restaurant\"]").append(bbox).append(";\n");
                    } else if (c.equals("bar")) {
                        sb.append("  node[\"amenity\"=\"bar\"]").append(bbox).append(";\n");
                    } else if (c.equals("museum")) {
                        sb.append("  node[\"tourism\"=\"museum\"]").append(bbox).append(";\n");
                    } else if (c.equals("park")) {
                        sb.append("  node[\"leisure\"=\"park\"]").append(bbox).append(";\n");
                    } else if (c.equals("hotel")) {
                        sb.append("  node[\"tourism\"=\"hotel\"]").append(bbox).append(";\n");
                    } else if (c.equals("atm")) {
                        sb.append("  node[\"amenity\"=\"atm\"]").append(bbox).append(";\n");
                    } else {
                        // fallback: try amenity=<category> as-is
                        sb.append("  node[\"amenity\"=\"").append(escape(c)).append("\"]").append(bbox).append(";\n");
                    }
                }
                sb.append(")\n");
                filters = sb.toString();
            }

            // out center gives lat/lon for ways too (biz şimdilik node alıyoruz ama)
            // limit: Overpass “out” limit direkt yok; biz query içinde (out;); sonra client-side kırparız.
            return """
                    [out:json][timeout:25];
                    %s
                    out body;
                    """.formatted(filters);
        }

        private static String escape(String s) {
            return s.replace("\"", "\\\"");
        }
    }
}