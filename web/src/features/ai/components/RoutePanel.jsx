import React from "react";
import { Button } from "antd";
import { CloseOutlined } from "@ant-design/icons";
import { getCategoryColor } from "../../../constants/categoryColors";
import "../styles/routePanel.css";

const TIME_SLOT_LABELS = {
  morning: "Sabah",
  afternoon: "Öğle",
  evening: "Akşam",
};

function formatTimeSlot(slot) {
  if (!slot) return null;
  const key = String(slot).trim().toLowerCase();
  return TIME_SLOT_LABELS[key] || slot;
}

export default function RoutePanel({
  route,
  activeDay,
  onDayChange,
  onClose,
  onWaypointClick,
}) {
  if (!route) return null;

  const days = route.days || [];
  const dayPlan = days.find((d) => Number(d?.day) === Number(activeDay));
  const waypoints = (dayPlan?.waypoints || []).filter((w) => {
    const lat = Number(w.latitude ?? w.lat);
    const lon = Number(w.longitude ?? w.lon);
    return Number.isFinite(lat) && Number.isFinite(lon);
  });
  const totalDays = route.total_days ?? route.totalDays ?? days.length;

  return (
    <div className="route-panel">
      <div className="route-panel-header">
        <div className="route-panel-title-row">
          <div>
            <div className="route-panel-title">{route.title}</div>
            <div className="route-panel-destination">{route.destination}</div>
          </div>
          <div className="route-panel-badges">
            <span className="route-panel-days-badge">{totalDays} gün</span>
            <Button
              type="text"
              icon={<CloseOutlined />}
              onClick={onClose}
              className="route-panel-close"
              aria-label="Close route"
            />
          </div>
        </div>
      </div>

      <div className="route-panel-tabs">
        {days.map((d) => {
          const isActive = d.day === activeDay;
          return (
            <button
              key={d.day}
              type="button"
              className={`route-panel-tab ${isActive ? "route-panel-tab-active" : ""}`}
              onClick={() => onDayChange(d.day)}
            >
              <span className="route-panel-tab-label">Gün {d.day}</span>
              {d.title && (
                <span className="route-panel-tab-sublabel">
                  {d.title.length > 30 ? `${d.title.slice(0, 30)}...` : d.title}
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className="route-panel-waypoints">
        {waypoints.length === 0 ? (
          <div className="route-panel-empty">Bu güne ait waypoint bulunamadı.</div>
        ) : (
          <ul className="route-panel-timeline">
            {waypoints.map((wp, idx) => {
              const color = getCategoryColor(wp.category);
              const isLast = idx === waypoints.length - 1;
              const isClickable = wp.latitude != null && wp.longitude != null;

              return (
                <li
                  key={`${wp.day}-${wp.order}`}
                  className={`route-panel-waypoint-row ${isLast ? "route-panel-waypoint-last" : ""}`}
                  onClick={() => isClickable && onWaypointClick?.(wp)}
                  role={isClickable ? "button" : undefined}
                  tabIndex={isClickable ? 0 : undefined}
                  onKeyDown={(e) => {
                    if (isClickable && (e.key === "Enter" || e.key === " ")) {
                      e.preventDefault();
                      onWaypointClick(wp);
                    }
                  }}
                >
                  <div
                    className="route-panel-waypoint-dot"
                    style={{ background: color, borderColor: color, color: "#fff" }}
                  >
                    {idx + 1}
                  </div>
                  {!isLast && <div className="route-panel-waypoint-line" />}
                  <div className="route-panel-waypoint-content">
                    <div className="route-panel-waypoint-main">
                      <span className="route-panel-waypoint-name">{wp.name}</span>
                      {(wp.estimated_duration_min ?? wp.estimatedDurationMin) != null && (
                        <span className="route-panel-waypoint-duration">
                          ~{wp.estimated_duration_min ?? wp.estimatedDurationMin} dk
                        </span>
                      )}
                    </div>
                    {wp.description && (
                      <div className="route-panel-waypoint-desc">{wp.description}</div>
                    )}
                    <div className="route-panel-waypoint-meta">
                      {wp.time_slot && (
                        <span className="route-panel-waypoint-timeslot">
                          {formatTimeSlot(wp.time_slot)}
                        </span>
                      )}
                    </div>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </div>

      {route.notes && (
        <div className="route-panel-notes">{route.notes}</div>
      )}
    </div>
  );
}
