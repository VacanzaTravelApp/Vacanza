import React, { useCallback } from "react";
import { Button, Typography } from "antd";
import { FaRegClock } from "react-icons/fa";
import "../styles/eventCard.css";

/**
 * Formats ISO or parseable date string for display (e.g. "5 Nisan, 20:00").
 */
function formatEventStart(startTime) {
  if (!startTime) return null;
  const d = new Date(startTime);
  if (Number.isNaN(d.getTime())) {
    return String(startTime);
  }
  const day = d.getDate();
  const month = d.toLocaleString("tr-TR", { month: "long" });
  const hm = d.toLocaleTimeString("tr-TR", {
    hour: "2-digit",
    minute: "2-digit",
  });
  return `${day} ${month}, ${hm}`;
}

/**
 * Compact single-event tile for horizontal recommendation lists.
 */
export default function EventCard({ event }) {
  const ticketHref = event?.ticketLink;

  const openTicket = useCallback(() => {
    if (!ticketHref) return;
    window.open(ticketHref, "_blank", "noopener,noreferrer");
  }, [ticketHref]);

  const onCardKeyDown = useCallback(
    (e) => {
      if (!ticketHref) return;
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        openTicket();
      }
    },
    [ticketHref, openTicket]
  );

  if (!event) return null;

  const {
    name,
    thumbnail,
    startTime,
    venueName,
    category,
    ticketLink,
    matchedDay,
    matchReason,
  } = event;

  const displayName = name?.trim() || "Etkinlik";
  const dateLine = formatEventStart(startTime);
  const ticketLabel = `Bilet al: ${displayName}`;
  const titleId =
    event.id != null ? `event-card-title-${String(event.id)}` : "event-card-title";

  return (
    <article
      className="event-card"
      tabIndex={0}
      onKeyDown={onCardKeyDown}
      aria-labelledby={titleId}
    >
      <div className="event-card-media">
        {thumbnail ? (
          <img
            className="event-card-media-img"
            src={thumbnail}
            alt={displayName}
            loading="lazy"
            decoding="async"
          />
        ) : null}
        {matchedDay != null && Number.isFinite(Number(matchedDay)) ? (
          <span className="event-card-badge event-card-badge--day">
            Day {matchedDay}
          </span>
        ) : null}
        {category ? (
          <span className="event-card-badge event-card-badge--cat" title={category}>
            {category}
          </span>
        ) : null}
      </div>

      <div className="event-card-body">
        <Typography.Paragraph
          id={titleId}
          className="event-card-title"
          strong
          ellipsis={{ rows: 2 }}
        >
          {displayName}
        </Typography.Paragraph>

        {dateLine ? (
          <div className="event-card-datetime">
            <FaRegClock aria-hidden />
            <span>{dateLine}</span>
          </div>
        ) : null}

        {venueName ? (
          <div className="event-card-venue" title={venueName}>
            {venueName}
          </div>
        ) : null}

        {matchReason ? (
          <p className="event-card-reason">{matchReason}</p>
        ) : null}

        {ticketLink ? (
          <Button
            type="default"
            size="small"
            className="event-card-ticket-btn"
            href={ticketLink}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={ticketLabel}
          >
            Bilet Al
          </Button>
        ) : null}
      </div>
    </article>
  );
}
