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
      dispatch({ type: "SEARCH_ERROR", payload: { message: "Unexpected error occurred." } });
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
                    <label className="input-label-mobile">ORIGIN</label>
                    <div className="input-with-icon-mobile">
                      <MdFlightTakeoff className="input-icon-prefix" />
                      <input
                        type="text" placeholder="e.g. IST or Istanbul"
                        value={activeSearchField === 'origin' ? searchQuery : (originLabel || state.searchParams.origin)}
                        onFocus={() => {
                          setActiveSearchField('origin');
                          isTypingRef.current = false;
                          setSearchQuery(originLabel || state.searchParams.origin || "");
                        }}
                        onChange={(e) => {
                          setActiveSearchField('origin');
                          isTypingRef.current = true;
                          setSearchQuery(e.target.value);
                          dispatch({ type: "UPDATE_PARAM", payload: { origin: e.target.value } });
                          if (originLabel) setOriginLabel("");
                        }}
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') handleSearch();
                        }}
                      />
                    </div>
                    {activeSearchField === 'origin' && (searchQuery.length > 0 || isSearching) && (
                      <div className="airport-dropdown-refined">
                        {isSearching ? (
                          <div className="dropdown-status-msg">Searching...</div>
                        ) : airportResults.length > 0 ? (
                          airportResults.map((item, i) => (
                            <div key={i} className="airport-item" onClick={() => {
                              const searchId = item.iataCode ?? item.kgmid;
                              dispatch({ type: "UPDATE_PARAM", payload: { origin: searchId } });
                              setOriginLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`);
                              setAirportResults([]); setActiveSearchField(null);
                            }}>
                              <div className="airport-item-row">
                                <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                                <div className="airport-item-info">
                                  <span className="aname">{item.name}</span>
                                  <span className="city">{item.city}, {item.country}</span>
                                </div>
                                {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                              </div>
                            </div>
                          ))
                        ) : (
                          <div className="dropdown-status-msg">No suggestions found</div>
                        )}
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
                      type="text" placeholder={state.bookingType === 'hotels' ? "Where are you going? (City or hotel)" : "e.g. CDG or Paris"}
                      autoComplete="off"
                      value={activeSearchField === 'destination' ? searchQuery : (destLabel || state.searchParams.destination)}
                      onFocus={() => {
                        setActiveSearchField('destination');
                        isTypingRef.current = false;
                        setSearchQuery(destLabel || state.searchParams.destination || "");
                      }}
                      onChange={(e) => {
                        setActiveSearchField('destination');
                        isTypingRef.current = true;
                        setSearchQuery(e.target.value);
                        dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value } });
                        if (destLabel) setDestLabel("");
                      }}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') handleSearch();
                      }}
                    />
                  </div>
                  {activeSearchField === 'destination' && state.bookingType !== 'hotels' && (searchQuery.length > 0 || isSearching) && (
                    <div className="airport-dropdown-refined">
                      {isSearching ? (
                        <div className="dropdown-status-msg">Searching...</div>
                      ) : airportResults.length > 0 ? (
                        airportResults.map((item, i) => (
                          <div key={i} className="airport-item" onClick={() => {
                            if (state.bookingType === 'hotels') {
                              if (item.iataCode || item.kgmid) {
                                const q = `Hotels in ${item.city || item.name}`;
                                dispatch({ type: "UPDATE_PARAM", payload: { destination: q } });
                                setDestLabel(item.name);
                              } else {
                                dispatch({ type: "UPDATE_PARAM", payload: { destination: item.searchQuery } });
                                setDestLabel(item.displayName);
                              }
                            } else {
                              const searchId = item.iataCode ?? item.kgmid;
                              dispatch({ type: "UPDATE_PARAM", payload: { destination: searchId } });
                              setDestLabel(item.kgmid ? `All airports — ${item.city}` : `${item.city} (${item.iataCode})`);
                            }
                            setAirportResults([]); setActiveSearchField(null);
                          }}>
                            <div className="airport-item-row">
                              <span className="airport-type-icon">{item.kgmid ? <MdLocationCity /> : <MdLocalAirport />}</span>
                              <div className="airport-item-info">
                                <span className="aname">{item.name}</span>
                                <span className="city">{item.city}, {item.country}</span>
                              </div>
                              {!item.kgmid && <span className="iata-badge">{item.iataCode}</span>}
                            </div>
                          </div>
                        ))
                      ) : (
                        <div className="dropdown-status-msg">No suggestions found</div>
                      )}
                    </div>
                  )}
                  {renderError('destination')}
                </div>

                {state.bookingType === 'flights' && (
                  <div className="round-trip-toggle-mobile" onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { isRoundTrip: !state.searchParams.isRoundTrip } })}>
                    <div className={`checkbox-custom-mobile ${state.searchParams.isRoundTrip ? 'checked' : ''}`}>
                      {state.searchParams.isRoundTrip && <MdCheck size={14} color="#fff" />}
                    </div>
                    <span>Round trip</span>
                  </div>
                )}

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label className="input-label-mobile">{state.bookingType === 'hotels' ? 'CHECK-IN' : 'DATE'}</label>
                    <input
                      type="date"
                      onFocus={() => setActiveSearchField(null)}
                      min={new Date().toISOString().split('T')[0]}
                      value={state.searchParams.dates}
                      onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { dates: e.target.value } })}
                    />
                    {renderError('dates')}
                  </div>
                  {state.bookingType === 'hotels' || state.searchParams.isRoundTrip ? (
                    <div className="input-group-modern half">
                      <label className="input-label-mobile">{state.bookingType === 'hotels' ? 'CHECK-OUT' : 'RETURN'}</label>
                      <input
                        type="date"
                        onFocus={() => setActiveSearchField(null)}
                        min={state.searchParams.dates || new Date().toISOString().split('T')[0]}
                        value={state.searchParams.checkOutDate}
                        onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { checkOutDate: e.target.value } })}
                      />
                    </div>
                  ) : <div className="half" />}
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
                    <label className="input-label-mobile">BUDGET (OPTIONAL)</label>
                    <input
                      type="number" min="0" placeholder="Max $"
                      onFocus={() => setActiveSearchField(null)}
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
                  <label className="input-label-mobile">SORT BY</label>
                  <select
                    className="custom-select-refined"
                    onFocus={() => setActiveSearchField(null)}
                    value={state.sortBy}
                    onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: e.target.value } })}
                  >
                    <option value="low">Price: Low to High</option>
                    <option value="high">Price: High to Low</option>
                  </select>
                </div>
              </div>
              <div className="search-footer-modern">
                {state.status === 'error' && (
                  <div className="form-error-banner">
                    {state.error?.message || "Search failed. Please check your connection."}
                  </div>
                )}
                <button className="search-submit-btn-premium" onClick={handleSearch} disabled={state.loading}>
                  {state.loading ? 'Searching...' : (state.bookingType === 'hotels' ? 'Search Hotels' : 'Search Flights')}
                </button>
              </div>
            </div>
          )}

          {state.view === 'results' && (
            <div className="results-list-refined">
              <div className="results-header-premium">
                <button className="back-btn-circle" onClick={() => dispatch({ type: "RETRY" })}><MdChevronLeft /></button>
                <div className="results-title-stack">
                  <h3 className="results-count-text">{filteredAndSortedItems.length} {state.bookingType === 'hotels' ? 'Hotels' : 'Flights'} Found</h3>
                  <span className="results-summary-sub">
                    {state.bookingType === 'hotels'
                      ? `${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)} – ${formatFriendlyDate(state.searchParams.checkOutDate)} · ${state.searchParams.adults} adult`
                      : `${state.searchParams.origin}→${state.searchParams.destination} · ${formatFriendlyDate(state.searchParams.dates)}${state.searchParams.isRoundTrip ? ` – ${formatFriendlyDate(state.searchParams.checkOutDate)}` : ''} · ${state.searchParams.adults} adult`}
                  </span>
                </div>
                <button className="filter-tune-btn" onClick={() => dispatch({ type: "OPEN_FILTERS" })}><MdTune /></button>
              </div>

              <div className="results-grid-mobile">
                {filteredAndSortedItems.map((item, idx) => {
                  if (state.bookingType === 'hotels') {
                    return (
                      <div key={idx} className="mobile-card hotel">
                        <div className="hotel-thumb-box">
                          <HotelImage src={item.imageUrl || item.thumbnailUrl} />
                        </div>
                        <div className="hotel-details-col">
                          <div className="hotel-name-row">
                            <h4 className="hotel-name-text">{item.hotelName}</h4>
                            <span className="price-text-blue">${item.pricePerNight || item.price}</span>
                          </div>
                          <div className="rating-row-mobile" style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: 6 }}>
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
            </div>
          )}

          {state.view === 'filters' && (
            <div className="filters-view-premium">
              <div className="filters-header-mobile" style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
                <button className="back-btn-circle" onClick={() => dispatch({ type: "CLOSE_FILTERS" })}><MdChevronLeft /></button>
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