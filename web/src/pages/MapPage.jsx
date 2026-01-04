// src/pages/MapPage.jsx
import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { Layout, Button, Card, Avatar, Tooltip } from "antd";
import {
  LogoutOutlined,
  UserOutlined,
  GlobalOutlined,
  CompassOutlined,
  HeatMapOutlined,
  UnorderedListOutlined,
  CloseOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";

import Map, { NavigationControl, GeolocateControl, Marker, Source, Layer } from "react-map-gl";

import { auth } from "../firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";

const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
  longitude: 32.8597,
  latitude: 39.9334,
  zoom: 11,
  bearing: 0,
  pitch: 0,
};

const STYLES = [
  "mapbox://styles/mapbox/outdoors-v12",
  "mapbox://styles/mapbox/streets-v12",
  "mapbox://styles/mapbox/navigation-preview-night-v4",
  "mapbox://styles/mapbox/satellite-streets-v12",
  "mapbox://styles/mapbox/monochrome",
];

const BACKEND_BASE_URL = "http://165.232.69.83:9002";

function normalizeCategory(raw) {
  return String(raw || "").trim().toLowerCase();
}

const UI_CATEGORIES = [
  {
    key: "restaurant",
    label: "Restaurants",
    geo: "catering.restaurant",
    aliases: ["restaurant", "restaurants", "catering.restaurant"],
    emoji: "🍽️",
    ring: "#FFB020",
    fill: "#FFF7E6",
    pill: "#FFF3E0",
  },
  {
    key: "cafe",
    label: "Cafes",
    geo: "catering.cafe",
    aliases: ["cafe", "cafes", "catering.cafe"],
    emoji: "☕",
    ring: "#6F4E37",
    fill: "#F5F5DC",
    pill: "#EFEBE9",
  },
  {
    key: "museum",
    label: "Museums",
    geo: "entertainment.museum",
    aliases: ["museum", "museums", "entertainment.museum"],
    emoji: "🖼️",
    ring: "#9B51E0",
    fill: "#F3EBFF",
    pill: "#F3EBFF",
  },
  {
    key: "monuments",
    label: "Monuments",
    geo: "tourism.attraction",
    aliases: ["monument", "monuments", "tourism.attraction"],
    emoji: "🏛️",
    ring: "#FF7A45",
    fill: "#FFF1E8",
    pill: "#FFF1E8",
  },
  {
    key: "parks",
    label: "Parks",
    geo: "leisure.park",
    aliases: ["park", "parks", "leisure.park"],
    emoji: "🌿",
    ring: "#27AE60",
    fill: "#E9F9EF",
    pill: "#E9F9EF",
  },
];

function poiIconByCategory(category) {
  const c = normalizeCategory(category);
  const found = UI_CATEGORIES.find((x) => x.aliases.includes(c));
  if (!found) return null;
  return { emoji: found.emoji, ring: found.ring, fill: found.fill, uiKey: found.key };
}

function labelByCategory(category) {
  const icon = poiIconByCategory(category);
  if (!icon) return null;
  const found = UI_CATEGORIES.find((x) => x.key === icon.uiKey);
  return found?.label || null;
}

function getSafePoiTitle(p) {
  const name = (p?.name && String(p.name).trim()) || "";
  if (name) return name;

  const label = labelByCategory(p?.category);
  if (label) return label;

  const cat = (p?.category && String(p.category).trim()) || "";
  if (cat) return cat;

  return "Place";
}

function isPointInsidePolygon(lat, lng, polygonLatLng) {
  if (!polygonLatLng || polygonLatLng.length < 3) return false;
  let inside = false;
  for (let i = 0, j = polygonLatLng.length - 1; i < polygonLatLng.length; j = i++) {
    const xi = polygonLatLng[i].lng,
      yi = polygonLatLng[i].lat;
    const xj = polygonLatLng[j].lng,
      yj = polygonLatLng[j].lat;
    const intersect =
      yi > lat !== yj > lat && lng < ((xj - xi) * (lat - yi)) / (yj - yi + 0.0) + xi;
    if (intersect) inside = !inside;
  }
  return inside;
}

export default function MapPage() {
  const navigate = useNavigate();
  const mapRef = useRef(null);

  const [user, setUser] = useState(null);
  const [loadingAuth, setLoadingAuth] = useState(true);

  const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);
  const [styleIndex, setStyleIndex] = useState(1);
  const [is3D, setIs3D] = useState(false);

  const [mode, setMode] = useState("VIEWPORT"); // VIEWPORT | SELECTION
  const [selection, setSelection] = useState({ mode: null, polygon: [] });

  const [freehandEnabled, setFreehandEnabled] = useState(false);
  const drawingRef = useRef({ isDown: false, points: [] });

  const [previewLine, setPreviewLine] = useState(null);

  const [poisRaw, setPoisRaw] = useState([]);
  const [poiLoading, setPoiLoading] = useState(false);

  const [filterOpen, setFilterOpen] = useState(true);

  const [selectedCats, setSelectedCats] = useState(() => {
    const all = {};
    UI_CATEGORIES.forEach((c) => (all[c.key] = true));
    return all;
  });

  const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;
  const mapStyle = useMemo(() => STYLES[styleIndex], [styleIndex]);

  // ✅ Backend categories: restaurant/cafe/museum/monuments/parks
  const selectedBackendCats = useMemo(() => {
    return UI_CATEGORIES.filter((c) => selectedCats[c.key]).map((c) => c.key);
  }, [selectedCats]);

  const previewGeoJSON = useMemo(
    () => ({ type: "FeatureCollection", features: previewLine ? [previewLine] : [] }),
    [previewLine]
  );

  const selectionGeoJSON = useMemo(() => {
    if (selection?.mode !== "polygon" || !selection.polygon?.length) {
      return { type: "FeatureCollection", features: [] };
    }
    const ring = [...selection.polygon, selection.polygon[0]].map((p) => [p.lng, p.lat]);
    return {
      type: "FeatureCollection",
      features: [{ type: "Feature", properties: {}, geometry: { type: "Polygon", coordinates: [ring] } }],
    };
  }, [selection]);

  const selectionOutlineGeoJSON = useMemo(() => {
    if (selection?.mode !== "polygon" || selection.polygon.length < 2) {
      return { type: "FeatureCollection", features: [] };
    }
    const coords = selection.polygon.map((p) => [p.lng, p.lat]);
    coords.push([selection.polygon[0].lng, selection.polygon[0].lat]);
    return {
      type: "FeatureCollection",
      features: [{ type: "Feature", properties: {}, geometry: { type: "LineString", coordinates: coords } }],
    };
  }, [selection]);

  const previewGlowLayer = useMemo(
    () => ({
      id: "preview-glow",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-width": 10, "line-opacity": 0.22, "line-color": "#7DD3FC", "line-blur": 2.2 },
    }),
    []
  );

  const previewMainLayer = useMemo(
    () => ({
      id: "preview-main",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 4,
        "line-opacity": 0.95,
        "line-gradient": [
          "interpolate",
          ["linear"],
          ["line-progress"],
          0.0,
          "#22C55E",
          0.5,
          "#60A5FA",
          1.0,
          "#A78BFA",
        ],
      },
    }),
    []
  );

  const selectionFillLayer = useMemo(
    () => ({ id: "sel-fill", type: "fill", paint: { "fill-color": "#60A5FA", "fill-opacity": 0.1 } }),
    []
  );

  const selectionOutlineGlowLayer = useMemo(
    () => ({
      id: "sel-outline-glow",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: { "line-width": 10, "line-opacity": 0.18, "line-color": "#93C5FD", "line-blur": 2.0 },
    }),
    []
  );

  const selectionOutlineMainLayer = useMemo(
    () => ({
      id: "sel-outline-main",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 4,
        "line-opacity": 0.95,
        "line-gradient": [
          "interpolate",
          ["linear"],
          ["line-progress"],
          0.0,
          "#22C55E",
          0.55,
          "#60A5FA",
          1.0,
          "#A78BFA",
        ],
      },
    }),
    []
  );

  // AUTH
  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
        navigate("/login");
        return;
      }
      setUser(currentUser);
      setLoadingAuth(false);
    });
    return () => unsub();
  }, [navigate]);

  const handleLogout = useCallback(async () => {
    try {
      await signOut(auth);
      navigate("/login");
    } catch (e) {
      console.error(e);
    }
  }, [navigate]);

  const getViewportBbox = useCallback(() => {
    const map = mapRef.current?.getMap?.();
    if (!map) return null;
    const b = map.getBounds();
    const sw = b.getSouthWest();
    const ne = b.getNorthEast();
    return { minLat: sw.lat, minLng: sw.lng, maxLat: ne.lat, maxLng: ne.lng };
  }, []);

  /**
   * ✅ Backend DTO uyumu:
   * selectionType: "BBOX" | "POLYGON"
   * bbox: {minLat,minLng,maxLat,maxLng} (BBOX)
   * polygon: [{lat,lng}] (POLYGON)
   * categories: null/empty => filtre yok
   * sort: "RATING_DESC"
   */
  const fetchPois = useCallback(
    async ({ selectionType, bbox, polygon, categoriesOverride }) => {
      try {
        setPoiLoading(true);

        const body = {
          selectionType,
          bbox: selectionType === "BBOX" ? bbox : null,
          polygon: selectionType === "POLYGON" ? polygon : null,
          categories:
            categoriesOverride !== undefined ? categoriesOverride : selectedBackendCats, // ✅ override varsa onu gönder
          page: 0,
          limit: 200,
          sort: "RATING_DESC",
        };

        const res = await fetch(`${BACKEND_BASE_URL}/pois/search-in-area`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });

        if (!res.ok) {
          setPoisRaw([]);
          return;
        }

        const data = await res.json();
        setPoisRaw(Array.isArray(data?.pois) ? data.pois : []);
      } catch (e) {
        console.error(e);
        setPoisRaw([]);
      } finally {
        setPoiLoading(false);
      }
    },
    [selectedBackendCats]
  );

  // Debounce viewport fetch
  const debounceRef = useRef(null);

  const scheduleViewportFetch = useCallback(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);

    debounceRef.current = setTimeout(() => {
      if (mode !== "VIEWPORT") return;

      const bbox = getViewportBbox();
      if (bbox) fetchPois({ selectionType: "BBOX", bbox });
    }, 500);
  }, [mode, fetchPois, getViewportBbox]);

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  // İlk yükleme
  useEffect(() => {
    if (!MAPBOX_TOKEN || !user) return;

    const t = setTimeout(() => {
      if (mode !== "VIEWPORT") return;
      const bbox = getViewportBbox();
      if (bbox) fetchPois({ selectionType: "BBOX", bbox });
    }, 600);

    return () => clearTimeout(t);
  }, [MAPBOX_TOKEN, user, mode, getViewportBbox, fetchPois]);

  // Kategori değişince (VIEWPORT’ta) refetch
  useEffect(() => {
    if (!MAPBOX_TOKEN || !user) return;
    if (mode !== "VIEWPORT") return;

    const bbox = getViewportBbox();
    if (bbox) fetchPois({ selectionType: "BBOX", bbox });
  }, [selectedBackendCats, MAPBOX_TOKEN, user, mode, getViewportBbox, fetchPois]);

  const startFreehand = useCallback(() => {
    setMode("SELECTION");
    setFreehandEnabled(true);
    setFilterOpen(false);
    drawingRef.current = { isDown: false, points: [] };
    setPreviewLine(null);
    setSelection({ mode: null, polygon: [] });
  }, []);

  // ✅ Reset Area: filtreyi kaldırıp tüm POI’leri geri getir
  const clearSelectionOnly = useCallback(async () => {
    setFreehandEnabled(false);
    setPreviewLine(null);
    setSelection({ mode: null, polygon: [] });
    setMode("VIEWPORT");

    const bbox = getViewportBbox();
    if (bbox) {
      // ✅ categories: [] => backend "filtre yok"
      await fetchPois({ selectionType: "BBOX", bbox, categoriesOverride: [] });
    }

    setFilterOpen(true);
  }, [fetchPois, getViewportBbox]);

  const onMouseDownFreehand = useCallback(
    (e) => {
      if (!freehandEnabled) return;
      drawingRef.current.isDown = true;
      drawingRef.current.points = [{ lng: e.lngLat.lng, lat: e.lngLat.lat }];
      setPreviewLine({
        type: "Feature",
        properties: {},
        geometry: { type: "LineString", coordinates: [[e.lngLat.lng, e.lngLat.lat]] },
      });
    },
    [freehandEnabled]
  );

  const onMouseMoveFreehand = useCallback(
    (e) => {
      if (!freehandEnabled || !drawingRef.current.isDown) return;
      drawingRef.current.points.push({ lng: e.lngLat.lng, lat: e.lngLat.lat });
      setPreviewLine({
        type: "Feature",
        properties: {},
        geometry: { type: "LineString", coordinates: drawingRef.current.points.map((p) => [p.lng, p.lat]) },
      });
    },
    [freehandEnabled]
  );

  const onMouseUpFreehand = useCallback(async () => {
    if (!freehandEnabled || !drawingRef.current.isDown) return;

    drawingRef.current.isDown = false;
    const pts = drawingRef.current.points;

    setPreviewLine(null);
    setFreehandEnabled(false);

    if (pts.length < 3) {
      setSelection({ mode: null, polygon: [] });
      setMode("VIEWPORT");
      return;
    }

    const poly = pts.map((p) => ({ lat: p.lat, lng: p.lng }));
    setSelection({ mode: "polygon", polygon: poly });

    await fetchPois({ selectionType: "POLYGON", polygon: poly });
    setFilterOpen(true);
  }, [freehandEnabled, fetchPois]);

  const handleToggle2D3D = useCallback(() => {
    const nextIs3D = !is3D;
    setIs3D(nextIs3D);

    const map = mapRef.current?.getMap?.();
    if (map) map.easeTo({ pitch: nextIs3D ? 60 : 0, duration: 650 });

    setViewState((prev) => ({ ...prev, pitch: nextIs3D ? 60 : 0 }));
  }, [is3D]);

  // POI'ler: polygon içi filtre + UI filtre
  const pois = useMemo(() => {
    let list = poisRaw;

    if (mode === "SELECTION" && selection?.mode === "polygon" && selection.polygon.length >= 3) {
      list = list.filter((p) => isPointInsidePolygon(p.latitude, p.longitude, selection.polygon));
    }

    const activeKeys = new Set(UI_CATEGORIES.filter((c) => selectedCats[c.key]).map((c) => c.key));

    return list.filter((p) => {
      const icon = poiIconByCategory(p.category);
      if (!icon) return true; // POI silme
      return activeKeys.has(icon.uiKey);
    });
  }, [poisRaw, mode, selection, selectedCats]);

  if (loadingAuth || !user) return null;

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 20px",
          background: "#fff",
          borderBottom: "1px solid #f0f0f0",
          position: "fixed",
          width: "100%",
          zIndex: 100,
        }}
      >
        <div style={{ display: "flex", alignItems: "center" }}>
          <GlobalOutlined style={{ fontSize: 24, color: "#1890ff", marginRight: 10 }} />
          <span style={{ fontSize: 20, fontWeight: 700 }}>Vacanza Map</span>
        </div>
        <Button icon={<LogoutOutlined />} onClick={handleLogout}>
          Log Out
        </Button>
      </Header>

      <Content style={{ marginTop: 64, padding: 24, position: "relative" }}>
        <div
          style={{
            height: "calc(100vh - 88px)",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
            background: "#f5f5f5",
            position: "relative",
          }}
        >
          <Map
            ref={mapRef}
            {...viewState}
            onMove={(e) => setViewState(e.viewState)}
            onMoveEnd={() => {
              if (mode === "VIEWPORT" && !freehandEnabled) scheduleViewportFetch();
            }}
            style={{ width: "100%", height: "100%" }}
            mapStyle={mapStyle}
            mapboxAccessToken={MAPBOX_TOKEN}
            attributionControl={false}
            onMouseDown={onMouseDownFreehand}
            onMouseMove={onMouseMoveFreehand}
            onMouseUp={onMouseUpFreehand}
            dragPan={!freehandEnabled}
            cursor={freehandEnabled ? "crosshair" : "grab"}
          >
            <NavigationControl position="bottom-right" showCompass={false} />
            <GeolocateControl position="bottom-right" />

            {freehandEnabled && (
              <Source id="p-src" type="geojson" data={previewGeoJSON} lineMetrics>
                <Layer {...previewGlowLayer} />
                <Layer {...previewMainLayer} />
              </Source>
            )}

            {selection?.mode === "polygon" && (
              <>
                <Source id="f-src" type="geojson" data={selectionGeoJSON}>
                  <Layer {...selectionFillLayer} />
                </Source>
                <Source id="o-src" type="geojson" data={selectionOutlineGeoJSON} lineMetrics>
                  <Layer {...selectionOutlineGlowLayer} />
                  <Layer {...selectionOutlineMainLayer} />
                </Source>
              </>
            )}

            {pois.map((p) => {
              const icon = poiIconByCategory(p.category);
              const title = getSafePoiTitle(p);

              const ring = icon?.ring || "#64748B";
              const fill = icon?.fill || "#F1F5F9";
              const emoji = icon?.emoji || "📍";

              return (
                <Marker key={p.poiId || `${p.latitude}-${p.longitude}`} longitude={p.longitude} latitude={p.latitude} anchor="center">
                  <Tooltip title={title} placement="top">
                    <div
                      style={{
                        width: 34,
                        height: 34,
                        borderRadius: 999,
                        display: "grid",
                        placeItems: "center",
                        background: fill,
                        border: `2px solid ${ring}`,
                        boxShadow: "0 4px 10px rgba(0,0,0,0.15)",
                        cursor: "pointer",
                      }}
                    >
                      <span style={{ fontSize: 16 }}>{emoji}</span>
                    </div>
                  </Tooltip>
                </Marker>
              );
            })}
          </Map>

          <div style={{ position: "absolute", top: 18, right: 18, zIndex: 60, display: "flex", flexDirection: "column", gap: 10 }}>
            <Tooltip title="Draw Area" placement="left">
              <Button shape="circle" onClick={startFreehand} disabled={poiLoading} style={{ width: 48, height: 48, border: freehandEnabled ? "2px solid #1890ff" : "none" }}>
                ✏️
              </Button>
            </Tooltip>

            <Button shape="circle" icon={<UnorderedListOutlined />} onClick={() => setFilterOpen((v) => !v)} style={{ width: 48, height: 48 }} />

            <Button shape="circle" icon={<CompassOutlined />} onClick={handleToggle2D3D} style={{ width: 48, height: 48, color: is3D ? "#1890ff" : "#555" }} />

            <Button shape="circle" icon={<HeatMapOutlined />} onClick={() => setStyleIndex((i) => (i + 1) % STYLES.length)} style={{ width: 48, height: 48 }} />
          </div>

          {filterOpen && (
            <div style={{ position: "absolute", top: 28, right: 78, zIndex: 70, width: 280, background: "rgba(255,255,255,0.95)", borderRadius: 16, boxShadow: "0 10px 30px rgba(0,0,0,0.1)", padding: 14 }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10 }}>
                <b>Filter {poiLoading ? " • Loading..." : ""}</b>
                <Button type="text" icon={<CloseOutlined />} onClick={() => setFilterOpen(false)} />
              </div>

              <div style={{ display: "flex", gap: 8, marginBottom: 10 }}>
                <Button size="small" onClick={clearSelectionOnly} disabled={poiLoading}>
                  Reset Area
                </Button>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                {UI_CATEGORIES.map((c) => (
                  <button
                    key={c.key}
                    onClick={() => setSelectedCats((prev) => ({ ...prev, [c.key]: !prev[c.key] }))}
                    disabled={poiLoading}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 10,
                      padding: 10,
                      borderRadius: 10,
                      border: selectedCats[c.key] ? `2px solid ${c.ring}` : "1px solid #eee",
                      background: selectedCats[c.key] ? c.pill : "#fff",
                      cursor: poiLoading ? "not-allowed" : "pointer",
                      opacity: poiLoading ? 0.7 : 1,
                    }}
                  >
                    <span style={{ width: 24, height: 24, borderRadius: 12, background: c.fill, display: "grid", placeItems: "center", border: `1px solid ${c.ring}` }}>
                      {c.emoji}
                    </span>
                    <b>{c.label}</b>
                  </button>
                ))}
              </div>
            </div>
          )}

          <Card style={{ position: "absolute", top: 20, left: 20, zIndex: 50, width: 280, borderRadius: 16 }}>
            <div style={{ display: "flex", alignItems: "center" }}>
              <Avatar size={48} icon={<UserOutlined />} src={user.photoURL} style={{ marginRight: 12, backgroundColor: "#1890ff" }} />
              <div>
                <div style={{ fontWeight: 700 }}>{user.displayName || "User"}</div>
                <div style={{ fontSize: 12, color: "#888" }}>{user.email}</div>
              </div>
            </div>
          </Card>
        </div>
      </Content>

      <Footer style={{ textAlign: "center", padding: "12px 50px", background: "#fff" }}>
        Vacanza App ©{new Date().getFullYear()}
      </Footer>
    </Layout>
  );
}
