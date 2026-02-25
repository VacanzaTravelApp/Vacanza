import React, { useEffect } from "react";
import "../styles/bookingSheet.css";

export default function BookingSheet({ open, onClose }) {
  // ESC ile kapatma (opsiyonel ama iyi)
  useEffect(() => {
    if (!open) return;

    const onKeyDown = (e) => {
      if (e.key === "Escape") onClose?.();
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  const stopPropagation = (e) => e.stopPropagation();

  return (
    <div className="booking-backdrop" onClick={onClose}>
      <div className="booking-sheet" onClick={stopPropagation} role="dialog" aria-modal="true">
        <div className="booking-handle" />

        <div className="booking-header">
          <div className="booking-title">Book</div>

          <button
            className="booking-close"
            type="button"
            onClick={onClose}
            aria-label="Close booking"
            title="Close"
          >
            ✕
          </button>
        </div>

        {/* Default View: Search (placeholder) */}
        <div className="booking-content">
          <div className="booking-tabs">
            <button type="button" className="booking-tab booking-tab-active">
              Hotels
            </button>
            <button type="button" className="booking-tab">
              Flights
            </button>
          </div>

          <div className="booking-placeholder">
            <div className="booking-placeholder-title">Search</div>
            <div className="booking-placeholder-text">
              WEB2 tamam ✅ <br />
              Search form wiring WEB7’de eklenecek.
            </div>

            <button type="button" className="booking-primary-btn" disabled>
              Search
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}