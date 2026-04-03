import React, { useEffect, useState } from "react";
import { FaCalendarAlt } from "react-icons/fa";
import { getEventRecommendations } from "../../../api/aiApi";
import EventCard from "./EventCard";
import "../styles/eventRecommendations.css";

/**
 * Fetches and shows event recommendations for a saved backend route.
 */
export default function EventRecommendations({ routeId }) {
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState(null);

  useEffect(() => {
    if (!routeId) {
      setLoading(false);
      setData(null);
      return undefined;
    }

    let cancelled = false;
    setLoading(true);
    setData(null);

    (async () => {
      try {
        const res = await getEventRecommendations(routeId);
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
  }, [routeId]);

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

  const headerText = data.message && String(data.message).trim() ? data.message : "Etkinlik önerileri";

  return (
    <div className="event-recommendations-section event-rec-loaded">
      <div className="event-recommendations-header">
        <FaCalendarAlt aria-hidden />
        <span>{headerText}</span>
      </div>
      <div className="event-recommendations-list">
        {events.map((event) => (
          <EventCard key={event.id} event={event} />
        ))}
      </div>
    </div>
  );
}
