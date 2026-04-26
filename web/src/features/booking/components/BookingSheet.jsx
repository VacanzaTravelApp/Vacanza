import React, { useReducer, useEffect, useRef, useState, useMemo } from 'react';
import { MdClose, MdTune, MdHotel, MdFlightTakeoff, MdArrowForward, MdStar, MdCheck, MdRefresh, MdLocationCity, MdLocalAirport, MdChevronLeft, MdLocationOn, MdSearch } from 'react-icons/md';
import { bookingReducer, initialState } from '../bookingReducer';
import { searchHotels, searchFlights, searchAirports, searchDestinations } from '../../../api/bookingApi';
import '../styles/bookingSheet.css';

const formatFriendlyDate = (dateStr) => {
  if (!dateStr) return '';
  // Force T00:00:00 to avoid timezone shifts
  const d = new Date(dateStr + (dateStr.includes('T') ? '' : 'T00:00:00'));
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

  const [isSearching, setIsSearching] = useState(false);
  const isTypingRef = useRef(false);


  useEffect(() => {
    if (!open) {
      dispatch({ type: "RESET_STATE" });
      setAirportResults([]);
      setActiveSearchField(null);
      setSearchQuery("");
      setOriginLabel("");
      setDestLabel("");
      setIsSearching(false);
    }
  }, [open]);

  // Clear local text state when switching between flights/hotels
  useEffect(() => {
    setOriginLabel("");
    setDestLabel("");
    setSearchQuery("");
    setAirportResults([]);
    setActiveSearchField(null);
  }, [state.bookingType]);

  useEffect(() => {
    const delayDebounce = setTimeout(async () => {
      const q = searchQuery.trim();
      const shouldSearch = q.length >= 2 &&
        (activeSearchField === 'origin' || activeSearchField === 'destination') &&
        isTypingRef.current &&
        state.bookingType !== 'hotels';

      if (shouldSearch) {
        setIsSearching(true);
        let results = [];
        try {
          const airportReq = searchAirports(q);
          if (state.bookingType === 'hotels') {
            const [airports, dests] = await Promise.all([
              airportReq,
              searchDestinations(q)
            ]);
            results = [...(dests || []), ...(airports || [])];
          } else {
            results = await airportReq;
          }
        } finally {
          setAirportResults(results || []);
          setIsSearching(false);
          isTypingRef.current = false;
        }
      } else {
        setAirportResults([]);
        setIsSearching(false);
      }
    }, 600);
    return () => clearTimeout(delayDebounce);
  }, [searchQuery, activeSearchField, state.bookingType]);

  useEffect(() => {
    function handleClickOutside(event) {
      if (activeSearchField === 'origin' && originRef.current && !originRef.current.contains(event.target)) {
        setActiveSearchField(null);
      }
      if (activeSearchField === 'destination' && destRef.current && !destRef.current.contains(event.target)) {
        setActiveSearchField(null);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [activeSearchField]);

  const handleSearch = async () => {
    const newErrors = {};
    if (!state.searchParams.destination) newErrors.destination = "Required";
    if (!state.searchParams.dates) newErrors.dates = "Required";
    if (state.bookingType === 'flights') {
      if (!state.searchParams.origin) newErrors.origin = "Required";
      if (!state.searchParams.destination) newErrors.destination = "Required";
      if (state.searchParams.isRoundTrip && !state.searchParams.checkOutDate) {
        newErrors.checkOutDate = "Required";
      }
    }

    if (Object.keys(newErrors).length > 0) {
      dispatch({ type: "SET_ERRORS", payload: newErrors });
      return;
    }

    dispatch({ type: "SEARCH_START" });
    setActiveSearchField(null);
    try {
      let response;
      if (state.bookingType === 'hotels') {
        response = await searchHotels({
          query: state.searchParams.destination,
          checkInDate: state.searchParams.dates,
          checkOutDate: state.searchParams.checkOutDate,
          adults: state.searchParams.adults,
          budget: state.searchParams.budget ? parseFloat(state.searchParams.budget) : null,
          sortBy: state.sortBy === 'low' ? 'PRICE_ASC' : 'PRICE_DESC'
        });
      } else {
        response = await searchFlights({
          origin: state.searchParams.origin ? state.searchParams.origin.toUpperCase() : "",
          destination: state.searchParams.destination ? state.searchParams.destination.toUpperCase() : "",
          departureDate: state.searchParams.dates,
          returnDate: state.searchParams.isRoundTrip ? state.searchParams.checkOutDate : null,
          adults: state.searchParams.adults,
          budget: state.searchParams.budget ? parseFloat(state.searchParams.budget) : null,
          sortBy: state.sortBy === 'low' ? 'PRICE_ASC' : 'PRICE_DESC'
        });
      }
      if (response.success) {
        dispatch({ type: "SEARCH_SUCCESS", payload: response.data || [] });
      } else {
        dispatch({ type: "SEARCH_ERROR", payload: response.error });
      }
      if (scrollRef.current) scrollRef.current.scrollTop = 0;
    } catch (err) {
      dispatch({ type: "SEARCH_ERROR", payload: { message: "An unexpected error occurred. Please try again." } });
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
    <div className="custom-backdrop">
      <div className="custom-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-header-unified">
          <div className="header-left-area">
            {(state.view === 'results' || state.view === 'filters') && (
              <button className="sheet-header-btn" onClick={() => { if (state.view === 'filters') dispatch({ type: "CLOSE_FILTERS" }); else dispatch({ type: "RETRY" }); }}>
                <MdChevronLeft />
              </button>
            )}
          </div>
          <div className="header-center-area">
            {state.view === 'search' ? (
              <div className="tab-pill-container-mock">
                <button className={state.bookingType === 'hotels' ? 'pill-active-mock' : ''} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'hotels' } })}>
                  <MdHotel size={16} /> Hotels
                </button>
                <button className={state.bookingType === 'flights' ? 'pill-active-mock' : ''} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'flights' } })}>
                  <MdFlightTakeoff size={16} /> Flights
                </button>
              </div>
            ) : (
              <div className="sheet-header-title-stack">
                <h3>{state.view === 'filters' ? 'Filters' : `${filteredAndSortedItems.length} ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'} Found`}</h3>
                <span>
                  {state.bookingType === 'hotels'
                    ? `${state.searchParams.destination}`
                    : `${state.searchParams.origin}→${state.searchParams.destination}`}
                </span>
              </div>
            )}
          </div>
          <div className="header-right-area">
            {state.view === 'results' && (
              <button className="sheet-header-btn" onClick={() => dispatch({ type: "OPEN_FILTERS" })}>
                <MdTune />
              </button>
            )}
            <button className="sheet-header-btn" onClick={onClose}>
              <MdClose />
            </button>
          </div>
        </div>

        <div className="sheet-main-layout">
          {state.view === 'search' && (
            <div className="search-form-container">
              <div className="sheet-scroll-area">
                <div className="inputs-grid-refined">
                {state.bookingType === 'flights' && (
                  <div className="input-group-modern" ref={originRef}>
                    <label className="input-label-mobile">ORIGIN</label>
                    <div className="input-with-icon-mobile">
                      <MdFlightTakeoff className="input-icon-prefix" />
                      <input
                        type="text"
                        value={activeSearchField === 'origin' ? searchQuery : (originLabel || state.searchParams.origin)}
                        onFocus={() => { setActiveSearchField('origin'); isTypingRef.current = false; setSearchQuery(originLabel || state.searchParams.origin || ""); }}
                        onChange={(e) => { setActiveSearchField('origin'); isTypingRef.current = true; setSearchQuery(e.target.value); dispatch({ type: "UPDATE_PARAM", payload: { origin: e.target.value } }); if (originLabel) setOriginLabel(""); }}
                        onKeyDown={(e) => { if (e.key === 'Enter') handleSearch(); }}
                      />
                    </div>
                    {activeSearchField === 'origin' && (searchQuery.length > 0 || isSearching) && (
                      <div className="airport-dropdown-refined">
                        {isSearching ? <div className="dropdown-status-msg">Searching...</div> : airportResults.length > 0 ? airportResults.map((item, i) => (
                          <div key={i} className="airport-item" onClick={() => { const searchId = item.iataCode ?? item.kgmid; dispatch({ type: "UPDATE_PARAM", payload: { origin: searchId } }); setOriginLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`); setAirportResults([]); setActiveSearchField(null); }}>
                            <div className="airport-item-row">
                              <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                              <div className="airport-item-info"><span className="aname">{item.name}</span><span className="city">{item.city}, {item.country}</span></div>
                              {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                            </div>
                          </div>
                        )) : <div className="dropdown-status-msg">No suggestions found</div>}
                      </div>
                    )}
                    {renderError('origin')}
                  </div>
                )}

                <div className="input-group-modern" ref={destRef}>
                  <label className="input-label-mobile">{state.bookingType === 'hotels' ? 'SEARCH LOCATION OR HOTEL' : 'DESTINATION'}</label>
                  <div className="input-with-icon-mobile">
                    {state.bookingType === 'hotels' ? <MdHotel className="input-icon-prefix" /> : <MdLocationOn className="input-icon-prefix" />}
                    <input
                      type="text" placeholder={state.bookingType === 'hotels' ? "City or hotel" : ""}
                      value={activeSearchField === 'destination' ? searchQuery : (destLabel || state.searchParams.destination)}
                      onFocus={() => { setActiveSearchField('destination'); isTypingRef.current = false; setSearchQuery(destLabel || state.searchParams.destination || ""); }}
                      onChange={(e) => { setActiveSearchField('destination'); isTypingRef.current = true; setSearchQuery(e.target.value); dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value } }); if (destLabel) setDestLabel(""); }}
                      onKeyDown={(e) => { if (e.key === 'Enter') handleSearch(); }}
                      autoComplete="off"
                    />
                  </div>
                  {activeSearchField === 'destination' && state.bookingType !== 'hotels' && (searchQuery.length > 0 || isSearching) && (
                    <div className="airport-dropdown-refined">
                      {isSearching ? <div className="dropdown-status-msg">Searching...</div> : airportResults.length > 0 ? airportResults.map((item, i) => (
                        <div key={i} className="airport-item" onClick={() => { const searchId = item.iataCode ?? item.kgmid; dispatch({ type: "UPDATE_PARAM", payload: { destination: searchId } }); setDestLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`); setAirportResults([]); setActiveSearchField(null); }}>
                          <div className="airport-item-row">
                            <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                            <div className="airport-item-info"><span className="aname">{item.name}</span><span className="city">{item.city}, {item.country}</span></div>
                            {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                          </div>
                        </div>
                      )) : <div className="dropdown-status-msg">No suggestions found</div>}
                    </div>
                  )}
                  {renderError('destination')}
                </div>

                {state.bookingType === 'flights' && (
                  <div className="round-trip-toggle-mobile" onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { isRoundTrip: !state.searchParams.isRoundTrip } })}>
                    <div className={`checkbox-custom-mobile ${state.searchParams.isRoundTrip ? 'checked' : ''}`}>{state.searchParams.isRoundTrip && <MdCheck size={14} color="#fff" />}</div>
                    <span>Round trip</span>
                  </div>
                )}

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label className="input-label-mobile">{state.bookingType === 'hotels' ? 'CHECK-IN' : 'DATE'}</label>
                    <input type="date" className={state.searchParams.dates ? 'date-filled' : 'date-empty'} onFocus={() => setActiveSearchField(null)} min={new Date().toISOString().split('T')[0]} value={state.searchParams.dates} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { dates: e.target.value } })} />
                    {renderError('dates')}
                  </div>
                  {(state.bookingType === 'hotels' || state.searchParams.isRoundTrip) && (
                    <div className="input-group-modern half">
                      <label className="input-label-mobile">{state.bookingType === 'hotels' ? 'CHECK-OUT' : 'RETURN'}</label>
                      <input type="date" className={state.searchParams.checkOutDate ? 'date-filled' : 'date-empty'} onFocus={() => setActiveSearchField(null)} min={state.searchParams.dates || new Date().toISOString().split('T')[0]} value={state.searchParams.checkOutDate} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { checkOutDate: e.target.value } })} />
                    </div>
                  )}
                </div>

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label className="input-label-mobile">ADULTS</label>
                    <div className="counter-box">
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: Math.max(1, state.searchParams.adults - 1) } })}>−</button>
                      <span>{state.searchParams.adults}</span>
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: state.searchParams.adults + 1 } })}>+</button>
                    </div>
                  </div>
                  <div className="input-group-modern half">
                    <label className="input-label-mobile">BUDGET (MAX)</label>
                    <input type="number" min="0" placeholder="$" onFocus={() => setActiveSearchField(null)} value={state.searchParams.budget} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { budget: e.target.value.replace('-', '') } })} />
                  </div>
                </div>

                <div className="input-group-modern">
                  <label className="input-label-mobile">SORT BY</label>
                  <select className="custom-select-refined" onFocus={() => setActiveSearchField(null)} value={state.sortBy} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: e.target.value } })}>
                    <option value="low">Price: Low to High</option>
                    <option value="high">Price: High to Low</option>
                  </select>
                </div>
              </div>
            </div>
            <div className="search-footer-modern">
                {state.status === 'error' && <div className="form-error-banner">{state.error?.message || "Search failed."}</div>}
                <button className="search-submit-btn-premium" onClick={handleSearch} disabled={state.loading}>{state.loading ? 'Searching...' : (state.bookingType === 'hotels' ? 'Search Hotels' : 'Search Flights')}</button>
              </div>
            </div>
          )}

          {state.view === 'results' && (
            <div className="results-list-refined">
              <div className="sheet-scroll-area" ref={scrollRef}>
                {filteredAndSortedItems.map((item, idx) => (
                  <div key={idx} className={`mobile-card ${state.bookingType === 'hotels' ? 'hotel' : 'flight'}`}>
                    {state.bookingType === 'hotels' ? (
                      <>
                        <div className="hotel-thumb-box"><HotelImage src={item.imageUrl || item.thumbnailUrl} /></div>
                        <div className="hotel-details-col">
                          <div className="hotel-name-row"><h4 className="hotel-name-text">{item.hotelName}</h4><span className="price-text-blue">${item.pricePerNight || item.price}</span></div>
                          <div className="rating-row-mobile" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            {item.rating && <span className="star-rating"><MdStar color="#FFD166" size={16} /> {item.rating}</span>}
                            {item.totalReviews && <span className="review-count-sub">({item.totalReviews} reviews)</span>}
                          </div>
                          <div className="hotel-book-btn-row"><button className="hotel-book-btn-mobile" onClick={() => window.open(item.externalBookingUrl, '_blank')}>Open booking</button></div>
                        </div>
                      </>
                    ) : (
                      <>
                        <div className="card-top-row">
                          <div className="airline-logo-circle">{item.airlineLogo ? <img src={item.airlineLogo} alt="" /> : <span className="fallback-text" style={{ color: '#1a1a1a' }}>{item.carrier?.substring(0, 2)}</span>}</div>
                          <div className="card-main-info"><span className="flight-date-subtext">{formatDateShort(item.departureTime)}</span><span className="time-range-text">{formatTime(item.departureTime)} – {formatTime(item.arrivalTime)}</span><span className="carrier-subtext">{[item.carrier, item.flightNumber].filter(Boolean).join(' · ')}</span></div>
                          <div className="card-right-price"><span className="price-text-blue">${item.price}</span>{item.travelClass && <span className="class-tag">{item.travelClass}</span>}</div>
                        </div>
                        <div className="route-section">
                          <div className="route-labels-row"><span>{item.origin}</span><span>{item.duration || 'Auto'}</span><span>{item.destination}</span></div>
                          <div className="path-line-stack"><div className="gray-line" />{item.stops > 0 && <div className="stop-dot" />}</div>
                        </div>
                        <div className="stops-badge-row"><div className={`stops-badge ${item.stops === 0 ? 'direct' : 'stops'}`}>{item.stops === 0 ? 'Direct' : `${item.stops} stop`}</div></div>
                        <div style={{ marginTop: 14 }}><button className="launch-btn-mobile" onClick={() => window.open(item.externalBookingUrl, '_blank')}>Open Google Flights</button></div>
                      </>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {state.view === 'filters' && (
            <div className="filters-view-premium">
              <div className="sheet-scroll-area">
                <div className="filter-item">
                  <label className="filter-section-label">Budget</label>
                  <div className="budget-input-wrapper"><span className="prefix">$</span><input type="number" value={state.searchParams.budget} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { budget: e.target.value } })} /><span className="suffix">USD</span></div>
                </div>
                <div className="filter-item" style={{ marginTop: 20 }}>
                  <label className="filter-section-label">Sort by</label>
                  <div className="sort-chips-wrap">
                    <button className={`sort-chip ${state.sortBy === 'low' ? 'active' : ''}`} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: 'low' } })}>Price ↑</button>
                    <button className={`sort-chip ${state.sortBy === 'high' ? 'active' : ''}`} onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: 'high' } })}>Price ↓</button>
                  </div>
                </div>
              </div>
              <div className="filter-footer-mobile">
                <button className="apply-btn-blue" onClick={() => { handleSearch(); dispatch({ type: "CLOSE_FILTERS" }); }}>Apply Filters</button>
              </div>
            </div>
          )}
        </div>
      </div >
    </div >
  );
}

function HotelImage({ src }) {
  const [status, setStatus] = useState('loading');
  const imgRef = useRef(null);

  useEffect(() => {
    if (!src) {
      setStatus('fail');
      return;
    }
    const img = new Image();
    img.src = src;
    img.onload = () => setStatus('ok');
    img.onerror = () => setStatus('fail');
  }, [src]);

  if (status === 'fail') {
    return (
      <div className="no-photo-box">
        <span style={{ fontSize: 10, color: '#aaa', fontWeight: 600 }}>No Photo Available</span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt="Hotel"
      style={{ opacity: status === 'ok' ? 1 : 0, transition: 'opacity 0.3s' }}
    />
  );
}