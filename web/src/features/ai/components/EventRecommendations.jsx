import React, { useEffect, useState } from "react";
import { getEventRecommendations } from "../../../api/aiApi";
import EventCard from "./EventCard";
import "../styles/eventRecommendations.css";

/**
 * Fetches and shows event recommendations for a saved backend route.
 * @param {number} [tripDay] — 1-based itinerary day (e.g. when the user selects "Gün 2" on the map panel); narrows Ticketmaster to that calendar day.
 */
const BROAD_WINDOW = "BROAD_30_DAYS";
const INITIAL_BROAD_VISIBLE = 6;

export default function EventRecommendations({ routeId, tripDay, refreshKey = 0 }) {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);
  const [internalRefresh, setInternalRefresh] = useState(0);
  const [showAllBroad, setShowAllBroad] = useState(false);

  useEffect(() => {
    if (!routeId) {
      setLoading(false);
      setData(null);
      return undefined;
    }

    let cancelled = false;
    setLoading(true);
    setData(null);
    setShowAllBroad(false);

    (async () => {
      try {
        const res = await getEventRecommendations(routeId, { day: tripDay });
        if (!cancelled) setData(res);
      } catch {
        if (!cancelled) setData(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [routeId, tripDay, refreshKey, internalRefresh]);

  if (!routeId) return null;

  if (loading) {
    return (
      <div className="event-recommendations-section" aria-busy="true">
        <div className="event-rec-skeleton">
          <div className="event-rec-skeleton-card" />
          <div className="event-rec-skeleton-card" />
          <div className="event-rec-skeleton-card" />
        </div>
      </div>
    );
  }

  if (!data || data.hasRecommendations === false) {
    return null;
  }

  const events = Array.isArray(data.events) ? data.events : [];
  if (events.length === 0) {
    return null;
  }

  const isBroadWindow = data.eventSearchWindow === BROAD_WINDOW;
  const visibleEvents =
    isBroadWindow && !showAllBroad
      ? events.slice(0, INITIAL_BROAD_VISIBLE)
      : events;

  const headerText = data.message && String(data.message).trim() ? data.message : "Etkinlik önerileri";

  return (
    <div className="event-recommendations-section event-rec-loaded">
      {isBroadWindow && (
        <p className="event-rec-window-hint" role="status">
          Tarih belirtmediğin için yaklaşık bir aylık etkinlik listeleniyor. Sohbette gün veya hafta
          söylersen öneriler daha isabetli olur.
        </p>
      )}
      <div className="event-recommendations-header">
        <span className="event-recommendations-header-text">{headerText}</span>
        <button
          type="button"
          className="event-rec-refresh-btn"
          onClick={() => setInternalRefresh((n) => n + 1)}
          aria-label="Etkinlik önerilerini yeniden yükle"
        >
          Yenile
        </button>
      </div>
      <div className="event-recommendations-list">
        {visibleEvents.map((event) => (
          <EventCard key={event.id} event={event} />
        ))}
      </div>
      {isBroadWindow && events.length > INITIAL_BROAD_VISIBLE && (
        <div className="event-rec-broad-actions">
          {!showAllBroad ? (
            <button
              type="button"
              className="event-rec-show-more-btn"
              onClick={() => setShowAllBroad(true)}
            >
              Tümünü göster ({events.length})
            </button>
          ) : (
            <button
              type="button"
              className="event-rec-show-more-btn"
              onClick={() => setShowAllBroad(false)}
            >
              Daha az göster
            </button>
          )}
        </div>
      )}
    </div>
  );
}
