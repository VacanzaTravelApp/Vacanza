import React, { useState } from "react";
import { Button, message } from "antd";
import { LikeOutlined, LikeFilled, DislikeOutlined, DislikeFilled } from "@ant-design/icons";
import { useAuth } from "../../../context/useAuth";
import { postPoiFeedbackEvent } from "../../../api/feedbackApi";
import { getWaypointCategory } from "../utils/routeMap";

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
 * Sohbetteki genel rota kartı için toplu kategori geri bildirimi (POI id gerekmez).
 */
export default function RouteCardFeedback({ route }) {
  const { isAuthenticated } = useAuth();
  const [sending, setSending] = useState(false);
  const [vote, setVote] = useState(null);

  const categoryKeys = collectRouteCategoryKeys(route);
  const canSend = isAuthenticated && categoryKeys.length > 0;

  if (!canSend) {
    return null;
  }

  const send = async (eventType) => {
    if (sending) return;
    setSending(true);
    try {
      await postPoiFeedbackEvent({
        eventType,
        mapboxId: null,
        foursquareId: null,
        categoryKeys,
      });
      setVote(eventType === "THUMBS_UP" ? "up" : "down");
      message.success("Teşekkürler, rota tercihin kaydedildi.");
    } catch (e) {
      message.error(e?.friendlyMessage || "Geri bildirim gönderilemedi.");
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="route-card-feedback" role="group" aria-label="Rota genel geri bildirimi">
      <span className="route-card-feedback-label">Bu öneri:</span>
      <Button
        type="text"
        size="small"
        className={`route-card-feedback-btn ${vote === "up" ? "route-card-feedback-btn--active-up" : ""}`}
        icon={vote === "up" ? <LikeFilled /> : <LikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_UP")}
        aria-label="Rota önerisini beğendim"
        aria-pressed={vote === "up"}
      />
      <Button
        type="text"
        size="small"
        className={`route-card-feedback-btn ${vote === "down" ? "route-card-feedback-btn--active-down" : ""}`}
        icon={vote === "down" ? <DislikeFilled /> : <DislikeOutlined />}
        loading={sending}
        onClick={() => send("THUMBS_DOWN")}
        aria-label="Rota önerisini beğenmedim"
        aria-pressed={vote === "down"}
      />
    </div>
  );
}
