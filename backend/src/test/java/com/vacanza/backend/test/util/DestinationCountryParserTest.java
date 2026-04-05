package com.vacanza.backend.test.util;

import com.vacanza.backend.util.DestinationCountryParser;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class DestinationCountryParserTest {

    @Test
    void helsinkiFinland_returnsFi() {
        assertThat(DestinationCountryParser.countryIso2FromDestination("Helsinki, Finland"))
                .contains("FI");
    }

    @Test
    void finnishTurkishName_returnsFi() {
        assertThat(DestinationCountryParser.countryIso2FromDestination("Helsinki, Finlandiya"))
                .contains("FI");
    }

    @Test
    void noComma_returnsEmpty() {
        assertThat(DestinationCountryParser.countryIso2FromDestination("Helsinki")).isEmpty();
    }

    @Test
    void istanbulTurkey_returnsTr() {
        assertThat(DestinationCountryParser.countryIso2FromDestination("Istanbul, Türkiye"))
                .contains("TR");
    }
}
