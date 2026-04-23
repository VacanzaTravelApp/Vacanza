package com.vacanza.backend.util;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * Stateless utility for producing RFC 5545 (iCalendar) compliant text.
 * <p>
 * Handles line folding, text escaping, date-time formatting, and
 * deterministic UID generation for Vacanza calendar exports.
 * </p>
 *
 * @see <a href="https://datatracker.ietf.org/doc/html/rfc5545">RFC 5545</a>
 */
public final class IcsBuilder {

    private static final int MAX_OCTETS_PER_LINE = 75;
    private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss");
    private static final DateTimeFormatter D_FMT = DateTimeFormatter.ofPattern("yyyyMMdd");

    private IcsBuilder() { /* utility */ }

    // ── Line folding (RFC 5545 §3.1) ────────────────────────────────────────

    /**
     * Folds a content line so that no single line exceeds 75 octets.
     * Continuation lines begin with a single SPACE character.
     */
    public static String foldLine(String line) {
        if (line == null || line.isEmpty()) {
            return "";
        }
        byte[] bytes = line.getBytes(StandardCharsets.UTF_8);
        if (bytes.length <= MAX_OCTETS_PER_LINE) {
            return line;
        }
        StringBuilder sb = new StringBuilder(bytes.length + 20);
        int pos = 0;
        boolean first = true;
        while (pos < bytes.length) {
            int limit = first ? MAX_OCTETS_PER_LINE : MAX_OCTETS_PER_LINE - 1;
            int end = Math.min(pos + limit, bytes.length);

            // Avoid breaking a multi-byte UTF-8 sequence
            while (end > pos && end < bytes.length && isContinuationByte(bytes[end])) {
                end--;
            }

            String segment = new String(bytes, pos, end - pos, StandardCharsets.UTF_8);
            if (!first) {
                sb.append("\r\n "); // CRLF + SPACE continuation
            }
            sb.append(segment);
            pos = end;
            first = false;
        }
        return sb.toString();
    }

    private static boolean isContinuationByte(byte b) {
        return (b & 0xC0) == 0x80;
    }

    // ── Text escaping (RFC 5545 §3.3.11) ────────────────────────────────────

    /**
     * Escapes TEXT property values per RFC 5545: backslash, semicolon,
     * comma, and newline characters are escaped.
     */
    public static String escapeText(String text) {
        if (text == null) {
            return "";
        }
        return text
                .replace("\\", "\\\\")
                .replace(";", "\\;")
                .replace(",", "\\,")
                .replace("\r\n", "\\n")
                .replace("\n", "\\n")
                .replace("\r", "\\n");
    }

    // ── Date / time formatting ──────────────────────────────────────────────

    /**
     * Formats a date + time as a floating-time iCalendar value: {@code YYYYMMDDTHHMMSS}.
     * "Floating" means no timezone suffix; the calendar app interprets it in the user's local zone.
     */
    public static String formatDateTime(LocalDate date, LocalTime time) {
        return date.atTime(time).format(DT_FMT);
    }

    /**
     * Formats a date as an all-day iCalendar value: {@code YYYYMMDD}.
     */
    public static String formatDate(LocalDate date) {
        return date.format(D_FMT);
    }

    // ── UID generation ──────────────────────────────────────────────────────

    /**
     * Generates a deterministic UID for a VEVENT so that re-importing the same
     * ICS file updates existing events rather than creating duplicates.
     * <p>Format: {@code {eventId}-wp{order}@vacanza.app}</p>
     */
    public static String generateUid(UUID eventId, int waypointOrder) {
        return eventId.toString() + "-wp" + waypointOrder + "@vacanza.app";
    }
}
