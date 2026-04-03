import React from "react";
import { Button } from "antd";
import { CloseOutlined } from "@ant-design/icons";
import { getCategoryColor } from "../../../constants/categoryColors";
import WaypointFeedback from "./WaypointFeedback";
import EventRecommendations from "./EventRecommendations";
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

function formatForecastDate(iso) {
  if (!iso) return "—";
  const d = new Date(String(iso).slice(0, 10));
  return Number.isNaN(d.getTime())
    ? String(iso)
    : d.toLocaleDateString("tr-TR", { weekday: "short", day: "numeric", month: "short" });
}

/** Match day_parts row to active day (by date from daily row, else index). */
function pickDayPartForActiveDay(dayParts, weatherForecast, activeDay) {
  if (!Array.isArray(dayParts) || dayParts.length === 0) return null;
  const idx = Number(activeDay) - 1;
  const wf = Array.isArray(weatherForecast) ? weatherForecast[idx] : null;
  const wfDate = wf?.date;
  if (wfDate != null) {
    const s = String(wfDate).slice(0, 10);
    const hit = dayParts.find((row) => {
      const d = row?.date;
      if (d == null) return false;
      return String(d).slice(0, 10) === s;
    });
    if (hit) return hit;
  }
  return dayParts[idx] ?? null;
}

/** Up to 2 short Turkish lines when avoid_outdoor is true for a slot. */
function formatDayPartHintLines(dayRow) {
  if (!dayRow) return [];
  const slots = [
    { prop: "morning", label: "Sabah" },
    { prop: "afternoon", label: "Öğleden sonra" },
    { prop: "evening", label: "Akşam" },
  ];
  const lines = [];
  for (const { prop, label } of slots) {
    const s = dayRow[prop];
    if (!s) continue;
    const avoid = s.avoid_outdoor ?? s.avoidOutdoor;
    if (!avoid) continue;
    const precip =
      s.precipitation_probability_max_percent ?? s.precipitationProbabilityMaxPercent;
    const pct =
      precip != null && Number.isFinite(Number(precip))
        ? ` (~%${Math.round(Number(precip))} yağış olasılığı)`
        : "";
    lines.push(`${label}${pct}: dış mekânda uzun süre önerilmez.`);
    if (lines.length >= 2) break;
  }
  return lines;
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
  const waypoints = [...(dayPlan?.waypoints || [])].sort(
    (a, b) => (Number(a.order) || 0) - (Number(b.order) || 0)
  );
  const dayStartLocal = dayPlan?.day_start_local ?? dayPlan?.dayStartLocal;
  const dayEndLocal = dayPlan?.day_end_local ?? dayPlan?.dayEndLocal;
  const totalDays = route.total_days ?? route.totalDays ?? days.length;
  const weatherForecast = route.weather_forecast ?? route.weatherForecast ?? null;
  const weatherDayParts = route.weather_day_parts ?? route.weatherDayParts ?? null;
  const dayPartRow = pickDayPartForActiveDay(
    weatherDayParts,
    weatherForecast,
    activeDay
  );
  const dayPartHintLines = formatDayPartHintLines(dayPartRow);
  const showWeatherBlock =
    (Array.isArray(weatherForecast) && weatherForecast.length > 0) ||
    (Array.isArray(weatherDayParts) && weatherDayParts.length > 0);

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
              aria-label="Rotayı kapat"
            />
          </div>
        </div>
      </div>

      {!showWeatherBlock && route.destination && (
        <div className="route-panel-weather route-panel-weather--empty" role="status">
          <div className="route-panel-weather-title">Hava tahmini</div>
          <p className="route-panel-weather-empty-hint">
            Bu rota verisinde günlük hava yok. Hava, rota oluşturulurken backend tarafından eklenir.
          </p>
        </div>
      )}

      {showWeatherBlock && (
        <div className="route-panel-weather" aria-label="Hava tahmini">
          <div className="route-panel-weather-title">Hava tahmini (rota hedefi)</div>
          {Array.isArray(weatherForecast) && weatherForecast.length > 0 && (
            <ul className="route-panel-weather-days">
              {weatherForecast.map((row, i) => {
                const date = row.date;
                const tMax = row.temp_max_celsius ?? row.tempMaxCelsius;
                const tMin = row.temp_min_celsius ?? row.tempMinCelsius;
                const precip =
                  row.precipitation_probability_max_percent ??
                  row.precipitationProbabilityMaxPercent;
                return (
                  <li key={i} className="route-panel-weather-day">
                    <span className="route-panel-weather-date">{formatForecastDate(date)}</span>
                    <span className="route-panel-weather-temps">
                      {tMax != null && tMin != null
                        ? `${Math.round(tMax)}° / ${Math.round(tMin)}°`
                        : "—"}
                    </span>
                    {precip != null && (
                      <span className="route-panel-weather-rain">Yağış %{Math.round(precip)}</span>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
          {dayPartHintLines.length > 0 && (
            <div
              className="route-panel-weather-dayparts"
              aria-label="Seçili gün için gün içi hava ipucu"
            >
              {dayPartHintLines.map((line, i) => (
                <p key={i} className="route-panel-weather-dayparts-line">
                  {line}
                </p>
              ))}
            </div>
          )}
          <p className="route-panel-weather-hint">
            Tahmin, rotanın hedef bölgesine göredir.
          </p>
        </div>
      )}

      {(dayStartLocal || dayEndLocal) && (
        <div className="route-panel-day-window" aria-label="Gün özeti">
          {dayStartLocal && dayEndLocal
            ? `${dayStartLocal} – ${dayEndLocal}`
            : dayStartLocal || dayEndLocal}
        </div>
      )}

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
              const lat = Number(wp.latitude ?? wp.lat);
              const lon = Number(wp.longitude ?? wp.lon);
              const isClickable =
                wp.latitude != null &&
                wp.longitude != null &&
                Number.isFinite(lat) &&
                Number.isFinite(lon);
              const travelMin =
                wp.travel_from_previous_min ?? wp.travelFromPreviousMin;
              const arrival =
                wp.arrival_time_local ?? wp.arrivalTimeLocal;
              const departure =
                wp.departure_time_local ?? wp.departureTimeLocal;
              const dwell =
                wp.estimated_duration_min ?? wp.estimatedDurationMin;

              return (
                <React.Fragment key={`${wp.day}-${wp.order}-${idx}`}>
                  {idx > 0 && travelMin != null && travelMin > 0 && (
                    <li className="route-panel-travel-leg">
                      <div className="route-panel-travel-line" />
                      <span className="route-panel-travel-label">
                        Yürüyüş ~{travelMin} dk
                      </span>
                    </li>
                  )}
                  <li
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
                      {(arrival || departure) && (
                        <div className="route-panel-waypoint-clock">
                          {arrival && departure
                            ? `${arrival} – ${departure}`
                            : arrival || departure}
                          {dwell != null && (
                            <span className="route-panel-waypoint-dwell">
                              {" "}
                              (~{dwell} dk)
                            </span>
                          )}
                        </div>
                      )}
                      <div className="route-panel-waypoint-main">
                        <div className="route-panel-waypoint-title-block">
                          <span className="route-panel-waypoint-name">{wp.name}</span>
                          {(wp.estimated_duration_min ?? wp.estimatedDurationMin) != null &&
                            !arrival &&
                            !departure && (
                              <span className="route-panel-waypoint-duration">
                                ~{wp.estimated_duration_min ?? wp.estimatedDurationMin} dk
                              </span>
                            )}
                        </div>
                        <WaypointFeedback
                          waypoint={wp}
                          storageKey={`d${activeDay}-i${idx}-o${wp.order ?? idx}-${String(wp.name || "").slice(0, 48)}`}
                        />
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
                </React.Fragment>
              );
            })}
          </ul>
        )}
      </div>

      {(route.routeId ?? route.route_id) ? (
        <div className="route-panel-event-recs">
          <div className="route-panel-event-recs-head">
            <span className="route-panel-event-recs-title">Etkinlik önerileri</span>
            <span className="route-panel-event-recs-desc">
              Ticketmaster — konser, spor, gösteri
            </span>
          </div>
          <EventRecommendations routeId={route.routeId ?? route.route_id} />
        </div>
      ) : null}

      {route.notes && (
        <div className="route-panel-notes">{route.notes}</div>
      )}
    </div>
  );
}
