import React, { useEffect, useMemo, useState } from "react";
import { Button, message } from "antd";
import { LikeOutlined, LikeFilled, DislikeOutlined, DislikeFilled } from "@ant-design/icons";
import { useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../../../context/useAuth";
import { postPoiFeedbackEvent } from "../../../api/feedbackApi";
import { getWaypointCategory } from "../utils/routeMap";
import { deriveWaypointVote, hasPoiFeedbackKeys, pickWaypointIds } from "../utils/feedbackVoteUtils";
import { useFeedbackAffinity } from "../../../hooks/useFeedbackAffinity";

const WP_STORAGE_PREFIX = "vacanzaWpVote:v2:";

function readWaypointStoredVote(storageKey) {
  if (!storageKey || typeof sessionStorage === "undefined") return null;
  try {
    const v = sessionStorage.getItem(WP_STORAGE_PREFIX + storageKey);
    return v === "up" || v === "down" ? v : null;
  } catch {
    return null;
  }
}

function normalizeCategoryKeys(category) {
  if (category == null || String(category).trim() === "") return [];
  return [String(category).toLowerCase().trim().replace(/-/g, "_")];
}

function canSendFeedback(wp) {
  const { mapboxId, foursquareId } = pickWaypointIds(wp);
  const cats = normalizeCategoryKeys(getWaypointCategory(wp));
  return !!(mapboxId || foursquareId || cats.length);
}

/**
 * Thumbs for a single route waypoint; stops click propagation so map focus does not fire.
 * @param storageKey unique per row (e.g. day+index) — category-only feedback uses sessionStorage so rows don't share UI state.
 */
export default function WaypointFeedback({ waypoint, storageKey }) {
  const { isAuthenticated } = useAuth();
  const queryClient = useQueryClient();
  const { data: affinity } = useFeedbackAffinity();
  const [sending, setSending] = useState(false);
  const [localVote, setLocalVote] = useState(() => readWaypointStoredVote(storageKey));

  const hasPoiKeys = useMemo(() => hasPoiFeedbackKeys(waypoint), [waypoint]);
  const serverVote = useMemo(() => {
    if (!hasPoiKeys) return null;
    return deriveWaypointVote(affinity, waypoint);
  }, [affinity, waypoint, hasPoiKeys]);

  useEffect(() => {
    setLocalVote(readWaypointStoredVote(storageKey));
  }, [storageKey]);

  const vote = hasPoiKeys ? serverVote : localVote;

  if (!isAuthenticated || !waypoint || !canSendFeedback(waypoint) || !storageKey) {
    return null;
  }

  const { mapboxId, foursquareId } = pickWaypointIds(waypoint);
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
      const v = eventType === "THUMBS_UP" ? "up" : "down";
      if (!hasPoiKeys) {
        try {
          sessionStorage.setItem(WP_STORAGE_PREFIX + storageKey, v);
        } catch {
          /* ignore */
        }
        setLocalVote(v);
      } else {
        await queryClient.invalidateQueries({ queryKey: ["feedback", "affinity"] });
      }
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
