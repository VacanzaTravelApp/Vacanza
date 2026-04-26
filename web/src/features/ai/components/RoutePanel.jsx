import React, { useRef, useState, useEffect } from "react";
import { Button } from "antd";
import { CalendarOutlined, CloseOutlined } from "@ant-design/icons";
import { getCategoryColor } from "../../../constants/categoryColors";
import WaypointFeedback from "./WaypointFeedback";
import EventRecommendations from "./EventRecommendations";
import HotelPickerSheet from "./HotelPickerSheet";
import HotelIcon from "./icons/HotelIcon";
import { aiApi } from "../../../api/aiApi";
import { createTripCalendarEvent, exportRouteICS } from "../../../api/tripCalendarApi";
import { message, Tooltip } from "antd";
import { Rnd } from "react-rnd";
import "../styles/routePanel.css";

/** Set to true to show per-stop thumbs on the map route card (POI feedback). */
const ENABLE_ROUTE_PANEL_WAYPOINT_FEEDBACK = false;

const TIME_SLOT_LABELS = {
  morning: "Morning",
  lunch: "Lunch",
  afternoon: "Afternoon",
  evening: "Evening",
  dinner: "Dinner",
  night: "Night",
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
    : d.toLocaleDateString("en-US", { weekday: "short", day: "numeric", month: "short" }).replace(',', '');
}

function stripEmojis(text) {
  if (!text) return text;
  return String(text)
    .replace(/[\p{Extended_Pictographic}\p{Emoji_Presentation}]/gu, '')
    .trim();
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
    { prop: "morning", label: "Morning" },
    { prop: "afternoon", label: "Afternoon" },
    { prop: "evening", label: "Evening" },
  ];
  const lines = [];
  for (const { prop, label } of slots) {
    const s = dayRow[prop];
    if (!s) continue;
    const avoid = s.avoid_outdoor ?? s.avoidOutdoor;
    if (!avoid) continue;
    const precip = s.precipitation_probability_max_percent ?? s.precipitationProbabilityMaxPercent;
    const pct =
      precip != null && Number.isFinite(Number(precip))
        ? ` (~${Math.round(Number(precip))}% chance of rain)`
        : "";
    lines.push(`${label}${pct}: not recommended for long outdoor activities.`);
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
  onMarkUnavailable,
  onRouteUpdate,
}) {
  if (!route) return null;

  const routeId = route.routeId ?? route.route_id;
  const selectedHotel = route.selectedHotel ?? null;

  const [adjustingPoi, setAdjustingPoi] = useState(null);
  const [hotelPickerOpen, setHotelPickerOpen] = useState(false);
  const [savingHotel, setSavingHotel] = useState(false);
  const [hotelError, setHotelError] = useState(null);
  const [exporting, setExporting] = useState(false);
  const [alreadyExported, setAlreadyExported] = useState(false);

  useEffect(() => {
    if (!routeId) return;
    const exportedRoutes = JSON.parse(localStorage.getItem("vacanza_exported_routes") || "[]");
    setAlreadyExported(exportedRoutes.includes(routeId));
  }, [routeId]);

  async function handleExportCalendar() {
    if (!routeId) return;
    setExporting(true);
    try {
      // 1. Determine date (fallback to today if no forecast)
      let eventDate = new Date().toISOString().split('T')[0];
      if (Array.isArray(route.weather_forecast) && route.weather_forecast[0]?.date) {
        eventDate = String(route.weather_forecast[0].date).slice(0, 10);
      }

      // 2. Register to backend
      try {
        await createTripCalendarEvent({ routeId, eventDate });
      } catch (err) {
        // If it's already there, we can proceed to download the ICS anyway
        if (err?.response?.status !== 409) {
          throw err;
        }
      }

      // 3. Export ICS
      const blob = await exportRouteICS(routeId);

      // 4. Download
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.setAttribute("download", `vacanza-trip.ics`);
      document.body.appendChild(link);
      link.click();
      link.parentNode.removeChild(link);
      window.URL.revokeObjectURL(url);

      message.success("Successfully exported to calendar!");
      setAlreadyExported(true);

      // Persist in localStorage so it stays disabled after refresh
      const exportedRoutes = JSON.parse(localStorage.getItem("vacanza_exported_routes") || "[]");
      if (!exportedRoutes.includes(routeId)) {
        exportedRoutes.push(routeId);
        localStorage.setItem("vacanza_exported_routes", JSON.stringify(exportedRoutes));
      }

      // Refresh the internal Vacanza calendar if it's open
      window.dispatchEvent(new CustomEvent("vacanza-trip-calendar-changed"));
    } catch (err) {
      console.error("Export error", err);
      message.error("Failed to export to calendar.");
    } finally {
      setExporting(false);
    }
  }

  async function handleHotelSelect(hotel) {
    if (!routeId) return;
    setSavingHotel(true);
    setHotelPickerOpen(false);
    setHotelError(null);
    try {
      await aiApi.setRouteHotel(routeId, {
        hotelName: hotel.hotelName,
        hotelExternalId: hotel.hotelId,
        address: hotel.address,
        latitude: hotel.latitude,
        longitude: hotel.longitude,
        imageUrl: hotel.imageUrl,
        externalBookingUrl: hotel.externalBookingUrl,
        pricePerNight: hotel.pricePerNight,
        currency: hotel.currency,
        rating: hotel.rating,
        providerName: hotel.providerName,
      });
      onRouteUpdate?.({
        ...route,
        selectedHotel: {
          hotelName: hotel.hotelName,
          hotelExternalId: hotel.hotelId,
          address: hotel.address,
          latitude: hotel.latitude,
          longitude: hotel.longitude,
          imageUrl: hotel.imageUrl,
          externalBookingUrl: hotel.externalBookingUrl,
          pricePerNight: hotel.pricePerNight,
          currency: hotel.currency,
          rating: hotel.rating,
          providerName: hotel.providerName,
        },
      });
    } catch (err) {
      console.error("Failed to save hotel", err);
      const msg = err?.friendlyMessage || err?.response?.data?.message || err?.message || "Failed to save hotel.";
      setHotelError(msg);
    } finally {
      setSavingHotel(false);
    }
  }

  async function handleRemoveHotel() {
    if (!routeId) return;
    setSavingHotel(true);
    setHotelError(null);
    try {
      await aiApi.removeRouteHotel(routeId);
      onRouteUpdate?.({ ...route, selectedHotel: null });
    } catch (err) {
      console.error("Failed to remove hotel", err);
      const msg = err?.friendlyMessage || err?.response?.data?.message || err?.message || "Failed to remove hotel.";
      setHotelError(msg);
    } finally {
      setSavingHotel(false);
    }
  }

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

  const isMobile = window.innerWidth <= 768;

  const content = (
    <div className="route-panel">
      <div className="route-panel-header">

        <div className="route-panel-title-row">
          <div>
            <div className="route-panel-title">{route.title}</div>
            <div className="route-panel-destination">{route.destination}</div>
          </div>
          <div className="route-panel-badges">
            <Tooltip title={alreadyExported ? "This route is already in your calendar" : "Export this trip to your calendar (.ics)"}>
              <Button
                size="small"
                icon={<CalendarOutlined />}
                loading={exporting}
                disabled={alreadyExported}
                onClick={handleExportCalendar}
                className={`route-panel-export-btn ${alreadyExported ? "route-panel-export-btn--done" : ""}`}
              >
                {alreadyExported ? "EXPORTED TO CALENDAR" : "EXPORT TO CALENDAR"}
              </Button>
            </Tooltip>
            <span className="route-panel-days-badge">{totalDays} days</span>
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

      <div className="route-panel-content">
        {!showWeatherBlock && route.destination && (
          <div className="route-panel-weather route-panel-weather--empty" role="status">
            <div className="route-panel-weather-title">Weather Forecast</div>
            <p className="route-panel-weather-empty-hint">
              No daily weather forecast available for this route. Forecast is added when the AI creates the plan.
            </p>
          </div>
        )}

        {showWeatherBlock && (
          <div className="route-panel-weather" aria-label="Weather forecast">
            <div className="route-panel-weather-title">Weather Forecast (destination)</div>
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
                          ? `${Math.round(tMax)}°C / ${Math.round(tMin)}°C`
                          : "—"}
                      </span>
                      {precip != null && (
                        <span className="route-panel-weather-rain">Rain {Math.round(precip)}%</span>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
            {dayPartHintLines.length > 0 && (
              <div
                className="route-panel-weather-dayparts"
                aria-label="Hourly weather tips for selected day"
              >
                {dayPartHintLines.map((line, i) => (
                  <p key={i} className="route-panel-weather-dayparts-line">
                    {line}
                  </p>
                ))}
              </div>
            )}
            <p className="route-panel-weather-hint">
              Forecast is relative to the destination area.
            </p>
          </div>
        )}

        {/* ── Hotel Section ── */}
        <div className="route-panel-hotel-section">
          <div className="route-panel-hotel-section-label">
            <HotelIcon size={14} className="route-panel-hotel-icon" />
            Accommodation
          </div>
          {hotelError && (
            <div className="route-panel-hotel-error">{hotelError}</div>
          )}
          {selectedHotel ? (
            <div className="route-panel-hotel-card">
              <div className="route-panel-hotel-card-inner">
                <div className="route-panel-hotel-thumb">
                  {selectedHotel.imageUrl ? (
                    <img
                      className="route-panel-hotel-thumb-img"
                      src={selectedHotel.imageUrl}
                      alt={selectedHotel.hotelName}
                      loading="lazy"
                      onError={(e) => { e.currentTarget.style.display = "none"; }}
                    />
                  ) : (
                    <div className="route-panel-hotel-thumb-placeholder" aria-hidden>
                      <HotelIcon size={22} className="route-panel-hotel-thumb-icon" title="Hotel" />
                    </div>
                  )}
                </div>
                <div className="route-panel-hotel-info">
                  <div className="route-panel-hotel-name">{selectedHotel.hotelName}</div>
                  {selectedHotel.address && (
                    <div className="route-panel-hotel-address">📍 {selectedHotel.address}</div>
                  )}
                  {selectedHotel.rating != null && (
                    <div className="route-panel-hotel-stars">★ {selectedHotel.rating}</div>
                  )}
                </div>
              </div>
              <div className="route-panel-hotel-actions">
                <div className="route-panel-hotel-actions-left">
                  {selectedHotel.externalBookingUrl && (
                    <a
                      className="route-panel-hotel-book-btn"
                      href={selectedHotel.externalBookingUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      Book ↗
                    </a>
                  )}
                  <button
                    className="route-panel-hotel-change-btn"
                    onClick={() => setHotelPickerOpen(true)}
                    disabled={savingHotel}
                  >
                    Change
                  </button>
                </div>
                <button
                  className="route-panel-hotel-remove-btn"
                  onClick={handleRemoveHotel}
                  disabled={savingHotel}
                >
                  {savingHotel ? '...' : 'Remove'}
                </button>
              </div>
            </div>
          ) : (
            <div className="route-panel-hotel-empty">
              <span className="route-panel-hotel-empty-text">No hotel added yet</span>
              <button
                className="route-panel-hotel-add-btn"
                onClick={() => setHotelPickerOpen(true)}
                disabled={savingHotel || !routeId}
              >
                {savingHotel ? "Saving..." : "+ Add Hotel"}
              </button>
            </div>
          )}
        </div>

        {(dayStartLocal || dayEndLocal) && (
          <div className="route-panel-day-window" aria-label="Day summary">
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
                <span className="route-panel-tab-label">Day {d.day}</span>
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
            <div className="route-panel-empty">No waypoints found for this day.</div>
          ) : (
            <ul className="route-panel-timeline">

              {/* ── Hotel start ── */}
              {selectedHotel && (
                <>
                  <li className="route-panel-waypoint-row">
                    <div className="route-panel-hotel-dot" aria-hidden>
                      <HotelIcon size={18} className="route-panel-hotel-dot-icon" title="Hotel" />
                    </div>
                    <div className="route-panel-waypoint-line" />
                    <div className="route-panel-waypoint-content" style={{ paddingTop: 4 }}>
                      <div className="route-panel-waypoint-name">{selectedHotel.hotelName}</div>
                      {selectedHotel.address && (
                        <div className="route-panel-waypoint-desc">{selectedHotel.address}</div>
                      )}
                    </div>
                  </li>
                  <li className="route-panel-travel-leg">
                    <div className="route-panel-travel-line" />
                    <span className="route-panel-travel-label">Depart from hotel</span>
                  </li>
                </>
              )}

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
                          Walk ~{travelMin} min
                        </span>
                      </li>
                    )}
                    <li
                      className={`route-panel-waypoint-row ${isLast ? "route-panel-waypoint-last" : ""} ${wp.unavailable ? "route-panel-waypoint-unavailable" : ""}`}
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
                      {(!isLast || selectedHotel) && <div className="route-panel-waypoint-line" />}
                      <div className="route-panel-waypoint-content">
                        {(arrival || departure) && (
                          <div className="route-panel-waypoint-clock">
                            {arrival && departure
                              ? `${arrival} – ${departure}`
                              : arrival || departure}
                            {dwell != null && (
                              <span className="route-panel-waypoint-dwell">
                                {" "}
                                (~{dwell} min)
                              </span>
                            )}
                          </div>
                        )}
                        <div className="route-panel-waypoint-main">
                          <div className="route-panel-waypoint-title-block">
                            <span className="route-panel-waypoint-name">{stripEmojis(wp.name)}</span>
                            {(wp.estimated_duration_min ?? wp.estimatedDurationMin) != null &&
                              !arrival &&
                              !departure && (
                                <span className="route-panel-waypoint-duration">
                                  ~{wp.estimated_duration_min ?? wp.estimatedDurationMin} min
                                </span>
                              )}
                          </div>
                          {ENABLE_ROUTE_PANEL_WAYPOINT_FEEDBACK ? (
                            <WaypointFeedback
                              waypoint={wp}
                              storageKey={`d${activeDay}-i${idx}-o${wp.order ?? idx}-${stripEmojis(String(wp.name || "")).slice(0, 48)}`}
                            />
                          ) : null}
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
                          {wp.unavailable && (
                            <span className="route-panel-waypoint-closed-badge">
                              Closed
                            </span>
                          )}
                        </div>
                        {!wp.unavailable && onMarkUnavailable && (
                          <button
                            className="route-panel-mark-closed-btn"
                            disabled={adjustingPoi === wp.name}
                            onClick={async (e) => {
                              e.stopPropagation();
                              setAdjustingPoi(wp.name);
                              try {
                                await onMarkUnavailable(wp);
                              } finally {
                                setAdjustingPoi(null);
                              }
                            }}
                            title="I couldn't reach this place or it is closed"
                          >
                            {adjustingPoi === wp.name ? "Updating..." : "This place is closed"}
                          </button>
                        )}
                      </div>
                    </li>
                  </React.Fragment>
                );
              })}

              {/* ── Hotel end (return) ── */}
              {selectedHotel && (
                <>
                  <li className="route-panel-travel-leg">
                    <div className="route-panel-travel-line" />
                    <span className="route-panel-travel-label">Return to hotel</span>
                  </li>
                  <li className="route-panel-waypoint-row route-panel-waypoint-last">
                    <div className="route-panel-hotel-dot" aria-hidden>
                      <HotelIcon size={18} className="route-panel-hotel-dot-icon" title="Hotel" />
                    </div>
                    <div className="route-panel-waypoint-content" style={{ paddingTop: 4 }}>
                      <div className="route-panel-waypoint-name">{selectedHotel.hotelName}</div>
                    </div>
                  </li>
                </>
              )}

            </ul>
          )}
        </div>

        {(route.routeId ?? route.route_id) ? (
          <div className="route-panel-event-recs">
            <div className="route-panel-event-recs-head">
              <span className="route-panel-event-recs-title">Event Recommendations</span>
              <span className="route-panel-event-recs-desc">
                Ticketmaster — concerts, sports, shows
              </span>
            </div>
            <EventRecommendations routeId={route.routeId ?? route.route_id} tripDay={activeDay} />
          </div>
        ) : null}

        {route.notes && (
          <div className="route-panel-notes">{route.notes}</div>
        )}
      </div>
    </div>
  );

  const hotelPicker = (
    <HotelPickerSheet
      open={hotelPickerOpen}
      onClose={() => setHotelPickerOpen(false)}
      defaultDestination={route.destination}
      onSelect={handleHotelSelect}
    />
  );

  if (isMobile) {
    return <>{content}{hotelPicker}</>;
  }

  return (
    <>
      <Rnd
        default={{
          x: window.innerWidth - 640,
          y: 84,
          width: 480,
          height: 600,
        }}
        minWidth={320}
        minHeight={400}
        dragHandleClassName="route-panel-header"
        cancel=".route-panel-close, .route-panel-tab"
        bounds="parent"
        enableResizing={{
          top: true,
          right: true,
          bottom: true,
          left: true,
          topRight: true,
          bottomRight: true,
          bottomLeft: true,
          topLeft: true,
        }}
      >
        {content}
      </Rnd>
      {hotelPicker}
    </>
  );
}
