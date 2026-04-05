package com.vacanza.backend.test.service;

import com.vacanza.backend.entity.UserPreferenceAi;
import com.vacanza.backend.entity.UserPreferences;
import com.vacanza.backend.entity.enums.TravelStyle;
import com.vacanza.backend.service.EventPreferenceMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class EventPreferenceMapperTest {

    private EventPreferenceMapper mapper;

    @BeforeEach
    void setUp() {
        mapper = new EventPreferenceMapper();
    }

    @Test
    void travelStyle_cultural_mapsToArtsAndTheatre() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.CULTURAL)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).containsExactly("Arts & Theatre");
    }

    @Test
    void travelStyle_luxury_mapsToArtsAndTheatre() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.LUXURY)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).containsExactly("Arts & Theatre");
    }

    @Test
    void travelStyle_nightlife_mapsToMusic() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.NIGHTLIFE)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).containsExactly("Music");
    }

    @Test
    void travelStyle_romantic_mapsToMusic() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.ROMANTIC)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).containsExactly("Music");
    }

    @Test
    void travelStyle_adventure_addsNoCategory() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.ADVENTURE)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).isEmpty();
    }

    @Test
    void travelStyle_relaxation_addsNoCategory() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.RELAXATION)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).isEmpty();
    }

    @Test
    void travelStyle_family_addsNoCategory() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.FAMILY)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).isEmpty();
    }

    @Test
    void travelStyle_backpacker_addsNoCategory() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.BACKPACKER)
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).isEmpty();
    }

    @Test
    void favoriteCategories_mapsKeywords() {
        UserPreferences p = UserPreferences.builder()
                .favoriteCategories(List.of(
                        "live music night",
                        "museum tour",
                        "football",
                        "movie night"))
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null))
                .containsExactly("Music", "Arts & Theatre", "Sports", "Film");
    }

    @Test
    void favoriteCategories_theaterAndCinema_keywords() {
        UserPreferences p = UserPreferences.builder()
                .favoriteCategories(List.of("theater", "cinema"))
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null))
                .containsExactly("Arts & Theatre", "Film");
    }

    @Test
    void aiEventInterest_parsesLikeKeywordMapping() {
        List<UserPreferenceAi> ai = List.of(
                UserPreferenceAi.builder()
                        .preferenceKey("event_interest")
                        .preferenceValue("jazz and classical music")
                        .build(),
                UserPreferenceAi.builder()
                        .preferenceKey("event_interest")
                        .preferenceValue("theater")
                        .build());
        UserPreferences structured = UserPreferences.builder().build();
        assertThat(mapper.mapToTicketmasterCategories(structured, ai))
                .containsExactly("Music", "Arts & Theatre");
    }

    @Test
    void aiIgnoresNonEventInterestKeys() {
        List<UserPreferenceAi> ai = List.of(
                UserPreferenceAi.builder()
                        .preferenceKey("other_key")
                        .preferenceValue("football")
                        .build(),
                UserPreferenceAi.builder()
                        .preferenceKey("event_interest")
                        .preferenceValue("basketball")
                        .build());
        assertThat(mapper.mapToTicketmasterCategories(null, ai)).containsExactly("Sports");
    }

    @Test
    void eventInterestKeyIsCaseInsensitive() {
        List<UserPreferenceAi> ai = List.of(
                UserPreferenceAi.builder()
                        .preferenceKey("EVENT_INTEREST")
                        .preferenceValue("opera")
                        .build());
        assertThat(mapper.mapToTicketmasterCategories(null, ai)).containsExactly("Arts & Theatre");
    }

    @Test
    void deduplicatesCategories() {
        UserPreferences p = UserPreferences.builder()
                .travelStyle(TravelStyle.CULTURAL)
                .favoriteCategories(List.of("theater", "opera"))
                .build();
        List<UserPreferenceAi> ai = List.of(
                UserPreferenceAi.builder()
                        .preferenceKey("event_interest")
                        .preferenceValue("ballet")
                        .build());
        assertThat(mapper.mapToTicketmasterCategories(p, ai)).containsExactly("Arts & Theatre");
    }

    @Test
    void nullStructuredAndNullAi_returnsEmpty() {
        assertThat(mapper.mapToTicketmasterCategories(null, null)).isEmpty();
    }

    @Test
    void nullStructured_emptyAi_returnsEmpty() {
        assertThat(mapper.mapToTicketmasterCategories(null, List.of())).isEmpty();
    }

    @Test
    void structuredNullTravelStyle_noFavorites_returnsEmpty() {
        UserPreferences p = UserPreferences.builder().build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).isEmpty();
    }

    @Test
    void nullTravelStyle_favoriteCategoriesStillMapped() {
        UserPreferences p = UserPreferences.builder()
                .favoriteCategories(List.of("concert"))
                .build();
        assertThat(mapper.mapToTicketmasterCategories(p, null)).containsExactly("Music");
    }

    @Test
    void aiPrefList_withNullEntries_skipsNulls() {
        UserPreferenceAi valid = UserPreferenceAi.builder()
                .preferenceKey("event_interest")
                .preferenceValue("film")
                .build();
        List<UserPreferenceAi> withNull = new ArrayList<>();
        withNull.add(null);
        withNull.add(valid);
        assertThat(mapper.mapToTicketmasterCategories(null, withNull)).containsExactly("Film");
    }

    @Test
    void aiPref_withNullKey_skipped() {
        UserPreferenceAi bad = UserPreferenceAi.builder()
                .preferenceKey(null)
                .preferenceValue("sports")
                .build();
        assertThat(mapper.mapToTicketmasterCategories(null, List.of(bad))).isEmpty();
    }

    @Test
    void userPreferenceAi_minimalBuilder() {
        UserPreferenceAi pref = UserPreferenceAi.builder()
                .preferenceId(UUID.randomUUID())
                .preferenceKey("event_interest")
                .preferenceValue("sports")
                .confidence(0.9)
                .source("CHAT")
                .build();
        assertThat(mapper.mapToTicketmasterCategories(null, List.of(pref))).containsExactly("Sports");
    }

    @Test
    void eventInterest_turkishSportsAndRave_mapsToSportsAndMusic() {
        UserPreferenceAi pref = UserPreferenceAi.builder()
                .preferenceKey("event_interest")
                .preferenceValue("futbol, basketbol, voleybol, rave")
                .build();
        assertThat(mapper.mapToTicketmasterCategories(null, List.of(pref)))
                .containsExactly("Music", "Sports");
    }

    @Test
    void eventInterest_volleyball_mapsToSports() {
        UserPreferenceAi pref = UserPreferenceAi.builder()
                .preferenceKey("event_interest")
                .preferenceValue("beach volleyball")
                .build();
        assertThat(mapper.mapToTicketmasterCategories(null, List.of(pref))).containsExactly("Sports");
    }

    @Test
    void eventInterest_edmTechno_mapsToMusic() {
        UserPreferenceAi pref = UserPreferenceAi.builder()
                .preferenceKey("event_interest")
                .preferenceValue("EDM ve techno geceleri")
                .build();
        assertThat(mapper.mapToTicketmasterCategories(null, List.of(pref))).containsExactly("Music");
    }
}
