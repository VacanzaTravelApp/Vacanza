package com.vacanza.backend.integration.viator;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.time.Instant;
import java.util.Locale;
import java.util.Set;

/**
 * Resolves the minimum Viator product price for a given attraction name via a single
 * {@code POST /search/freetext} call (no caching, no attraction pre-lookup).
 *
 * <p>Filtering applied (in order):
 * <ol>
 *   <li>Non-ticketable <em>category</em> → skip API call entirely.</li>
 *   <li>Non-ticketable <em>name type word</em> (e.g. "Bridge", "Street", "Park") → skip,
 *       unless the category is a clearly ticket-worthy type (museum, amusement park…).</li>
 *   <li>Title relevance — at least one significant token from the waypoint name must appear
 *       in the Viator product title.</li>
 *   <li>Zero/negative {@code fromPrice} — discarded.</li>
 * </ol>
 */
@Service
@RequiredArgsConstructor
public class ViatorWaypointPriceService {

    /**
     * Categories where Viator ticket/tour products make no sense.
     * Any freetext match for these is an unrelated city tour, not an actual ticket.
     */
    private static final Set<String> NON_TICKETABLE_CATEGORIES = Set.of(
            // Food & drink
            "restaurant", "fine_dining", "bistro", "fast_food",
            "cafe", "coffee_shop", "tea_house", "bakery",
            "bar", "pub", "nightclub",
            // Retail & markets
            "market", "bazaar", "food_market", "flea_market",
            "shopping_mall", "department_store", "shopping_center",
            // Public outdoor spaces — free access, no entry ticket
            "park", "national_park", "nature_reserve",
            "beach", "public_bath",
            "bridge", "pier",
            "viewpoint", "overlook", "belvedere",
            // Streets & roads (cadde, sokak, bulvar…)
            "street", "road", "avenue", "boulevard", "alley"
    );

    /**
     * Categories that are <em>always</em> worth querying on Viator, even if the place name
     * contains a generic type word like "park" (e.g. "Disneyland Park", "Safari Park").
     * These override the name-based filter below.
     */
    private static final Set<String> ALWAYS_TICKETABLE_CATEGORIES = Set.of(
            "museum", "art_gallery",
            "historic_site", "ruins", "palace",
            "amusement_park", "theme_park", "water_park",
            "zoo", "aquarium", "wildlife_park", "zoo_aquarium",
            "observation_deck"
    );

    /**
     * Place-type words embedded in attraction names that indicate the place is a public
     * infrastructure / natural feature where Viator tickets do not exist.
     * Applied when the AI category is generic (landmark, attraction, neighborhood, null).
     *
     * <p>Examples caught:
     * <ul>
     *   <li>"Golden Gate <b>Bridge</b>" → bridge</li>
     *   <li>"Lombard <b>Street</b>" → street</li>
     *   <li>"Central <b>Park</b>" → park</li>
     *   <li>"İstiklal <b>Caddesi</b>" → caddesi</li>
     * </ul>
     */
    private static final Set<String> NON_TICKETABLE_NAME_TOKENS = Set.of(
            // Infrastructure — no tickets sold
            "bridge", "viaduct", "tunnel", "dam",
            "köprü",                                       // Turkish: bridge
            // Roads & streets
            "street", "avenue", "boulevard", "road", "highway", "lane", "alley",
            "cadde", "caddesi", "sokak", "bulvar",         // Turkish
            "rue", "strasse", "straße", "via", "calle",    // FR / DE / IT / ES
            // Public outdoor spaces — free access
            "park", "garden", "gardens",
            "beach", "plaj", "sahil",
            "lake", "river", "creek", "falls"
            // NOTE: pier, wharf, harbor, square, plaza are intentionally excluded —
            // waterfront areas and squares frequently have legitimate boat/walking tours.
    );

    /**
     * Common words excluded from the title-relevance token match.
     */
    private static final Set<String> STOP_WORDS = Set.of(
            "the", "a", "an", "of", "in", "at", "on", "and", "or", "by", "to",
            "san", "de", "la", "le", "los", "las", "el", "von", "van"
    );

    private final ViatorClient viatorClient;

    public ViatorWaypointPrice getPrice(String attractionName, String category, String currency) {
        // 1. Explicit non-ticketable category
        if (isNonTicketableCategory(category)) {
            return ViatorWaypointPrice.empty(Instant.now());
        }
        // 2. Name contains a place-type word (bridge, street, park …)
        //    — but honour the override for venues that are always ticket-worthy.
        if (!isAlwaysTicketableCategory(category) && hasNonTicketableNameToken(attractionName)) {
            return ViatorWaypointPrice.empty(Instant.now());
        }
        ViatorProductSearchResponse resp = viatorClient.searchProductsByName(attractionName, currency);
        return extractMin(resp, attractionName, currency);
    }

    // ── private helpers ───────────────────────────────────────────────────────

    private static boolean isNonTicketableCategory(String category) {
        if (!StringUtils.hasText(category)) return false;
        return NON_TICKETABLE_CATEGORIES.contains(category.trim().toLowerCase(Locale.ROOT));
    }

    private static boolean isAlwaysTicketableCategory(String category) {
        if (!StringUtils.hasText(category)) return false;
        return ALWAYS_TICKETABLE_CATEGORIES.contains(category.trim().toLowerCase(Locale.ROOT));
    }

    static boolean hasNonTicketableNameToken(String name) {
        if (!StringUtils.hasText(name)) return false;
        for (String token : strip(name).split("[\\s\\-,.'\"()&]+")) {
            if (NON_TICKETABLE_NAME_TOKENS.contains(token)) return true;
        }
        return false;
    }

    private static ViatorWaypointPrice extractMin(
            ViatorProductSearchResponse resp, String searchTerm, String currency) {
        Instant now = Instant.now();
        if (resp.getProducts() == null || resp.getProducts().isEmpty()) {
            return ViatorWaypointPrice.empty(now);
        }
        BigDecimal min = null;
        String bestUrl = null;
        String bestTitle = null;
        String ccy = StringUtils.hasText(currency) ? currency.trim().toUpperCase(Locale.ROOT) : "USD";
        for (var p : resp.getProducts()) {
            if (!isTitleRelevant(p.getTitle(), searchTerm)) continue;
            if (p.getPricing() == null || p.getPricing().getSummary() == null) continue;
            BigDecimal fp = p.getPricing().getSummary().getFromPrice();
            if (fp == null || fp.compareTo(BigDecimal.ZERO) <= 0) continue;
            if (min == null || fp.compareTo(min) < 0) {
                min = fp;
                bestUrl = p.getProductUrl();
                bestTitle = p.getTitle();
                if (p.getPricing().getCurrency() != null) {
                    ccy = p.getPricing().getCurrency();
                }
            }
        }
        return min == null ? ViatorWaypointPrice.empty(now) : new ViatorWaypointPrice(min, ccy, bestUrl, bestTitle, now);
    }

    static boolean isTitleRelevant(String title, String searchTerm) {
        if (!StringUtils.hasText(title) || !StringUtils.hasText(searchTerm)) return false;
        String titleNorm = strip(title);
        String[] tokens = strip(searchTerm).split("[\\s\\-,.'\"()&]+");
        for (String token : tokens) {
            if (token.length() >= 4 && !STOP_WORDS.contains(token) && titleNorm.contains(token)) {
                return true;
            }
        }
        return false;
    }

    private static String strip(String s) {
        String nfd = Normalizer.normalize(s, Normalizer.Form.NFD);
        return nfd.replaceAll("\\p{InCombiningDiacriticalMarks}", "").toLowerCase(Locale.ENGLISH);
    }
}
