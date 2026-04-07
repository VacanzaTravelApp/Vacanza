import React, { useEffect, useMemo, useRef, useState, useCallback } from "react";
import { Layout, Button, Card, Avatar, Tooltip, Modal, Form, InputNumber, Select, message, Spin, Popover } from "antd";
import { useQueryClient } from "@tanstack/react-query";
import {
  LogoutOutlined,
  GlobalOutlined,
  HeatMapOutlined,
  InfoCircleOutlined,
  CalendarOutlined,
  SunOutlined,
  MoonOutlined,
  UserOutlined,
  CompassOutlined,
  CloseOutlined,
  UnorderedListOutlined,
  HeartOutlined,
  HeartFilled,
} from "@ant-design/icons";
import defaultAvatar from "../assets/default-avatar.png";
import { useNavigate } from "react-router-dom";

import Map, { NavigationControl, GeolocateControl, Marker, Source, Layer } from "react-map-gl";

import { auth } from "../firebase";
import { onAuthStateChanged, signOut, sendEmailVerification } from "firebase/auth";
import { useGamificationProfile } from "../gamification/useGamification";
import { useUserProfile } from "../hooks/useUserProfileData";
import { useProfilePhoto } from "../hooks/useProfilePhoto";
import BookingSheet from "../features/booking/components/BookingSheet";
import VacanzaChat, {
  getSessionConversationId,
  linkPolygonRouteConversation,
} from "../features/ai/components/VacanzaChat";
import RoutePanel from "../features/ai/components/RoutePanel";
import ProfileModal from "./ProfileModal";
import PreferencesModal from "./PreferencesModal";
import CalendarModal from "./CalendarModal";
import http from "../api/http";
import { aiApi } from "../api/aiApi";
import { postPoiFeedbackEvent } from "../api/feedbackApi";
import { useFeedbackAffinity } from "../hooks/useFeedbackAffinity";
import { normalizeRouteForMap } from "../features/ai/utils/routeMap";
import { buildMapPoiFeedbackPayload, deriveMapPoiFavorited } from "../features/ai/utils/feedbackVoteUtils";
import "./MapPage.css";



const { Header, Content, Footer } = Layout;

const INITIAL_VIEW_STATE = {
  longitude: 32.8200,
  latitude: 39.8950,
  zoom: 11.5,
  bearing: 0,
  pitch: 0,
};

const STYLES = [
  "mapbox://styles/mapbox/streets-v12",          // 0: Day (Streets)
  "mapbox://styles/mapbox/dark-v11",             // 1: Night (Dark)
  "mapbox://styles/mapbox/satellite-streets-v12" // 2: Live (Satellite + Labels)
];

const RestaurantIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"></path>
    <path d="M7 2v20"></path>
    <path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"></path>
  </svg>
);

const CafeIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 8h1a4 4 0 1 1 0 8h-1" /><path d="M3 8h14v9a4 4 0 0 1-4 4H7a4 4 0 0 1-4-4V8z" /><line x1="6" y1="2" x2="6" y2="4" /><line x1="10" y1="2" x2="10" y2="4" /><line x1="14" y1="2" x2="14" y2="4" />
  </svg>
);

const MuseumIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 22h20" /><path d="M4 22V10" /><path d="M10 22V10" /><path d="M14 22V10" /><path d="M20 22V10" /><path d="M2 10l10-8 10 8" />
  </svg>
);

const MonumentIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="m12 2-8 8v12h16V10Z" /><path d="M8 22v-4a4 4 0 1 1 8 0v4" /><path d="m11 11.5 1-1 1 1" />
  </svg>
);

const ParkIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M12 22v-6"></path>
    <path d="M5 16l7-9 7 9H5z"></path>
    <path d="M7 11l5-7 5 7H7z"></path>
  </svg>
);

const AttractionIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="10" /><path d="M12 8v8" /><path d="M8 12h8" />
  </svg>
);

const BarIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M3 2h18" /><path d="M18 20a1 1 0 0 0 1-1V5H5v14a1 1 0 0 0 1 1h12z" /><path d="M12 11h.01" /><path d="M12 7h.01" /><path d="M12 15h.01" />
  </svg>
);

const ShoppingIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M6 2 3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4Z" /><path d="M3 6h18" /><path d="M16 10a4 4 0 0 1-8 0" />
  </svg>
);

const HotelIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 22h20" /><path d="M7 22v-5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v5" /><path d="M9 10h6" /><path d="M11 14h2" /><path d="M11 6h2" /><path d="M5 22V4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v18" />
  </svg>
);

const TransportIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <rect x="4" y="3" width="16" height="16" rx="2" /><path d="M9 22h6" /><path d="M8 7h8" /><path d="M12 3v16" />
  </svg>
);

const PencilIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z" /><path d="m15 5 4 4" />
  </svg>
);

const LayerIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <polygon points="12 2 2 7 12 12 22 7 12 2" /><polyline points="2 17 12 22 22 17" /><polyline points="2 12 12 17 22 12" />
  </svg>
);

const CubeIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><polyline points="3.27 6.96 12 12.01 20.73 6.96" /><line x1="12" y1="22.08" x2="12" y2="12" />
  </svg>
);

const LogoutIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
  </svg>
);

const SettingsIcon = () => (
  <svg viewBox="0 0 24 24" fill="none" width="18" height="18" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
    <circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" />
  </svg>
);

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
  park: "park",
  attraction: "attraction",
  bar: "bar",
  shopping: "shopping",
  hotel: "hotel",
  transport: "transport",
  others: "poi",
};

const UI_CATEGORIES = [
  {
    key: "restaurant",
    label: "Restaurants",
    geo: "catering.restaurant",
    aliases: [
      "restaurant", "restaurants", "catering.restaurant", "fast_food", "food_court",
      "pizza_restaurant", "mexican_restaurant", "indian_restaurant", "asian_restaurant",
      "burger_restaurant", "diner_restaurant", "noodle_restaurant", "sushi_restaurant",
      "buffet_restaurant", "ramen_restaurant", "tapas_restaurant", "steakhouse",
      "turkish_restaurant", "japanese_restaurant", "chinese_restaurant", "seafood_restaurant",
      "italian_restaurant", "hawaiian_restaurant", "korean_barbeque_restaurant",
      "portuguese_restaurant", "latin_american_restaurant", "vietnamese_restaurant",
      "french_restaurant", "african_restaurant", "brazilian_restaurant", "filipino_restaurant",
      "german_restaurant", "carribean_restaurant", "middle_eastern_restaurant",
      "mediterranean_restaurant", "creole_restaurant", "peruvian_restaurant", "wings_joint",
      "hot_dog_stand", "food_truck", "food", "food_and_drink", "deli"
    ],
    icon: <RestaurantIcon />,
    pill: "rgba(255, 107, 107, 0.15)",
    fill: "rgba(255, 107, 107, 1)",
    ring: "#FF6B6B",
    uiKey: "restaurant",
  },
  {
    key: "cafe",
    label: "Cafes",
    geo: "catering.cafe",
    aliases: [
      "cafe", "cafes", "catering.cafe", "coffee", "coffee_shop", "teahouse", "bakery",
      "dessert_shop", "ice_cream", "confectionery", "juice_bar", "bubble_tea", "donut_shop",
      "bagel_shop", "frozen_yogurt_shop", "waffle_shop", "turkish_coffeehouse",
      "coffee_roaster", "snack_bar", "tea_house"
    ],
    icon: <CafeIcon />,
    pill: "rgba(255, 179, 71, 0.15)",
    fill: "rgba(255, 179, 71, 1)",
    ring: "#FFB347",
    uiKey: "cafe",
  },
  {
    key: "museum",
    label: "Museums & Arts",
    geo: "tourism.attraction.museum",
    aliases: ["museum", "museums", "tourism.attraction.museum", "planetarium", "aquarium", "art_gallery", "zoo", "zoo_exhibit", "exhibit"],
    icon: <MuseumIcon />,
    pill: "rgba(0, 180, 216, 0.15)",
    fill: "rgba(0, 180, 216, 1)",
    ring: "#00B4D8",
    uiKey: "museum",
  },
  {
    key: "monuments",
    label: "Culture",
    aliases: [
      "monument", "memorial", "castle", "fort", "place_of_worship", "tomb", "theatre", 
      "art_gallery", "gallery", "historic_site", "public_artwork", "outdoor_sculpture", 
      "concert_hall", "music_venue", "arts_center", "studio", "movie_theater", "cinema", 
      "theater", "opera_house", "religious_christian", "religious_muslim", "religious_jewish", 
      "religious_buddhist", "mosque", "church", "temple", "synagogue", "buddhist_temple", 
      "place_of_worship.muslim", "place_of_worship.christian", "place_of_worship.jewish", 
      "place_of_worship.buddhist", "landmark", "historic", "attraction", 
      "tourist_attraction", "sightseeing", "cultural_center", "place_of_interest",
      "religious", "spiritual", "mosques", "churches", "temples", "synagogues", "historic_place",
      "cathedral", "chapel", "shrine", "monastic", "abbey", "priory", "historical_landmark",
      "religious_facility", "cultural_heritage", "basilica"
    ],
    icon: <MonumentIcon />,
    pill: "rgba(99, 102, 241, 0.15)",
    fill: "rgba(99, 102, 241, 1)",
    ring: "#4338ca",
    uiKey: "monuments",
  },
  {
    key: "park",
    label: "Parks/Nature",
    aliases: [
      "park", "garden", "forest", "nature_reserve", "wood", "leisure.park",
      "recreation_ground", "national_park", "playground", "dog_park", "picnic_shelter",
      "botanical_garden", "natural"
    ],
    icon: <ParkIcon />,
    pill: "rgba(34, 197, 94, 0.15)",
    fill: "rgba(34, 197, 94, 1)",
    ring: "#15803d",
    uiKey: "park",
  },
  {
    key: "attraction",
    label: "Attractions",
    aliases: [
      "attraction", "viewpoint", "theme_park", "zoo", "aquarium", "historic",
      "scenic_viewpoint", "tourist_attraction", "lighthouse", "waterfall", "dam",
      "cave", "island", "mountain", "mountain_hut", "beach", "stadium", "soccer_stadium",
      "basketball_stadium", "football_stadium", "hockey_stadium", "baseball_stadium",
      "tennis_stadium", "racetrack", "racecourse", "casino", "amusement_park",
      "theme_park_attraction", "fair_grounds"
    ],
    icon: <AttractionIcon />,
    pill: "rgba(168, 85, 247, 0.15)",
    fill: "rgba(168, 85, 247, 1)",
    ring: "#7e22ce",
    uiKey: "attraction",
  },
  {
    key: "bar",
    label: "Nightlife",
    aliases: [
      "bar", "pub", "night_club", "nightclub", "nightlife", "liquor_store", "alcohol",
      "wine_bar", "beer_garden", "cocktail_bar", "lounge", "karaoke_bar", "gay_bar",
      "beach_bar", "dive_bar", "stripclub", "brewery", "speakeasy", "champagne_bar",
      "sake_bar", "beer_bar", "hookah_lounge", "whiskey_bar", "tiki_bar", "gastropub",
      "biergarten"
    ],
    icon: <BarIcon />,
    pill: "rgba(236, 72, 153, 0.15)",
    fill: "rgba(236, 72, 153, 1)",
    ring: "#be185d",
    uiKey: "bar",
  },
  {
    key: "shopping",
    label: "Shopping",
    aliases: [
      "shop", "mall", "supermarket", "marketplace", "clothing_store", "bakery",
      "convenience_store", "convenience", "electronics", "electronics_shop",
      "hardware_store", "furniture_store", "jewelry_store", "flower_shop", "book_store",
      "gift_shop", "toy_store", "pet_store", "pharmacy", "cosmetics_shop", "beauty_store",
      "optician", "bicycle_shop", "liquor_store", "alcohol_shop", "vape_shop",
      "tobacco_shop", "smoke_shop", "camera_shop", "watch_store", "hobby_shop",
      "antique_shop", "thrift_shop", "pawnshop", "duty_free_shop", "outlet_store",
      "luggage_store", "music_shop", "fabric_store", "frame_store", "paper_goods_store",
      "kitchen_store", "mattress_store", "lighting_store", "arts_and_craft_store",
      "home_repair", "baby_goods_shop", "variety_store", "pop_up_shop", "clothing", "shopping_mall", "department_store"
    ],
    icon: <ShoppingIcon />,
    pill: "rgba(245, 158, 11, 0.15)",
    fill: "rgba(245, 158, 11, 1)",
    ring: "#b45309",
    uiKey: "shopping",
  },
  {
    key: "hotel",
    label: "Hotels",
    aliases: ["hotel", "motel", "hostel", "apartment", "guest_house", "accommodation", "lodging", "bed_and_breakfast", "vacation_rental", "resort", "campground", "campsite"],
    icon: <HotelIcon />,
    pill: "rgba(14, 165, 233, 0.15)",
    fill: "rgba(14, 165, 233, 1)",
    ring: "#0369a1",
    uiKey: "hotel",
  },
  {
    key: "transport",
    label: "Transport",
    aliases: [
      "station", "airport", "bus_stop", "subway_entrance", "train_station",
      "ferry_terminal", "transit_stop", "stop_area", "railway_station", "bus_station",
      "subway_station", "light_rail_station", "public_transportation_station", "taxi",
      "car_rental", "parking_lot", "parking", "gas_station", "charging_station",
      "train", "bus", "rail", "subway"
    ],
    icon: <TransportIcon />,
    pill: "rgba(71, 85, 105, 0.15)",
    fill: "rgba(71, 85, 105, 1)",
    ring: "#334155",
    uiKey: "transport",
  },
  {
    key: "others",
    label: "Services",
    aliases: [
      "poi", "office", "educational", "healthcare", "public", "bank", "atm", "pharmacy", 
      "hospital", "clinic", "post_office", "medical_clinic", "doctors_office", "dentist", 
      "veterinarian", "police_station", "fire_station", "government_offices", "library", 
      "school", "university", "college", "community_center", "mosque", "church", 
      "temple", "synagogue", "buddhist_temple", "cemetery", "laundry", "dry_cleaners", 
      "salon", "hairdresser", "barber", "spa", "gym", "fitness_center", "yoga_studio", 
      "pilates_studio", "sports_club", "swimming_pool", "tennis_courts", "golf_course", 
      "bowling_alley", "arcade", "laser_tag", "billiards", "karaoke", "dance_studio", 
      "recording_studio", "television_studio", "radio_studio", "design_studio", 
      "coworking_space", "event_space", "conference_center", "offices", "factory", 
      "warehouse", "storage", "services", "it", "consulting", "advertising_agency", 
      "chiropractor", "physiotherapist", "alternative_healthcare", "assisted_living_facility"
    ],
    icon: <GlobalOutlined />,
    pill: "rgba(100, 116, 139, 0.1)",
    fill: "rgba(100, 116, 139, 1)",
    ring: "#475569",
    uiKey: "others",
  }
];

function hideTrafficLayers(map) {
  if (!map) return;
  const style = map.getStyle();
  if (!style || !style.layers) return;
  style.layers.forEach((layer) => {
    if (layer.id.includes("traffic")) {
      map.setLayoutProperty(layer.id, "visibility", "none");
    }
  });
}

function poiIconByCategory(poi) {
  if (!poi) return null;
  // Support both passing the full POI object or just the category string for legacy calls
  const category = (typeof poi === 'string' || Array.isArray(poi)) ? poi : poi.category;
  const name = (typeof poi === 'object' && poi !== null) ? String(poi.title || poi.name || "").toLowerCase() : "";

  if (!category) return null;

  // HEURISTIC: Specific overrides for famous landmarks that might have generic categories
  if (name.includes("ayasofya") || name.includes("hagia sophia") || name.includes("blue mosque") || name.includes("sultanahmet")) {
    const culture = UI_CATEGORIES.find(c => c.key === "monuments");
    if (culture) return { ring: culture.ring, fill: culture.fill, uiKey: culture.key, icon: culture.icon };
  }

  // Handle both single strings, arrays, or comma-separated strings
  const rawCatsArray = Array.isArray(category) 
    ? category 
    : String(category).split(',').map(s => s.trim());
    
  // Split by both comma AND dot to handle Mapbox dot-notation subcategories
  const normCats = rawCatsArray.flatMap(c => c.toLowerCase().trim().split('.')).filter(Boolean);
  
  // Also keep the full strings for exact matching
  rawCatsArray.forEach(c => normCats.push(c.toLowerCase().trim()));

  const specificCategories = UI_CATEGORIES.filter(c => c.key !== 'others');
  const othersCategory = UI_CATEGORIES.find(c => c.key === 'others');

  for (const catObj of specificCategories) {
    if (normCats.some(nc => catObj.aliases.includes(nc))) {
      return { ring: catObj.ring, fill: catObj.fill, uiKey: catObj.key, icon: catObj.icon };
    }
  }

  if (othersCategory) {
    if (normCats.some(nc => othersCategory.aliases.includes(nc))) {
      return { ring: othersCategory.ring, fill: othersCategory.fill, uiKey: othersCategory.key, icon: othersCategory.icon };
    }
  }

  return null;
}

function labelByCategory(poi) {
  const icon = poiIconByCategory(poi);
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

/** Stable React key + favorite row id for a map / Discover POI row. */
function getMapPoiRowKey(p) {
  if (!p) return "";
  if (p.poiId != null) return String(p.poiId);
  const lat = Number(p.latitude ?? p.lat);
  const lon = Number(p.longitude ?? p.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return `unknown:${String(p?.name || "").slice(0, 48)}`;
  }
  return `${lat.toFixed(5)}:${lon.toFixed(5)}:${String(p?.name || "").slice(0, 48)}`;
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

  // Force globe projection EARLY and ALWAYS
  try {
    map.setProjection("globe");
  } catch (e) {
    // ignore
  }

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
  const { data: profile } = useUserProfile();
  const { profilePhotoUrl } = useProfilePhoto(profile);
  const { data: gamification, isLoading: gamificationLoading, error: gamificationError } =
    useGamificationProfile();

  const [user, setUser] = useState(null);
  const [loadingAuth, setLoadingAuth] = useState(true);

  const queryClient = useQueryClient();
  const { data: feedbackAffinity } = useFeedbackAffinity();
  const [favSendingKey, setFavSendingKey] = useState(null);
  /** Which viewport POI marker has the detail popover open (pin tap). */
  const [viewportPoiPopoverKey, setViewportPoiPopoverKey] = useState(null);

  const [viewState, setViewState] = useState({
    longitude: 32.8597,
    latitude: 39.9334,
    zoom: 12,
    pitch: 0,
    bearing: 0,
  });

  // Attempt to center map on user's current location on mount
  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setViewState((prev) => ({
            ...prev,
            latitude: pos.coords.latitude,
            longitude: pos.coords.longitude,
            zoom: 13, // Slightly closer on user location
          }));
        },
        (err) => {
          console.log("[MapPage] Geolocation denied or failed, using default center.", err);
        },
        { enableHighAccuracy: true, timeout: 5000, maximumAge: 0 }
      );
    }
  }, []);

  const initialDarkMode = (() => {
    const saved = localStorage.getItem('vacanza-theme');
    if (saved) return saved === 'night';
    const hour = new Date().getHours();
    return hour < 6 || hour >= 20;
  })();

  const [styleIndex, setStyleIndex] = useState(initialDarkMode ? 1 : 0);
  const [isDarkMode, setIsDarkMode] = useState(initialDarkMode);
  const [is3D, setIs3D] = useState(false);
  const [mapboxPois, setMapboxPois] = useState([]);

  const [mode, setMode] = useState("VIEWPORT"); // VIEWPORT | SELECTION
  const [selection, setSelection] = useState({ mode: null, polygon: [] });

  const [freehandEnabled, setFreehandEnabled] = useState(false);
  const drawingRef = useRef({ isDown: false, points: [] });

  const [previewLine, setPreviewLine] = useState(null);

  const [poisRaw, setPoisRaw] = useState([]);
  const [poiLoading, setPoiLoading] = useState(false);

  const [filterOpen, setFilterOpen] = useState(false);

  const [selectedCats, setSelectedCats] = useState(() => {
    const all = {};
    UI_CATEGORIES.forEach((c) => (all[c.key] = true));
    return all;
  });

  const [resultsOpen, setResultsOpen] = useState(false);
  const [resultsTab, setResultsTab] = useState("all");
  const [bookingOpen, setBookingOpen] = useState(false);
  const [profileModalOpen, setProfileModalOpen] = useState(false);
  const [preferencesModalOpen, setPreferencesModalOpen] = useState(false);
  const [calendarOpen, setCalendarOpen] = useState(false);
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

  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [fabExpanded, setFabExpanded] = useState(false);

  // 1. Initial State Calculation (Clock-driven unless manual)
  // (isDarkMode is now initialized above)

  const [isManual, setIsManual] = useState(() => localStorage.getItem('vacanza-manual') === 'true');

  useEffect(() => {
    const syncTheme = () => {
      if (!isManual) {
        const hour = new Date().getHours();
        const shouldBeDark = hour < 6 || hour >= 20;
        if (shouldBeDark !== isDarkMode) {
          setIsDarkMode(shouldBeDark);
          setStyleIndex(shouldBeDark ? 1 : 0);
        }
      }
    };

    const timer = setInterval(syncTheme, 60000);
    return () => clearInterval(timer);
  }, [isManual, isDarkMode]);

  const toggleTheme = () => {
    const nextVal = !isDarkMode;
    setIsDarkMode(nextVal);
    setIsManual(true);
    setStyleIndex(nextVal ? 1 : 0);
    localStorage.setItem('vacanza-theme', nextVal ? 'night' : 'day');
    localStorage.setItem('vacanza-manual', 'true');
  };

  const themeClass = isDarkMode ? "theme-night" : "theme-day";
  const mapStyleIndex = isDarkMode ? 1 : 0;

  const [formattedTime, setFormattedTime] = useState("");
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      const h = now.getHours();
      const m = now.getMinutes().toString().padStart(2, '0');
      const hours12 = h % 12 || 12;
      const ampm = h >= 12 ? 'PM' : 'AM';
      setFormattedTime(`${hours12}:${m} ${ampm}`);
    };
    updateTime();
    const timer = setInterval(updateTime, 60000);
    return () => clearInterval(timer);
  }, []);
  // Mutual exclusion for ALL panels to avoid overlaps - fixed logic
  useEffect(() => {
    if (resultsOpen) {
      if (filterOpen) setFilterOpen(false);
      if (isChatOpen) setIsChatOpen(false);
      if (bookingOpen) setBookingOpen(false);
      if (fabExpanded) setFabExpanded(false);
    }
  }, [resultsOpen]); // Only react when resultsOpen changes

  useEffect(() => {
    if (filterOpen) {
      if (resultsOpen) setResultsOpen(false);
      if (isChatOpen) setIsChatOpen(false);
      if (bookingOpen) setBookingOpen(false);
    }
  }, [filterOpen]);

  useEffect(() => {
    if (isChatOpen) {
      if (filterOpen) setFilterOpen(false);
      if (resultsOpen) setResultsOpen(false);
      if (bookingOpen) setBookingOpen(false);
    }
  }, [isChatOpen]);

  useEffect(() => {
    if (bookingOpen) {
      if (filterOpen) setFilterOpen(false);
      if (isChatOpen) setIsChatOpen(false);
      if (resultsOpen) setResultsOpen(false);
      if (fabExpanded) setFabExpanded(false);
    }
  }, [bookingOpen]);

  useEffect(() => {
    if (sidebarOpen) {
      if (filterOpen) setFilterOpen(false);
      if (isChatOpen) setIsChatOpen(false);
      if (bookingOpen) setBookingOpen(false);
      if (resultsOpen) setResultsOpen(false);
      if (fabExpanded) setFabExpanded(false);
    }
  }, [sidebarOpen]);

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
        // Only redirect if NOT loading, but wait, we need to know if it's the first check.
        // Actually, just set loading to false and let the user decide.
        setLoadingAuth(false);
        navigate("/login");
        return;
      }

      // If email is not verified, send to verification page
      if (!currentUser.emailVerified) {
        setLoadingAuth(false);
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

  const toggleMapPoiFavorite = useCallback(
    async (p) => {
      if (!user) return;
      const lat = Number(p?.latitude ?? p?.lat);
      const lon = Number(p?.longitude ?? p?.lon);
      if (!Number.isFinite(lat) || !Number.isFinite(lon)) return;
      const key = getMapPoiRowKey(p);
      const base = buildMapPoiFeedbackPayload(p);
      const favored = deriveMapPoiFavorited(feedbackAffinity, p);
      const eventType = favored ? "THUMBS_DOWN" : "THUMBS_UP";
      setFavSendingKey(key);
      try {
        await postPoiFeedbackEvent({ eventType, ...base });
        await queryClient.invalidateQueries({ queryKey: ["feedback", "affinity"] });
        message.success(favored ? "Removed from your favorites." : "Saved to your favorites.");
      } catch (e) {
        message.error(e?.friendlyMessage || "Could not update favorites.");
      } finally {
        setFavSendingKey(null);
      }
    },
    [user, feedbackAffinity, queryClient]
  );

  const handleMapIdle = useCallback(() => {
    if (!mapRef.current) return;
    const map = mapRef.current.getMap();
    if (map.getZoom() < 12) {
      setMapboxPois([]);
      return;
    }

    // Standard Mapbox layers for diverse POIs
    const poiLayers = [
      'poi-label',
      'settlement-label',
      'medical-label',
      'transit-label',
      'airport-label',
      'natural-label',
      'park-label',
      'place-label'
    ];

    // Safety check: only query layers that exist in current style
    const styleLayers = map.getStyle().layers.map(l => l.id);
    const validLayers = poiLayers.filter(id => styleLayers.includes(id));

    const features = map.queryRenderedFeatures({ layers: validLayers });
    if (!features || features.length === 0) return;

    const discovered = features.map(f => {
      const p = f.properties;
      const name = p.name_en || p.name;
      const type = p.type || p.maki || p.class || p.category || p.category_en || "poi";
      const [lng, lat] = f.geometry.coordinates;

      return {
        id: `mb-${name}-${lng.toFixed(5)}-${lat.toFixed(5)}`,
        name: name,
        category: type.toLowerCase(),
        location: { lat, lng },
        source: 'mapbox'
      };
    }).filter(p => !!p.name);

    setMapboxPois(discovered);
  }, []);

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
      const map = mapRef.current?.getMap?.();
      if (map && map.getZoom() < 12) {
        setPoisRaw([]);
        return;
      }
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
      const map = mapRef.current?.getMap?.();
      if (map && map.getZoom() < 12) {
        setPoisRaw([]);
        return;
      }
      const bbox = getViewportBbox();
      if (bbox) fetchPois({ selectionType: "BBOX", bbox });
    }, 600);

    return () => clearTimeout(t);
  }, [MAPBOX_TOKEN, user, mode, getViewportBbox, fetchPois]);

  // Kategori değişince (VIEWPORT’ta) refetch
  useEffect(() => {
    if (!MAPBOX_TOKEN || !user) return;
    if (mode !== "VIEWPORT") return;

    const map = mapRef.current?.getMap?.();
    if (map && map.getZoom() < 12) {
      setPoisRaw([]);
      return;
    }
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

  const handleSelectAllFilters = useCallback(() => {
    const all = {};
    UI_CATEGORIES.forEach((c) => (all[c.key] = true));
    setSelectedCats(all);
  }, []);

  const handleDeselectAllFilters = useCallback(() => {
    const all = {};
    UI_CATEGORIES.forEach((c) => (all[c.key] = false));
    setSelectedCats(all);
  }, []);

  const handleResetFilters = useCallback(async () => {
    handleSelectAllFilters();
    await clearSelectionOnly();
  }, [handleSelectAllFilters, clearSelectionOnly]);

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

    // Crucial: The useEffect will handle closing others when resultsOpen becomes true
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
        message.warning("Please select a valid area first.");
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
          else message.success("Route is being displayed on the map.");
        } else {
          message.warning("Could not retrieve route data.");
        }
      } catch (e) {
        const msg =
          e?.response?.data?.message ||
          e?.friendlyMessage ||
          e?.message ||
          "Failed to create route.";
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
        "Draw an area on the map → select a day from the route panel on the right → update that day from the orange banner at the top.",
      duration: 8,
    });
  }, []);

  const submitReplanDayFromPolygon = useCallback(async () => {
    if (!selection?.polygon || selection.polygon.length < 3) {
      message.error("Please draw a valid area.");
      return;
    }
    const convId = mapChatConversationId || getSessionConversationId();
    if (!convId) {
      message.error("Open a route from the chat first or select the chat associated with the route created from the map.");
      return;
    }
    if (!activeRoute?.days?.length) {
      message.error("No route available to replan.");
      return;
    }
    const td = Number(activeRoute.total_days || activeRoute.totalDays || activeRoute.days.length);
    if (!Number.isFinite(activeDay) || activeDay < 1 || activeDay > td) {
      message.error("Please select a valid day.");
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
        else message.success(`Day ${activeDay} has been updated based on your drawing. You can check the chat.`);
      } else {
        message.warning("Could not retrieve route data.");
      }
    } catch (e) {
      const msg =
        e?.response?.data?.message ||
        e?.friendlyMessage ||
        e?.message ||
        "Failed to replan day.";
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
    const next = !is3D;
    setIs3D(next);
    const map = mapRef.current?.getMap?.();
    if (map) {
      map.easeTo({ pitch: next ? 60 : 0, duration: 650 });
      ensureMapbox3D(map, next);
    }
    setViewState((prev) => ({ ...prev, pitch: next ? 60 : 0 }));
  }, [is3D]);

  const handleStyleChange = useCallback(() => {
    setStyleIndex((i) => (i + 1) % STYLES.length);
  }, []);

  // Map load + style reload => 3D tekrar ekle + traffic sakla
  const onMapLoad = useCallback((e) => {
    const map = e?.target || mapRef.current?.getMap?.();
    if (map) {
      ensureMapbox3D(map, is3D);
      hideTrafficLayers(map);
      try {
        map.setProjection("globe");
        map.setFog({ "horizon-blend": 0.1, "space-color": "#000000", "star-intensity": 0.0 });
      } catch (err) {
        // ignore
      }

      // Secondary delay ensures projection sticks for styles that might override it
      setTimeout(() => {
        try {
          if (map) map.setProjection("globe");
        } catch (e) { }
      }, 500);
    }
  }, [is3D]);

  const onStyleData = useCallback((e) => {
    const map = e?.target || mapRef.current?.getMap?.();
    if (map) {
      ensureMapbox3D(map, is3D);
      hideTrafficLayers(map);

      // Force Globe forcefully
      try {
        map.setProjection({ name: "globe" });
        map.setFog({
          "horizon-blend": 0.1,
          "space-color": "#000000",
          "star-intensity": 0.1,
        });
      } catch (err) {
        // ignore
      }

      // Reinforce after style data settle
      setTimeout(() => {
        try {
          if (map) {
            map.setProjection({ name: "globe" });
          }
        } catch (e) { }
      }, 300);
    }
  }, [is3D]);

  // POI'ler: polygon içi filtre + UI filtre
  // Combined POI list (Backend + Mapbox Discoveries)
  const pois = useMemo(() => {
    // 1. Performance Rule: Hide POIs at low zoom levels to prevent clutter
    if (viewState.zoom <= 10) return [];

    const all = [...poisRaw];
    const poiCoords = new Set(poisRaw.map(p => `${p.latitude?.toFixed(4)},${p.longitude?.toFixed(4)}`));

    mapboxPois.forEach(mbp => {
      const coordKey = `${mbp.location.lat.toFixed(4)},${mbp.location.lng.toFixed(4)}`;
      if (!poiCoords.has(coordKey)) {
        all.push({
          poiId: mbp.id,
          latitude: mbp.location.lat,
          longitude: mbp.location.lng,
          name: mbp.name,
          category: mbp.category,
          source: 'mapbox'
        });
        poiCoords.add(coordKey);
      }
    });

    let list = all;

    if (mode === "SELECTION" && selection?.mode === "polygon" && selection.polygon.length >= 3) {
      list = list.filter((p) => isPointInsidePolygon(p.latitude, p.longitude, selection.polygon));
    }

    const activeKeys = new Set(UI_CATEGORIES.filter((c) => selectedCats[c.key]).map((c) => c.key));

    const out = list.filter((p) => {
      const icon = poiIconByCategory(p.category);
      if (!icon) return true;
      return activeKeys.has(icon.uiKey);
    });

    // 2. Performance Rule: Cap at 1000 POIs to prevent memory bloating
    return out.slice(0, 1000);
  }, [poisRaw, mapboxPois, mode, selection, selectedCats, viewState.zoom]);

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

    const bottomPad = isMobile ? 340 : 380; // Optimized for lowered list sheet
    const rightPad = isMobile ? 16 : filterOpen ? (FILTER_PANEL_APPROX_WIDTH_DESKTOP + 60) : 90;

    map.fitBounds(
      [
        [bbox.minLng, bbox.minLat],
        [bbox.maxLng, bbox.maxLat],
      ],
      {
        duration: 800,
        padding: {
          top: isMobile ? 80 : 100,
          left: isMobile ? 16 : 90,
          right: rightPad,
          bottom: bottomPad,
        },
      }
    );
  }, [canShowResultsPanel, selection, filterOpen, isMobile]);

  const mapPadding = useMemo(() => ({
    top: 0,
    bottom: 0,
    left: 0,
    right: (isChatOpen || activeRoute) ? (isMobile ? 0 : 440) : 0
  }), [isChatOpen, activeRoute, isMobile]);

  if (loadingAuth || !user) return null;

  // ---------- Responsive sizes ----------
  const headerHeight = isMobile ? 54 : 64;
  const contentPadding = isMobile ? 0 : 24;
  const mapContainerRadius = isMobile ? 0 : 12;
  const mapContainerHeight = isMobile ? `calc(100vh - ${headerHeight}px)` : `calc(100vh - ${headerHeight + contentPadding * 2}px)`;

  const fabSize = isMobile ? 44 : 48;
  const fabGap = isMobile ? 8 : 10;

  const filterPanelWidth = isMobile ? "min(92vw, 360px)" : 280;
  const filterPanelTop = isMobile ? headerHeight + 10 : 28;
  const filterPanelRight = isMobile ? 12 : 78;

  const resultsWidth = isMobile ? "calc(100% - 24px)" : "min(760px, calc(100% - 48px))";
  const resultsBottom = isMobile ? 12 : 18;
  const resultsMaxHeight = isMobile ? 220 : 240;


  return (
    <div className={`vivid-map-page ${themeClass} ${sidebarOpen ? "sidebar-open" : ""}`}>

      {/* 1. Header (TOPBAR) */}
      <header className={`vivid-map-header ${themeClass}`}>
        <div className="header-left">
          <button className="hamburger-btn vivid-interactive" onClick={() => setSidebarOpen(true)}>
            <div className="line" />
            <div className="line" />
            <div className="line" />
          </button>
          <div className="brand-logo vivid-brand">Vacanza</div>
        </div>
        <div className="header-right" style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div
            className="vivid-theme-toggle"
            onClick={toggleTheme}
            title={isDarkMode ? "Switch to Day Mode" : "Switch to Night Mode"}
          >
            <button className={`toggle-btn ${isDarkMode ? 'is-night' : 'is-day'}`}>
              {isDarkMode ? <SunOutlined /> : <MoonOutlined />}
            </button>
          </div>
        </div>
      </header>

      {/* 2. Sidebar (Hamburger Menu Content) */}
      <div className="vivid-sidebar-overlay" onClick={() => setSidebarOpen(false)} />
      <aside className="vivid-sidebar">
        <div className="sidebar-header" style={{ marginBottom: 24 }}>
          <span className="brand-logo" style={{ marginLeft: 0, fontSize: 24 }}>Settings</span>
        </div>

        <div className="sidebar-user-section">
          <div className="sidebar-avatar-wrapper">
            <Avatar size={90} src={profilePhotoUrl || profile?.profileImageUrl || defaultAvatar} className="sidebar-avatar" />
          </div>
          <div className="sidebar-info" style={{ textAlign: "center" }}>
            <div className="sidebar-username">{profile?.preferredName || profile?.firstName || user?.displayName || "Adventurer"}</div>
            <div className="sidebar-role">{gamification?.levelText || "Level 1 Explorer"}</div>
          </div>

          <div className="sidebar-xp-container">
            <div className="xp-label">
              <span>Level Progress</span>
              <span>{gamification?.xpProgressPercent || 0}%</span>
            </div>
            <div className="sidebar-xp-bar">
              <div className="sidebar-xp-fill" style={{ width: `${gamification?.xpProgressPercent || 0}%` }} />
            </div>
          </div>
        </div>

        <nav className="sidebar-menu">
          <button className="sidebar-item vivid-interactive" onClick={() => { setProfileModalOpen(true); setSidebarOpen(false); }}>
            <UserOutlined /> Account Profile
          </button>

          <button className="sidebar-item vivid-interactive" onClick={() => { setCalendarOpen(true); setSidebarOpen(false); }}>
            <CalendarOutlined /> Trip Agenda
          </button>

          <button className="sidebar-item vivid-interactive" onClick={() => { setPreferencesModalOpen(true); setSidebarOpen(false); }}>
            <SettingsIcon /> Preferences
          </button>

          <button className="sidebar-item logout vivid-interactive" onClick={handleLogout}>
            <LogoutIcon /> Sign Out
          </button>
        </nav>
      </aside>

      {/* 3. Main Content (MAP) */}
      <main className={`map-layout-content ${viewState.zoom >= 20 ? "zoom-at-max" : viewState.zoom <= 1.5 ? "zoom-at-min" : ""}`}>
        <Map
          ref={mapRef}
          {...viewState}
          padding={mapPadding}
          onMove={(evt) => setViewState(evt.viewState)}
          onClick={() => setViewportPoiPopoverKey(null)}
          onIdle={handleMapIdle}
          onMoveEnd={() => { if (mode === "VIEWPORT" && !freehandEnabled) scheduleViewportFetch(); }}
          mapStyle={mapStyle}
          mapboxAccessToken={MAPBOX_TOKEN}
          onMouseDown={onMouseDownFreehand}
          onMouseMove={onMouseMoveFreehand}
          onMouseUp={onMouseUpFreehand}
          onLoad={onMapLoad}
          onStyleData={onStyleData}
          projection="globe"
          renderWorldCopies={false}
          style={{ width: "100%", height: "100%" }}
          dragPan={!freehandEnabled}
          cursor={freehandEnabled ? "crosshair" : "grab"}
          attributionControl={false}
          minZoom={1.5}
          maxZoom={20}
        >
          <NavigationControl position="bottom-left" showCompass={false} />
          <GeolocateControl position="bottom-left" />

          <Source id="selection-src" type="geojson" data={selectionGeoJSON}>
            <Layer {...selectionFillLayer} />
          </Source>
          <Source id="selection-outline-src" type="geojson" data={selectionOutlineGeoJSON} lineMetrics>
            <Layer {...selectionOutlineGlowLayer} />
            <Layer {...selectionOutlineMainLayer} />
          </Source>
          <Source id="preview-src" type="geojson" data={previewGeoJSON} lineMetrics>
            <Layer {...previewGlowLayer} />
            <Layer {...previewMainLayer} />
          </Source>
          {pois.map((p) => {
            const icon = poiIconByCategory(p);
            const catKey = icon?.uiKey || "others";
            if (!selectedCats[catKey]) return null;

            const title = getSafePoiTitle(p);
            const catInfo = UI_CATEGORIES.find(c => c.key === catKey);
            const markerBg = catInfo?.fill || "rgba(100, 116, 139, 1)";
            const markerKey = getMapPoiRowKey(p);
            const catLabel = labelByCategory(p);
            const mapPoiFavored = deriveMapPoiFavorited(feedbackAffinity, p);
            const zoomScale = Math.min(1.2, Math.max(0.7, viewState.zoom / 15));

            const popoverContent = (
              <div className="map-viewport-poi-card glass-panel">
                <div className="map-viewport-poi-card__row">
                  <div className="map-viewport-poi-card__text">
                    <div className="map-viewport-poi-card__title">{title}</div>
                    {catLabel ? <div className="map-viewport-poi-card__meta">{catLabel}</div> : null}
                  </div>
                  {user && Number.isFinite(Number(p.latitude)) && Number.isFinite(Number(p.longitude)) ? (
                    <Tooltip title={mapPoiFavored ? "Remove favorite" : "Save to favorites"}>
                      <button
                        type="button"
                        className={`map-poi-fav-hit${mapPoiFavored ? " map-poi-fav-hit--active" : ""}`}
                        aria-label={mapPoiFavored ? "Remove favorite" : "Save to favorites"}
                        aria-pressed={mapPoiFavored}
                        disabled={favSendingKey === markerKey}
                        onClick={(e) => {
                          e.stopPropagation();
                          toggleMapPoiFavorite(p);
                        }}
                      >
                        {favSendingKey === markerKey ? (
                          <Spin size="small" className="map-poi-fav-hit__spin" />
                        ) : (
                          <span className="map-poi-fav-hit__icon-wrap" aria-hidden>
                            {mapPoiFavored ? (
                              <HeartFilled className="map-poi-fav-hit__heart map-poi-fav-hit__heart--filled" />
                            ) : (
                              <HeartOutlined className="map-poi-fav-hit__heart" />
                            )}
                          </span>
                        )}
                      </button>
                    </Tooltip>
                  ) : (
                    <span className="map-viewport-poi-card__hint">Sign in to save favorites</span>
                  )}
                </div>
              </div>
            );

            return (
              <Marker key={p.poiId || `${p.latitude}-${p.longitude}-${title}`} longitude={p.longitude} latitude={p.latitude} anchor="bottom">
                <Popover
                  open={viewportPoiPopoverKey === markerKey}
                  onOpenChange={(open) => {
                    if (open) setViewportPoiPopoverKey(markerKey);
                    else setViewportPoiPopoverKey((k) => (k === markerKey ? null : k));
                  }}
                  trigger="click"
                  placement="top"
                  rootClassName="map-viewport-poi-popover"
                  styles={{ body: { padding: 0 } }}
                  content={popoverContent}
                >
                  <div
                    className={`map-viewport-marker-hit vivid-interactive${viewportPoiPopoverKey === markerKey ? " map-viewport-marker-hit--open" : ""}`}
                    role="button"
                    tabIndex={0}
                    aria-label={`${title}. Tap for details and favorites.`}
                    onClick={(e) => e.stopPropagation()}
                    style={{ transform: `scale(${zoomScale})`, transition: "transform 0.2s ease-out" }}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault();
                        e.stopPropagation();
                        setViewportPoiPopoverKey((prev) => (prev === markerKey ? null : markerKey));
                      }
                    }}
                  >
                    <div style={{ cursor: "pointer", filter: "drop-shadow(0 4px 8px rgba(0,0,0,0.25))" }}>
                      <div
                        style={{
                          width: 32,
                          height: 32,
                          borderRadius: "50% 50% 50% 0",
                          transform: "rotate(-45deg)",
                          background: markerBg,
                          border:
                            viewportPoiPopoverKey === markerKey
                              ? "2.5px solid var(--vivid-blue, #3da8c8)"
                              : "2.5px solid white",
                          display: "grid",
                          placeItems: "center",
                          boxShadow: "0 4px 12px rgba(0,0,0,0.15)",
                          position: "relative",
                        }}
                      >
                        <div
                          style={{
                            transform: "rotate(45deg)",
                            color: "white",
                            display: "grid",
                            placeItems: "center",
                            width: 22,
                            height: 22,
                            fontSize: 16,
                            lineHeight: 0,
                          }}
                        >
                          {icon?.icon || <GlobalOutlined />}
                        </div>
                      </div>
                    </div>
                  </div>
                </Popover>
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
            <Marker key={`route-wp-${wp.day}-${wp.order}`} longitude={wp.longitude} latitude={wp.latitude} anchor="center">
              <Tooltip title={wp.name} placement="top">
                <div style={{
                  width: 30, height: 30, borderRadius: "50%", background: "linear-gradient(135deg, #F97316, #EF4444)",
                  border: "2.5px solid white", display: "flex", alignItems: "center", justifyContent: "center",
                  color: "white", fontSize: 13, fontWeight: 800, boxShadow: "0 2px 8px rgba(249,115,22,0.4)", cursor: "pointer"
                }}>{idx + 1}</div>
              </Tooltip>
            </Marker>
          ))}
        </Map>

        {/* 4. AI Sticky Pill (CENTRAL) - ONLY show if results panel and chat are closed */}
        {!canShowResultsPanel && !isChatOpen && (
          <button className="vivid-ai-sticky-pill vivid-interactive" onClick={() => {
            setFilterOpen(false);
            setFabExpanded(false);
            setIsChatOpen(true);
          }}>
            <div className="pill-content">
              <CompassOutlined className="pill-icon" />
              <span className="pill-text">Ask Vacanza AI</span>
            </div>
          </button>
        )}

        {/* 5. Unified Action FAB (RIGHT) */}
        <div className="vivid-fab-group">
          <Tooltip title={fabExpanded ? "Close" : "Actions"} placement="left">
            <button className={`main-fab vivid-interactive ${fabExpanded ? "expanded" : ""}`} onClick={() => {
              const next = !fabExpanded;
              if (next) {
                setFilterOpen(false);
                setIsChatOpen(false);
              }
              setFabExpanded(next);
            }}>
              {fabExpanded ? <CloseOutlined /> : <CompassOutlined style={{ fontSize: 24 }} />}
            </button>
          </Tooltip>

          <div className={`fab-sub-actions ${fabExpanded ? "visible" : ""}`}>
            <Tooltip title="Local Filters" placement="left">
              <button className="sub-fab vivid-interactive" onClick={() => {
                const next = !filterOpen;
                if (next) setIsChatOpen(false);
                setFilterOpen(next);
                setFabExpanded(false);
              }}>
                <UnorderedListOutlined />
              </button>
            </Tooltip>
            <Tooltip title="Draw Area" placement="left">
              <button className="sub-fab vivid-interactive" onClick={() => { startFreehand(); setFabExpanded(false); }}>
                <PencilIcon />
              </button>
            </Tooltip>
            <Tooltip title="Book Flights & Hotels" placement="left">
              <button className="sub-fab vivid-interactive" onClick={() => { setBookingOpen(true); setFabExpanded(false); }}>
                <CalendarOutlined />
              </button>
            </Tooltip>
            <Tooltip title={is3D ? "Reset to 2D View" : "Enable 3D Perspective"} placement="left">
              <button className="sub-fab vivid-interactive" onClick={() => { handleToggle2D3D(); /* No setFabExpanded(false) */ }}>
                <CubeIcon />
              </button>
            </Tooltip>
            <Tooltip title="Switch Map Theme" placement="left">
              <button className="sub-fab vivid-interactive" onClick={() => { handleStyleChange(); /* No setFabExpanded(false) */ }}>
                <LayerIcon />
              </button>
            </Tooltip>
          </div>
        </div>

        {/* 5. Filter Panel (Glass) */}
        {filterOpen && (
          <div className="glass-panel filter-panel">
            <div className="filter-header">
              <span className="filter-title">Filter Places</span>
              <div className="filter-header-actions" style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <Button size="small" type="link" onClick={handleSelectAllFilters} style={{ padding: "0 4px", fontSize: 13, height: "auto" }}>All</Button>
                <div style={{ height: 12, width: 1, background: "rgba(0,0,0,0.1)" }} />
                <Button size="small" type="link" onClick={handleDeselectAllFilters} style={{ padding: "0 4px", fontSize: 13, height: "auto" }}>None</Button>
                <Button type="text" size="small" icon={<CloseOutlined />} onClick={() => setFilterOpen(false)} style={{ marginLeft: 4 }} />
              </div>
            </div>
            <div className="filter-body">
              {UI_CATEGORIES.map((c) => (
                <div key={c.key} className="cat-pill vivid-interactive" onClick={() => setSelectedCats(prev => ({ ...prev, [c.key]: !prev[c.key] }))}
                  style={{
                    background: selectedCats[c.key] ? c.pill : "rgba(var(--vivid-navy-rgb, 26,35,50), 0.05)",
                    border: selectedCats[c.key] ? `2.5px solid ${c.ring}` : "1.5px solid rgba(255,255,255,0.08)",
                    opacity: selectedCats[c.key] ? 1 : 0.6
                  }}
                >
                  <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
                    <div className="cat-pill-icon" style={{ color: selectedCats[c.key] ? c.ring : "var(--text-sub)" }}>{c.icon}</div>
                    <span className="cat-pill-label">{c.label}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* 6. Results Sheet (Glass) */}
        {canShowResultsPanel && (
          <div className="glass-panel results-sheet">
            <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 16 }}>
              <div>
                <div style={{ fontWeight: 800, fontSize: 18 }}>Discover Local Gems</div>
                <div style={{ fontSize: 13, color: "var(--text-sub)" }}>{resultsPois.length} curated spots found</div>
              </div>
              <div style={{ display: "flex", gap: 8 }}>
                {user && !activeRoute && (
                  <Button type="primary" shape="round" onClick={openPolygonRouteParams} style={{ background: "var(--vivid-blue)", borderColor: "var(--vivid-blue)" }}>
                    Create AI Route
                  </Button>
                )}
                <Button type="text" icon={<CloseOutlined />} onClick={clearSelectionOnly} />
              </div>
            </div>

            <div style={{ display: "flex", gap: 10, overflowX: "auto", paddingBottom: 12 }}>
              {[{ key: "all", label: "Overview", icon: <GlobalOutlined /> }, ...UI_CATEGORIES].map(t => {
                const active = resultsTab === t.key;
                return (
                  <button key={t.key} onClick={() => setResultsTab(t.key)}
                    style={{
                      flex: "0 0 auto", display: "flex", alignItems: "center", gap: 8, padding: "8px 16px", borderRadius: 20,
                      border: active ? "1px solid var(--vivid-blue)" : "1px solid rgba(0,0,0,0.1)",
                      background: active ? "rgba(61, 168, 200, 0.1)" : "rgba(255,255,255,0.5)",
                      color: active ? "var(--vivid-blue)" : "var(--text-main)", fontWeight: 600, cursor: "pointer"
                    }}
                  >
                    {t.icon || <GlobalOutlined />} {t.label}
                  </button>
                );
              })}
            </div>

            <div style={{ height: resultsMaxHeight, overflowY: "auto", marginTop: 8, paddingRight: 4, display: "flex", flexDirection: "column" }}>
              {poiLoading ? (
                <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: 12, opacity: 0.8 }}>
                  <Spin size="large" />
                  <div style={{ fontSize: 13, fontWeight: 600, color: "var(--text-sub)" }}>Finding nearby gems...</div>
                </div>
              ) : resultsPois.length > 0 ? (
                resultsPois.map((p) => {
                  const favRowKey = getMapPoiRowKey(p);
                  const mapPoiFavored = deriveMapPoiFavorited(feedbackAffinity, p);
                  return (
                  <div key={favRowKey} style={{
                    display: "flex", alignItems: "center", gap: 16, padding: "14px 18px",
                    borderRadius: 20, background: "rgba(var(--vivid-navy-rgb, 255,255,255), 0.08)",
                    marginBottom: 10, border: "1px solid rgba(255,255,255,0.06)",
                    backdropFilter: "blur(4px)",
                    flexShrink: 0
                  }}>
                    <div style={{
                      width: 48, height: 48, borderRadius: 14,
                      background: "rgba(255,255,255,0.05)",
                      display: "grid", placeItems: "center",
                      boxShadow: "0 4px 12px rgba(0,0,0,0.1)",
                      border: "1px solid rgba(255,255,255,0.1)"
                    }}>
                      <div style={{
                        color: poiIconByCategory(p)?.ring,
                        fontSize: 20,
                        filter: "drop-shadow(0 2px 4px rgba(0,0,0,0.1))"
                      }}>
                        {poiIconByCategory(p)?.icon}
                      </div>
                    </div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ fontWeight: 700, fontSize: 16 }}>{getSafePoiTitle(p)}</div>
                      <div style={{ fontSize: 12, opacity: 0.7 }}>{labelByCategory(p)}</div>
                    </div>
                    {user && Number.isFinite(Number(p.latitude)) && Number.isFinite(Number(p.longitude)) ? (
                      <Tooltip title={mapPoiFavored ? "Remove favorite" : "Favorite"}>
                        <button
                          type="button"
                          className={`map-poi-fav-hit map-poi-fav-hit--in-sheet${mapPoiFavored ? " map-poi-fav-hit--active" : ""}`}
                          aria-label={mapPoiFavored ? "Remove favorite" : "Add favorite"}
                          aria-pressed={mapPoiFavored}
                          disabled={favSendingKey === favRowKey}
                          onClick={() => toggleMapPoiFavorite(p)}
                        >
                          {favSendingKey === favRowKey ? (
                            <Spin size="small" className="map-poi-fav-hit__spin" />
                          ) : (
                            <span className="map-poi-fav-hit__icon-wrap" aria-hidden>
                              {mapPoiFavored ? (
                                <HeartFilled className="map-poi-fav-hit__heart map-poi-fav-hit__heart--filled" />
                              ) : (
                                <HeartOutlined className="map-poi-fav-hit__heart" />
                              )}
                            </span>
                          )}
                        </button>
                      </Tooltip>
                    ) : null}
                  </div>
                  );
                })
              ) : (
                <div style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", opacity: 0.5 }}>
                  <GlobalOutlined style={{ fontSize: 32, marginBottom: 12 }} />
                  <div style={{ fontSize: 14, fontWeight: 600 }}>No results in this area</div>
                </div>
              )}
            </div>
          </div>
        )}

        <Modal title="AI Route Parameters" open={polygonRouteParamsOpen} onCancel={() => setPolygonRouteParamsOpen(false)} footer={null} zIndex={1100}>
          <Spin spinning={polygonRouteSubmitting}>
            <Form form={polygonRouteForm} layout="vertical" onFinish={submitPolygonRoute}>
              <Form.Item name="totalDays" label="Duration (Days)"><InputNumber min={1} max={14} style={{ width: "100%" }} /></Form.Item>
              <Form.Item name="travelStyle" label="Travel Style"><Select options={[{ value: "general", label: "Balanced" }, { value: "history", label: "Historical" }, { value: "food", label: "Gourmet" }, { value: "nature", label: "Outdoors" }]} /></Form.Item>
              <Button type="primary" block size="large" htmlType="submit" loading={polygonRouteSubmitting} style={{ borderRadius: 12 }}>Generate Smart Route</Button>
            </Form>
          </Spin>
        </Modal>

        <BookingSheet open={bookingOpen} onClose={() => setBookingOpen(false)} />

        {/* 7. Itinerary/Route Card (RoutePanel) - RESTORED */}
        {activeRoute && (
          <RoutePanel
            route={activeRoute}
            activeDay={activeDay}
            onDayChange={setActiveDay}
            onClose={() => setActiveRoute(null)}
          />
        )}

        <VacanzaChat
          isOpen={isChatOpen}
          onClose={() => setIsChatOpen(false)}
          externalConversationRefreshNonce={chatConversationRefreshNonce}
          onConversationIdChange={setMapChatConversationId}
          onRequestDrawToEdit={handleRequestDrawToEditFromChat}
          onRouteGenerated={(routeData, meta) => {
            setActiveRoute(normalizeRouteForMap(routeData));
            setActiveDay(1);
            setIsChatOpen(false);
          }}
        />
        <ProfileModal
          open={profileModalOpen}
          onClose={() => setProfileModalOpen(false)}
          user={user}
          themeClass={themeClass}
          isDarkMode={isDarkMode}
          onOpenPreferences={() => {
            setProfileModalOpen(false);
            setPreferencesModalOpen(true);
          }}
          onOpenCalendar={() => {
            setProfileModalOpen(false);
            setCalendarOpen(true);
          }}
        />
        <PreferencesModal
          open={preferencesModalOpen}
          onClose={() => setPreferencesModalOpen(false)}
          themeClass={themeClass}
          isDarkMode={isDarkMode}
        />
        <CalendarModal
          open={calendarOpen}
          onClose={() => setCalendarOpen(false)}
        />
      </main>
    </div>
  );
}
