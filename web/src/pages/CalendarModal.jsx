import React, { useState, useRef, useEffect, useCallback } from 'react';
import { Modal, Button, Input, Select, ConfigProvider, Spin, message } from 'antd';
import { CloseOutlined, LeftOutlined, RightOutlined, PlusOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import { useAuth } from '../context/useAuth';
import { deleteTripCalendarEvent, deleteTripCalendarEventsByRoute, listTripCalendarEvents } from '../api/tripCalendarApi';
import './CalendarModal.css';

const { Option } = Select;

const DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const MONTH_NAMES = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

const CATEGORIES = [
    { key: 'Flight', color: '#38BDF8' },
    { key: 'Hotel', color: '#10B981' },
    { key: 'Activity', color: '#8B5CF6' },
    { key: 'Dining', color: '#F59E0B' },
    { key: 'Transport', color: '#EF4444' },
];

/** Saved liked routes on the calendar (server). */
const ROUTE_EVENT_COLOR = '#8B5CF6';

function formatRouteDayLabel(re) {
    const td = Number(re.totalDays) || 1;
    const id = Number(re.itineraryDay) || 1;
    if (td > 1) return `Day ${id}: ${re.title}`;
    return re.title;
}

/** Extract destination from title like "3-Day Trip to Istanbul" -> "Istanbul" */
function getTripDestination(title) {
    if (!title) return "";
    if (title.includes("Trip to ")) {
        return title.split("Trip to ").pop().trim();
    }
    // Fallback: remove common words
    return title.replace(/\d+-Day\s+/, "").replace(/Trip/gi, "").trim();
}

function getDaysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
function getFirstDay(y, m) { const d = new Date(y, m, 1).getDay(); return d === 0 ? 6 : d - 1; }

/** Generate a consistent readable color from a string ID (HSL). */
function getRouteColor(id) {
    if (!id) return "#8B5CF6";
    let hash = 0;
    for (let i = 0; i < id.length; i++) {
        hash = id.charCodeAt(i) + ((hash << 5) - hash);
    }
    const hue = Math.abs(hash % 360);
    // Prefer pleasant teal/purple/blue/orange ranges, steer clear of pure red/yellow
    return `hsl(${hue}, 60%, 55%)`;
}

export default function CalendarModal({ open, onClose, onOpenRouteFromCalendar, isDarkMode = true, themeClass = "theme-night" }) {
    const { isAuthenticated } = useAuth();
    const today = new Date();
    const [month, setMonth] = useState(today.getMonth());
    const [year, setYear] = useState(today.getFullYear());
    const [events, setEvents] = useState([]);
    const [remoteEvents, setRemoteEvents] = useState([]);
    const [remoteLoading, setRemoteLoading] = useState(false);
    // Selection state: click first day, then click second day for range
    const [selectStart, setSelectStart] = useState(null);
    const [selectEnd, setSelectEnd] = useState(null);
    const [hoverDay, setHoverDay] = useState(null);

    // Popup form
    const [showForm, setShowForm] = useState(false);
    const [formPos, setFormPos] = useState({ top: 0, left: 0 });
    const [newTitle, setNewTitle] = useState('');
    const [newCat, setNewCat] = useState('Activity');
    /** Right-hand detail panel (Apple-style inspector) */
    const [eventDetail, setEventDetail] = useState(null);
    const gridRef = useRef(null);

    const closeEventDetail = useCallback(() => setEventDetail(null), []);

    useEffect(() => {
        if (!open) setEventDetail(null);
    }, [open]);

    const prev = () => { if (month === 0) { setMonth(11); setYear(y => y - 1); } else setMonth(m => m - 1); };
    const next = () => { if (month === 11) { setMonth(0); setYear(y => y + 1); } else setMonth(m => m + 1); };
    const goToday = () => { setMonth(today.getMonth()); setYear(today.getFullYear()); };
    const isToday = (d) => d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
    const catInfo = (key) => CATEGORIES.find(c => c.key === key) || CATEGORIES[2];

    const loadRemoteEvents = useCallback(async () => {
        if (!open || !isAuthenticated) {
            setRemoteEvents([]);
            return;
        }
        setRemoteLoading(true);
        try {
            const rows = await listTripCalendarEvents(year, month + 1);
            setRemoteEvents(Array.isArray(rows) ? rows : []);
        } catch {
            setRemoteEvents([]);
        } finally {
            setRemoteLoading(false);
        }
    }, [open, isAuthenticated, year, month]);

    useEffect(() => {
        loadRemoteEvents();
    }, [loadRemoteEvents]);

    useEffect(() => {
        const onChanged = () => {
            if (open) loadRemoteEvents();
        };
        window.addEventListener('vacanza-trip-calendar-changed', onChanged);
        return () => window.removeEventListener('vacanza-trip-calendar-changed', onChanged);
    }, [open, loadRemoteEvents]);

    /** Unified chips for one calendar day: saved routes + local notes */
    const getEvts = (d) => {
        const fromRemote = remoteEvents
            .filter((re) => {
                const dt = dayjs(re.eventDate);
                return dt.date() === d && dt.month() === month && dt.year() === year;
            })
            .map((re) => ({
                key: `remote-${re.eventId}`,
                title: formatRouteDayLabel(re),
                shortTitle: re.title,
                color: ROUTE_EVENT_COLOR,
                routeId: re.routeId,
                eventId: re.eventId,
                itineraryDay: Number(re.itineraryDay) || 1,
                totalDays: Number(re.totalDays) || 1,
            }));

        const fromLocal = events
            .filter((e) => {
                const end = e.endDay || e.day;
                return d >= e.day && d <= end && e.month === month && e.year === year;
            })
            .map((e) => ({
                key: `local-${events.indexOf(e)}-${e.title}`,
                title: e.title,
                color: e.color,
                localIndex: events.indexOf(e),
                day: e.day,
                endDay: e.endDay || null,
            }));

        return [...fromRemote, ...fromLocal];
    };

    const removeRemoteEvent = async (eventId) => {
        try {
            await deleteTripCalendarEvent(eventId);
            await loadRemoteEvents();
            closeEventDetail();
            try {
                window.dispatchEvent(new CustomEvent('vacanza-trip-calendar-changed'));
            } catch {
                /* ignore */
            }
        } catch (e) {
            message.error(e?.friendlyMessage || 'Could not remove calendar item.');
        }
    };

    const removeRemoteRouteAll = async (routeId) => {
        try {
            await deleteTripCalendarEventsByRoute(routeId);
            await loadRemoteEvents();
            closeEventDetail();
            try {
                window.dispatchEvent(new CustomEvent('vacanza-trip-calendar-changed'));
            } catch {
                /* ignore */
            }
            // message.success('Trip removed from calendar.');
        } catch (e) {
            message.error(e?.friendlyMessage || 'Could not remove trip from calendar.');
        }
    };

    const rangeMin = () => selectStart && selectEnd ? Math.min(selectStart, selectEnd) : selectStart;
    const rangeMax = () => selectStart && selectEnd ? Math.max(selectStart, selectEnd) : selectStart;
    const previewMin = () => selectStart && !selectEnd && hoverDay ? Math.min(selectStart, hoverDay) : null;
    const previewMax = () => selectStart && !selectEnd && hoverDay ? Math.max(selectStart, hoverDay) : null;

    const isInRange = (d) => {
        const rmin = rangeMin(), rmax = rangeMax();
        if (rmin && rmax) return d >= rmin && d <= rmax;
        const pmin = previewMin(), pmax = previewMax();
        if (pmin && pmax) return d >= pmin && d <= pmax;
        return false;
    };

    const handleCellClick = (day, cur, e) => {
        if (!cur) return;

        if (!selectStart) {
            setSelectStart(day);
            setSelectEnd(null);
            setShowForm(false);
            closeEventDetail();
        } else if (!selectEnd) {
            setSelectEnd(day);
            const gridRect = gridRef.current?.getBoundingClientRect();
            const cellRect = e.currentTarget.getBoundingClientRect();
            if (gridRect) {
                setFormPos({
                    top: cellRect.top - gridRect.top + cellRect.height + 4,
                    left: Math.min(cellRect.left - gridRect.left, gridRect.width - 280),
                });
            }
            setShowForm(true);
            setNewTitle('');
            setNewCat('Activity');
        }
    };

    const addEvent = () => {
        if (!newTitle.trim() || !selectStart) return;
        const s = rangeMin();
        const en = rangeMax();
        setEvents(prev => [...prev, {
            title: newTitle.trim(),
            category: newCat,
            color: catInfo(newCat).color,
            day: s,
            endDay: en !== s ? en : null,
            month, year,
        }]);
        resetSelection();
    };

    const resetSelection = () => {
        setSelectStart(null);
        setSelectEnd(null);
        setShowForm(false);
        setNewTitle('');
        setHoverDay(null);
    };

    const removeEvent = (idx) => {
        setEvents(prev => prev.filter((_, i) => i !== idx));
        closeEventDetail();
    };

    const dim = getDaysInMonth(year, month);
    const fd = getFirstDay(year, month);
    const prevDim = getDaysInMonth(year, month - 1);
    const cells = [];
    for (let i = fd - 1; i >= 0; i--) cells.push({ day: prevDim - i, cur: false });
    for (let d = 1; d <= dim; d++) cells.push({ day: d, cur: true });
    while (cells.length < 42) cells.push({ day: cells.length - fd - dim + 1, cur: false });

    return (
        <ConfigProvider
            theme={{
                token: {
                    colorPrimary: '#38BDF8',
                    colorBgElevated: isDarkMode ? '#1A2333' : '#FFFFFF',
                    colorText: isDarkMode ? '#F8FAFC' : '#1E293B',
                },
                components: {
                    Modal: {
                        contentBg: 'transparent',
                        paddingMD: 0,
                        borderRadiusLG: 28,
                        boxShadow: 'none',
                    }
                }
            }}
        >
            <Modal
                open={open}
                onCancel={() => { onClose(); resetSelection(); }}
                footer={null}
                width={eventDetail ? "min(1080px, 96vw)" : "min(820px, 96vw)"}
                centered
                closable={false}
                maskClosable={false}
                styles={{
                    mask: { backdropFilter: 'blur(8px)', background: isDarkMode ? 'rgba(0,0,0,0.4)' : 'rgba(0,0,0,0.1)' },
                    content: { background: 'transparent', border: 'none', boxShadow: 'none' },
                    body: { padding: 0 }
                }}
                modalRender={(modal) => (
                    <div className={themeClass}>
                        <div className="vivid-calendar-modal">
                            {modal}
                        </div>
                    </div>
                )}
            >
                <div className={`cal-modal-row ${eventDetail ? 'cal-modal-row--split' : ''}`}>
                    <div className={`cal-container ${eventDetail ? 'cal-container--split-left' : ''}`}>
                        <div className="cal-nav">
                            <div>
                                <div className="cal-nav-heading">
                                    <span className="cal-month-name">{MONTH_NAMES[month]}</span>
                                    <span className="cal-year">{year}</span>
                                </div>
                                <p className="cal-help-line">
                                    Click an event to open details on the right — map, remove one day, or remove the whole trip.
                                    Double-click a date to add a note.
                                </p>
                            </div>
                            <div className="cal-nav-right">
                                {remoteLoading ? (
                                    <Spin size="small" style={{ marginRight: 8 }} aria-label="Loading calendar" />
                                ) : null}
                                {selectStart && (
                                    <Button size="small" className="cal-cancel-sel" onClick={resetSelection}>Cancel</Button>
                                )}
                                <Button size="small" className="cal-nav-btn" onClick={prev}><LeftOutlined /></Button>
                                <Button size="small" className="cal-today-btn" onClick={goToday}>Today</Button>
                                <Button size="small" className="cal-nav-btn" onClick={next}><RightOutlined /></Button>

                                <Button
                                    icon={<CloseOutlined style={{ fontSize: 14 }} />}
                                    type="text"
                                    style={{
                                        color: "var(--cal-text)", marginLeft: 8, padding: 0, width: 34, height: 34,
                                        borderRadius: "50%", background: "var(--cal-nav-bg)",
                                        display: "flex", alignItems: "center", justifyContent: "center"
                                    }}
                                    onClick={onClose}
                                />
                            </div>
                        </div>

                        {selectStart && !selectEnd && (
                            <div className="cal-range-hint">
                                Select end date (started from <strong>{selectStart} {MONTH_NAMES[month]}</strong>)
                            </div>
                        )}

                        <div className="cal-grid cal-header-row">
                            {DAYS.map(d => <div key={d} className="cal-header-cell">{d}</div>)}
                        </div>

                        <div className="cal-grid cal-body" ref={gridRef} style={{ position: 'relative' }}>
                            {cells.map((c, idx) => {
                                const evts = c.cur ? getEvts(c.day) : [];
                                const inRange = c.cur && isInRange(c.day);
                                const isRangeStart = c.cur && c.day === rangeMin();
                                const isRangeEnd = c.cur && c.day === rangeMax();

                                return (
                                    <div key={idx}
                                        className={`cal-cell ${c.cur ? '' : 'cal-cell-other'} ${isToday(c.day) && c.cur ? 'cal-cell-today' : ''} ${inRange ? 'cal-cell-selected' : ''} ${isRangeStart ? 'cal-range-start' : ''} ${isRangeEnd ? 'cal-range-end' : ''} ${selectStart && !selectEnd && c.cur ? 'cal-selecting' : ''}`}
                                        onClick={(e) => handleCellClick(c.day, c.cur, e)}
                                        onMouseEnter={() => { if (selectStart && !selectEnd && c.cur) setHoverDay(c.day); }}>
                                        <div className="cal-cell-top">
                                            <div className={`cal-day-number ${isToday(c.day) && c.cur ? 'cal-today-num' : ''}`}>
                                                {c.day}
                                            </div>
                                            {c.cur && !selectStart && <PlusOutlined className="cal-add-icon" />}
                                        </div>
                                        <div className="cal-events">
                                            {evts.map((ev) => {
                                                const routeMulti = !!(ev.routeId && ev.totalDays > 1);
                                                const displayTitle = ev.routeId ? getTripDestination(ev.title) : (ev.title || "").trim();
                                                const primaryText = (ev.title || "").trim();
                                                return (
                                                    <div
                                                        key={ev.key}
                                                        className={`cal-event-pill ${ev.routeId ? "cal-event-pill--route" : "cal-event-pill--local"}`}
                                                        style={
                                                            ev.routeId
                                                                ? { "--route-pill-bg": getRouteColor(ev.routeId) }
                                                                : { "--local-pill-bg": ev.color }
                                                        }
                                                    >
                                                        <button
                                                            type="button"
                                                            className="cal-event-pill-main cal-event-pill-main--full"
                                                            title={primaryText}
                                                            onClick={(e) => {
                                                                e.stopPropagation();
                                                                setEventDetail({ ev, dayOfMonth: c.day });
                                                            }}
                                                        >
                                                            <span className="cal-event-pill-line">
                                                                <span className="cal-event-pill-ellip">{displayTitle}</span>
                                                            </span>
                                                        </button>
                                                    </div>
                                                );
                                            })}
                                        </div>
                                    </div>
                                );
                            })}

                            {showForm && (
                                <div className="cal-popup" style={{ top: formPos.top, left: formPos.left }}
                                    onClick={e => e.stopPropagation()}>
                                    <div className="cal-popup-header">
                                        <span style={{ fontSize: 15, fontWeight: 800 }}>
                                            {rangeMin()} {rangeMin() !== rangeMax() ? `– ${rangeMax()} ` : ''}{MONTH_NAMES[month].slice(0, 3)}
                                        </span>
                                        <Button type="text" size="small" icon={<CloseOutlined />}
                                            onClick={resetSelection} style={{ color: 'var(--cal-text-muted)', opacity: 0.6 }} />
                                    </div>

                                    {getEvts(rangeMin()).length > 0 && (
                                        <div className="cal-popup-events">
                                            {getEvts(rangeMin()).map((ev) => {
                                                const localEv = ev.localIndex != null ? events[ev.localIndex] : null;
                                                return (
                                                    <div
                                                        key={ev.key}
                                                        className="cal-popup-event-row cal-popup-event-row--clickable"
                                                        role="button"
                                                        tabIndex={0}
                                                        onClick={(e) => {
                                                            e.stopPropagation();
                                                            setEventDetail({ ev, dayOfMonth: rangeMin() });
                                                        }}
                                                        onKeyDown={(e) => {
                                                            if (e.key === 'Enter' || e.key === ' ') {
                                                                e.preventDefault();
                                                                e.stopPropagation();
                                                                setEventDetail({ ev, dayOfMonth: rangeMin() });
                                                            }
                                                        }}
                                                    >
                                                        <span className="cal-popup-dot" style={{ background: ev.color }} />
                                                        <span className="cal-popup-event-text">
                                                            {ev.title}
                                                            {localEv?.endDay ? (
                                                                <span className="cal-popup-event-range">
                                                                    {' '}({localEv.day}–{localEv.endDay})
                                                                </span>
                                                            ) : null}
                                                        </span>
                                                    </div>
                                                );
                                            })}
                                        </div>
                                    )}

                                    <div className="cal-popup-form">
                                        <Input
                                            placeholder="What's happening?"
                                            value={newTitle}
                                            onChange={e => setNewTitle(e.target.value)}
                                            onPressEnter={addEvent}
                                            autoFocus
                                            className="cal-popup-input"
                                        />
                                        <div className="cal-popup-row">
                                            <Select size="small" value={newCat} onChange={setNewCat}
                                                className="cal-popup-select" popupMatchSelectWidth={false}
                                                getPopupContainer={trigger => trigger.parentNode}
                                                variant="borderless">
                                                {CATEGORIES.map(c => (
                                                    <Option key={c.key} value={c.key}>
                                                        <span className="cal-cat-dot" style={{ background: c.color }} /> {c.key}
                                                    </Option>
                                                ))}
                                            </Select>
                                            <Button type="primary" size="small" onClick={addEvent}
                                                className="cal-popup-add-btn" disabled={!newTitle.trim()}>
                                                Add
                                            </Button>
                                        </div>
                                    </div>
                                </div>
                            )}
                        </div>
                    </div>

                    {eventDetail ? (
                        (() => {
                            const { ev, dayOfMonth } = eventDetail;
                            const primaryText = (ev.shortTitle || ev.title || '').trim();
                            const routeMulti = !!(ev.routeId && ev.totalDays > 1);
                            const localEv = ev.localIndex != null ? events[ev.localIndex] : null;
                            const dateStr = `${MONTH_NAMES[month]} ${dayOfMonth}, ${year}`;
                            return (
                                <aside
                                    className={`cal-event-detail-aside ${ev.routeId ? 'cal-event-detail-aside--route' : 'cal-event-detail-aside--local'}`}
                                    style={ev.routeId ? undefined : { '--detail-accent': ev.color }}
                                    aria-label="Event details"
                                >
                                    <div className="cal-event-detail-inner">
                                        <div className="cal-event-detail-top">
                                            <button
                                                type="button"
                                                className="cal-event-detail-close"
                                                aria-label="Close"
                                                onClick={closeEventDetail}
                                            >
                                                <CloseOutlined />
                                            </button>
                                        </div>
                                        <p className="cal-event-detail-kicker">{dateStr}</p>
                                        {routeMulti ? (
                                            <p className="cal-event-detail-daytag">
                                                {ev.itineraryDay}/{ev.totalDays}
                                            </p>
                                        ) : null}
                                        <h2 className="cal-event-detail-title">{primaryText}</h2>

                                        {ev.routeId && (
                                            <div className="cal-event-detail-stats">
                                                <div className="cal-stat-item">
                                                    <span className="cal-stat-val">{ev.totalDays}</span>
                                                    <span className="cal-stat-label">Total Days</span>
                                                </div>
                                                <div className="cal-stat-item">
                                                    <span className="cal-stat-val">{ev.itineraryDay}</span>
                                                    <span className="cal-stat-label">Current Day</span>
                                                </div>
                                            </div>
                                        )}

                                        <div className="cal-event-detail-actions">
                                            {ev.routeId && onOpenRouteFromCalendar ? (
                                                <button
                                                    type="button"
                                                    className="cal-event-detail-btn cal-event-detail-btn--primary"
                                                    onClick={() => onOpenRouteFromCalendar(ev.routeId)}
                                                >
                                                    Open on map
                                                </button>
                                            ) : null}

                                            {ev.eventId ? (
                                                <button
                                                    type="button"
                                                    className="cal-event-detail-btn cal-event-detail-btn--danger"
                                                    onClick={() => removeRemoteEvent(ev.eventId)}
                                                >
                                                    Remove this day
                                                </button>
                                            ) : null}

                                            {ev.routeId && routeMulti ? (
                                                <button
                                                    type="button"
                                                    className="cal-event-detail-btn cal-event-detail-btn--muted"
                                                    onClick={() => removeRemoteRouteAll(ev.routeId)}
                                                >
                                                    Remove all {ev.totalDays} days
                                                </button>
                                            ) : null}

                                            {ev.localIndex != null ? (
                                                <button
                                                    type="button"
                                                    className="cal-event-detail-btn cal-event-detail-btn--danger"
                                                    onClick={() => removeEvent(ev.localIndex)}
                                                >
                                                    {localEv?.endDay ? 'Remove note from calendar' : 'Remove note'}
                                                </button>
                                            ) : null}
                                        </div>
                                    </div>
                                </aside>
                            );
                        })()
                    ) : null}
                </div>
            </Modal>
        </ConfigProvider>
    );
}

