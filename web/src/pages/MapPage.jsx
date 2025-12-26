import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { Layout, Button, Card, Avatar, Tooltip } from "antd";
import {
  LogoutOutlined,
  UserOutlined,
  GlobalOutlined,
  CompassOutlined,
  HeatMapOutlined,
  EditOutlined,
} from "@ant-design/icons";
import { useNavigate } from "react-router-dom";

import Map, { NavigationControl, GeolocateControl, Source, Layer } from "react-map-gl";

import MapboxDraw from "@mapbox/mapbox-gl-draw";
import "@mapbox/mapbox-gl-draw/dist/mapbox-gl-draw.css";

import { auth } from "../firebase";
import { onAuthStateChanged, signOut } from "firebase/auth";

const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
  longitude: 32.8597,
  latitude: 39.9334,
  zoom: 8,
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

/**
 * ✅ Daha "Figma" kalem cursor:
 * - küçük
 * - açık stroke
 * - hafif gölge
 */
const PEN_CURSOR_SVG = encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32">
  <defs>
    <filter id="ds" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="1" stdDeviation="1" flood-color="#000" flood-opacity="0.20"/>
    </filter>
    <linearGradient id="g" x1="0" x2="1">
      <stop offset="0" stop-color="#7DD3FC"/>
      <stop offset="1" stop-color="#A78BFA"/>
    </linearGradient>
  </defs>

  <g filter="url(#ds)" transform="translate(9,6) rotate(-25 7 7)">
    <!-- body -->
    <path d="M2 14 L2 10 L12 0 L16 4 L6 14 Z"
          fill="white" stroke="#CBD5E1" stroke-width="1" />
    <!-- gradient cap -->
    <path d="M12 0 L14 -2 L18 2 L16 4 Z" fill="url(#g)" stroke="#CBD5E1" stroke-width="1"/>
    <!-- tip -->
    <path d="M2 14 L6 14 L2 10 Z" fill="#E2E8F0" stroke="#CBD5E1" stroke-width="1"/>
  </g>
</svg>
`);
const PEN_CURSOR = `url("data:image/svg+xml,${PEN_CURSOR_SVG}") 6 26, auto`;

export default function MapPage() {
  const navigate = useNavigate();
  const mapRef = useRef(null);
  const drawRef = useRef(null);

  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const [viewState, setViewState] = useState(INITIAL_VIEW_STATE);
  const [styleIndex, setStyleIndex] = useState(1);
  const [is3D, setIs3D] = useState(false);

  const [selection, setSelection] = useState({ mode: null, polygon: [] });

  const [freehandEnabled, setFreehandEnabled] = useState(false);
  const drawingRef = useRef({ isDown: false, points: [] });
  const [previewLine, setPreviewLine] = useState(null);

  const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;
  const mapStyle = useMemo(() => STYLES[styleIndex], [styleIndex]);

  // ✅ preview data
  const previewGeoJSON = useMemo(() => {
    return { type: "FeatureCollection", features: previewLine ? [previewLine] : [] };
  }, [previewLine]);

  /**
   * ✅ ÇİZGİYİ AÇTIK / PASTEL YAPTIK
   * - glow daha az opak
   * - ana çizgi daha ince + daha açık
   * - gradient pastel tonlar
   */
  const previewGlowLayer = useMemo(
    () => ({
      id: "preview-glow",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 14,        // biraz geniş ama
        "line-opacity": 0.12,    // çok hafif
        "line-blur": 3.2,
        "line-color": "#93C5FD", // açık mavi glow
      },
    }),
    []
  );

  const previewGradientLayer = useMemo(
    () => ({
      id: "preview-gradient",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 4.2,       // daha ince
        "line-opacity": 0.78,    // koyu değil
        "line-gradient": [
          "interpolate",
          ["linear"],
          ["line-progress"],
          0.0, "#A5F3FC",   // pastel cyan
          0.35, "#93C5FD",  // pastel blue
          0.7, "#C4B5FD",   // pastel purple
          1.0, "#86EFAC",   // pastel green
        ],
      },
    }),
    []
  );

  // Draw yükleme (final polygon)
  const onMapLoad = useCallback(() => {
    const draw = new MapboxDraw({
      displayControlsDefault: false,
      userProperties: true,
      styles: [
        {
          id: "gl-draw-polygon-fill",
          type: "fill",
          filter: ["all", ["==", "$type", "Polygon"]],
          paint: { "fill-color": "#60A5FA", "fill-opacity": 0.10 }, // daha yumuşak
        },
        {
          id: "gl-draw-polygon-stroke",
          type: "line",
          filter: ["all", ["==", "$type", "Polygon"]],
          layout: { "line-cap": "round", "line-join": "round" },
          paint: { "line-color": "#60A5FA", "line-width": 2.2, "line-opacity": 0.75 },
        },
      ],
    });

    if (mapRef.current) {
      mapRef.current.addControl(draw);
      drawRef.current = draw;
    }
  }, []);

  const updateSelection = useCallback(() => {
    if (!drawRef.current) return;
    const data = drawRef.current.getAll();
    if (!data?.features?.length) return;

    const poly = data.features.find((f) => f.geometry?.type === "Polygon");
    if (!poly) return;

    const coords = poly.geometry.coordinates[0].map((c) => ({ lat: c[1], lng: c[0] }));
    setSelection({ mode: "polygon", polygon: coords });
  }, []);

  const buildPolygonFromPoints = useCallback((pts) => {
    if (!pts || pts.length < 3) return null;
    const ring = [...pts, pts[0]].map((p) => [p.lng, p.lat]);
    return { type: "Feature", properties: {}, geometry: { type: "Polygon", coordinates: [ring] } };
  }, []);

  const buildLineFromPoints = useCallback((pts) => {
    if (!pts || pts.length < 2) return null;
    return {
      type: "Feature",
      properties: { preview: true },
      geometry: { type: "LineString", coordinates: pts.map((p) => [p.lng, p.lat]) },
    };
  }, []);

  const startFreehand = useCallback(() => {
    drawRef.current?.deleteAll();
    setSelection({ mode: null, polygon: [] });
    setPreviewLine(null);

    setFreehandEnabled(true);
    drawingRef.current = { isDown: false, points: [] };
  }, []);

  const stopFreehand = useCallback(() => {
    setFreehandEnabled(false);
    drawingRef.current = { isDown: false, points: [] };
  }, []);

  const onMouseDownFreehand = useCallback(
    (e) => {
      if (!freehandEnabled) return;
      e.originalEvent?.preventDefault?.();
      e.originalEvent?.stopPropagation?.();

      drawingRef.current.isDown = true;
      drawingRef.current.points = [];

      const { lngLat } = e;
      drawingRef.current.points.push({ lng: lngLat.lng, lat: lngLat.lat });
      setPreviewLine(buildLineFromPoints(drawingRef.current.points));
    },
    [freehandEnabled, buildLineFromPoints]
  );

  const onMouseMoveFreehand = useCallback(
    (e) => {
      if (!freehandEnabled) return;
      if (!drawingRef.current.isDown) return;

      const { lngLat } = e;
      const last = drawingRef.current.points[drawingRef.current.points.length - 1];

      const dist = last ? Math.hypot(lngLat.lng - last.lng, lngLat.lat - last.lat) : Infinity;

      if (dist > 0.00025) {
        drawingRef.current.points.push({ lng: lngLat.lng, lat: lngLat.lat });
        setPreviewLine(buildLineFromPoints(drawingRef.current.points));
      }
    },
    [freehandEnabled, buildLineFromPoints]
  );

  const onMouseUpFreehand = useCallback(() => {
    if (!freehandEnabled) return;
    if (!drawingRef.current.isDown) return;

    drawingRef.current.isDown = false;

    const feature = buildPolygonFromPoints(drawingRef.current.points);
    setPreviewLine(null);

    if (!feature) {
      drawRef.current?.deleteAll();
      setSelection({ mode: null, polygon: [] });
      stopFreehand();
      return;
    }

    drawRef.current?.deleteAll();
    drawRef.current?.add(feature);

    updateSelection();
    stopFreehand();
  }, [freehandEnabled, buildPolygonFromPoints, updateSelection, stopFreehand]);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (currentUser) => {
      if (!currentUser) {
        navigate("/login");
        return;
      }
      setUser(currentUser);
      setLoading(false);
    });
    return () => unsub();
  }, [navigate]);

  const handleLogout = async () => {
    try {
      await signOut(auth);
      navigate("/login");
    } catch (e) {
      console.error(e);
    }
  };

  const handleMapStyleChange = () => setStyleIndex((prev) => (prev + 1) % STYLES.length);

  const handleToggle2D3D = () => {
    const nextIs3D = !is3D;
    setIs3D(nextIs3D);
    const nextPitch = nextIs3D ? 60 : 0;

    try {
      const map = mapRef.current?.getMap?.();
      if (map) map.easeTo({ pitch: nextPitch, bearing: 0, duration: 650 });
    } catch (e) {
      console.error("2D/3D easeTo error:", e);
    }

    setViewState((prev) => ({ ...prev, pitch: nextPitch, bearing: 0 }));
  };

  if (loading) {
    return <div style={{ height: "100vh", display: "grid", placeItems: "center" }}>Loading...</div>;
  }
  if (!user) return null;

  const displayName = user.displayName || user.email?.split("@")?.[0] || "User";
  const userEmail = user.email || "";

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
          <span style={{ fontSize: 20, fontWeight: 700, color: "#333" }}>Vacanza Map</span>
        </div>

        <Button type="default" icon={<LogoutOutlined />} onClick={handleLogout}>
          Log Out
        </Button>
      </Header>

      <Content style={{ marginTop: 64, padding: 24, position: "relative", flexGrow: 1 }}>
        <div
          style={{
            height: "calc(100vh - 88px)",
            width: "100%",
            borderRadius: 12,
            overflow: "hidden",
            boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
            background: "#f5f5f5",
            position: "relative",
          }}
        >
          {!MAPBOX_TOKEN ? (
            <div style={{ height: "100%", display: "grid", placeItems: "center" }}>
              Mapbox token not found. <br />
              Add <b>VITE_MAPBOX_ACCESS_TOKEN=...</b> to `.env` and restart dev server.
            </div>
          ) : (
            <Map
              ref={mapRef}
              {...viewState}
              onMove={(e) => setViewState(e.viewState)}
              style={{ width: "100%", height: "100%" }}
              mapStyle={mapStyle}
              mapboxAccessToken={MAPBOX_TOKEN}
              attributionControl={false}
              onLoad={onMapLoad}
              onDrawCreate={updateSelection}
              onDrawUpdate={updateSelection}
              onMouseDown={onMouseDownFreehand}
              onMouseMove={onMouseMoveFreehand}
              onMouseUp={onMouseUpFreehand}
              onTouchStart={onMouseDownFreehand}
              onTouchMove={onMouseMoveFreehand}
              onTouchEnd={onMouseUpFreehand}
              dragPan={!freehandEnabled}
              dragRotate={!freehandEnabled}
              cursor={freehandEnabled ? PEN_CURSOR : "grab"}
              onError={(e) => console.error("Map error:", e)}
            >
              {freehandEnabled && (
                <Source id="freehand-preview-source" type="geojson" data={previewGeoJSON} lineMetrics>
                  <Layer {...previewGlowLayer} />
                  <Layer {...previewGradientLayer} />
                </Source>
              )}

              <NavigationControl position="bottom-right" showCompass={false} />
              <GeolocateControl position="bottom-right" trackUserLocation />
            </Map>
          )}

          {/* SAĞ ÜST ARAÇLAR */}
          <div
            style={{
              position: "absolute",
              top: 18,
              right: 18,
              zIndex: 60,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 10,
            }}
          >
            <Tooltip title="Elle Alan Çiz (Live)" placement="left">
              <Button
                shape="circle"
                icon={<EditOutlined />}
                onClick={startFreehand}
                style={{
                  width: 48,
                  height: 48,
                  background: "#fff",
                  boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
                  border: freehandEnabled ? "2px solid #60A5FA" : "1px solid #e5e7eb",
                }}
              />
            </Tooltip>

            <div style={{ margin: "5px 0", height: "1px", width: "30px", background: "#eee" }} />

            <button
              type="button"
              onClick={handleToggle2D3D}
              style={{
                width: 48,
                height: 48,
                borderRadius: "999px",
                border: is3D ? "2px solid #60A5FA" : "1px solid #e5e7eb",
                background: "#fff",
                boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
                display: "grid",
                placeItems: "center",
                cursor: "pointer",
              }}
              aria-label="2D / 3D Toggle"
              title="2D / 3D"
            >
              <CompassOutlined style={{ fontSize: 20, color: is3D ? "#60A5FA" : "#555" }} />
            </button>

            <Button
              shape="circle"
              icon={<HeatMapOutlined />}
              onClick={handleMapStyleChange}
              style={{
                width: 48,
                height: 48,
                background: "#fff",
                boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
                border: "1px solid #e5e7eb",
              }}
              title="Change Map Style"
            />
          </div>

          {/* USER CARD */}
          <Card
            style={{
              position: "absolute",
              top: 40,
              left: 40,
              zIndex: 50,
              width: 290,
              backgroundColor: "rgba(255,255,255,0.95)",
              backdropFilter: "blur(10px)",
              borderRadius: 16,
            }}
            bodyStyle={{ display: "flex", alignItems: "center", padding: 16 }}
          >
            <Avatar
              size={48}
              icon={<UserOutlined />}
              src={user.photoURL}
              style={{ marginRight: 15, backgroundColor: "#60A5FA" }}
            />
            <div style={{ minWidth: 0 }}>
              <div style={{ fontWeight: 700, fontSize: 16 }}>{displayName}</div>
              <div style={{ fontSize: 12, color: "#888" }}>{userEmail}</div>

              {selection.mode === "polygon" && (
                <div style={{ marginTop: 6, fontSize: 12, color: "#666" }}>
                  Selected area points: {selection.polygon.length}
                </div>
              )}
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
