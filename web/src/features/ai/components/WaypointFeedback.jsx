import React, { useState } from "react";
import { Button, message } from "antd";
import { LikeOutlined, LikeFilled, DislikeOutlined, DislikeFilled } from "@ant-design/icons";
import { useAuth } from "../../../context/useAuth";
import { postPoiFeedbackEvent } from "../../../api/feedbackApi";
import { getWaypointCategory } from "../utils/routeMap";

function normalizeCategoryKeys(category) {
  if (category == null || String(category).trim() === "") return [];
  return [String(category).toLowerCase().trim().replace(/-/g, "_")];
}

function pickIds(wp) {
  const mapboxId = wp.mapbox_id ?? wp.mapboxId ?? null;
  const foursquareId =
    wp.foursquare_id ?? wp.foursquareId ?? wp.external_id ?? wp.externalId ?? null;
  return { mapboxId, foursquareId };
}

function canSendFeedback(wp) {
  const { mapboxId, foursquareId } = pickIds(wp);
  const cats = normalizeCategoryKeys(getWaypointCategory(wp));
  return !!(mapboxId || foursquareId || cats.length);
}

/**
 * Thumbs for a single route waypoint; stops click propagation so map focus does not fire.
 */
export default function WaypointFeedback({ waypoint }) {
  const { isAuthenticated } = useAuth();
  const [sending, setSending] = useState(false);
  /** 'up' | 'down' | null — son başarılı oylama */
  const [vote, setVote] = useState(null);

  if (!isAuthenticated || !waypoint || !canSendFeedback(waypoint)) {
    return null;
  }

  const { mapboxId, foursquareId } = pickIds(waypoint);
  const categoryKeys = normalizeCategoryKeys(getWaypointCategory(waypoint));
  const payloadBase = {
    mapboxId: mapboxId || null,
    foursquareId: foursquareId || null,
    categoryKeys: categoryKeys.length ? categoryKeys : null,
  };

  const send = async (eventType) => {
    if (sending) return;
    setSending(true);
    try {
      await postPoiFeedbackEvent({ eventType, ...payloadBase });
      setVote(eventType === "THUMBS_UP" ? "up" : "down");
      message.success("Teşekkürler, tercihin kaydedildi.");
    } catch (e) {
      message.error(e?.friendlyMessage || "Geri bildirim gönderilemedi.");
    } finally {
      setSending(false);
    }
  };

  return (
    <div
      className="waypoint-feedback"
      onClick={(e) => e.stopPropagation()}
      onKeyDown={(e) => e.stopPropagation()}
      role="group"
      aria-label="Durak geri bildirimi"
    >
      <Button
        type="text"
        size="small"
        className={`waypoint-feedback-btn ${vote === "up" ? "waypoint-feedback-btn--active-up" : ""}`}
        icon={vote === "up" ? <LikeFilled /> : <LikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_UP")}
        aria-label="Beğendim"
        aria-pressed={vote === "up"}
      />
      <Button
        type="text"
        size="small"
        className={`waypoint-feedback-btn ${vote === "down" ? "waypoint-feedback-btn--active-down" : ""}`}
        icon={vote === "down" ? <DislikeFilled /> : <DislikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_DOWN")}
        aria-label="Beğenmedim"
        aria-pressed={vote === "down"}
      />
    </div>
  );
}
