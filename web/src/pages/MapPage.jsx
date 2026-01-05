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

// Results panel haritayı kapatmasın diye padding hesabında kullanıyoruz
const RESULTS_PANEL_APPROX_HEIGHT_DESKTOP = 320;
const FILTER_PANEL_APPROX_WIDTH_DESKTOP = 320;

function useIsMobile(breakpoint = 768) {
  const [isMobile, setIsMobile] = useState(() => window.innerWidth <= breakpoint);
  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth <= breakpoint);
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [breakpoint]);
  return isMobile;
}

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

// "Unnamed" gelenleri kategori label'ına çeviriyoruz (geçici çözüm)
function getSafePoiTitle(p) {
  const rawName = (p?.name && String(p.name).trim()) || "";
  const invalidNames = new Set(["unnamed", "unknown", "n/a", "na", "-", "null", "undefined", ""]);
  const normalizedName = rawName.toLowerCase();
  const hasValidName = rawName.length > 0 && !invalidNames.has(normalizedName);

  if (hasValidName) return rawName;

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

function polygonToBbox(poly) {
  let minLat = Infinity,
    minLng = Infinity,
    maxLat = -Infinity,
    maxLng = -Infinity;

  poly.forEach((p) => {
    minLat = Math.min(minLat, p.lat);
    minLng = Math.min(minLng, p.lng);
    maxLat = Math.max(maxLat, p.lat);
    maxLng = Math.max(maxLng, p.lng);
  });

  if (!isFinite(minLat)) return null;
  return { minLat, minLng, maxLat, maxLng };
}

/**
 * GERÇEK 3D:
 * - DEM terrain
 * - Sky
 * - 3D buildings (fill-extrusion)
 */
function ensureMapbox3D(map, enabled) {
  if (!map) return;

  const DEM_SOURCE_ID = "mapbox-dem";
  const SKY_LAYER_ID = "sky-layer";
  const BUILDING_LAYER_ID = "3d-buildings";

  const safeRemoveLayer = (id) => {
    if (map.getLayer(id)) map.removeLayer(id);
  };
  const safeRemoveSource = (id) => {
    if (map.getSource(id)) map.removeSource(id);
  };

  if (!enabled) {
    try {
      map.setTerrain(null);
    // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // ignore
    }
    safeRemoveLayer(SKY_LAYER_ID);
    safeRemoveLayer(BUILDING_LAYER_ID);
    safeRemoveSource(DEM_SOURCE_ID);
    return;
  }

  if (!map.getSource(DEM_SOURCE_ID)) {
    map.addSource(DEM_SOURCE_ID, {
      type: "raster-dem",
      url: "mapbox://mapbox.mapbox-terrain-dem-v1",
      tileSize: 512,
      maxzoom: 14,
    });
  }

  try {
    map.setTerrain({ source: DEM_SOURCE_ID, exaggeration: 1.2 });
  // eslint-disable-next-line no-unused-vars
  } catch (e) {
    // ignore
  }

  if (!map.getLayer(SKY_LAYER_ID)) {
    try {
      map.addLayer({
        id: SKY_LAYER_ID,
        type: "sky",
        paint: {
          "sky-type": "atmosphere",
          "sky-atmosphere-sun": [0.0, 0.0],
          "sky-atmosphere-sun-intensity": 8,
        },
      });
    // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // ignore
    }
  }

  if (!map.getLayer(BUILDING_LAYER_ID)) {
    try {
      const layers = map.getStyle()?.layers || [];
      const firstSymbolLayer = layers.find((l) => l.type === "symbol" && l.layout?.["text-field"]);
      const beforeId = firstSymbolLayer?.id;

      map.addLayer(
        {
          id: BUILDING_LAYER_ID,
          source: "composite",
          "source-layer": "building",
          filter: ["==", ["get", "extrude"], "true"],
          type: "fill-extrusion",
          minzoom: 13,
          paint: {
            "fill-extrusion-color": "#aaaaaa",
            "fill-extrusion-opacity": 0.65,
            "fill-extrusion-height": ["get", "height"],
            "fill-extrusion-base": ["get", "min_height"],
          },
        },
        beforeId
      );
    // eslint-disable-next-line no-unused-vars
    } catch (e) {
      // ignore
    }
  }

  try {
    map.setFog({
      "horizon-blend": 0.1,
      "space-color": "#000000",
      "star-intensity": 0.0,
    });
  // eslint-disable-next-line no-unused-vars
  } catch (e) {
    // ignore
  }
}

export default function MapPage() {
  const navigate = useNavigate();
  const mapRef = useRef(null);
  const isMobile = useIsMobile(768);

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

  const [resultsOpen, setResultsOpen] = useState(false);
  const [resultsTab, setResultsTab] = useState("all");

  // Results açılınca sağdaki filtre otomatik kapanır (çakışma yok)
  useEffect(() => {
    if (resultsOpen) setFilterOpen(false);
  }, [resultsOpen]);

  const MAPBOX_TOKEN = import.meta.env.VITE_MAPBOX_ACCESS_TOKEN;
  const mapStyle = useMemo(() => STYLES[styleIndex], [styleIndex]);

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
        "line-gradient": ["interpolate", ["linear"], ["line-progress"], 0.0, "#22C55E", 0.5, "#60A5FA", 1.0, "#A78BFA"],
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
        "line-gradient": ["interpolate", ["linear"], ["line-progress"], 0.0, "#22C55E", 0.55, "#60A5FA", 1.0, "#A78BFA"],
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

  const fetchPois = useCallback(
    async ({ selectionType, bbox, polygon, categoriesOverride }) => {
      try {
        setPoiLoading(true);

        const body = {
          selectionType,
          bbox: selectionType === "BBOX" ? bbox : null,
          polygon: selectionType === "POLYGON" ? polygon : null,
          categories: categoriesOverride !== undefined ? categoriesOverride : selectedBackendCats,
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
    setResultsOpen(false);
    setResultsTab("all");
    drawingRef.current = { isDown: false, points: [] };
    setPreviewLine(null);
    setSelection({ mode: null, polygon: [] });
  }, []);

  const clearSelectionOnly = useCallback(async () => {
    setFreehandEnabled(false);
    setPreviewLine(null);
    setSelection({ mode: null, polygon: [] });
    setMode("VIEWPORT");
    setResultsOpen(false);
    setResultsTab("all");

    const bbox = getViewportBbox();
    if (bbox) {
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
      setResultsOpen(false);
      setResultsTab("all");
      return;
    }

    const poly = pts.map((p) => ({ lat: p.lat, lng: p.lng }));
    setSelection({ mode: "polygon", polygon: poly });

    await fetchPois({ selectionType: "POLYGON", polygon: poly });
    setFilterOpen(true);

    setResultsOpen(true);
    setResultsTab("all");
  }, [freehandEnabled, fetchPois]);

  // 3D toggle: pitch + gerçek 3D layerlar
  const handleToggle2D3D = useCallback(() => {
    const nextIs3D = !is3D;
    setIs3D(nextIs3D);

    const map = mapRef.current?.getMap?.();
    if (map) {
      map.easeTo({ pitch: nextIs3D ? 60 : 0, duration: 650 });
      ensureMapbox3D(map, nextIs3D);
    }

    setViewState((prev) => ({ ...prev, pitch: nextIs3D ? 60 : 0 }));
  }, [is3D]);

  const handleStyleChange = useCallback(() => {
    setStyleIndex((i) => (i + 1) % STYLES.length);
  }, []);

  // Map load + style reload => 3D tekrar ekle
  const onMapLoad = useCallback(() => {
    const map = mapRef.current?.getMap?.();
    if (map) ensureMapbox3D(map, is3D);
  }, [is3D]);

  const onStyleData = useCallback(() => {
    const map = mapRef.current?.getMap?.();
    if (map) ensureMapbox3D(map, is3D);
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
      if (!icon) return true;
      return activeKeys.has(icon.uiKey);
    });
  }, [poisRaw, mode, selection, selectedCats]);

  const resultsPois = useMemo(() => {
    if (!resultsOpen) return [];
    if (!(selection?.mode === "polygon" && selection.polygon.length >= 3)) return [];
    if (resultsTab === "all") return pois;

    return pois.filter((p) => {
      const icon = poiIconByCategory(p.category);
      return icon?.uiKey === resultsTab;
    });
  }, [pois, resultsOpen, resultsTab, selection]);

  const canShowResultsPanel = useMemo(() => {
    return resultsOpen && selection?.mode === "polygon" && selection.polygon.length >= 3;
  }, [resultsOpen, selection]);

  // ✅ Results panel açılınca: polygon panel altında kalmasın diye fitBounds + padding
  useEffect(() => {
    if (!canShowResultsPanel) return;

    const map = mapRef.current?.getMap?.();
    if (!map) return;

    const bbox = polygonToBbox(selection.polygon);
    if (!bbox) return;

    const bottomPad = isMobile ? 300 : RESULTS_PANEL_APPROX_HEIGHT_DESKTOP + 60;
    const rightPad = isMobile ? 16 : filterOpen ? FILTER_PANEL_APPROX_WIDTH_DESKTOP + 60 : 90;

    map.fitBounds(
      [
        [bbox.minLng, bbox.minLat],
        [bbox.maxLng, bbox.maxLat],
      ],
      {
        duration: 650,
        padding: {
          top: isMobile ? 90 : 90,
          left: isMobile ? 16 : 90,
          right: rightPad,
          bottom: bottomPad,
        },
      }
    );
  }, [canShowResultsPanel, selection, filterOpen, isMobile]);

  if (loadingAuth || !user) return null;

  // ---------- Responsive sizes ----------
  const headerHeight = isMobile ? 54 : 64;
  const contentPadding = isMobile ? 0 : 24;
  const mapContainerRadius = isMobile ? 0 : 12;
  const mapContainerHeight = isMobile ? `calc(100vh - ${headerHeight}px)` : "calc(100vh - 88px)";

  const fabSize = isMobile ? 44 : 48;
  const fabGap = isMobile ? 8 : 10;

  const filterPanelWidth = isMobile ? "min(92vw, 360px)" : 280;
  const filterPanelTop = isMobile ? headerHeight + 10 : 28;
  const filterPanelRight = isMobile ? 12 : 78;

  const resultsWidth = isMobile ? "calc(100% - 24px)" : "min(760px, calc(100% - 48px))";
  const resultsBottom = isMobile ? 12 : 18;
  const resultsMaxHeight = isMobile ? 240 : 260;

  const userCardWidth = isMobile ? 220 : 280;

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: isMobile ? "0 12px" : "0 20px",
          height: headerHeight,
          background: "#fff",
          borderBottom: "1px solid #f0f0f0",
          position: "fixed",
          width: "100%",
          zIndex: 100,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <GlobalOutlined style={{ fontSize: isMobile ? 20 : 24, color: "#1890ff" }} />
          <span style={{ fontSize: isMobile ? 16 : 20, fontWeight: 700 }}>Vacanza Map</span>
        </div>

        <Button size={isMobile ? "small" : "middle"} icon={<LogoutOutlined />} onClick={handleLogout}>
          {isMobile ? "" : "Log Out"}
        </Button>
      </Header>

      <Content style={{ marginTop: headerHeight, padding: contentPadding, position: "relative" }}>
        <div
          style={{
            height: mapContainerHeight,
            borderRadius: mapContainerRadius,
            overflow: "hidden",
            boxShadow: isMobile ? "none" : "0 4px 12px rgba(0,0,0,0.1)",
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
            onLoad={onMapLoad}
            onStyleData={onStyleData}
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
                        width: isMobile ? 30 : 34,
                        height: isMobile ? 30 : 34,
                        borderRadius: 999,
                        display: "grid",
                        placeItems: "center",
                        background: fill,
                        border: `2px solid ${ring}`,
                        boxShadow: "0 4px 10px rgba(0,0,0,0.15)",
                        cursor: "pointer",
                      }}
                    >
                      <span style={{ fontSize: isMobile ? 14 : 16 }}>{emoji}</span>
                    </div>
                  </Tooltip>
                </Marker>
              );
            })}
          </Map>

          {/* sağdaki butonlar */}
          <div
            style={{
              position: "absolute",
              top: isMobile ? 12 : 18,
              right: isMobile ? 12 : 18,
              zIndex: 60,
              display: "flex",
              flexDirection: "column",
              gap: fabGap,
            }}
          >
            <Tooltip title="Draw Area" placement="left">
              <Button
                shape="circle"
                onClick={startFreehand}
                disabled={poiLoading}
                style={{
                  width: fabSize,
                  height: fabSize,
                  border: freehandEnabled ? "2px solid #1890ff" : "none",
                }}
              >
                ✏️
              </Button>
            </Tooltip>

            <Button
              shape="circle"
              icon={<UnorderedListOutlined />}
              onClick={() => {
                setResultsOpen(false);
                setFilterOpen((v) => !v);
              }}
              style={{ width: fabSize, height: fabSize }}
            />

            <Button
              shape="circle"
              icon={<CompassOutlined />}
              onClick={handleToggle2D3D}
              style={{ width: fabSize, height: fabSize, color: is3D ? "#1890ff" : "#555" }}
            />

            <Button
              shape="circle"
              icon={<HeatMapOutlined />}
              onClick={handleStyleChange}
              style={{ width: fabSize, height: fabSize }}
            />
          </div>

          {/* Filter panel */}
          {filterOpen && (
            <div
              style={{
                position: "absolute",
                top: filterPanelTop,
                right: filterPanelRight,
                zIndex: 70,
                width: filterPanelWidth,
                maxHeight: isMobile ? "62vh" : "unset",
                overflow: isMobile ? "auto" : "visible",
                background: "rgba(255,255,255,0.95)",
                borderRadius: 16,
                boxShadow: "0 10px 30px rgba(0,0,0,0.1)",
                padding: 14,
                backdropFilter: "blur(6px)",
              }}
            >
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 10 }}>
                <b style={{ fontSize: 14 }}>Filter {poiLoading ? " • Loading..." : ""}</b>
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
                      justifyContent: "space-between",
                      gap: 10,
                      padding: 10,
                      borderRadius: 10,
                      border: selectedCats[c.key] ? `2px solid ${c.ring}` : "1px solid #eee",
                      background: selectedCats[c.key] ? c.pill : "#fff",
                      cursor: poiLoading ? "not-allowed" : "pointer",
                      opacity: poiLoading ? 0.7 : 1,
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      <span
                        style={{
                          width: 24,
                          height: 24,
                          borderRadius: 12,
                          background: c.fill,
                          display: "grid",
                          placeItems: "center",
                          border: `1px solid ${c.ring}`,
                        }}
                      >
                        {c.emoji}
                      </span>
                      <b>{c.label}</b>
                    </div>

                    <span style={{ fontSize: 12, color: "#555" }}>
                      {pois.filter((p) => poiIconByCategory(p.category)?.uiKey === c.key).length}
                    </span>
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Results bottom sheet */}
          {canShowResultsPanel && (
            <div
              style={{
                position: "absolute",
                left: "50%",
                transform: "translateX(-50%)",
                bottom: resultsBottom,
                zIndex: 80,
                width: resultsWidth,
              }}
            >
              <Card
                style={{
                  borderRadius: 18,
                  boxShadow: "0 14px 40px rgba(0,0,0,0.18)",
                  overflow: "hidden",
                  background: "rgba(255,255,255,0.96)",
                  backdropFilter: "blur(6px)",
                }}
                // ✅ antd warning fix: bodyStyle -> styles.body
                styles={{ body: { padding: 14 } }}
              >
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12 }}>
                  <div style={{ display: "flex", flexDirection: "column" }}>
                    <div style={{ fontWeight: 800, fontSize: 16 }}>Results in Your Area</div>
                    <div style={{ fontSize: 12, color: "#777" }}>
                      {resultsPois.length} place{resultsPois.length === 1 ? "" : "s"} found in your selected zone
                    </div>
                  </div>

                  <Button
                    type="text"
                    icon={<CloseOutlined />}
                    onClick={async () => {
                      // ✅ alanı sil + VIEWPORT'a dön + tüm POI'leri getir
                      setResultsOpen(false);
                      setResultsTab("all");
                      setSelection({ mode: null, polygon: [] });
                      setMode("VIEWPORT");

                      const bbox = getViewportBbox();
                      if (bbox) {
                        await fetchPois({ selectionType: "BBOX", bbox, categoriesOverride: [] });
                      }

                      setFilterOpen(true);
                    }}
                    aria-label="Close results"
                  />
                </div>

                <div style={{ display: "flex", gap: 8, marginTop: 12, overflowX: "auto", paddingBottom: 6 }}>
                  {[{ key: "all", label: "All" }, ...UI_CATEGORIES.map((c) => ({ key: c.key, label: c.label, emoji: c.emoji }))].map(
                    (t) => {
                      const active = resultsTab === t.key;
                      return (
                        <button
                          key={t.key}
                          onClick={() => setResultsTab(t.key)}
                          style={{
                            flex: "0 0 auto",
                            display: "inline-flex",
                            alignItems: "center",
                            gap: 8,
                            padding: "8px 12px",
                            borderRadius: 999,
                            border: active ? "1px solid #1890ff" : "1px solid #e6e6e6",
                            background: active ? "rgba(24,144,255,0.10)" : "#fff",
                            cursor: "pointer",
                            fontWeight: 700,
                            fontSize: 13,
                            color: active ? "#1677ff" : "#444",
                          }}
                        >
                          {t.emoji ? <span>{t.emoji}</span> : null}
                          <span>{t.label}</span>
                        </button>
                      );
                    }
                  )}
                </div>

                <div style={{ marginTop: 12, maxHeight: resultsMaxHeight, overflowY: "auto", paddingRight: 6 }}>
                  {poiLoading ? (
                    <div style={{ padding: 10, color: "#777" }}>Loading results...</div>
                  ) : resultsPois.length === 0 ? (
                    <div style={{ padding: 10, color: "#777" }}>No places found for the current filter.</div>
                  ) : (
                    resultsPois.map((p) => {
                      const title = getSafePoiTitle(p);
                      const icon = poiIconByCategory(p.category);
                      const subtitle = labelByCategory(p.category) || "POI";

                      return (
                        <div
                          key={p.poiId || `${p.latitude}-${p.longitude}-${title}`}
                          style={{
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "space-between",
                            gap: 12,
                            padding: 12,
                            borderRadius: 14,
                            border: "1px solid #f0f0f0",
                            marginBottom: 10,
                            background: "#fff",
                          }}
                        >
                          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                            <div
                              style={{
                                width: 38,
                                height: 38,
                                borderRadius: 12,
                                display: "grid",
                                placeItems: "center",
                                background: icon?.fill || "#F1F5F9",
                                border: `1px solid ${icon?.ring || "#CBD5E1"}`,
                                flex: "0 0 auto",
                              }}
                            >
                              <span style={{ fontSize: 18 }}>{icon?.emoji || "📍"}</span>
                            </div>

                            <div style={{ display: "flex", flexDirection: "column" }}>
                              <div style={{ fontWeight: 800, lineHeight: 1.15 }}>{title}</div>
                              <div style={{ fontSize: 12, color: "#777" }}>{subtitle}</div>
                            </div>
                          </div>
                        </div>
                      );
                    })
                  )}
                </div>
              </Card>
            </div>
          )}

          {/* User card */}
          <Card
            style={{
              position: "absolute",
              top: isMobile ? 10 : 20,
              left: isMobile ? 10 : 20,
              zIndex: 50,
              width: userCardWidth,
              borderRadius: 16,
              background: "rgba(255,255,255,0.95)",
              backdropFilter: "blur(6px)",
            }}
            // ✅ antd warning fix: bodyStyle -> styles.body
            styles={{ body: { padding: isMobile ? 10 : 14 } }}
          >
            <div style={{ display: "flex", alignItems: "center" }}>
              <Avatar
                size={isMobile ? 40 : 48}
                icon={<UserOutlined />}
                src={user.photoURL}
                style={{ marginRight: 10, backgroundColor: "#1890ff" }}
              />
              <div style={{ minWidth: 0 }}>
                <div style={{ fontWeight: 700, fontSize: isMobile ? 13 : 14, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {user.displayName || "User"}
                </div>
                <div style={{ fontSize: 12, color: "#888", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                  {user.email}
                </div>
              </div>
            </div>
          </Card>
        </div>
      </Content>

      {!isMobile && (
        <Footer style={{ textAlign: "center", padding: "12px 50px", background: "#fff" }}>
          Vacanza App ©{new Date().getFullYear()}
        </Footer>
      )}
    </Layout>
  );
}
