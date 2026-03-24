import React, { useReducer, useEffect, useMemo, useState } from "react";
import "../styles/bookingSheet.css";
import { bookingReducer, initialState } from "../bookingReducer";
import { auth } from "../../../firebase";
import http from "../../../api/http";
import { MdFlightTakeoff, MdImageNotSupported, MdHotel } from "react-icons/md";

export default function BookingSheet({ open, onClose }) {
  const [state, dispatch] = useReducer(bookingReducer, initialState);
  const [airportResults, setAirportResults] = useState([]);
  const [activeSearchField, setActiveSearchField] = useState(null); // 'origin' | 'destination'
  const [searchQuery, setSearchQuery] = useState("");

  useEffect(() => {
    if (!open) {
      dispatch({ type: "RESET_STATE" });
      setAirportResults([]);
      setActiveSearchField(null);
      setSearchQuery("");
    }
  }, [open]);

  // Airport Autocomplete Effect
  useEffect(() => {
    if (searchQuery.length < 2) {
      setAirportResults([]);
      return;
    }

    const timer = setTimeout(async () => {
      try {
        const res = await http.get(`/bookings/airports/search?q=${searchQuery}`);
        setAirportResults(res.data || []);
      } catch (err) {
        console.error("Airport search failed:", err);
      }
    }, 350);

    return () => clearTimeout(timer);
  }, [searchQuery]);

  const filteredAndSortedItems = useMemo(() => {
    let list = [...state.items];

    // Hard filtering by budget in frontend to guarantee results
    const maxBudget = parseFloat(state.searchParams.budget);
    if (!isNaN(maxBudget) && maxBudget > 0) {
      list = list.filter(item => {
        const itemPrice = item.pricePerNight || item.price;
        return itemPrice <= maxBudget;
      });
    }

    if (state.sortBy === 'low') {
      list.sort((a, b) => (a.pricePerNight || a.price) - (b.pricePerNight || b.price));
    } else if (state.sortBy === 'high') {
      list.sort((a, b) => (b.pricePerNight || b.price) - (a.pricePerNight || a.price));
    } else if (state.sortBy === 'duration') {
      list.sort((a, b) => (a.duration || "").localeCompare(b.duration || ""));
    }
    return list;
  }, [state.items, state.sortBy, state.searchParams.budget]);

  const handleSearch = async () => {
    const { destination, origin, dates, checkOutDate, adults, budget, isRoundTrip, sortBy, travelClass } = state.searchParams;
    const isHotel = state.bookingType === 'hotels';

    const errors = {};
    if (!isHotel) {
      if (!origin) errors.origin = "Entry required";
      if (!destination) errors.destination = "Entry required";
    } else {
      if (!destination) errors.destination = "Entry required";
    }

    if (!dates) errors.dates = "Selection required";

    if ((isHotel || isRoundTrip) && !checkOutDate) {
      errors.checkOutDate = "Selection required";
    }

    if (Object.keys(errors).length > 0) {
      dispatch({ type: "SET_ERRORS", payload: errors });
      return;
    }

    dispatch({ type: "SEARCH_START" });
    try {
      const endpoint = isHotel ? `/bookings/accommodations/search` : `/bookings/transportation/search`;

      // SORT MAPPING: Backend SortCriteria enum: PRICE_ASC, PRICE_DESC, RATING_DESC
      let apiSortBy = 'PRICE_ASC';
      if (sortBy === 'high') apiSortBy = 'PRICE_DESC';
      if (sortBy === 'rating') apiSortBy = 'RATING_DESC';
      // 'duration' is not supported by backend enum, fallback to PRICE_ASC

      const payload = isHotel ? {
        query: destination,
        checkInDate: dates,
        checkOutDate: checkOutDate || dates,
        adults: parseInt(adults) || 1,
        budget: budget ? parseFloat(budget) : null,
        currency: 'USD',
        sortBy: apiSortBy
      } : {
        origin,
        destination,
        departureDate: dates,
        returnDate: isRoundTrip ? checkOutDate : null,
        adults: parseInt(adults) || 1,
        budget: budget ? parseFloat(budget) : null,
        currency: 'USD',
        sortBy: apiSortBy
      };

      const response = await http.post(endpoint, payload);
      dispatch({ type: "SEARCH_SUCCESS", payload: response.data || [] });
    } catch (err) {
      console.error("Error:", err);
      const status = err?.response?.status;
      const dataMsg = err?.response?.data?.message || "";
      let errorMsg = "Search is currently unavailable. Please try again later.";

      if (status === 400) {
        if (dataMsg.toUpperCase().includes("IATA")) {
          errorMsg = "Please make sure to select a valid 3-letter airport code (IATA).";
        } else {
          errorMsg = "Please fill in all mandatory fields correctly.";
        }
      } else if (status === 401) {
        errorMsg = "Unauthorized access, please log in to the system.";
      } else if (status === 500) {
        errorMsg = "Search is currently unavailable. Please try again later.";
      } else if (status === 502) {
        errorMsg = "Invalid response from SerpApi (Bad Gateway).";
      } else if (status === 503) {
        errorMsg = "The service is currently busy. SerpApi request limit may have been exceeded.";
      }

      dispatch({ type: "SEARCH_ERROR", payload: errorMsg });
    }
  };

  if (!open) return null;

  const formatTime = (t) => {
    if (!t) return "";
    if (t.includes(' ')) return t.split(' ')[1];
    if (t.includes('T')) return t.split('T')[1].substring(0, 5);
    return t;
  };

  const formatDuration = (d) => d?.replace('PT', '').toLowerCase() || '2h 15m';

  const formatStops = (s) => {
    if (!s || s === 0) return "Direct";
    return `${s} stop${s > 1 ? 's' : ''}`;
  };

  const renderError = (field) => {
    if (state.errors?.[field]) {
      return <span className="field-error-msg">{state.errors[field]}</span>;
    }
    return null;
  };

  // COMMON SORT COMPONENT
  const SortField = (
    <div className="sort-container-refined">
      <label>Sort by</label>
      <select
        className="modern-sort-select"
        value={state.sortBy || 'low'}
        onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { sortBy: e.target.value } })}
      >
        <option value="low">Price: Low to High</option>
        <option value="high">Price: High to Low</option>
      </select>
    </div>
  );

  return (
    <div className="custom-backdrop" onClick={(e) => e.target === e.currentTarget && onClose()}>
      <div className="custom-sheet modern-ui" onClick={(e) => e.stopPropagation()}>
        <div className="drag-handle-line" />

        <button className="close-circle-btn-top" onClick={onClose}>✕</button>

        <div className="sheet-scrollable-content">
          {state.view === 'search' ? (
            <div className="search-form-container">
              <div className="tab-pill-container-mock">
                <button className={state.bookingType === 'hotels' ? 'pill-active-mock' : ''}
                  onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'hotels' } })}>
                  <span className="pill-icon"><MdHotel /></span> Hotels
                </button>
                <button className={state.bookingType === 'flights' ? 'pill-active-mock' : ''}
                  onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'flights' } })}>
                  <span className="pill-icon"><MdFlightTakeoff /></span> Flights
                </button>
              </div>

              <div className="inputs-grid-refined">
                {state.bookingType === 'flights' && (
                  <div className="input-group-modern" style={{ position: 'relative' }}>
                    <label>Origin</label>
                    <input type="text"
                      placeholder="e.g. IST or London"
                      value={state.searchParams.origin}
                      onChange={(e) => {
                        const val = e.target.value;
                        dispatch({ type: "UPDATE_PARAM", payload: { origin: val } });
                        setActiveSearchField('origin');
                        setSearchQuery(val);
                      }}
                      onFocus={() => {
                        setActiveSearchField('origin');
                        setSearchQuery(state.searchParams.origin || "");
                      }}
                    />
                    {activeSearchField === 'origin' && airportResults.length > 0 && (
                      <div className="airport-dropdown-refined">
                        {airportResults.map((item, i) => (
                          <div key={i} className="airport-item" onClick={() => {
                            dispatch({ type: "UPDATE_PARAM", payload: { origin: item.iataCode } });
                            setAirportResults([]);
                            setActiveSearchField(null);
                          }}>
                            <span className="iata">{item.iataCode}</span>
                            <span className="aname">{item.name}</span>
                            <span className="city">{item.city}, {item.country}</span>
                          </div>
                        ))}
                      </div>
                    )}
                    {renderError('origin')}
                  </div>
                )}

                <div className="input-group-modern" style={{ position: 'relative' }}>
                  <label>{state.bookingType === 'hotels' ? 'Search location or hotel' : 'Destination'}</label>
                  <input type="text"
                    placeholder={state.bookingType === 'hotels' ? "e.g. Istanbul, Hotels in Paris, near Eiffel Tower" : "e.g. SAW, Tokyo or Paris"}
                    value={state.searchParams.destination}
                    onChange={(e) => {
                      const val = e.target.value;
                      dispatch({ type: "UPDATE_PARAM", payload: { destination: val } });
                      if (state.bookingType === 'flights') {
                        setActiveSearchField('destination');
                        setSearchQuery(val);
                      }
                    }}
                    onFocus={() => {
                      if (state.bookingType === 'flights') {
                        setActiveSearchField('destination');
                        setSearchQuery(state.searchParams.destination || "");
                      }
                    }}
                  />
                  {activeSearchField === 'destination' && airportResults.length > 0 && (
                    <div className="airport-dropdown-refined">
                      {airportResults.map((item, i) => (
                        <div key={i} className="airport-item" onClick={() => {
                          dispatch({ type: "UPDATE_PARAM", payload: { destination: item.iataCode } });
                          setAirportResults([]);
                          setActiveSearchField(null);
                        }}>
                          <span className="iata">{item.iataCode}</span>
                          <span className="aname">{item.name}</span>
                          <span className="city">{item.city}, {item.country}</span>
                        </div>
                      ))}
                    </div>
                  )}
                  {renderError('destination')}
                </div>

                {state.bookingType === 'flights' && (
                  <div className="checkbox-wrapper-ios">
                    <input type="checkbox" id="rt-check" checked={state.searchParams.isRoundTrip}
                      onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { isRoundTrip: e.target.checked } })} />
                    <label htmlFor="rt-check">Round trip flight</label>
                  </div>
                )}

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label>{state.bookingType === 'hotels' ? 'Check-in' : 'Date'}</label>
                    <input
                      type="date"
                      value={state.searchParams.dates}
                      min={new Date().toISOString().split("T")[0]}
                      onChange={(e) => {
                        const newCheckIn = e.target.value;
                        const update = { dates: newCheckIn };
                        if (state.searchParams.checkOutDate && newCheckIn > state.searchParams.checkOutDate) {
                          update.checkOutDate = newCheckIn;
                        }
                        dispatch({ type: "UPDATE_PARAM", payload: update });
                      }}
                    />
                    {renderError('dates')}
                  </div>
                  {(state.bookingType === 'hotels' || state.searchParams.isRoundTrip) && (
                    <div className="input-group-modern half">
                      <label>{state.bookingType === 'hotels' ? 'Check-out' : 'Return'}</label>
                      <input
                        type="date"
                        value={state.searchParams.checkOutDate}
                        min={state.searchParams.dates || new Date().toISOString().split("T")[0]}
                        onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { checkOutDate: e.target.value } })}
                      />
                      {renderError('checkOutDate')}
                    </div>
                  )}
                </div>

                <div className="row-compact">
                  <div className="input-group-modern half">
                    <label>Adults</label>
                    <div className="counter-box">
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: Math.max(1, (state.searchParams.adults || 1) - 1) } })}>−</button>
                      <span>{state.searchParams.adults || 1}</span>
                      <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: (state.searchParams.adults || 1) + 1 } })}>+</button>
                    </div>
                  </div>
                  <div className="input-group-modern half">
                    <label>Budget <small>(Optional)</small></label>
                    <input
                      type="number"
                      placeholder="Max $"
                      value={state.searchParams.budget}
                      min="0"
                      onChange={(e) => {
                        const val = e.target.value;
                        if (val === "" || parseFloat(val) >= 0) {
                          dispatch({ type: "UPDATE_PARAM", payload: { budget: val } });
                        }
                      }}
                    />
                  </div>
                </div>
              </div>

              {SortField}
              {state.generalError && <div className="validation-error-msg">{state.generalError}</div>}
              <button className="main-search-btn" onClick={handleSearch} disabled={state.loading}>
                {state.loading ? "Searching..." : `Search ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'}`}
              </button>
            </div>

          ) : (
            <div className="results-container-mobile">
              <div className="results-header-mobile">
                <h3 className="count-title">
                  {filteredAndSortedItems.length} {state.bookingType === 'hotels' ? 'Hotels' : 'Flights'} Found
                </h3>
                <p className="summary-detail">
                  {state.bookingType === 'flights'
                    ? `${state.searchParams.origin} → ${state.searchParams.destination} · ${state.searchParams.dates} · ${state.searchParams.adults || 1} adult`
                    : `${state.searchParams.destination} · ${state.searchParams.dates}${state.searchParams.checkOutDate ? ` – ${state.searchParams.checkOutDate}` : ""} · ${state.searchParams.adults || 1} adult`
                  }
                </p>
              </div>

              <div className="results-list-mock">
                {filteredAndSortedItems.map((item, idx) => {
                  const isHotel = state.bookingType === 'hotels';
                  if (isHotel) {
                    return (
                      <div key={idx} className="hotel-result-card-mobile">
                        <div className="hotel-card-left">
                          {item.imageUrl ? (
                            <img
                              src={item.imageUrl}
                              alt={item.hotelName}
                              className="hotel-card-thumb"
                              onError={(e) => {
                                e.target.onerror = null;
                                e.target.outerHTML = '<div class="hotel-thumb-placeholder" style="font-size: 11px; font-weight: 500; color: #999; text-align: center; line-height: 1.2;">No Photo<br/>Available</div>';
                              }}
                            />
                          ) : (
                            <div className="hotel-thumb-placeholder" style={{ fontSize: '11px', fontWeight: 500, color: '#999', textAlign: 'center', lineHeight: '1.2' }}>No Photo<br />Available</div>
                          )}
                        </div>
                        <div className="hotel-card-right">
                          <div className="hotel-header-line">
                            <h4 className="hotel-title-text">{item.hotelName}</h4>
                            <span className="hotel-price-blue">${(item.pricePerNight || item.price).toFixed(2)}</span>
                          </div>


                          <div className="hotel-meta-row-mobile">
                            <span className="hotel-rating-yellow"><span style={{ color: '#FFD166', marginRight: '3px', fontSize: '15px' }}>★</span>{item.rating || '4.0'}</span>
                            {item.totalReviews && <span className="hotel-reviews-count">({item.totalReviews} reviews)</span>}
                          </div>

                          {item.description && (
                            <p className="hotel-desc-clamp">{item.description}</p>
                          )}

                          <div className="hotel-provider-line">
                            {item.providerName || "Google Hotels"}
                          </div>

                          <div className="hotel-action-align-right">
                            <button className="hotel-open-booking-btn" onClick={() => window.open(item.externalBookingUrl, '_blank')}>
                              Open booking
                            </button>
                          </div>
                        </div>
                      </div>
                    );
                  }

                  return (
                    <div key={idx} className="flight-result-card-mobile">
                      <div className="flight-card-top-row">
                        <div className="flight-logo-info">
                          <div className="flight-logo-circle">
                            {item.airlineLogo ? (
                              <img src={item.airlineLogo} alt={item.carrier} />
                            ) : (
                              <MdFlightTakeoff style={{ fontSize: '20px', color: '#007AFF' }} />
                            )}
                          </div>
                          <div className="flight-time-carrier">
                            <div className="flight-time-range">
                              {formatTime(item.departureTime)} – {formatTime(item.arrivalTime)}
                            </div>
                            <div className="flight-carrier-details">
                              {item.carrier}{item.flightNumber ? ` · ${item.flightNumber}` : ''}
                            </div>
                          </div>
                        </div>

                        <div className="flight-price-class">
                          <div className="flight-price-text">${Math.round(item.price)}</div>
                          {item.travelClass && (
                            <div className="flight-class-pill">{item.travelClass}</div>
                          )}
                        </div>
                      </div>

                      <div className="flight-route-section">
                        <div className="flight-route-labels">
                          <span>{item.origin}</span>
                          <span>{item.duration || 'Auto'}</span>
                          <span>{item.destination}</span>
                        </div>
                        <div className="flight-path-bar-wrap">
                          <div className="flight-path-bar"></div>
                          {item.stops > 0 && <div className="flight-path-dot"></div>}
                        </div>
                        <div className="flight-stops-badge-wrap">
                          <span className={`flight-stops-badge ${item.stops === 0 ? 'direct' : 'stops'}`}>
                            {formatStops(item.stops)}
                          </span>
                        </div>
                      </div>

                      <button className="flight-google-btn-mobile" onClick={() => window.open(item.externalBookingUrl, '_blank')}>
                        Open in Google Flights <span className="arrow">→</span>
                      </button>
                    </div>
                  );
                })}
              </div>

              <div className="results-footer-mock">
                <div className="footer-credits">
                  <span>Powered by SerpApi (Google Hotels & Flights)</span>
                </div>
              </div>

              <div className="results-footer-actions">
                <div className="center-btn-wrapper">
                  <button className="retry-link-btn" onClick={() => dispatch({ type: "RETRY" })}>
                    ← Back to Search
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}