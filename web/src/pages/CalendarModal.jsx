import React, { useState, useRef } from 'react';
import { Modal, Typography, Button, Input, Select, ConfigProvider } from 'antd';
import { CloseOutlined, LeftOutlined, RightOutlined, PlusOutlined, DeleteOutlined } from '@ant-design/icons';
import './CalendarModal.css';

const { Title, Text } = Typography;
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

function getDaysInMonth(y, m) { return new Date(y, m + 1, 0).getDate(); }
function getFirstDay(y, m) { const d = new Date(y, m, 1).getDay(); return d === 0 ? 6 : d - 1; }

export default function CalendarModal({ open, onClose, isDarkMode = true, themeClass = "theme-night" }) {
    const today = new Date();
    const [month, setMonth] = useState(today.getMonth());
    const [year, setYear] = useState(today.getFullYear());
    const [events, setEvents] = useState([]);

    // Selection state: click first day, then click second day for range
    const [selectStart, setSelectStart] = useState(null);
    const [selectEnd, setSelectEnd] = useState(null);
    const [hoverDay, setHoverDay] = useState(null);

    // Popup form
    const [showForm, setShowForm] = useState(false);
    const [formPos, setFormPos] = useState({ top: 0, left: 0 });
    const [newTitle, setNewTitle] = useState('');
    const [newCat, setNewCat] = useState('Activity');
    const gridRef = useRef(null);

    const prev = () => { if (month === 0) { setMonth(11); setYear(y => y - 1); } else setMonth(m => m - 1); };
    const next = () => { if (month === 11) { setMonth(0); setYear(y => y + 1); } else setMonth(m => m + 1); };
    const goToday = () => { setMonth(today.getMonth()); setYear(today.getFullYear()); };
    const isToday = (d) => d === today.getDate() && month === today.getMonth() && year === today.getFullYear();
    const catInfo = (key) => CATEGORIES.find(c => c.key === key) || CATEGORIES[2];

    const getEvts = (d) => events.filter(e => {
        const end = e.endDay || e.day;
        return d >= e.day && d <= end && e.month === month && e.year === year;
    });

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
                width={820}
                centered
                closable={false}
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
                <div className="cal-container">
                    <div className="cal-nav">
                        <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
                            <span className="cal-month-name">{MONTH_NAMES[month]}</span>
                            <span className="cal-year">{year}</span>
                        </div>
                        <div className="cal-nav-right">
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
                                        {evts.map((ev, i) => (
                                            <div key={i} className="cal-event-chip" style={{ background: ev.color }}>
                                                {ev.title}
                                            </div>
                                        ))}
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
                                        {events.map((ev, i) => (
                                            ev.day === rangeMin() && ev.month === month && ev.year === year ? (
                                                <div key={i} className="cal-popup-event-row">
                                                    <span className="cal-popup-dot" style={{ background: ev.color }} />
                                                    <span style={{ flex: 1, fontSize: 13, fontWeight: 700 }}>
                                                        {ev.title}
                                                        {ev.endDay && <span style={{ color: 'var(--cal-text-muted)', fontSize: 11, fontWeight: 600 }}> ({ev.day}–{ev.endDay})</span>}
                                                    </span>
                                                    <DeleteOutlined className="cal-delete-icon" onClick={() => removeEvent(i)} />
                                                </div>
                                            ) : null
                                        ))}
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
            </Modal>
        </ConfigProvider>
    );
}

