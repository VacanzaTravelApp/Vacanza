import React from "react";

/**
 * Compact event tile for horizontal recommendation lists (Task 6 / 7).
 */
export default function EventCard({ event }) {
  if (!event) return null;

  const {
    name,
    description,
    thumbnail,
    startTime,
    endTime,
    venueName,
    fullAddress,
    category,
    ticketLink,
    matchedDay,
    matchReason,
    relevanceScore,
  } = event;

  const when =
    startTime && endTime
      ? `${startTime} – ${endTime}`
      : startTime || endTime || null;

  return (
    <article className="event-card">
      {thumbnail ? (
        <div className="event-card-thumb-wrap">
          <img className="event-card-thumb" src={thumbnail} alt="" loading="lazy" />
        </div>
      ) : (
        <div className="event-card-thumb-placeholder" aria-hidden />
      )}
      <div className="event-card-body">
        <div className="event-card-title">{name}</div>
        {category ? <span className="event-card-cat">{category}</span> : null}
        {when ? <div className="event-card-when">{when}</div> : null}
        {venueName ? <div className="event-card-venue">{venueName}</div> : null}
        {fullAddress ? <div className="event-card-address">{fullAddress}</div> : null}
        {matchedDay != null ? (
          <div className="event-card-day">Gün {matchedDay}</div>
        ) : null}
        {matchReason ? <p className="event-card-reason">{matchReason}</p> : null}
        {description ? (
          <p className="event-card-desc">{description}</p>
        ) : null}
        {relevanceScore != null && Number.isFinite(Number(relevanceScore)) ? (
          <div className="event-card-score">
            {Math.round(Number(relevanceScore) * 100)}% uyum
          </div>
        ) : null}
        {ticketLink ? (
          <a
            className="event-card-link"
            href={ticketLink}
            target="_blank"
            rel="noopener noreferrer"
          >
            Bilet / detay
          </a>
        ) : null}
      </div>
    </article>
  );
}
