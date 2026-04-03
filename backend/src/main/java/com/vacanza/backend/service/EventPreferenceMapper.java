package com.vacanza.backend.service;

import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.entity.UserPreferences;
import com.vacanza.backend.entity.enums.TravelStyle;
import com.vacanza.backend.integration.ai.AiChatDto;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * Maps Vacanza user preferences to Ticketmaster {@code classificationName} values
 * (e.g. Music, Sports, Arts & Theatre, Film, Miscellaneous).
 */
@Service
public class EventPreferenceMapper {

    private static final String MUSIC = "Music";
    private static final String ARTS_THEATRE = "Arts & Theatre";
    private static final String SPORTS = "Sports";
    private static final String FILM = "Film";

    private static final String EVENT_INTEREST_KEY = "event_interest";

    private static final Pattern LIVE_MUSIC = Pattern.compile("(?i)live\\s+music");
    private static final Pattern WORD_MUSIC = wordPattern("music");
    private static final Pattern WORD_CONCERT = wordPattern("concert");
    private static final Pattern WORD_ART = wordPattern("art");
    private static final Pattern WORD_THEATER = wordPattern("theater");
    private static final Pattern WORD_THEATRE = wordPattern("theatre");
    private static final Pattern WORD_MUSEUM = wordPattern("museum");
    private static final Pattern WORD_OPERA = wordPattern("opera");
    private static final Pattern WORD_BALLET = wordPattern("ballet");
    private static final Pattern WORD_SPORTS = wordPattern("sports");
    private static final Pattern WORD_FOOTBALL = wordPattern("football");
    private static final Pattern WORD_BASKETBALL = wordPattern("basketball");
    private static final Pattern WORD_FILM = wordPattern("film");
    private static final Pattern WORD_CINEMA = wordPattern("cinema");
    private static final Pattern WORD_MOVIE = wordPattern("movie");

    private static Pattern wordPattern(String word) {
        return Pattern.compile("\\b" + Pattern.quote(word) + "\\b", Pattern.CASE_INSENSITIVE);
    }

    /**
     * Maps structured preferences and AI-learned preferences to Ticketmaster category names.
     * Results are deduplicated; order is stable (travel style, then favorites, then AI).
     * Empty or null inputs yield an empty list (caller may pass null to Ticketmaster for no filter).
     */
    public List<String> mapToTicketmasterCategories(UserPreferences structured, List<UserPreferenceAi> aiPrefs) {
        LinkedHashSet<String> categories = new LinkedHashSet<>();
        addStructured(structured, categories);
        addFromUserPreferenceAiList(aiPrefs, categories);
        return new ArrayList<>(categories);
    }

    /**
     * Same category mapping as {@link #mapToTicketmasterCategories(UserPreferences, List)} but using
     * {@link AiChatDto.ExtractedPreference} rows from
     * {@link UserPreferenceAiService#getExistingPreferences(com.vacanza.backend.entity.User)}.
     * <p>
     * Named separately because Java cannot overload two {@code List&lt;?&gt;} parameter types (same erasure).
     */
    public List<String> mapToTicketmasterCategoriesFromExtracted(UserPreferences structured,
            List<AiChatDto.ExtractedPreference> extractedPrefs) {
        LinkedHashSet<String> categories = new LinkedHashSet<>();
        addStructured(structured, categories);
        addFromExtractedPreferences(extractedPrefs, categories);
        return new ArrayList<>(categories);
    }

    private static void addStructured(UserPreferences structured, LinkedHashSet<String> categories) {
        if (structured == null) {
            return;
        }
        addFromTravelStyle(structured.getTravelStyle(), categories);
        addFromFavoriteCategories(structured.getFavoriteCategories(), categories);
    }

    private static void addFromUserPreferenceAiList(List<UserPreferenceAi> aiPrefs, LinkedHashSet<String> categories) {
        if (aiPrefs == null) {
            return;
        }
        for (UserPreferenceAi pref : aiPrefs) {
            if (pref == null || pref.getPreferenceKey() == null) {
                continue;
            }
            if (!EVENT_INTEREST_KEY.equalsIgnoreCase(pref.getPreferenceKey().trim())) {
                continue;
            }
            addFromKeywordText(pref.getPreferenceValue(), categories);
        }
    }

    private static void addFromExtractedPreferences(List<AiChatDto.ExtractedPreference> extractedPrefs,
            LinkedHashSet<String> categories) {
        if (extractedPrefs == null) {
            return;
        }
        for (AiChatDto.ExtractedPreference pref : extractedPrefs) {
            if (pref == null || pref.getPreferenceKey() == null) {
                continue;
            }
            if (!EVENT_INTEREST_KEY.equalsIgnoreCase(pref.getPreferenceKey().trim())) {
                continue;
            }
            addFromKeywordText(pref.getPreferenceValue(), categories);
        }
    }

    private static void addFromTravelStyle(TravelStyle style, LinkedHashSet<String> out) {
        if (style == null) {
            return;
        }
        switch (style) {
            case CULTURAL:
            case LUXURY:
                out.add(ARTS_THEATRE);
                break;
            case NIGHTLIFE:
            case ROMANTIC:
                out.add(MUSIC);
                break;
            case ADVENTURE:
                out.add(SPORTS);
                break;
            case RELAXATION:
            case FAMILY:
            case BACKPACKER:
            default:
                break;
        }
    }

    private static void addFromFavoriteCategories(List<String> favoriteCategories, LinkedHashSet<String> out) {
        if (favoriteCategories == null || favoriteCategories.isEmpty()) {
            return;
        }
        for (String raw : favoriteCategories) {
            addFromKeywordText(raw, out);
        }
    }

    private static void addFromKeywordText(String text, LinkedHashSet<String> out) {
        if (text == null || text.isBlank()) {
            return;
        }
        String haystack = text.toLowerCase(Locale.ROOT);

        if (LIVE_MUSIC.matcher(haystack).find() || WORD_MUSIC.matcher(haystack).find()
                || WORD_CONCERT.matcher(haystack).find()) {
            out.add(MUSIC);
        }
        if (WORD_ART.matcher(haystack).find() || WORD_THEATER.matcher(haystack).find()
                || WORD_THEATRE.matcher(haystack).find() || WORD_MUSEUM.matcher(haystack).find()
                || WORD_OPERA.matcher(haystack).find() || WORD_BALLET.matcher(haystack).find()) {
            out.add(ARTS_THEATRE);
        }
        if (WORD_SPORTS.matcher(haystack).find() || WORD_FOOTBALL.matcher(haystack).find()
                || WORD_BASKETBALL.matcher(haystack).find()) {
            out.add(SPORTS);
        }
        if (WORD_FILM.matcher(haystack).find() || WORD_CINEMA.matcher(haystack).find()
                || WORD_MOVIE.matcher(haystack).find()) {
            out.add(FILM);
        }
    }
}
