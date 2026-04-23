import React, { useState, useEffect, useRef, useCallback } from 'react';
import Map, { Marker } from 'react-map-gl';
import '../styles/hotelPickerSheet.css';
import HotelIcon from "./icons/HotelIcon";

const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;

async function geocodeQuery(query) {
  if (!query || !MAPBOX_TOKEN) return [];
  try {
    const res = await fetch(
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?access_token=${MAPBOX_TOKEN}&limit=5&types=address,place,poi`
    );
    const data = await res.json();
    return data.features || [];
  } catch {
    return [];
  }
}

async function reverseGeocode(lat, lon) {
  if (!MAPBOX_TOKEN) return '';
  try {
    const res = await fetch(
      `https://api.mapbox.com/geocoding/v5/mapbox.places/${lon},${lat}.json?access_token=${MAPBOX_TOKEN}&limit=1`
    );
    const data = await res.json();
    return data.features?.[0]?.place_name || '';
  } catch {
    return '';
  }
}

export default function HotelPickerSheet({ open, onClose, defaultDestination, onSelect }) {
  const [manualName, setManualName] = useState('');
  const [manualAddress, setManualAddress] = useState('');
  const [manualCoords, setManualCoords] = useState(null);
  const [suggestions, setSuggestions] = useState([]);
  const [suggestionsOpen, setSuggestionsOpen] = useState(false);
  const [geocoding, setGeocoding] = useState(false);
  const [viewport, setViewport] = useState({ latitude: 48.8566, longitude: 2.3522, zoom: 4 });
  const [saving, setSaving] = useState(false);
  const geocodeTimer = useRef(null);

  useEffect(() => {
    if (!open) return;
    setManualName('');
    setManualAddress('');
    setManualCoords(null);
    setSuggestions([]);
    setSuggestionsOpen(false);
    setSaving(false);
    if (defaultDestination) {
      geocodeQuery(defaultDestination).then(features => {
        if (features.length > 0) {
          const [lon, lat] = features[0].center;
          setViewport({ latitude: lat, longitude: lon, zoom: 11 });
        }
      });
    }
  }, [open, defaultDestination]);

  useEffect(() => {
    clearTimeout(geocodeTimer.current);
    if (manualAddress.length < 3) { setSuggestions([]); return; }
    geocodeTimer.current = setTimeout(async () => {
      setGeocoding(true);
      const features = await geocodeQuery(manualAddress);
      setSuggestions(features);
      setGeocoding(false);
      setSuggestionsOpen(features.length > 0);
    }, 400);
    return () => clearTimeout(geocodeTimer.current);
  }, [manualAddress]);

  function pickSuggestion(feature) {
    const [lon, lat] = feature.center;
    setManualAddress(feature.place_name);
    setManualCoords({ lat, lon });
    setViewport({ latitude: lat, longitude: lon, zoom: 14 });
    setSuggestions([]);
    setSuggestionsOpen(false);
  }

  const handleMapClick = useCallback(async (e) => {
    const { lat, lng } = e.lngLat;
    setManualCoords({ lat, lon: lng });
    const addr = await reverseGeocode(lat, lng);
    if (addr) setManualAddress(addr);
    setSuggestionsOpen(false);
  }, []);

  function handleSave() {
    if (!manualName.trim()) return;
    setSaving(true);
    onSelect({
      hotelName: manualName.trim(),
      hotelId: null,
      address: manualAddress || null,
      latitude: manualCoords?.lat ?? null,
      longitude: manualCoords?.lon ?? null,
      pricePerNight: null,
      currency: null,
      imageUrl: null,
      externalBookingUrl: null,
      rating: null,
      providerName: 'Manual',
    });
  }

  if (!open) return null;

  return (
    <div className="hps-overlay" onClick={onClose}>
      <div className="hps-sheet" onClick={(e) => e.stopPropagation()}>

        <div className="hps-header">
          <span className="hps-title">
            <HotelIcon size={18} className="hps-hotel-icon" />
            Add Hotel
          </span>
          <button className="hps-close" onClick={onClose} aria-label="Close">✕</button>
        </div>

        <div className="hps-manual">
          <div className="hps-manual-form">

            <div className="hps-field">
              <label className="hps-label">Hotel / Place name *</label>
              <input
                className="hps-input"
                type="text"
                placeholder="e.g. Grand Hyatt Paris"
                value={manualName}
                onChange={(e) => setManualName(e.target.value)}
              />
            </div>

            <div className="hps-field hps-field--relative">
              <label className="hps-label">
                Address {geocoding && <span className="hps-geocoding-indicator">searching...</span>}
              </label>
              <input
                className="hps-input"
                type="text"
                placeholder="Search address or click on the map"
                value={manualAddress}
                onChange={(e) => { setManualAddress(e.target.value); setSuggestionsOpen(true); }}
                onFocus={() => suggestions.length > 0 && setSuggestionsOpen(true)}
                autoComplete="off"
              />
              {suggestionsOpen && suggestions.length > 0 && (
                <ul className="hps-suggestions">
                  {suggestions.map((f, i) => (
                    <li key={i} className="hps-suggestion-item" onMouseDown={() => pickSuggestion(f)}>
                      <span className="hps-suggestion-main">{f.text}</span>
                      <span className="hps-suggestion-sub">{f.place_name?.replace(f.text + ', ', '')}</span>
                    </li>
                  ))}
                </ul>
              )}
            </div>

          </div>

          <div className="hps-minimap-wrap">
            <div className="hps-minimap-hint">
              {manualCoords ? '📍 Pin placed — click to adjust' : 'Click on the map to place your hotel pin'}
            </div>
            <div className="hps-minimap" onClick={() => setSuggestionsOpen(false)}>
              {MAPBOX_TOKEN && (
                <Map
                  {...viewport}
                  onMove={(e) => setViewport(e.viewState)}
                  onClick={handleMapClick}
                  mapboxAccessToken={MAPBOX_TOKEN}
                  mapStyle="mapbox://styles/mapbox/streets-v12"
                  style={{ width: '100%', height: '100%' }}
                  cursor="crosshair"
                >
                  {manualCoords && (
                    <Marker latitude={manualCoords.lat} longitude={manualCoords.lon} anchor="bottom">
                      <div className="hps-map-pin" aria-hidden>
                        <HotelIcon size={18} className="hps-map-pin-icon" title="Hotel" />
                      </div>
                    </Marker>
                  )}
                </Map>
              )}
              {!MAPBOX_TOKEN && (
                <div className="hps-minimap-unavailable">Map unavailable</div>
              )}
            </div>
          </div>

          <div className="hps-manual-footer">
            <button
              className="hps-save-btn"
              disabled={!manualName.trim() || saving}
              onClick={handleSave}
            >
              {saving ? 'Saving...' : 'Save Hotel'}
            </button>
          </div>
        </div>

      </div>
    </div>
  );
}
