package com.vacanza.backend.util;

import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Parses ISO 3166-1 alpha-2 country codes from free-text destinations such as
 * {@code "Helsinki, Finland"} or {@code "Paris, France"} for Ticketmaster {@code countryCode}.
 */
public final class DestinationCountryParser {

    private static final Map<String, String> NAME_TO_ISO2 = Map.ofEntries(
            Map.entry("finland", "FI"),
            Map.entry("finlandiya", "FI"),
            Map.entry("sweden", "SE"),
            Map.entry("isveç", "SE"),
            Map.entry("norway", "NO"),
            Map.entry("norveç", "NO"),
            Map.entry("denmark", "DK"),
            Map.entry("danimarka", "DK"),
            Map.entry("germany", "DE"),
            Map.entry("almanya", "DE"),
            Map.entry("france", "FR"),
            Map.entry("fransa", "FR"),
            Map.entry("spain", "ES"),
            Map.entry("ispanya", "ES"),
            Map.entry("italy", "IT"),
            Map.entry("italya", "IT"),
            Map.entry("netherlands", "NL"),
            Map.entry("hollanda", "NL"),
            Map.entry("belgium", "BE"),
            Map.entry("belçika", "BE"),
            Map.entry("austria", "AT"),
            Map.entry("avusturya", "AT"),
            Map.entry("switzerland", "CH"),
            Map.entry("isviçre", "CH"),
            Map.entry("poland", "PL"),
            Map.entry("polonya", "PL"),
            Map.entry("estonia", "EE"),
            Map.entry("letonya", "LV"),
            Map.entry("latvia", "LV"),
            Map.entry("lithuania", "LT"),
            Map.entry("litvanya", "LT"),
            Map.entry("ireland", "IE"),
            Map.entry("irlanda", "IE"),
            Map.entry("portugal", "PT"),
            Map.entry("portekiz", "PT"),
            Map.entry("greece", "GR"),
            Map.entry("yunanistan", "GR"),
            Map.entry("czech republic", "CZ"),
            Map.entry("çekya", "CZ"),
            Map.entry("hungary", "HU"),
            Map.entry("macaristan", "HU"),
            Map.entry("romania", "RO"),
            Map.entry("romanya", "RO"),
            Map.entry("bulgaria", "BG"),
            Map.entry("bulgaristan", "BG"),
            Map.entry("croatia", "HR"),
            Map.entry("hirvatistan", "HR"),
            Map.entry("slovenia", "SI"),
            Map.entry("slovenya", "SI"),
            Map.entry("slovakia", "SK"),
            Map.entry("united kingdom", "GB"),
            Map.entry("uk", "GB"),
            Map.entry("great britain", "GB"),
            Map.entry("england", "GB"),
            Map.entry("scotland", "GB"),
            Map.entry("wales", "GB"),
            Map.entry("birleşik krallık", "GB"),
            Map.entry("ingiltere", "GB"),
            Map.entry("united states", "US"),
            Map.entry("usa", "US"),
            Map.entry("u.s.", "US"),
            Map.entry("amerika birleşik devletleri", "US"),
            Map.entry("canada", "CA"),
            Map.entry("kanada", "CA"),
            Map.entry("mexico", "MX"),
            Map.entry("meksika", "MX"),
            Map.entry("türkiye", "TR"),
            Map.entry("turkey", "TR"));

    private DestinationCountryParser() {
    }

    /**
     * @param destination e.g. {@code "Helsinki, Finland"} — uses the segment after the first comma
     * @return ISO2 when the country segment matches a known name, else empty
     */
    public static Optional<String> countryIso2FromDestination(String destination) {
        if (destination == null || destination.isBlank()) {
            return Optional.empty();
        }
        String trimmed = destination.trim();
        int comma = trimmed.indexOf(',');
        if (comma < 0 || comma >= trimmed.length() - 1) {
            return Optional.empty();
        }
        String countryPart = trimmed.substring(comma + 1).trim();
        if (countryPart.isEmpty()) {
            return Optional.empty();
        }
        String key = normalizeCountryKey(countryPart);
        String iso = NAME_TO_ISO2.get(key);
        return Optional.ofNullable(iso);
    }

    private static String normalizeCountryKey(String countryPart) {
        String lower = countryPart.toLowerCase(Locale.ROOT).trim();
        // Strip common trailing region noise: "Finland (Europe)" -> "finland"
        int paren = lower.indexOf('(');
        if (paren > 0) {
            lower = lower.substring(0, paren).trim();
        }
        return lower;
    }
}
