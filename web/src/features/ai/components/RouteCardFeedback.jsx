import React, { useEffect, useMemo, useState } from "react";
import { Button, message } from "antd";
import { LikeOutlined, LikeFilled, DislikeOutlined, DislikeFilled } from "@ant-design/icons";
import { useAuth } from "../../../context/useAuth";
import { postPoiFeedbackEvent, postRouteFeedback } from "../../../api/feedbackApi";
import { getWaypointCategory } from "../utils/routeMap";

const STORAGE_PREFIX = "vacanzaRouteVote:v2:";

function readStoredVote(storageKey) {
  if (!storageKey || typeof sessionStorage === "undefined") return null;
  try {
    const v = sessionStorage.getItem(STORAGE_PREFIX + storageKey);
    return v === "up" || v === "down" ? v : null;
  } catch {
    return null;
  }
}

function dbVoteToUi(v) {
  if (v === "UP" || v === "up") return "up";
  if (v === "DOWN" || v === "down") return "down";
  return null;
}

/** Tüm günlerdeki waypoint kategorilerinden benzersiz anahtarlar (backend ile uyumlu). */
export function collectRouteCategoryKeys(route) {
  const set = new Set();
  for (const day of route?.days || []) {
    for (const w of day?.waypoints || []) {
      const c = getWaypointCategory(w);
      if (c) {
        set.add(c.toLowerCase().trim().replace(/-/g, "_"));
      }
    }
  }
  return [...set];
}

/**
 * Sohbetteki genel rota kartı — kayıtlı rota varsa oylar DB'de (user_route_feedback);
 * aksi halde kategori geri bildirimi + sessionStorage.
 */
export default function RouteCardFeedback({ route, storageKey, routeId, initialDbVote }) {
  const { isAuthenticated } = useAuth();
  const [sending, setSending] = useState(false);
  const [vote, setVote] = useState(() => {
    const fromDb = dbVoteToUi(initialDbVote);
    return fromDb ?? readStoredVote(storageKey);
  });

  const categoryKeys = useMemo(() => collectRouteCategoryKeys(route), [route]);
  const hasSavedRoute = !!routeId;
  const canSend =
    isAuthenticated &&
    !!storageKey &&
    (hasSavedRoute || categoryKeys.length > 0);

  useEffect(() => {
    const fromDb = dbVoteToUi(initialDbVote);
    setVote(fromDb ?? readStoredVote(storageKey));
  }, [storageKey, initialDbVote]);

  if (!canSend) {
    return null;
  }

  const send = async (eventType) => {
    if (sending) return;
    setSending(true);
    try {
      if (routeId) {
        await postRouteFeedback({ routeId, eventType });
      } else {
        await postPoiFeedbackEvent({
          eventType,
          mapboxId: null,
          foursquareId: null,
          categoryKeys,
        });
      }
      const v = eventType === "THUMBS_UP" ? "up" : "down";
      try {
        sessionStorage.setItem(STORAGE_PREFIX + storageKey, v);
      } catch {
        /* ignore */
      }
      setVote(v);
      message.success("Thanks, your route preference has been saved.");
    } catch (e) {
      message.error(e?.friendlyMessage || "Failed to send feedback.");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="route-card-feedback" role="group" aria-label="General route feedback">
      <span className="route-card-feedback-label">Feedback:</span>
      <Button
        type="text"
        size="small"
        className={`route-card-feedback-btn ${vote === "up" ? "route-card-feedback-btn--active-up" : ""}`}
        icon={vote === "up" ? <LikeFilled /> : <LikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_UP")}
        aria-label="I like this route recommendation"
        aria-pressed={vote === "up"}
      />
      <Button
        type="text"
        size="small"
        className={`route-card-feedback-btn ${vote === "down" ? "route-card-feedback-btn--active-down" : ""}`}
        icon={vote === "down" ? <DislikeFilled /> : <DislikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_DOWN")}
        aria-label="I don't like this route recommendation"
        aria-pressed={vote === "down"}
      />
    </div>
  );
}
