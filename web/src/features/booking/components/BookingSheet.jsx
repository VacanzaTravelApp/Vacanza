import React, { useReducer, useCallback } from "react";
import "../styles/bookingSheet.css";
import { bookingReducer, initialState } from "../bookingReducer";
import { auth } from "../../../firebase"; 

export default function BookingSheet({ open, onClose }) {
  const [state, dispatch] = useReducer(bookingReducer, initialState);

  const handleSearch = useCallback(async () => {
    // Backend Kuralı: IATA kodu 3 harf olmalı (ST-2.1)
    if (!state.searchParams.destination || state.searchParams.destination.length !== 3) {
      return alert("Lütfen 3 harfli bir IATA kodu girin (Örn: PAR)");
    }

    dispatch({ type: "SEARCH_START" });

    try {
      const user = auth.currentUser;
      const token = await user?.getIdToken(true);
      const isHotel = state.bookingType === 'hotels';
      
      const response = await fetch(isHotel ? "/bookings/accommodations/search" : "/bookings/transportation/search", {
        method: "POST",
        headers: { 
          "Content-Type": "application/json", 
          "Authorization": `Bearer ${token}` 
        },
        // Backend DTO (ST-2.1 & ST-2.2) ile tam uyumlu body
        body: JSON.stringify({
          cityCode: state.searchParams.destination, 
          origin: "IST", // Uçuşlar için varsayılan kalkış
          destination: state.searchParams.destination,
          checkInDate: state.searchParams.dates || "2026-07-01",
          checkOutDate: "2026-07-05", // Konaklama için gerekli (ST-2.1)
          departureDate: state.searchParams.dates || "2026-07-01",
          adults: state.searchParams.adults,
          budget: null, // Bütçe filtresi opsiyonel (ST-4.2)
          currency: "USD",
          sortBy: "PRICE_ASC" // ST-2.5: Varsayılan sıralama
        }),
      });

      if (!response.ok) throw new Error("Arama başarısız oldu.");

      const data = await response.json();
      dispatch({ type: "SEARCH_SUCCESS", payload: data });
    } catch (err) {
      console.error("Hata:", err);
      dispatch({ type: "SEARCH_ERROR", payload: err.message });
    }
  }, [state.bookingType, state.searchParams]);

  if (!open) return null;

  return (
    <div className="booking-backdrop" onClick={onClose}>
      <div className="booking-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="sheet-header-ios">
          <div className="drag-handle" />
          <div className="header-main">
            <h2 className="header-title">Book</h2>
            <button className="close-circle-btn" onClick={onClose}>✕</button>
          </div>
        </div>

        <div className="booking-content">
          <div className="booking-tabs-modern">
            <button 
              className={`tab-modern ${state.bookingType === 'hotels' ? 'active' : ''}`}
              onClick={() => dispatch({ type: "SET_TYPE", payload: "hotels" })}
            >🏨 Hotels</button>
            <button 
              className={`tab-modern ${state.bookingType === 'flights' ? 'active' : ''}`}
              onClick={() => dispatch({ type: "SET_TYPE", payload: "flights" })}
            >✈️ Flights</button>
          </div>

          <div className="form-scroll-area">
            {/* Hedef Şehir */}
            <div className="ios-input-group">
              <label>Destination (IATA Code)</label>
              <div className="ios-input-wrapper">
                <span className="ios-icon">🔍</span>
                <input 
                  type="text" 
                  placeholder="e.g. LON, PAR, IST"
                  maxLength={3}
                  value={state.searchParams.destination}
                  onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value.toUpperCase() }})}
                />
              </div>
            </div>

            {/* Takvim ve Yetişkin Sayısı */}
            <div className="ios-row">
              <div className="ios-input-group flex-2">
                <label>Date</label>
                <div className="ios-input-wrapper">
                  <span className="ios-icon">📅</span>
                  <input 
                    type="date" 
                    className="modern-date-input"
                    value={state.searchParams.dates}
                    onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { dates: e.target.value }})}
                  />
                </div>
              </div>
              <div className="ios-input-group flex-1">
                <label>Adults</label>
                <div className="ios-stepper">
                  <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: Math.max(1, state.searchParams.adults - 1) }})}>-</button>
                  <span className="adult-count-text">{state.searchParams.adults}</span>
                  <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: state.searchParams.adults + 1 }})}>+</button>
                </div>
              </div>
            </div>

            <button className="ios-main-search-btn" onClick={handleSearch} disabled={state.loading}>
              {state.loading ? "Searching..." : `🔍 Search ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'}`}
            </button>

            {/* ARAMA SONUÇLARI (ST-2.3 & ST-2.4) */}
            <div className="results-list" style={{ marginTop: '20px' }}>
               {state.items && state.items.length > 0 ? (
                 state.items.map((item, idx) => (
                   <div key={idx} className="ios-card">
                      <div className="card-image">
                        <img src={`https://picsum.photos/seed/${idx}/400/200`} alt="place" />
                      </div>
                      <div className="card-body">
                        {/* Backend DTO Alanları: hotelName veya carrier */}
                        <h4 className="hotel-name">{item.hotelName || item.carrier}</h4>
                        <p className="address-text">
                          {item.address || `${item.origin} ➔ ${item.destination}`}
                        </p>
                        <div className="card-footer-row">
                          <div className="price-box">
                             <span className="price-amount">{item.price}</span>
                             <span className="price-period"> {item.currency}</span>
                          </div>
                          {/* Amadeus Yönlendirmesi (ST-2.3) */}
                          <button 
                            className="book-now-btn"
                            onClick={() => window.open(item.externalBookingUrl, "_blank")}
                          >
                            Book Now
                          </button>
                        </div>
                      </div>
                   </div>
                 ))
               ) : !state.loading && state.items && (
                 <p className="no-results-text">No results found for this selection.</p>
               )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}