import React, { useReducer, useEffect, useRef, useState, useMemo } from 'react';
import { MdClose, MdTune, MdHotel, MdFlightTakeoff, MdArrowForward, MdStar, MdCheck, MdRefresh, MdLocationCity, MdLocalAirport, MdChevronLeft } from 'react-icons/md';
import { bookingReducer, initialState } from '../bookingReducer';
import { searchHotels, searchFlights, searchAirports } from '../../../api/bookingApi';
import '../styles/bookingSheet.css';

const formatFriendlyDate = (dateStr) => {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return `${months[d.getMonth()]} ${String(d.getDate()).padStart(2, '0')}, ${days[d.getDay()]}`;
};

const formatTime = (timeStr) => {
  if (!timeStr) return '--:--';
  const timePart = timeStr.includes(' ') ? timeStr.split(' ')[1] : (timeStr.includes('T') ? timeStr.split('T')[1].substring(0, 5) : timeStr);
  const parts = timePart.split(':');
  if (parts.length < 2) return timePart;
  return `${parts[0].padStart(2, '0')}:${parts[1].padStart(2, '0')}`;
};

const formatDateShort = (dateStr) => {
  if (!dateStr) return '';
  const d = new Date(dateStr);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return `${days[d.getDay()]}, ${months[d.getMonth()]} ${d.getDate()}`;
};

export default function BookingSheet({ open, onClose }) {
  const [state, dispatch] = useReducer(bookingReducer, initialState);
  const [airportResults, setAirportResults] = useState([]);
  const [activeSearchField, setActiveSearchField] = useState(null);
  const [searchQuery, setSearchQuery] = useState("");
  const [originLabel, setOriginLabel] = useState("");
  const [destLabel, setDestLabel] = useState("");

  const scrollRef = useRef(null);
  const originRef = useRef(null);
  const destRef = useRef(null);

  useEffect(() => {
    if (!open) {
      dispatch({ type: "RESET_STATE" });
      setOriginLabel("");
      setDestLabel("");
    }
  }, [open]);

  useEffect(() => {
    const fetchAirports = async () => {
      if (searchQuery.length < 2 || !activeSearchField) {
        setAirportResults([]);
        return;
      }
      try {
        const data = await searchAirports(searchQuery);
        setAirportResults(data || []);
      } catch (err) {
        setAirportResults([]);
      }
    };
    const timer = setTimeout(fetchAirports, 300);
    return () => clearTimeout(timer);
  }, [searchQuery, activeSearchField]);

  const handleSearch = async () => {
    const newErrors = {};
    if (!state.searchParams.destination) newErrors.destination = "Required";
    if (!state.searchParams.dates) newErrors.dates = "Required";
    if (state.bookingType === 'flights') {
      if (!state.searchParams.origin) newErrors.origin = "Required";

      const iataRegex = /^([a-zA-Z]{3}|\/m\/.+)$/;
      if (state.searchParams.origin && !iataRegex.test(state.searchParams.origin)) {
        newErrors.origin = "Select an airport from the list!";
      }
      if (state.searchParams.destination && !iataRegex.test(state.searchParams.destination)) {
        newErrors.destination = "Select an airport from the list!";
      }
    }

    if (Object.keys(newErrors).length > 0) {
      dispatch({ type: "SET_ERRORS", payload: newErrors });
      return;
    }

    dispatch({ type: "SEARCH_START" });
    try {
      let response;
      if (state.bookingType === 'hotels') {
        response = await searchHotels({
          query: state.searchParams.destination,
          checkInDate: state.searchParams.dates,
          checkOutDate: state.searchParams.checkOutDate || state.searchParams.dates,
          adults: state.searchParams.adults,
          budget: state.searchParams.budget ? parseFloat(state.searchParams.budget) : null
        });
      } else {
        response = await searchFlights({
          origin: state.searchParams.origin,
          destination: state.searchParams.destination,
          departureDate: state.searchParams.dates,
          returnDate: state.searchParams.isRoundTrip ? state.searchParams.checkOutDate : null,
          adults: state.searchParams.adults,
          budget: state.searchParams.budget ? parseFloat(state.searchParams.budget) : null
        });
      }
      if (response.success) {
        dispatch({ type: "SEARCH_SUCCESS", payload: response.data || [] });
      } else {
        dispatch({ type: "SEARCH_ERROR" });
      }
      if (scrollRef.current) scrollRef.current.scrollTop = 0;
    } catch (err) {
      dispatch({ type: "SEARCH_ERROR" });
    }
  };

  const filteredAndSortedItems = useMemo(() => {
    let list = [...state.items];
    const budget = parseFloat(state.searchParams.budget);
    if (!isNaN(budget)) {
      list = list.filter(item => {
        const price = item.pricePerNight || item.price;
        return price <= budget;
      });
    }

    list.sort((a, b) => {
      const priceA = a.pricePerNight || a.price;
      const priceB = b.pricePerNight || b.price;
      if (state.sortBy === 'low') return priceA - priceB;
      if (state.sortBy === 'high') return priceB - priceA;
      if (state.sortBy === 'rating') return (b.rating || 0) - (a.rating || 0);
      return 0;
    });
    return list;
  }, [state.items, state.searchParams.budget, state.sortBy]);

  const renderError = (field) => state.errors[field] && <span className="field-error-msg">{state.errors[field]}</span>;

  if (!open) return null;

  return (
    <div className="custom-backdrop" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="custom-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="drag-handle-line" />
        <button className="close-circle-btn-top" onClick={() => { if (state.view === 'filters') dispatch({ type: "CLOSE_FILTERS" }); else onClose(); }}><MdClose /></button>

        <div className="sheet-scrollable-content" ref={scrollRef}>
          {state.view === 'search' && (
            <div className="search-form-container">
              <div className="tab-pill-container-mock" style={{ width: '100%', justifyContent: 'center' }}>
                <button style={{ flex: 1 }} className={state.bookingType === 'hotels' ? 'pill-active-mock' : ''} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'hotels' } })}>
                  <MdHotel size={16} color={state.bookingType === 'hotels' ? '#fff' : '#999'} /> Hotels
                </button>
                <button style={{ flex: 1 }} className={state.bookingType === 'flights' ? 'pill-active-mock' : ''} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'flights' } })}>
                  <MdFlightTakeoff size={16} color={state.bookingType === 'flights' ? '#fff' : '#999'} /> Flights
                </button>
              </div>

              <div className="inputs-grid-refined">
                {state.bookingType === 'flights' && (
                  <div className="input-group-modern" ref={originRef}>
                    <label>ORIGIN</label>
                    <input
                      type="text" placeholder="Airport code (e.g. IST, ESB)"
                      value={activeSearchField === 'origin' ? searchQuery : (originLabel || state.searchParams.origin)}
                      onFocus={() => { if (activeSearchField !== 'origin') { setActiveSearchField('origin'); setSearchQuery(originLabel || state.searchParams.origin || ""); } }}
                      onChange={(e) => {
                        setActiveSearchField('origin');
                        setSearchQuery(e.target.value);
                        dispatch({ type: "UPDATE_PARAM", payload: { origin: e.target.value } });
                        if (originLabel) setOriginLabel("");
                      }}
                    />
                    {activeSearchField === 'origin' && airportResults.length > 0 && (
                      <div className="airport-dropdown-refined">
                        {airportResults.map((item, i) => (
                          <div key={i} className="airport-item" onClick={() => {
                            dispatch({ type: "UPDATE_PARAM", payload: { origin: item.iataCode } });
                            setOriginLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`);
                            setAirportResults([]); setActiveSearchField(null);
                          }}>
                            <div className="airport-item-row">
                              <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                              <div className="airport-item-info"><span className="aname">{item.name}</span><span className="city">{item.city}, {item.country}</span></div>
                              {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                    {renderError('origin')}
                  </div>
                )}

                <div className="input-group-modern" ref={destRef}>
                  <label>{state.bookingType === 'hotels' ? 'SEARCH LOCATION OR HOTEL' : 'DESTINATION'}</label>
                  <input
                    type="text" placeholder={state.bookingType === 'hotels' ? "Where are you going? (City or hotel)" : "Airport code (e.g. SAW, CDG)"}
                    value={state.bookingType === 'hotels' ? state.searchParams.destination : (activeSearchField === 'destination' ? searchQuery : (destLabel || state.searchParams.destination))}
                    onFocus={() => { if (state.bookingType === 'flights' && activeSearchField !== 'destination') { setActiveSearchField('destination'); setSearchQuery(destLabel || state.searchParams.destination || ""); } }}
                    onChange={(e) => {
                      if (state.bookingType === 'hotels') {
                        dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value } });
                      } else {
                        setActiveSearchField('destination');
                        setSearchQuery(e.target.value);
                        dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value } });
                        if (destLabel) setDestLabel("");
                      }
                    }}
                  />
                  {state.bookingType === 'flights' && activeSearchField === 'destination' && airportResults.length > 0 && (
                    <div className="airport-dropdown-refined">
                      {airportResults.map((item, i) => (
                        <div key={i} className="airport-item" onClick={() => {
                          dispatch({ type: "UPDATE_PARAM", payload: { destination: item.iataCode } });
                          setDestLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`);
                          setAirportResults([]); setActiveSearchField(null);
                        }}>
                          <div className="airport-item-row">
                            <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                            <div className="airport-item-info"><span className="aname">{item.name}</span><span className="city">{item.city}, {item.country}</span></div>
                            {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                  {renderError('destination')}
                </div>

                {state.bookingType === 'flights' && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <label className="toggle-switch">
                      <input type="checkbox" checked={state.searchParams.isRoundTrip} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { isRoundTrip: e.target.checked } })} />
                      <span className="toggle-slider" />
                    </label>
                    <span style={{ fontSize: 13, fontWeight: 600, color: '#1a1a1a' }}>Round trip flight</span>
                  </div>
                )}

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label>{state.bookingType === 'hotels' ? 'CHECK-IN' : 'DATE'}</label>
                    <input type="date" min={new Date().toISOString().split('T')[0]} value={state.searchParams.dates} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { dates: e.target.value } })} />
                    {renderError('dates')}
                  </div>
                  {state.bookingType === 'hotels' || state.searchParams.isRoundTrip ? (
                    <div className="input-group-modern half">
                      <label>{state.bookingType === 'hotels' ? 'CHECK-OUT' : 'RETURN'}</label>
                      <input type="date" min={state.searchParams.dates || new Date().toISOString().split('T')[0]} value={state.searchParams.checkOutDate} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { checkOutDate: e.target.value } })} />
                    </div>
                  ) : <div className="half" />}
                </div>

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label>ADULTS</label>
                    <div className="counter-box">
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: Math.max(1, state.searchParams.adults - 1) } })}>−</button>
                      <span>{state.searchParams.adults}</span>
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: state.searchParams.adults + 1 } })}>+</button>
                    </div>
                  </div>
                  <div className="input-group-modern half">
                    <label>BUDGET (OPTIONAL)</label>
                    <input
                      type="number" min="0" placeholder="Max $"
                      value={state.searchParams.budget}
                      onChange={(e) => {
                        const val = e.target.value;
                        if (val === "" || parseFloat(val) >= 0) {
                          dispatch({ type: "UPDATE_PARAM", payload: { budget: val.replace('-', '') } });
                        }
                      }}
                    />
                  </div>
                </div>

                <div className="input-group-modern">
                  <label>SORT BY</label>
                  <select
                    className="custom-select-refined"
                    value={state.sortBy}
                    onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: e.target.value } })}
                  >
                    <option value="low">Price: Low to High</option>
                    <option value="high">Price: High to Low</option>
                  </select>
                </div>
              </div>

              <button className="main-search-btn" onClick={handleSearch} disabled={state.loading}>
                {state.loading ? "Searching..." : `Search ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'}`}
              </button>
            </div>
          )}

          {state.view === 'results' && (
            <div className="results-list-refined">
              <div className="results-header-premium">
                <button className="back-btn-circle" onClick={() => dispatch({ type: "RETRY" })}><MdChevronLeft /></button>
                <div className="results-title-stack">
                  <h3 className="results-count-text">
                    {filteredAndSortedItems.length} {state.bookingType === 'hotels' ? 'Hotels' : 'Flights'} Found
                  </h3>
                  <span className="results-summary-sub">
                    {state.bookingType === 'hotels'
                      ? `${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)}${state.searchParams.checkOutDate ? ` – ${formatFriendlyDate(state.searchParams.checkOutDate)}` : ''} · ${state.searchParams.adults} adult${state.searchParams.adults > 1 ? 's' : ''}`
                      : `${state.searchParams.origin}→${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)} · ${state.searchParams.adults} adult${state.searchParams.adults > 1 ? 's' : ''}`}
                  </span>
                </div>
                <button className="filter-btn-circle" onClick={() => dispatch({ type: "OPEN_FILTERS" })}><MdTune /></button>
              </div>

              {filteredAndSortedItems.map((item, idx) => {
                if (state.bookingType === 'hotels') {
                  return (
                    <div key={idx} className="mobile-card hotel">
                      <div className="hotel-thumb-box" style={{ flexDirection: 'column', gap: 4 }}>
                        <HotelImage src={item.imageUrl || item.thumbnailUrl} />
                      </div>
                      <div className="hotel-details-col">
                        <div className="hotel-name-row">
                          <h4 className="hotel-name-text">{item.hotelName}</h4>
                          <span className="price-text-blue">${item.pricePerNight || item.price}</span>
                        </div>
                        <div className="rating-row-mobile" style={{ marginTop: 2, display: 'flex', alignItems: 'center', gap: 6 }}>
                          {item.rating && <span className="star-rating"><MdStar color="#FFD166" size={16} /> {item.rating}</span>}
                          {item.totalReviews && <span className="review-count-sub">({item.totalReviews} reviews)</span>}
                        </div>
                        {item.providerName && <span className="hotel-provider-text">{item.providerName}</span>}
                        <div className="hotel-book-btn-row">
                          <button className="hotel-book-btn-mobile" onClick={() => window.open(item.externalBookingUrl, '_blank')}>Open booking</button>
                        </div>
                      </div>
                    </div>
                  );
                }
                return (
                  <div key={idx} className="mobile-card flight">
                    <div className="card-top-row">
                      <div className="airline-logo-circle">
                        {item.airlineLogo ? <img src={item.airlineLogo} alt="" /> : <span className="fallback-text">{item.carrier?.substring(0, 2)}</span>}
                      </div>
                      <div className="card-main-info">
                        <span className="flight-date-subtext">{formatDateShort(item.departureTime)}</span>
                        <span className="time-range-text">{formatTime(item.departureTime)} – {formatTime(item.arrivalTime)}</span>
                        <span className="carrier-subtext">{[item.carrier, item.flightNumber].filter(Boolean).join(' · ')}</span>
                      </div>
                      <div className="card-right-price">
                        <span className="price-text-blue">${item.price}</span>
                        {item.travelClass && <span className="class-tag">{item.travelClass}</span>}
                      </div>
                    </div>
                    <div className="route-section">
                      <div className="route-labels-row">
                        <span>{item.origin}</span>
                        <span>{item.duration || 'Auto'}</span>
                        <span>{item.destination}</span>
                      </div>
                      <div className="path-line-stack">
                        <div className="gray-line" />
                        {item.stops > 0 && <div className="stop-dot" />}
                      </div>
                    </div>
                    <div className="stops-badge-row">
                      <div className={`stops-badge ${item.stops === 0 ? 'direct' : 'stops'}`}>
                        {item.stops === 0 ? 'Direct' : `${item.stops} stop${item.stops > 1 ? 's' : ''}`}
                      </div>
                    </div>
                    <div style={{ marginTop: 14 }}>
                      <button className="launch-btn-mobile" onClick={() => window.open(item.externalBookingUrl, '_blank')}>
                        Open in Google Flights <MdArrowForward size={14} style={{ marginLeft: 6 }} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {state.view === 'filters' && (
            <div className="filters-view-premium">
              <div className="filters-header-mobile" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
                <div className="filters-title-stack">
                  <h3 className="results-count-text" style={{ fontSize: 18, marginBottom: 4 }}>Filters</h3>
                  <span className="results-summary-sub" style={{ color: '#888' }}>
                    {state.bookingType === 'hotels'
                      ? `${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)}`
                      : `${state.searchParams.origin}→${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)}`}
                  </span>
                </div>
              </div>
              <div className="filters-content">
                <div className="filter-item">
                  <label className="filter-section-label">{state.bookingType === 'hotels' ? 'Budget per night' : 'Budget'}</label>
                  <div className="budget-input-wrapper">
                    <span className="prefix">$</span>
                    <input
                      type="number"
                      min={0}
                      placeholder="No limit"
                      value={state.searchParams.budget}
                      onChange={(e) => {
                        const val = e.target.value;
                        if (val === "" || parseFloat(val) >= 0) {
                          dispatch({ type: "UPDATE_PARAM", payload: { budget: val.replace('-', '') } });
                        }
                      }}
                    />
                    <span className="suffix">USD</span>
                  </div>
                </div>
                <div className="filter-item">
                  <label className="filter-section-label">Sort by</label>
                  <div className="sort-chips-wrap">
                    <button className={`sort-chip ${state.sortBy === 'low' ? 'active' : ''}`} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: 'low' } })}>Price ↑</button>
                    <button className={`sort-chip ${state.sortBy === 'high' ? 'active' : ''}`} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: 'high' } })}>Price ↓</button>
                  </div>
                </div>
              </div>
              <div className="filter-footer-mobile">
                <button className="apply-btn-blue" onClick={() => { handleSearch(); dispatch({ type: "CLOSE_FILTERS" }); }}>
                  <MdCheck size={18} /> Apply Filters
                </button>
                <button className="reset-btn-gray" onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { budget: '', sortBy: 'low' } })}>
                  <MdRefresh size={16} /> Reset Filters
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function HotelImage({ src }) {
  const [status, setStatus] = useState('loading'); // 'loading' | 'ok' | 'fail'
  const imgRef = useRef(null);

  useEffect(() => {
    if (!src) {
      setStatus('fail');
      return;
    }
    const img = new Image();
    img.onload = () => {
      // If the image is smaller than 100px in either dimension, it's likely a favicon/placeholder
      if (img.naturalWidth < 100 || img.naturalHeight < 100) {
        setStatus('fail');
      } else {
        setStatus('ok');
      }
    };
    img.onerror = () => setStatus('fail');
    img.src = src;
  }, [src]);

  if (status === 'fail') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', width: '100%', background: '#F5F5F7', borderRadius: '16px' }}>
        <span style={{ fontSize: '10px', color: '#AAAAAA', textAlign: 'center', fontWeight: '600', letterSpacing: '0.3px' }}>No Photo Available</span>
      </div>
    );
  }

  if (status === 'loading') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%', width: '100%', background: '#F5F5F7', borderRadius: '16px' }}>
        <span style={{ fontSize: '9px', color: '#CCC' }}>...</span>
      </div>
    );
  }

  return <img ref={imgRef} src={src} alt="" />;
}