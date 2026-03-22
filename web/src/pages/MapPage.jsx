import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { Layout, Button, Card, Avatar, Tooltip, Modal, Form, InputNumber, Select, message, Spin } from "antd";
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
import { onAuthStateChanged, signOut, sendEmailVerification } from "firebase/auth";
import { useGamificationProfile } from "../gamification/useGamification";
import BookingSheet from "../features/booking/components/BookingSheet";
import { CalendarOutlined } from "@ant-design/icons";
import VacanzaChat, {
  getSessionConversationId,
  linkPolygonRouteConversation,
} from "../features/ai/components/VacanzaChat";
import RoutePanel from "../features/ai/components/RoutePanel";
import ProfileModal from "./ProfileModal";
import http from "../api/http";
import { aiApi } from "../api/aiApi";
import { normalizeRouteForMap } from "../features/ai/utils/routeMap";

import cafeImg from "../assets/poi/poi_cafe.png";
import museumImg from "../assets/poi/poi_museum.png";
import monumentImg from "../assets/poi/poi_monument.png";
import parkImg from "../assets/poi/poi_park.png";
import restaurantImg from "../assets/poi/poi_restaurant.png";

const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
  longitude: 32.8200,
  latitude: 39.8950,
  zoom: 11.5,
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

/** Map filter keys → backend /chat/routes/from-polygon category strings (MapboxPoiSearchClient). */
const UI_KEY_TO_BACKEND_CATEGORY = {
  restaurant: "restaurant",
  cafe: "cafe",
  museum: "museum",
  monuments: "monument",
  parks: "park",
};

const UI_CATEGORIES = [
  {
    key: "restaurant",
    label: "Restaurants",
    geo: "catering.restaurant",
    aliases: ["restaurant", "restaurants", "catering.restaurant"],
    emoji: "🍽️",
    img: restaurantImg,
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
    img: cafeImg,
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
    img: museumImg,
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
    img: monumentImg,
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
    img: parkImg,
    ring: "#27AE60",
    fill: "#E9F9EF",
    pill: "#E9F9EF",
  },
];

function poiIconByCategory(category) {
  const c = normalizeCategory(category);
  const found = UI_CATEGORIES.find((x) => x.aliases.includes(c));
  if (!found) return null;
  return { emoji: found.emoji, img: found.img, ring: found.ring, fill: found.fill, uiKey: found.key };
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
  const { data: gamification, isLoading: gamificationLoading, error: gamificationError } =
    useGamificationProfile();

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
  const [bookingOpen, setBookingOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [activeRoute, setActiveRoute] = useState(null);
  const [activeDay, setActiveDay] = useState(1);
  const [routeGeometry, setRouteGeometry] = useState(null);

  /** Parametre modalı (sadece API göndermeden önce) */
  const [polygonRouteParamsOpen, setPolygonRouteParamsOpen] = useState(false);
  /** Üstteki rota isteği bandı kapatıldıysa; sonuç panelinde yedek CTA kalır */
  const [polygonRouteBannerDismissed, setPolygonRouteBannerDismissed] = useState(false);
  const [polygonRouteSubmitting, setPolygonRouteSubmitting] = useState(false);
  const [polygonRouteForm] = Form.useForm();
  const [chatConversationRefreshNonce, setChatConversationRefreshNonce] = useState(0);
  /** Sohbet–harita bağlantısı (replan gün); VacanzaChat onConversationIdChange ile güncellenir. */
  const [mapChatConversationId, setMapChatConversationId] = useState(null);
  const [replanDaySubmitting, setReplanDaySubmitting] = useState(false);
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

      // If email is not verified, send to verification page
      if (!currentUser.emailVerified) {
        navigate("/verify-email");
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
        const res = await fetch("/pois/search-in-area", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
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
    setPolygonRouteParamsOpen(false);
    setPolygonRouteBannerDismissed(false);
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
    setPolygonRouteParamsOpen(false);
    setPolygonRouteBannerDismissed(false);
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

    if (user) {
      setPolygonRouteBannerDismissed(false);
    }
  }, [freehandEnabled, fetchPois, user]);

  const openPolygonRouteParams = useCallback(() => {
    polygonRouteForm.resetFields();
    polygonRouteForm.setFieldsValue({ totalDays: 3, travelStyle: "general" });
    setPolygonRouteParamsOpen(true);
  }, [polygonRouteForm]);

  const submitPolygonRoute = useCallback(
    async (values) => {
      if (!selection?.polygon || selection.polygon.length < 3) {
        message.error("Geçerli bir alan seçin.");
        return;
      }
      const ring = selection.polygon.map((p) => [p.lng, p.lat]);
      const categories = selectedBackendCats
        .map((k) => UI_KEY_TO_BACKEND_CATEGORY[k])
        .filter(Boolean);
      setPolygonRouteSubmitting(true);
      try {
        const body = {
          coordinates: ring,
          totalDays: values.totalDays,
          travelStyle: values.travelStyle,
        };
        if (categories.length) body.categories = categories;
        const res = await aiApi.createRouteFromPolygon(body);
        const routeData = res.route_data || res.routeData;
        if (routeData) {
          setActiveRoute(normalizeRouteForMap(routeData));
          setActiveDay(1);
          setPolygonRouteParamsOpen(false);
          setPolygonRouteBannerDismissed(false);
          setResultsOpen(false);
          setFilterOpen(false);
          setIsChatOpen(false);
          const convId = res.conversation_id || res.conversationId;
          if (convId) {
            linkPolygonRouteConversation(convId);
            setMapChatConversationId(String(convId));
            setChatConversationRefreshNonce((n) => n + 1);
          }
          const summary = res.route_summary_message || res.routeSummaryMessage;
          if (summary) message.success(summary);
          else message.success("Rota haritada gösteriliyor.");
        } else {
          message.warning("Rota verisi alınamadı.");
        }
      } catch (e) {
        const msg =
          e?.response?.data?.message ||
          e?.friendlyMessage ||
          e?.message ||
          "Rota oluşturulamadı.";
        message.error(msg);
      } finally {
        setPolygonRouteSubmitting(false);
      }
    },
    [selection, selectedBackendCats]
  );

  const handleRequestDrawToEditFromChat = useCallback(() => {
    setIsChatOpen(false);
    setMode("SELECTION");
    setFreehandEnabled(true);
    message.info({
      content:
        "Haritada alan çiz → sağdaki rota panelinden gün seç → üstteki turuncu banttan o günü güncelle.",
      duration: 8,
    });
  }, []);

  const submitReplanDayFromPolygon = useCallback(async () => {
    if (!selection?.polygon || selection.polygon.length < 3) {
      message.error("Geçerli bir alan çizin.");
      return;
    }
    const convId = mapChatConversationId || getSessionConversationId();
    if (!convId) {
      message.error("Önce sohbetten bir rota açın veya haritadan oluşturulan rotaya bağlı sohbeti seçin.");
      return;
    }
    if (!activeRoute?.days?.length) {
      message.error("Yeniden planlanacak rota yok.");
      return;
    }
    const td = Number(activeRoute.total_days || activeRoute.totalDays || activeRoute.days.length);
    if (!Number.isFinite(activeDay) || activeDay < 1 || activeDay > td) {
      message.error("Geçerli bir gün seçin.");
      return;
    }
    const ring = selection.polygon.map((p) => [p.lng, p.lat]);
    const categories = selectedBackendCats.map((k) => UI_KEY_TO_BACKEND_CATEGORY[k]).filter(Boolean);
    setReplanDaySubmitting(true);
    try {
      const body = {
        conversationId: convId,
        day: activeDay,
        coordinates: ring,
        travelStyle: "general",
      };
      if (categories.length) body.categories = categories;
      const res = await aiApi.replanDayFromPolygon(body);
      const routeData = res.route_data || res.routeData;
      if (routeData) {
        setActiveRoute(normalizeRouteForMap(routeData));
        setActiveDay(activeDay);
        setFilterOpen(false);
        setIsChatOpen(true);
        linkPolygonRouteConversation(convId);
        setChatConversationRefreshNonce((n) => n + 1);
        const summary = res.route_summary_message || res.routeSummaryMessage;
        if (summary) message.success(summary);
        else message.success(`Gün ${activeDay} çizime göre güncellendi. Sohbete bakabilirsin.`);
      } else {
        message.warning("Rota verisi alınamadı.");
      }
    } catch (e) {
      const msg =
        e?.response?.data?.message ||
        e?.friendlyMessage ||
        e?.message ||
        "Gün yeniden planlanamadı.";
      message.error(msg);
    } finally {
      setReplanDaySubmitting(false);
    }
  }, [selection, mapChatConversationId, activeRoute, activeDay, selectedBackendCats]);

  /** Band kapatıldı + sonuç paneli kapalıyken küçük yedek CTA */
  const showCompactPolygonRouteCta = useMemo(
    () =>
      Boolean(
        user &&
          selection?.mode === "polygon" &&
          (selection.polygon?.length ?? 0) >= 3 &&
          !activeRoute &&
          polygonRouteBannerDismissed &&
          !resultsOpen
      ),
    [user, selection, activeRoute, polygonRouteBannerDismissed, resultsOpen]
  );

  /** Rota açıkken çizilen alanla tek günü yeniden planlama (sohbet + kayıtlı rota gerekir). */
  const showReplanDayBanner = useMemo(
    () =>
      Boolean(
        user &&
          activeRoute &&
          selection?.mode === "polygon" &&
          (selection.polygon?.length ?? 0) >= 3
      ),
    [user, activeRoute, selection]
  );

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

  // Normalize waypoint coords: backend may send latitude/longitude (camelCase); ensure numeric and consistent order
  const activeWaypoints = useMemo(() => {
    if (!activeRoute) return [];
    const dayPlan = activeRoute.days?.find(
      (d) => Number(d?.day) === Number(activeDay)
    );
    const raw = (dayPlan?.waypoints || []).map((w) => {
      const lat = Number(w.latitude ?? w.lat ?? NaN);
      const lon = Number(w.longitude ?? w.lon ?? NaN);
      return { ...w, latitude: lat, longitude: lon };
    });
    return raw.filter(
      (w) => Number.isFinite(w.latitude) && Number.isFinite(w.longitude)
    );
  }, [activeRoute, activeDay]);

  const routeLineGeoJSON = useMemo(() => {
    const coords =
      Array.isArray(routeGeometry) && routeGeometry.length >= 2
        ? routeGeometry.map((c) => [c.longitude, c.latitude])
        : activeWaypoints.length >= 2
          ? activeWaypoints.map((w) => [w.longitude, w.latitude])
          : null;

    if (!coords || coords.length < 2) {
      return { type: "FeatureCollection", features: [] };
    }

    return {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          properties: {},
          geometry: {
            type: "LineString",
            coordinates: coords,
          },
        },
      ],
    };
  }, [activeWaypoints, routeGeometry]);

  const routeGlowLayer = useMemo(
    () => ({
      id: "route-glow",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 14,
        "line-opacity": 0.18,
        "line-color": "#FDBA74",
        "line-blur": 3.5,
      },
    }),
    []
  );

  const routeMainLayer = useMemo(
    () => ({
      id: "route-main",
      type: "line",
      layout: { "line-cap": "round", "line-join": "round" },
      paint: {
        "line-width": 5,
        "line-opacity": 0.95,
        "line-gradient": [
          "interpolate", ["linear"], ["line-progress"],
          0.0, "#FB923C", 0.5, "#F97316", 1.0, "#EA580C",
        ],
      },
    }),
    []
  );

  // Fetch road-following route geometry from backend (Mapbox Directions)
  useEffect(() => {
    let cancelled = false;

    const fetchRouteGeometry = async () => {
      if (activeWaypoints.length < 2) {
        // No route for single-point days
        setRouteGeometry(null);
        return;
      }

      try {
        const body = {
          waypoints: activeWaypoints.map((w) => ({
            latitude: w.latitude,
            longitude: w.longitude,
          })),
        };
        const res = await http.post("/routes/directions", body);

        // Debug: see raw Mapbox-based geometry and inputs in browser console
        // so we can tune routing later if needed.
        // Not spamming: only logs when a route is actually fetched.
        // eslint-disable-next-line no-console
        console.log("[Vacanza][RouteGeometry] request", body, "response", res?.data);

        const coords = res?.data?.coordinates;
        if (!cancelled) {
          if (Array.isArray(coords) && coords.length >= 2) {
            setRouteGeometry(
              coords
                .map((c) => ({
                  latitude: Number(c.latitude),
                  longitude: Number(c.longitude),
                }))
                .filter(
                  (c) =>
                    Number.isFinite(c.latitude) && Number.isFinite(c.longitude)
                )
            );
          } else {
            setRouteGeometry(null);
          }
        }
      } catch (e) {
        console.warn("[MapPage] Failed to fetch route geometry, falling back to straight lines:", e);
        if (!cancelled) {
          setRouteGeometry(null);
        }
      }
    };

    fetchRouteGeometry();

    return () => {
      cancelled = true;
    };
  }, [activeWaypoints]);

  // fitBounds when route day changes
  useEffect(() => {
    if (activeWaypoints.length === 0) return;
    const map = mapRef.current?.getMap?.();
    if (!map) return;
    try {
      const lngs = activeWaypoints.map((w) => w.longitude);
      const lats = activeWaypoints.map((w) => w.latitude);
      // Safe padding: cap at 50% of container to prevent Mapbox NaN from overflow
      const container = map.getContainer();
      const maxV = Math.floor((container?.clientHeight || 600) * 0.25);
      const maxH = Math.floor((container?.clientWidth || 800) * 0.25);
      map.fitBounds(
        [[Math.min(...lngs), Math.min(...lats)], [Math.max(...lngs), Math.max(...lats)]],
        {
          duration: 650,
          padding: {
            top: Math.min(60, maxV),
            left: Math.min(60, maxH),
            right: Math.min(60, maxH),
            bottom: Math.min(200, maxV),
          },
        }
      );
    } catch (e) {
      console.warn("[MapPage] fitBounds failed, flying to first waypoint:", e.message);
      // Fallback: fly to the first waypoint
      const wp = activeWaypoints[0];
      if (wp) map.flyTo({ center: [wp.longitude, wp.latitude], zoom: 13, duration: 650 });
    }
  }, [activeWaypoints]);

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
        <div
          style={{ display: "flex", alignItems: "center", gap: 10, cursor: "pointer" }}
          onClick={() => window.location.reload()}
        >
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
          {user &&
            selection?.mode === "polygon" &&
            selection.polygon.length >= 3 &&
            !activeRoute &&
            !polygonRouteBannerDismissed && (
              <div
                style={{
                  position: "absolute",
                  top: 12,
                  left: 12,
                  right: 12,
                  zIndex: 25,
                  display: "flex",
                  justifyContent: "center",
                  pointerEvents: "none",
                  boxSizing: "border-box",
                }}
              >
                <div style={{ width: "100%", maxWidth: 640, pointerEvents: "auto" }}>
                <Card
                  size="small"
                  styles={{ body: { padding: "10px 12px" } }}
                  style={{
                    borderRadius: 12,
                    boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
                    background: "rgba(255,255,255,0.96)",
                    backdropFilter: "blur(8px)",
                  }}
                >
                  <div
                    style={{
                      display: "flex",
                      flexDirection: isMobile ? "column" : "row",
                      alignItems: isMobile ? "stretch" : "flex-start",
                      justifyContent: "space-between",
                      gap: 10,
                    }}
                  >
                    <span
                      style={{
                        fontSize: 13,
                        color: "#333",
                        lineHeight: 1.45,
                        flex: isMobile ? "none" : "1 1 0",
                        minWidth: 0,
                        wordBreak: "break-word",
                      }}
                    >
                      Bu alan için rota oluşturabilirsin. Önce haritayı ve sonuçları inceleyebilirsin; hazır olunca{" "}
                      <b>Rota oluştur</b> ile devam et.
                    </span>
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        gap: 6,
                        flexShrink: 0,
                        alignSelf: isMobile ? "stretch" : "auto",
                      }}
                    >
                      <Button type="primary" size="small" onClick={openPolygonRouteParams}>
                        Rota oluştur
                      </Button>
                      <Tooltip title="Bandı gizle (alan aynı kalır; rota için sonuç panelindeki düğmeyi kullan)">
                        <Button
                          type="text"
                          size="small"
                          icon={<CloseOutlined />}
                          onClick={() => setPolygonRouteBannerDismissed(true)}
                          aria-label="Rota isteğini gizle"
                        />
                      </Tooltip>
                    </div>
                  </div>
                </Card>
                </div>
              </div>
            )}

          {showReplanDayBanner && (
            <div
              style={{
                position: "absolute",
                top: 12,
                left: 12,
                right: 12,
                zIndex: 25,
                display: "flex",
                justifyContent: "center",
                pointerEvents: "none",
                boxSizing: "border-box",
              }}
            >
              <div style={{ width: "100%", maxWidth: 640, pointerEvents: "auto" }}>
              <Card
                size="small"
                styles={{ body: { padding: "10px 12px" } }}
                style={{
                  borderRadius: 12,
                  boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
                  background: "rgba(255,248,240,0.98)",
                  backdropFilter: "blur(8px)",
                  border: "1px solid rgba(249,115,22,0.35)",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    flexDirection: isMobile ? "column" : "row",
                    alignItems: isMobile ? "stretch" : "flex-start",
                    justifyContent: "space-between",
                    gap: 10,
                  }}
                >
                  <span
                    style={{
                      fontSize: 13,
                      color: "#333",
                      lineHeight: 1.45,
                      flex: isMobile ? "none" : "1 1 0",
                      minWidth: 0,
                      wordBreak: "break-word",
                    }}
                  >
                    <b>Gün {activeDay}</b> — Haritada çizdiğin alandaki mekânlara göre durakları güncelle. Bunun için
                    sohbet veya harita rotasına bağlı bir oturum gerekir.
                  </span>
                  <Button
                    type="primary"
                    size="small"
                    loading={replanDaySubmitting}
                    onClick={submitReplanDayFromPolygon}
                    style={{
                      background: "#ea580c",
                      borderColor: "#c2410c",
                      flexShrink: 0,
                      alignSelf: isMobile ? "stretch" : "flex-start",
                      whiteSpace: isMobile ? "normal" : "nowrap",
                    }}
                  >
                    {isMobile ? "Çizime göre güncelle" : "Günü çizime göre yenile"}
                  </Button>
                </div>
              </Card>
              </div>
            </div>
          )}

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

            {!activeRoute && pois.map((p) => {
              const icon = poiIconByCategory(p.category);
              const title = getSafePoiTitle(p);

              const ring = icon?.ring || "#64748B";
              const fill = icon?.fill || "#F1F5F9";
              const emoji = icon?.emoji || "📍";

              return (
                <Marker key={p.poiId || `${p.latitude}-${p.longitude}`} longitude={p.longitude} latitude={p.latitude} anchor="center">
                  <Tooltip title={title} placement="top">
                    {icon?.img ? (
                      <div
                        style={{
                          width: 64,
                          height: 64,
                          cursor: "pointer",
                          transition: "transform 0.2s",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.15)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                        }}
                        onClick={(e) => {
                          e.originalEvent.stopPropagation();
                        }}
                      >
                        <img src={icon.img} alt={title} style={{ width: "100%", height: "100%", objectFit: "contain" }} />
                      </div>
                    ) : (
                      <div
                        style={{
                          width: 28,
                          height: 28,
                          background: fill,
                          border: `2px solid ${ring}`,
                          borderRadius: "50%",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          cursor: "pointer",
                          boxShadow: "0 2px 4px rgba(0,0,0,0.15)",
                          transition: "transform 0.2s",
                        }}
                        onMouseEnter={(e) => {
                          e.currentTarget.style.transform = "scale(1.15)";
                        }}
                        onMouseLeave={(e) => {
                          e.currentTarget.style.transform = "scale(1)";
                        }}
                        onClick={(e) => {
                          e.originalEvent.stopPropagation();
                        }}
                      >
                        <span style={{ fontSize: 14 }}>{emoji}</span>
                      </div>
                    )}
                  </Tooltip>
                </Marker>
              );
            })}

            {activeWaypoints.length >= 2 && (
              <Source id="route-src" type="geojson" data={routeLineGeoJSON} lineMetrics>
                <Layer {...routeGlowLayer} />
                <Layer {...routeMainLayer} />
              </Source>
            )}

            {activeWaypoints.map((wp, idx) => (
              <Marker
                key={`route-wp-${wp.day}-${wp.order}`}
                longitude={wp.longitude}
                latitude={wp.latitude}
                anchor="center"
              >
                <Tooltip title={wp.name} placement="top">
                  <div
                    style={{
                      width: 30,
                      height: 30,
                      borderRadius: "50%",
                      background: "linear-gradient(135deg, #F97316, #EF4444)",
                      border: "2.5px solid white",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      color: "white",
                      fontSize: 13,
                      fontWeight: 800,
                      boxShadow: "0 2px 8px rgba(249,115,22,0.4)",
                      cursor: "pointer",
                      transition: "transform 0.2s",
                    }}
                    onMouseEnter={(e) => { e.currentTarget.style.transform = "scale(1.2)"; }}
                    onMouseLeave={(e) => { e.currentTarget.style.transform = "scale(1)"; }}
                  >
                    {idx + 1}
                  </div>
                </Tooltip>
              </Marker>
            ))}
          </Map>

          {showCompactPolygonRouteCta && (
            <div
              style={{
                position: "absolute",
                bottom: 20,
                left: 12,
                zIndex: 24,
              }}
            >
              <Button type="primary" size="middle" onClick={openPolygonRouteParams}>
                Rota oluştur
              </Button>
            </div>
          )}

          {activeRoute && (
            <RoutePanel
              route={activeRoute}
              activeDay={activeDay}
              onDayChange={setActiveDay}
              onClose={() => {
                setActiveRoute(null);
                setActiveDay(1);
                setMapChatConversationId(null);
                setFilterOpen(true);
              }}
              onWaypointClick={(wp) => {
                if (!Number.isFinite(wp.longitude) || !Number.isFinite(wp.latitude)) return;
                mapRef.current?.getMap?.()?.flyTo({
                  center: [wp.longitude, wp.latitude],
                  zoom: 15,
                  duration: 800,
                });
              }}
            />
          )}

          <Card
            onClick={() => setProfileModalOpen(true)}
            style={{
              position: "fixed",
              top: isMobile ? headerHeight + 10 : headerHeight + contentPadding + 20,
              left: isMobile ? 12 : contentPadding + 20,
              zIndex: 100,
              width: isMobile ? 240 : 280,
              borderRadius: 20,
              boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
              cursor: "pointer",
              background: "rgba(255, 255, 255, 0.95)",
              backdropFilter: "blur(8px)",
              transition: "transform 0.2s ease",
              border: "none"
            }}
            onMouseEnter={(e) => e.currentTarget.style.transform = "scale(1.02)"}
            onMouseLeave={(e) => e.currentTarget.style.transform = "scale(1)"}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 12 }}>
              <Avatar
                size={48}
                src={user?.photoURL}
                icon={<UserOutlined />}
                style={{ border: "2px solid #e6f7ff" }}
              />
              <div>
                <b style={{ fontSize: 16, display: "block" }}>{user?.displayName || "Gezgin"}</b>
                <span style={{ fontSize: 13, color: "#8c8c8c" }}>{gamification?.roleText || "Newbie"}</span>
              </div>
            </div>

            <div style={{ background: "#f5f5f5", padding: "12px", borderRadius: "14px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                <span style={{ fontSize: 13, fontWeight: "600", color: "#1890ff" }}>
                  {gamification?.levelText || "Level 1"}
                </span>
              </div>

              <div style={{ width: "100%", height: 6, background: "#e8e8e8", borderRadius: 10, overflow: "hidden", marginBottom: 6 }}>
                <div style={{
                  width: `${gamification?.xpProgressPercent || 0}%`,
                  height: "100%",
                  background: "linear-gradient(90deg, #1890ff, #69c0ff)",
                  transition: "width 0.5s ease-in-out"
                }} />
              </div>

              <div style={{ fontSize: 11, color: "#595959", textAlign: "center" }}>
                {gamification?.totalXp || 0} XP - {gamification?.xpProgressPercent || 0}% to next level
              </div>
            </div>
          </Card>
          {/* sağdaki butonlar */}
          <div
            style={{
              position: "fixed",
              top: isMobile ? headerHeight + 12 : headerHeight + contentPadding + 18,
              right: isMobile ? 12 : contentPadding + 18,
              zIndex: 60,
              display: "flex",
              flexDirection: "column",
              gap: fabGap,
            }}
          >
            <Tooltip title="Vacanza AI ile sohbet" placement="left">
              <Button
                shape="circle"
                icon={<CompassOutlined />}
                onClick={() => {
                  setIsChatOpen(true);
                  setFilterOpen(false);
                }}
                aria-label="Vacanza AI sohbetini aç"
                style={{
                  width: fabSize,
                  height: fabSize,
                  fontSize: isMobile ? "17px" : "18px",
                  background: "linear-gradient(145deg, #3da8c8 0%, #2c9eb8 55%, #2563eb 100%)",
                  border: "none",
                  color: "white",
                  boxShadow: "0 4px 14px rgba(61, 168, 200, 0.45)",
                }}
              />
            </Tooltip>

            <Tooltip title="Draw Area" placement="left">
              <Button
                shape="circle"
                onClick={startFreehand}
                style={{
                  width: fabSize,
                  height: fabSize,
                  border: freehandEnabled ? "2px solid #1890ff" : "none",
                }}
              >
                ✏️
              </Button>
            </Tooltip>

            <Tooltip title="Toggle Filter" placement="left">
              <Button
                shape="circle"
                icon={<UnorderedListOutlined />}
                onClick={() => {
                  setResultsOpen(false);
                  setFilterOpen((v) => !v);
                }}
                style={{ width: fabSize, height: fabSize }}
              />
            </Tooltip>

            <Tooltip title={is3D ? "Switch to 2D View" : "Switch to 3D View"} placement="left">
              <Button
                shape="circle"
                icon={<CompassOutlined />}
                onClick={handleToggle2D3D}
                style={{ width: fabSize, height: fabSize, color: is3D ? "#1890ff" : "#555" }}
              />
            </Tooltip>

            <Tooltip title="Change Map Style" placement="left">
              <Button
                shape="circle"
                icon={<HeatMapOutlined />}
                onClick={handleStyleChange}
                style={{ width: fabSize, height: fabSize }}
              />
            </Tooltip>

            <Tooltip title="Open Bookings" placement="left">
              <Button
                shape="circle"
                icon={<CalendarOutlined />}
                onClick={() => setBookingOpen(true)}
                style={{
                  width: fabSize,
                  height: fabSize,
                  border: "none",
                  background: bookingOpen ? "#1890ff" : "rgba(255,255,255,0.95)",
                  color: bookingOpen ? "#fff" : "#333",
                  backdropFilter: "blur(8px)",
                  boxShadow: "0 8px 24px rgba(0,0,0,0.15)",
                }}
              />
            </Tooltip>
          </div>

          {/* Filter panel */}
          {filterOpen && !activeRoute && (
            <div
              style={{
                position: "fixed",
                top: isMobile ? headerHeight + 10 : headerHeight + contentPadding + 28,
                right: isMobile ? 12 : 78 + contentPadding,
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
                <b style={{ fontSize: 14 }}>Filter</b>
                <Button type="text" icon={<CloseOutlined />} onClick={() => setFilterOpen(false)} />
              </div>

              <div style={{ display: "flex", gap: 8, marginBottom: 10 }}>
                <Button size="small" onClick={clearSelectionOnly}>
                  Reset Area
                </Button>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
                {UI_CATEGORIES.map((c) => (
                  <button
                    key={c.key}
                    onClick={() => setSelectedCats((prev) => ({ ...prev, [c.key]: !prev[c.key] }))}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "space-between",
                      gap: 10,
                      padding: 10,
                      borderRadius: 10,
                      border: selectedCats[c.key] ? `2px solid ${c.ring}` : "1px solid #eee",
                      background: selectedCats[c.key] ? c.pill : "#fff",
                      cursor: "pointer",
                    }}
                  >
                    <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                      {c.img ? (
                        <img src={c.img} alt={c.label} style={{ width: 32, height: 32, objectFit: "contain" }} />
                      ) : (
                        <span
                          style={{
                            width: 24,
                            height: 24,
                            borderRadius: 12,
                            background: c.fill,
                            display: "flex",
                            alignItems: "center",
                            justifyContent: "center",
                            border: `1px solid ${c.ring}`,
                          }}
                        >
                          <span style={{ fontSize: 13 }}>{c.emoji}</span>
                        </span>
                      )}
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
                position: "fixed",
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

                  <div style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}>
                    {user && !activeRoute && (
                      <Button type="primary" size="small" onClick={openPolygonRouteParams}>
                        Rota oluştur
                      </Button>
                    )}
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
          {/* End of User card logic */}
          <Modal
            title="Rota ayarları"
            open={polygonRouteParamsOpen}
            onCancel={() => {
              if (!polygonRouteSubmitting) setPolygonRouteParamsOpen(false);
            }}
            footer={null}
            destroyOnClose
            maskClosable={!polygonRouteSubmitting}
            zIndex={1100}
          >
            <Spin spinning={polygonRouteSubmitting}>
              <Form
                form={polygonRouteForm}
                layout="vertical"
                onFinish={submitPolygonRoute}
                initialValues={{ totalDays: 3, travelStyle: "general" }}
              >
                <Form.Item
                  name="totalDays"
                  label="Gün sayısı"
                  rules={[{ required: true, message: "Gün sayısı gerekli" }]}
                >
                  <InputNumber min={1} max={16} style={{ width: "100%" }} />
                </Form.Item>
                <Form.Item
                  name="travelStyle"
                  label="Stil"
                  rules={[{ required: true, message: "Stil seçin" }]}
                >
                  <Select
                    options={[
                      { value: "general", label: "Genel" },
                      { value: "history", label: "Tarih / kültür" },
                      { value: "food", label: "Yemek" },
                      { value: "nature", label: "Doğa" },
                      { value: "art", label: "Sanat" },
                    ]}
                  />
                </Form.Item>
                <div style={{ fontSize: 12, color: "#888", marginBottom: 12 }}>
                  Kategoriler, sağdaki filtrede seçili olanlarla gönderilir.
                </div>
                <div style={{ display: "flex", justifyContent: "flex-end", gap: 8 }}>
                  <Button onClick={() => setPolygonRouteParamsOpen(false)} disabled={polygonRouteSubmitting}>
                    İptal
                  </Button>
                  <Button type="primary" htmlType="submit" loading={polygonRouteSubmitting}>
                    Rota oluştur
                  </Button>
                </div>
              </Form>
            </Spin>
          </Modal>

          <BookingSheet open={bookingOpen} onClose={() => setBookingOpen(false)} />
          <VacanzaChat
            isOpen={isChatOpen}
            onClose={() => setIsChatOpen(false)}
            externalConversationRefreshNonce={chatConversationRefreshNonce}
            onConversationIdChange={(id) => setMapChatConversationId(id)}
            onRequestDrawToEdit={handleRequestDrawToEditFromChat}
            onRouteGenerated={(routeData, meta) => {
              setActiveRoute(routeData);
              setActiveDay(1);
              if (meta?.conversationId) setMapChatConversationId(String(meta.conversationId));
              setIsChatOpen(false);
              setFilterOpen(false);
            }}
          />
          <ProfileModal
            open={profileModalOpen}
            onClose={() => setProfileModalOpen(false)}
            user={user}
          />
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
