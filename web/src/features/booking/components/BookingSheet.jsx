import React, { useReducer, useEffect, useMemo } from "react";
import "../styles/bookingSheet.css";
import { bookingReducer, initialState } from "../bookingReducer";
import { auth } from "../../../firebase";

export default function BookingSheet({ open, onClose }) {
  const [state, dispatch] = useReducer(bookingReducer, initialState);

  useEffect(() => {
    if (!open) dispatch({ type: "RESET_STATE" });
  }, [open]);

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
    const { destination, origin, dates, checkOutDate, adults, budget, isRoundTrip } = state.searchParams;
    const isHotel = state.bookingType === 'hotels';

    const errors = {};
    if (!destination) errors.destination = "Entry required";
    if (!isHotel && !origin) errors.origin = "Entry required";
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
      const user = auth.currentUser;
      if (!user) { alert("Lütfen önce giriş yapın!"); dispatch({ type: "SEARCH_ERROR" }); return; }
      const token = await user.getIdToken();
      const endpoint = isHotel ? `/bookings/accommodations/search` : `/bookings/transportation/search`;

      const payload = isHotel ? {
        cityCode: destination, checkInDate: dates, checkOutDate: checkOutDate || dates,
        adults: parseInt(adults) || 1, budget: budget ? parseFloat(budget) : null
      } : {
        origin, destination, departureDate: dates,
        returnDate: isRoundTrip ? checkOutDate : null, adults: parseInt(adults) || 1,
        budget: budget ? parseFloat(budget) : null
      };

      const response = await fetch(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${token}` },
        body: JSON.stringify(payload),
      });

      if (!response.ok) throw new Error(`Sunucu Hatası: ${response.status}`);
      const data = await response.json();
      dispatch({ type: "SEARCH_SUCCESS", payload: data || [] });
    } catch (err) {
      console.error("Hata:", err);
      dispatch({ type: "SEARCH_ERROR" });
    }
  };

  if (!open) return null;

  const formatTime = (t) => t?.includes('T') ? t.split('T')[1].substring(0, 5) : t;
  const formatDuration = (d) => d?.replace('PT', '').toLowerCase() || '2h 15m';

  const renderError = (field) => {
    if (state.errors?.[field]) {
      return <span className="field-error-msg">{state.errors[field]}</span>;
    }
    return null;
  };

  // ORTAK SORT COMPONENTİ (Tekrardan kurtulmak için)
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
        {state.bookingType === 'flights' && <option value="duration">Shortest Duration</option>}
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
                  <span className="pill-icon">🏨</span> Hotels
                </button>
                <button className={state.bookingType === 'flights' ? 'pill-active-mock' : ''}
                  onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'flights' } })}>
                  <span className="pill-icon">✈️</span> Flights
                </button>
              </div>

              <div className="inputs-grid-refined">
                {state.bookingType === 'flights' && (
                  <div className="input-group-modern">
                    <label>Origin (IATA)</label>
                    <input type="text" placeholder="E.g. IST" maxLength="3" value={state.searchParams.origin}
                      onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { origin: e.target.value.toUpperCase() } })} />
                    {renderError('origin')}
                  </div>
                )}

                <div className="input-group-modern">
                  <label>{state.bookingType === 'hotels' ? 'City (IATA)' : 'Destination (IATA)'}</label>
                  <input type="text" placeholder="E.g. PAR" maxLength="3" value={state.searchParams.destination}
                    onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value.toUpperCase() } })} />
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

              {/* ARAMA EKRANI SORT VE BUTON */}
              {SortField}
              <button className="main-search-btn" onClick={handleSearch} disabled={state.loading}>
                {state.loading ? "Searching..." : `Search ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'}`}
              </button>
            </div>
          ) : (
            <div className="results-container-mock">
              <div className="results-header-mock">
                <h3 className="found-count-title-mock">
                  {filteredAndSortedItems.length} {state.bookingType === 'flights' ? 'Flights' : 'Hotels'} Found
                </h3>
                <p className="route-sub-detail-mock">
                  {state.bookingType === 'flights' ? `${state.searchParams.origin} • ${state.searchParams.destination}` : state.searchParams.destination} • {state.searchParams.dates}
                </p>
              </div>

              <div className="results-list-mock">
                {filteredAndSortedItems.map((item, idx) => {
                  const isHotel = state.bookingType === 'hotels';
                  if (isHotel) {
                    const thumbUrl = item.photo || `https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&q=80&w=200&h=200`;
                    return (
                      <div key={idx} className="premium-result-card">
                        <div className="result-card-main">
                          <div className="result-thumb-container">
                            <img
                              src={thumbUrl}
                              alt={item.hotelName}
                              className="result-thumb"
                              onError={(e) => {
                                e.target.onerror = null;
                                e.target.style.display = 'none';
                                e.target.parentNode.innerHTML = `<span class="thumb-fallback-icon">🏨</span>`;
                              }}
                            />
                          </div>
                          <div className="result-info-center">
                            <h4 className="result-title">{item.hotelName}</h4>
                            <div className="result-meta-row">
                              {item.rating && <><span className="result-rating">★ {item.rating}</span><span className="meta-dot">•</span></>}
                              <span className="result-dist">{item.distance ? `${item.distance} km` : state.searchParams.destination}</span>
                            </div>
                            <div className="result-price-row">
                              <span className="price-val">${item.pricePerNight || item.price}</span>
                              <span className="price-unit">/ night</span>
                            </div>
                          </div>
                          <button className="book-now-btn-green" onClick={() => window.open(item.externalBookingUrl, '_blank')}>
                            Book Now
                          </button>
                        </div>
                      </div>
                    );
                  }

                  // FLIGHTS: Geleneksel Zaman Çizelgesi UI'ına geri dönüş
                  return (
                    <div key={idx} className="hotel-detail-card">
                      <div className="card-top-row">
                        <span className="carrier-tag">✈️ {item.carrier || 'AIRLINE'}</span>
                        <span className="price-tag-blue">${item.price}</span>
                      </div>
                      <div className="flight-path-row">
                        <div className="time-node">
                          <span className="t-val">{formatTime(item.departureTime)}</span>
                          <span className="c-val">{item.origin}</span>
                        </div>
                        <div className="path-line-group">
                          <span className="dur-val">{formatDuration(item.duration)}</span>
                          <div className="line-bar"><div className="dot" /></div>
                          <span className="stop-badge-orange">{item.stops === 0 ? 'Direct' : `${item.stops} stop`}</span>
                        </div>
                        <div className="time-node" style={{ textAlign: 'right' }}>
                          <span className="t-val">{formatTime(item.arrivalTime)}</span>
                          <span className="c-val">{item.destination}</span>
                        </div>
                      </div>
                      <button className="google-action-btn" onClick={() => window.open(item.externalBookingUrl, '_blank')}>
                        Open in Google Flights ↗
                      </button>
                    </div>
                  );
                })}
              </div>

              <div className="results-footer-mock">
                <div className="footer-credits">
                  <span>Powered by Amadeus API</span>
                </div>
              </div>

              {/* SONUÇ EKRANI SORT VE GERİ DÖN BUTONU */}
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