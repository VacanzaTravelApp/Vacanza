package com.vacanza.backend.util;

import org.junit.jupiter.api.Test;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

class IcsBuilderTest {

    // ── foldLine ────────────────────────────────────────────────────────────

    @Test
    void foldLine_shortLineUnchanged() {
        String input = "SUMMARY:Short title";
        assertEquals(input, IcsBuilder.foldLine(input));
    }

    @Test
    void foldLine_exactly75OctetsUnchanged() {
        // Build a line that is exactly 75 bytes
        String input = "DESCRIPTION:" + "A".repeat(63); // 12 + 63 = 75
        assertEquals(75, input.getBytes(java.nio.charset.StandardCharsets.UTF_8).length);
        assertEquals(input, IcsBuilder.foldLine(input));
    }

    @Test
    void foldLine_longLineIsFolded() {
        String input = "DESCRIPTION:" + "X".repeat(100); // 112 bytes total
        String folded = IcsBuilder.foldLine(input);

        // Continuation lines start with CRLF+SPACE
        assertTrue(folded.contains("\r\n "), "Should contain CRLF+SPACE continuation");

        // Each physical line should be ≤75 octets
        String[] physicalLines = folded.split("\r\n");
        for (int i = 0; i < physicalLines.length; i++) {
            String line = physicalLines[i];
            int octets = line.getBytes(java.nio.charset.StandardCharsets.UTF_8).length;
            assertTrue(octets <= 75, "Line " + i + " is " + octets + " octets: " + line);
        }
    }

    @Test
    void foldLine_nullAndEmptyHandled() {
        assertEquals("", IcsBuilder.foldLine(null));
        assertEquals("", IcsBuilder.foldLine(""));
    }

    // ── escapeText ──────────────────────────────────────────────────────────

    @Test
    void escapeText_specialCharactersEscaped() {
        assertEquals("hello\\;world", IcsBuilder.escapeText("hello;world"));
        assertEquals("a\\,b\\,c", IcsBuilder.escapeText("a,b,c"));
        assertEquals("line1\\nline2", IcsBuilder.escapeText("line1\nline2"));
        assertEquals("back\\\\slash", IcsBuilder.escapeText("back\\slash"));
    }

    @Test
    void escapeText_windowsNewlinesNormalized() {
        assertEquals("line1\\nline2", IcsBuilder.escapeText("line1\r\nline2"));
    }

    @Test
    void escapeText_nullReturnsEmpty() {
        assertEquals("", IcsBuilder.escapeText(null));
    }

    // ── formatDateTime ──────────────────────────────────────────────────────

    @Test
    void formatDateTime_producesCorrectFormat() {
        LocalDate date = LocalDate.of(2026, 4, 20);
        LocalTime time = LocalTime.of(9, 30, 0);
        assertEquals("20260420T093000", IcsBuilder.formatDateTime(date, time));
    }

    // ── formatDate ──────────────────────────────────────────────────────────

    @Test
    void formatDate_producesCorrectFormat() {
        LocalDate date = LocalDate.of(2026, 12, 5);
        assertEquals("20261205", IcsBuilder.formatDate(date));
    }

    // ── generateUid ─────────────────────────────────────────────────────────

    @Test
    void generateUid_isDeterministic() {
        UUID id = UUID.fromString("11111111-2222-3333-4444-555555555555");
        String uid1 = IcsBuilder.generateUid(id, 3);
        String uid2 = IcsBuilder.generateUid(id, 3);
        assertEquals(uid1, uid2);
        assertEquals("11111111-2222-3333-4444-555555555555-wp3@vacanza.app", uid1);
    }

    @Test
    void generateUid_differentOrderProducesDifferentUid() {
        UUID id = UUID.randomUUID();
        assertNotEquals(IcsBuilder.generateUid(id, 1), IcsBuilder.generateUid(id, 2));
    }
}
