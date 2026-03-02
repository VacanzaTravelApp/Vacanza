import React, { useReducer, useEffect } from "react"; // useEffect eklendi
import "../styles/bookingSheet.css"; 
import { bookingReducer, initialState } from "../bookingReducer"; 
import { auth } from "../../../firebase";

export default function BookingSheet({ open, onClose }) {
  const [state, dispatch] = useReducer(bookingReducer, initialState);

  // --- MODAL KAPANDIĞINDA TÜM STATE'İ SIFIRLA ---
  useEffect(() => {
    if (!open) {
      // Bileşen gizlendiğinde reducer'ı ilk durumuna döndürür
      dispatch({ type: "RESET_STATE" }); 
    }
  }, [open]);

  const handleClose = () => {
    // Burada sadece onClose çağırmak yeterli, useEffect sıfırlamayı yapacak
    onClose(); 
  };

  const handleSort = () => {
    const currentOrder = state.searchParams.sortOrder || 'lowToHigh';
    const newOrder = currentOrder === 'lowToHigh' ? 'highToLow' : 'lowToHigh';
    dispatch({ type: "UPDATE_PARAM", payload: { sortOrder: newOrder } });
    
    const sortedItems = [...state.items].sort((a, b) => {
      const priceA = parseFloat(a.pricePerNight || a.price || 0);
      const priceB = parseFloat(b.pricePerNight || b.price || 0);
      return newOrder === 'lowToHigh' ? priceA - priceB : priceB - priceA;
    });
    dispatch({ type: "SEARCH_SUCCESS", payload: sortedItems });
  };

  const handleSearch = async () => {
    const { destination, dates, checkOutDate, adults, budget } = state.searchParams;

    if (!destination || destination.length < 3) {
      alert("Please enter a valid 3-letter destination code.");
      return;
    }

    if (!dates || !checkOutDate) {
      alert("Please select both check-in and check-out dates.");
      return;
    }

    if (!adults || adults < 1) {
      alert("Adults must be at least 1.");
      return;
    }

    dispatch({ type: "SEARCH_START" });
    
    try {
      const user = auth.currentUser;
      const token = await user?.getIdToken();
      
      const payload = {
        cityCode: destination,
        checkInDate: dates,
        checkOutDate: checkOutDate,
        adults: parseInt(adults) || 1,
        budget: budget ? parseFloat(budget) : null,
        currency: "USD"
      };

      const response = await fetch("/bookings/accommodations/search", {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": `Bearer ${token}` },
        body: JSON.stringify(payload),
      });

      if (!response.ok) throw new Error("Search failed. Please try again.");

      const data = await response.json();
      dispatch({ type: "SEARCH_SUCCESS", payload: data || [] });
      
    } catch (err) {
      dispatch({ type: "SEARCH_ERROR", payload: err.message });
    }
  };

  if (!open) return null;

  return (
    <div className="custom-backdrop" onClick={handleClose} style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'center' }}>
      <div className="custom-sheet" onClick={(e) => e.stopPropagation()} 
           style={{ width: '100%', maxWidth: '500px', background: 'white', borderTopLeftRadius: '28px', borderTopRightRadius: '28px', padding: '24px', position: 'relative' }}>
        
        <div className="drag-handle-line" style={{ width: '40px', height: '4px', background: '#E5E5EA', borderRadius: '2px', margin: '0 auto 20px' }} />
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: state.view === 'results' ? '12px' : '20px' }}>
          <h1 style={{ fontSize: '24px', fontWeight: '800', margin: 0 }}>
            {state.view === 'results' ? 'Results' : 'Book'}
          </h1>
          <button onClick={handleClose} style={{ background: '#F2F2F7', border: 'none', borderRadius: '50%', width: '36px', height: '36px', cursor: 'pointer', fontWeight: 'bold' }}>✕</button>
        </div>

        {state.view === 'search' ? (
          <div className="search-view" style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
            <div style={{ display: 'flex', background: '#F2F2F7', borderRadius: '14px', padding: '4px' }}>
              <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'hotels' }})}
                style={{ flex: 1, padding: '12px', borderRadius: '10px', border: 'none', background: state.bookingType === 'hotels' ? 'white' : 'transparent', color: state.bookingType === 'hotels' ? '#007AFF' : '#8E8E93', fontWeight: '700' }}>
                🏨 Hotels
              </button>
              <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { bookingType: 'flights' }})}
                style={{ flex: 1, padding: '12px', borderRadius: '10px', border: 'none', background: state.bookingType === 'flights' ? 'white' : 'transparent', color: state.bookingType === 'flights' ? '#007AFF' : '#8E8E93', fontWeight: '700' }}>
                ✈️ Flights
              </button>
            </div>

            <div className="input-group">
              <label style={{ fontSize: '13px', color: '#8E8E93', fontWeight: '600' }}>Destination (IATA)</label>
              <input type="text" placeholder="e.g. PAR" style={{ width: '100%', padding: '14px', borderRadius: '14px', border: '1px solid #E5E5EA' }} value={state.searchParams.destination || ''} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { destination: e.target.value.toUpperCase() }})} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
              <input type="date" value={state.searchParams.dates || ''} style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid #E5E5EA' }} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { dates: e.target.value }})} />
              <input type="date" value={state.searchParams.checkOutDate || ''} style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid #E5E5EA' }} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { checkOutDate: e.target.value }})} />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
               <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '8px', border: '1px solid #E5E5EA', borderRadius: '12px' }}>
                  <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: Math.max(1, (state.searchParams.adults || 1) - 1) }})} style={{ border: 'none', background: 'none', fontSize: '18px' }}>−</button>
                  <span style={{ fontWeight: '700' }}>{state.searchParams.adults || 1}</span>
                  <button onClick={() => dispatch({ type: "UPDATE_PARAM", payload: { adults: (state.searchParams.adults || 1) + 1 }})} style={{ border: 'none', background: 'none', fontSize: '18px' }}>+</button>
               </div>
               <input type="number" placeholder="Budget" style={{ width: '100%', padding: '12px', borderRadius: '12px', border: '1px solid #E5E5EA' }} value={state.searchParams.budget || ''} onChange={(e) => dispatch({ type: "UPDATE_PARAM", payload: { budget: e.target.value }})} />
            </div>

            <div onClick={handleSort} style={{ padding: '14px', borderRadius: '14px', border: '1px solid #E5E5EA', background: '#FAFAFA', cursor: 'pointer', display: 'flex', justifyContent: 'space-between' }}>
              <span style={{ fontWeight: '600' }}>Price: {state.searchParams.sortOrder === 'highToLow' ? 'High to Low' : 'Low to High'}</span>
              <span>⇄</span>
            </div>

            <button className="main-search-btn" onClick={handleSearch} disabled={state.loading} style={{ height: '56px', borderRadius: '18px', background: '#007AFF', color: 'white', border: 'none', fontWeight: '700', fontSize: '16px' }}>
              {state.loading ? "Searching..." : `Search ${state.bookingType === 'hotels' ? 'Hotels' : 'Flights'}`}
            </button>
          </div>
        ) : (
          <div className="results-view">
            {/* ... Results içeriği aynı ... */}
            <div style={{ marginBottom: '18px' }}>
              <h3 style={{ margin: '0 0 4px 0', fontSize: '18px', fontWeight: '700' }}>
                {state.items.length} {state.bookingType === 'hotels' ? 'Hotels' : 'Flights'} Found
              </h3>
              <p style={{ margin: 0, color: '#8E8E93', fontSize: '13px', fontWeight: '500' }}>
                {state.searchParams.destination} · {state.searchParams.dates} — {state.searchParams.checkOutDate} · {state.searchParams.adults || 1} adult
              </p>
            </div>
            
            <div style={{ maxHeight: '450px', overflowY: 'auto' }}>
              {state.items.map((item, idx) => (
                <div key={idx} style={{ background: '#F8F8F8', padding: '16px', borderRadius: '20px', marginBottom: '12px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', border: '1px solid #F2F2F7' }}>
                  <div style={{ flex: 1 }}>
                    <h4 style={{ margin: 0, fontSize: '16px', fontWeight: '700' }}>{item.hotelName || item.carrier}</h4>
                    <p style={{ margin: '4px 0 0', color: '#007AFF', fontWeight: '800' }}>{item.pricePerNight || item.price} {item.currency}</p>
                  </div>
                  <button onClick={() => window.open(item.externalBookingUrl, '_blank')} 
                    style={{ background: '#007AFF', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '14px', fontWeight: '700', cursor: 'pointer' }}>
                    Open booking
                  </button>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}