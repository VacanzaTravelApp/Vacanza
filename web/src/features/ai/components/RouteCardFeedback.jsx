import React, { useEffect, useMemo, useState } from "react";
import { Button, DatePicker, Modal, message } from "antd";
import {
  LikeOutlined,
  LikeFilled,
  DislikeOutlined,
  DislikeFilled,
  CalendarOutlined,
} from "@ant-design/icons";
import dayjs from "dayjs";
import { useAuth } from "../../../context/useAuth";
import { postPoiFeedbackEvent, postRouteFeedback } from "../../../api/feedbackApi";
import { createTripCalendarEvent } from "../../../api/tripCalendarApi";
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
  const [calendarOpen, setCalendarOpen] = useState(false);
  const [calendarDate, setCalendarDate] = useState(() => dayjs());
  const [calendarSaving, setCalendarSaving] = useState(false);
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
      // message.success("Thanks, your route preference has been saved.");
    } catch (e) {
      message.error(e?.friendlyMessage || "Failed to send feedback.");
    } finally {
      setSending(false);
    }
  };

  /** Calendar add is independent of thumbs vote; requires a server-saved route id. */
  const showAddToCalendar = hasSavedRoute && isAuthenticated;

  const tripDays = Math.max(
    1,
    Number(route?.total_days ?? route?.totalDays ?? 1) || 1
  );

  const addRouteToCalendar = async () => {
    if (!routeId || !calendarDate) return;
    setCalendarSaving(true);
    try {
      const created = await createTripCalendarEvent({
        routeId,
        eventDate: calendarDate.format("YYYY-MM-DD"),
      });
      const n = Array.isArray(created) ? created.length : 1;
      /*
      message.success(
        n > 1
          ? `${n} days added to your calendar (Day 1–${n}).`
          : "Route added to your calendar."
      );
      */
      try {
        window.dispatchEvent(new CustomEvent("vacanza-trip-calendar-changed"));
      } catch {
        /* ignore */
      }
      setCalendarOpen(false);
    } catch (e) {
      const status = e?.response?.status;
      if (status === 409) {
        message.warning("This route is already on that day.");
      } else {
        message.error(e?.friendlyMessage || "Could not add to calendar.");
      }
    } finally {
      setCalendarSaving(false);
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
      {showAddToCalendar ? (
        <>
          <Button
            type="text"
            size="small"
            className="route-card-feedback-calendar"
            icon={<CalendarOutlined />}
            onClick={() => {
              setCalendarDate(dayjs());
              setCalendarOpen(true);
            }}
            aria-label="Export this route to your calendar"
          >
            Export to calendar
          </Button>
          <Modal
            title="Export route to calendar"
            open={calendarOpen}
            onCancel={() => setCalendarOpen(false)}
            onOk={addRouteToCalendar}
            okText="Add"
            confirmLoading={calendarSaving}
            destroyOnClose
            wrapClassName="vacanza-chat vc-calendar-add-modal-wrap"
            className="vc-calendar-add-modal"
          >
            <p style={{ marginBottom: 12, opacity: 0.85 }}>
              {tripDays > 1 ? (
                <>
                  Choose the <strong>first trip day</strong>. A {tripDays}-day route is added as Day&nbsp;1…Day&nbsp;
                  {tripDays} on consecutive dates. Open any day from the map calendar.
                </>
              ) : (
                <>Pick the day for this route. Open it anytime from the map calendar.</>
              )}
            </p>
            <DatePicker
              value={calendarDate}
              onChange={(d) => d && setCalendarDate(d)}
              style={{ width: "100%" }}
              format="MMM D, YYYY"
            />
          </Modal>
        </>
      ) : null}
    </div>
  );
}
