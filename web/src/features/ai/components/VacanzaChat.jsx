import React, { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { aiApi } from "../../../api/aiApi";
import { Spin, message, Tooltip } from "antd";
import {
  CloseOutlined,
  CompassOutlined,
  EditOutlined,
  EnvironmentOutlined,
  HistoryOutlined,
  PlusOutlined,
  SendOutlined,
} from "@ant-design/icons";
import { Rnd } from "react-rnd";
import "../styles/vacanzaChat.css";
import { normalizeRouteForMap } from "../utils/routeMap";
import { getTipsForCity } from "../data/loadingTips";
import RouteCardFeedback from "./RouteCardFeedback";
import EventRecommendations from "./EventRecommendations";

/**
 * Sayfa oturumu: kullanıcı mesaj attıysa oluşturulmuş conversation id.
 * Boş sohbet sunucuda yaratılmaz; ilk mesajda createConversation çağrılır.
 */
let sessionConversationId = null;
let sessionHasOpenedChatThisPageLoad = false;

/** Harita / ebeveyn: aktif sohbet kimliği (replan vb.). */
export function getSessionConversationId() {
  return sessionConversationId;
}

/** Haritadan üretilen rotanın sohbet kaydına bağlanması (geçmiş listesinde görünsün). */
export function linkPolygonRouteConversation(conversationId) {
  if (conversationId == null || String(conversationId).trim() === "") return;
  sessionConversationId = String(conversationId).trim();
}

/** Saved route from GET /routes/conversation/:id (routeData may be object or JSON string). */
function routeDataFromSavedDetail(detail) {
  if (!detail || detail.routeData == null) return null;
  const raw = detail.routeData;
  if (typeof raw === "string") {
    try {
      return normalizeRouteForMap(JSON.parse(raw));
    } catch {
      return null;
    }
  }
  return normalizeRouteForMap(raw);
}

function routesForMessage(msg) {
  if (msg.routeDataList?.length) return msg.routeDataList;
  if (msg.routeData) return [msg.routeData];
  return [];
}

function stripEmojis(text) {
  if (!text) return text;
  return String(text)
    .replace(/[\p{Extended_Pictographic}\p{Emoji_Presentation}]/gu, '')
    .trim();
}

/**
 * Sohbet balonu: model **kalın** işaretlerini gerçek vurguya çevirir (düz metinde ** kalmaz).
 * Satır sonları .msg-text { white-space: pre-wrap } ile korunur.
 */
function ChatBubbleRichText({ text }) {
  const s = text == null ? "" : String(text);
  if (!s.includes("**")) return s;
  const out = [];
  const re = /\*\*([^*]+)\*\*/g;
  let last = 0;
  let m;
  let k = 0;
  while ((m = re.exec(s)) !== null) {
    if (m.index > last) out.push(s.slice(last, m.index));
    out.push(<strong key={`sb-${k++}`}>{m[1]}</strong>);
    last = m.index + m[0].length;
  }
  if (last < s.length) out.push(s.slice(last));
  return out.length ? out : s;
}

/**
 * Kayıtlı rotaları asistan mesajlarına bağlar (aynı sohbette birden çok rota).
 * Dil veya metin kalıbına bakılmaz: her rota, kayıttaki generatedAt ile zaman olarak en yakın
 * ve henüz başka rotaya atanmamış asistan balonuna düşer; böylece kart her dilde ilgili cevabın altında kalır.
 */
function mergeHistoryWithSavedRoutes(historyRaw, routeDetails) {
  const list = Array.isArray(routeDetails) ? routeDetails : [];
  const visibleHistory = (historyRaw || []).filter(
    (m) => !isSearchPoisPipelineMessage(m.content ?? "")
  );
  const msgs = visibleHistory.map((m) => {
    const base = mapHistoryMessage(m);
    const role = (m.role ?? "").toLowerCase();
    return {
      ...base,
      _createdAtMs: parseDate(m.created_at ?? m.createdAt)?.getTime() ?? 0,
      _isAssistant: role !== "user",
    };
  });
  const routes = list
    .map((detail) => ({
      data: routeDataFromSavedDetail(detail),
      routeId: detail.routeId ?? detail.route_id ?? null,
      userFeedback: detail.userFeedback ?? detail.user_feedback ?? null,
      t: routeGeneratedAtMs(detail),
    }))
    .filter((x) => x.data)
    .sort((a, b) => a.t - b.t);

  const assistantPool = msgs.filter((m) => m._isAssistant).sort((a, b) => a._createdAtMs - b._createdAtMs);

  const byMessageId = new Map();
  const usedAssistantIds = new Set();

  function pickAssistantForRoute(rr) {
    const candidates = assistantPool.filter((m) => !usedAssistantIds.has(m.id));
    if (candidates.length === 0) {
      return null;
    }
    let best = null;
    let bestScore = Infinity;
    for (const msg of candidates) {
      const dt = Math.abs(msg._createdAtMs - rr.t);
      const latePenalty = msg._createdAtMs + 1500 < rr.t ? 60000 : 0;
      const score = dt + latePenalty;
      if (score < bestScore) {
        bestScore = score;
        best = msg;
      }
    }
    return best;
  }

  for (let i = 0; i < routes.length; i++) {
    const rr = routes[i];
    let best = pickAssistantForRoute(rr);
    if (!best && assistantPool.length) {
      best = assistantPool[assistantPool.length - 1];
    }
    if (best) {
      usedAssistantIds.add(best.id);
      const bundle = byMessageId.get(best.id) ?? { data: [], routeIds: [], feedbacks: [] };
      bundle.data.push(rr.data);
      bundle.routeIds.push(rr.routeId);
      bundle.feedbacks.push(rr.userFeedback);
      byMessageId.set(best.id, bundle);
    }
  }
  for (const msg of msgs) {
    const bundle = byMessageId.get(msg.id);
    if (bundle?.data?.length) {
      msg.routeDataList = bundle.data;
      msg.routeData = bundle.data[bundle.data.length - 1];
      msg.routeIdList = bundle.routeIds;
      msg.routeFeedbackList = bundle.feedbacks;
    }
    delete msg._createdAtMs;
    delete msg._isAssistant;
  }
  return msgs;
}

function formatForecastDateShort(iso) {
  if (!iso) return "—";
  const d = new Date(String(iso).slice(0, 10));
  return Number.isNaN(d.getTime())
    ? String(iso)
    : d.toLocaleDateString("en-US", { weekday: "short", day: "numeric", month: "short" }).replace(',', '');
}

/** Weather cards — route JSON’unda weather_forecast varsa sohbet kartında gösterilir. */
function RouteWeatherStrip({ rd }) {
  const wf = rd?.weather_forecast ?? rd?.weatherForecast;
  if (!Array.isArray(wf) || wf.length === 0) return null;

  return (
    <div className="route-card-weather-strip-multi" role="status">
      {wf.slice(0, 5).map((row, i) => {
        const tMax = row.temp_max_celsius ?? row.tempMaxCelsius;
        const tMin = row.temp_min_celsius ?? row.tempMinCelsius;
        const precip =
          row.precipitation_probability_max_percent ?? row.precipitationProbabilityMaxPercent;

        const hasTemp = tMax != null && tMin != null;
        if (!hasTemp && precip == null) return null;

        return (
          <div key={i} className="weather-mini-card">
            <div className="weather-mini-date">{formatForecastDateShort(row.date)}</div>
            <div className="weather-mini-temp">
              {tMax != null ? `${Math.round(tMax)}°C` : ""}
              {tMax != null && tMin != null && <span className="weather-mini-temp-sep"> / </span>}
              {tMin != null ? `${Math.round(tMin)}°C` : ""}
            </div>
            {precip != null && Number.isFinite(Number(precip)) && precip > 0 && (
              <div className="weather-mini-precip">Rain {Math.round(precip)}%</div>
            )}
          </div>
        );
      })}
    </div>
  );
}

function parseDate(value) {
  if (value == null) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (Array.isArray(value) && value.length >= 3) {
    const [y, mo, d, h = 0, mi = 0, s = 0] = value;
    const dt = new Date(y, mo - 1, d, h, mi, s);
    return Number.isNaN(dt.getTime()) ? null : dt;
  }
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function routeGeneratedAtMs(detail) {
  const raw = detail?.generatedAt ?? detail?.generated_at;
  if (raw == null) return 0;
  if (typeof raw === "number" && Number.isFinite(raw)) return raw;
  const d = parseDate(raw);
  return d ? d.getTime() : 0;
}

function formatMessageTime(value) {
  const d = parseDate(value);
  if (!d) return "";
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

/** Subtitle for conversation list rows (similar idea to mobile sheet). */
function formatConversationDate(value) {
  const d = parseDate(value);
  if (!d) return "";
  const now = new Date();
  const diff = now.getTime() - d.getTime();
  const days = Math.floor(diff / (24 * 60 * 60 * 1000));
  if (days === 0) {
    return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }
  if (days === 1) return "Yesterday";
  if (days < 7) return `${days} days ago`;
  return d.toLocaleDateString(undefined, { day: "numeric", month: "short" });
}

function normalizeConversation(c) {
  if (!c || typeof c !== "object") return null;
  const id = String(c.id ?? "");
  if (!id) return null;
  return {
    id,
    title: c.title != null && String(c.title).trim() ? String(c.title).trim() : null,
    updatedAt: c.updated_at ?? c.updatedAt,
    createdAt: c.created_at ?? c.createdAt,
  };
}

function sortConversationsDesc(list) {
  return [...list].sort((a, b) => {
    const ta = parseDate(a.updatedAt)?.getTime() ?? 0;
    const tb = parseDate(b.updatedAt)?.getTime() ?? 0;
    return tb - ta;
  });
}

/** Harita polygon → rota: kullanıcıya gösterilecek (içerik maskelenir). */
function isPolygonMapRouteUserMessage(content) {
  return typeof content === "string" && content.trim().startsWith("[Polygon route request]");
}

/** Günü çizim alanına göre yeniden planlama (arka uç pipeline mesajı). */
function isReplanDayMapUserMessage(content) {
  return typeof content === "string" && content.trim().startsWith("[Replan day request]");
}

/** Internal POI tool round-trip rows (saved for LLM context; not for end-user UI). */
function isSearchPoisPipelineMessage(content) {
  if (content == null || typeof content !== "string") return false;
  if (isPolygonMapRouteUserMessage(content) && content.includes("__TOOL_RESULT__search_pois__")) {
    return false;
  }
  if (isReplanDayMapUserMessage(content) && content.includes("__TOOL_RESULT__search_pois__")) {
    return false;
  }
  if (content.includes("__TOOL_RESULT__search_pois__")) return true;
  const t = content.trim();
  if (!t.startsWith("{")) return false;
  try {
    const obj = JSON.parse(t);
    return obj && obj.tool === "search_pois";
  } catch {
    return false;
  }
}

function stripExistingRouteBlock(text) {
  if (typeof text !== "string") return text;
  const marker = "\n__EXISTING_ROUTE__";
  const idx = text.indexOf(marker);
  if (idx !== -1) return text.slice(0, idx).trim();
  // Also handle no leading newline
  if (text.includes("__EXISTING_ROUTE__")) {
    return text.split("__EXISTING_ROUTE__")[0].trim();
  }
  return text;
}

function mapHistoryMessage(m) {
  const role = (m.role ?? "").toLowerCase();
  const type = role === "user" ? "user" : "ai";
  let text = m.content ?? "";
  if (type === "user") text = stripExistingRouteBlock(text);
  if (type === "user" && isPolygonMapRouteUserMessage(text)) {
    text = "Route created from the area drawn on the map.";
  }
  if (type === "user" && isReplanDayMapUserMessage(text)) {
    text = "Selected day was replanned based on the area drawn on the map.";
  }
  return {
    id: String(m.id ?? `${Date.now()}-${Math.random()}`),
    type,
    text,
    time: formatMessageTime(m.created_at ?? m.createdAt),
    routeData: undefined,
    noRouteHint: false,
  };
}

const GREETING = {
  id: "greeting",
  type: "ai",
  text: "Hello, I'm Vacanza AI. Where would you like to explore today?",
  time: "",
};

function normalizePricingRow(raw) {
  if (!raw || typeof raw !== "object") return null;
  return {
    waypointName: raw.waypointName ?? raw.waypoint_name ?? "",
    day: Number(raw.day) || 0,
    order: Number(raw.order) || 0,
    minPriceUsd: raw.minPriceUsd ?? raw.min_price_usd,
    currency: raw.currency ?? "USD",
    bookingUrl: raw.bookingUrl ?? raw.booking_url,
    productTitle: raw.productTitle ?? raw.product_title ?? null,
    found: Boolean(raw.found),
    status: raw.status,
    message: raw.message,
  };
}

function formatTicketPriceLine(row) {
  if (!row?.found || row.minPriceUsd == null) return null;
  const n = Number(row.minPriceUsd);
  const ccy = row.currency || "USD";
  if (Number.isNaN(n)) return `from ${ccy}`;
  const decimals = n % 1 === 0 ? 0 : 2;
  return `from $${n.toFixed(decimals)} ${ccy}`;
}

export default function VacanzaChat({
  isOpen,
  onClose,
  onRouteGenerated,
  /** Haritadan rota kaydı sonrası artırın; geçmiş sohbet listesi yenilensin. */
  externalConversationRefreshNonce = 0,
  /** Sohbet değişince haritada conversationId senkronu (replan gün). */
  onConversationIdChange,
  /** Haritada serbest çizim modunu aç (rota kartı üstü “Yeniden çiz”). */
  onRequestDrawToEdit,
}) {
  const [messages, setMessages] = useState([]);
  const [inputText, setInputText] = useState("");
  const [loading, setLoading] = useState(false);
  const [sendError, setSendError] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const [conversations, setConversations] = useState([]);
  const [initialLoading, setInitialLoading] = useState(true);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [historyPanelOpen, setHistoryPanelOpen] = useState(false);
  /** `${messageId}-${routeIndex}` → bilet fiyatları yüklenirken / sonuç satırları */
  const [ticketLoadingByKey, setTicketLoadingByKey] = useState({});
  const [ticketRowsByKey, setTicketRowsByKey] = useState({});
  const messagesEndRef = useRef(null);
  const scrollContainerRef = useRef(null);
  const dragNodeRef = useRef(null);
  const abortControllerRef = useRef(null);
  const lastSentTextRef = useRef(null);
  const [currentTip, setCurrentTip] = useState(null);
  const tipPoolRef = useRef([]);
  const tipIndexRef = useRef(0);

  const ticketStateKey = (msgId, rIdx) => `${msgId}-r${rIdx}`;

  const handleTicketSearch = useCallback(async (routeId, msgId, rIdx) => {
    const key = ticketStateKey(msgId, rIdx);
    setTicketLoadingByKey((prev) => ({ ...prev, [key]: true }));
    try {
      const rows = await aiApi.getRoutePricing(routeId);
      setTicketRowsByKey((prev) => ({ ...prev, [key]: Array.isArray(rows) ? rows : [] }));
    } catch (e) {
      console.error(e);
      message.error("Failed to load ticket prices. Please check your connection and try again.");
      setTicketRowsByKey((prev) => ({ ...prev, [key]: [] }));
    } finally {
      setTicketLoadingByKey((prev) => ({ ...prev, [key]: false }));
    }
  }, []);

  const scrollToBottom = () => {
    const el = scrollContainerRef.current;
    if (!el) return;
    el.scrollTo({ top: el.scrollHeight, behavior: "smooth" });
  };

  const activeTitle = useMemo(() => {
    if (!conversationId) return "Vacanza AI";
    const c = conversations.find((x) => x.id === conversationId);
    if (!c) return "New chat";
    return c.title || "New chat";
  }, [conversations, conversationId]);

  const refreshConversations = useCallback(async () => {
    try {
      const raw = await aiApi.listConversations(50, 0);
      const list = raw.map(normalizeConversation).filter(Boolean);
      setConversations(sortConversationsDesc(list));
    } catch {
      /* non-blocking */
    }
  }, []);

  const loadMessagesForConversation = useCallback(async (convId) => {
    const history = await aiApi.getMessages(convId, 500, 0);
    let routeDetails = [];
    try {
      routeDetails = await aiApi.getRoutesForConversation(convId);
    } catch {
      /* Rota isteğe bağlı; mesajlar yine yüklensin. */
    }
    if (!history.length) {
      const t = formatMessageTime(new Date());
      setMessages([{ ...GREETING, time: t }]);
    } else {
      setMessages(mergeHistoryWithSavedRoutes(history, routeDetails));
    }
  }, []);

  useEffect(() => {
    if (isOpen) {
      scrollToBottom();
    }
  }, [messages, isOpen]);

  useEffect(() => {
    if (!isOpen) return;

    let cancelled = false;

    (async () => {
      setInitialLoading(true);
      try {
        if (!sessionHasOpenedChatThisPageLoad) {
          sessionHasOpenedChatThisPageLoad = true;
          const linkedFromMap = sessionConversationId;
          if (!linkedFromMap) {
            if (cancelled) return;
            setConversationId(null);
            const t = formatMessageTime(new Date());
            setMessages([{ ...GREETING, time: t }]);
          } else {
            setConversationId(linkedFromMap);
            setMessagesLoading(true);
            try {
              await loadMessagesForConversation(linkedFromMap);
            } finally {
              if (!cancelled) setMessagesLoading(false);
            }
          }
          await refreshConversations();
        } else {
          const id = sessionConversationId;
          if (!id) {
            if (cancelled) return;
            setConversationId(null);
            const t = formatMessageTime(new Date());
            setMessages([{ ...GREETING, time: t }]);
          } else {
            setConversationId(id);
            setMessagesLoading(true);
            try {
              await loadMessagesForConversation(id);
            } finally {
              if (!cancelled) setMessagesLoading(false);
            }
          }
          await refreshConversations();
        }
      } catch (err) {
        console.error("Failed to load chat:", err);
        const t = formatMessageTime(new Date());
        setMessages([
          {
            id: "error",
            type: "ai",
            text: "Connection failed. Please try again later.",
            time: t,
          },
        ]);
      } finally {
        if (!cancelled) setInitialLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [isOpen, loadMessagesForConversation, refreshConversations]);

  useEffect(() => {
    if (!externalConversationRefreshNonce) return;
    void refreshConversations();
  }, [externalConversationRefreshNonce, refreshConversations]);

  useEffect(() => {
    onConversationIdChange?.(conversationId);
  }, [conversationId, onConversationIdChange]);

  const handleSelectConversation = async (id) => {
    if (id === conversationId) {
      setHistoryPanelOpen(false);
      return;
    }
    setHistoryPanelOpen(false);
    sessionConversationId = id;
    setMessagesLoading(true);
    setConversationId(id);
    try {
      const history = await loadMessagesForConversation(id);
    } catch (e) {
      console.error(e);
      message.error("Failed to load messages.");
    } finally {
      setMessagesLoading(false);
    }
  };

  /** Yeni taslak: sunucuda sohbet oluşturulmaz; mesaj yoksa hiçbir kayıt düşmez. */
  const handleNewChat = () => {
    sessionConversationId = null;
    setConversationId(null);
    setInputText("");
    const t = formatMessageTime(new Date());
    setMessages([{ ...GREETING, time: t }]);
    setHistoryPanelOpen(false);
  };

  const handleStop = useCallback(() => {
    abortControllerRef.current?.abort();
  }, []);

  const handleSendMessage = async (customText = null) => {
    const textToSend = (customText || inputText)?.trim();
    if (!textToSend || loading || messagesLoading) return;

    setSendError(false);
    lastSentTextRef.current = textToSend;
    abortControllerRef.current = new AbortController();
    const signal = abortControllerRef.current.signal;

    setLoading(true);
    let activeConvId = conversationId;
    try {
      if (!activeConvId) {
        const newConv = await aiApi.createConversation();
        activeConvId = String(newConv.id ?? "");
        sessionConversationId = activeConvId;
        setConversationId(activeConvId);
      }
    } catch (e) {
      console.error(e);
      message.error("Failed to start chat.");
      setLoading(false);
      return;
    }

    const userMsg = {
      id: `local-${Date.now()}`,
      type: "user",
      text: textToSend,
      time: formatMessageTime(new Date()),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText("");

    try {
      const response = await aiApi.sendMessage(activeConvId, textToSend, { signal });
      if (response && response.content) {
        const routeData = response.route_data || response.routeData || null;
        const wasRouteRequest = /plan|rota|gün|tatil|itinerary|day/i.test(textToSend);
        const aiAskedFollowUp = !routeData && wasRouteRequest &&
          /\?|hangi|which|where|nere|kaç gün|how many/i.test(response.content || "");
        if (routeData) {
          const allWps = (routeData.days || []).flatMap((d) => d.waypoints || []);
          console.log("[VacanzaChat] route_data received:", {
            title: routeData.title,
            destination: routeData.destination,
            waypointCount: allWps.length,
            waypointCoords: allWps.map((w) => ({ name: w.name, lat: w.latitude, lon: w.longitude })),
          });
        }
        if (!routeData && wasRouteRequest && !aiAskedFollowUp) {
          console.warn("[VacanzaChat] Rota isteği gönderildi ama route_data gelmedi:", response);
        }
        const routeSummaryMessage = response.route_summary_message ?? response.routeSummaryMessage;
        const displayText =
          routeData && routeSummaryMessage ? routeSummaryMessage : response.content;

        const norm = routeData ? normalizeRouteForMap(routeData) : null;
        const routeIdFromResponse = response.route_id ?? response.routeId ?? null;
        // Detect Turn3: route came back but conversation already had a route → this is a chat-edit
        const hadExistingRoute = messages.some(
          (m) => m.routeDataList?.length > 0 || m.routeData
        );
        const isRouteEdit = !!norm && hadExistingRoute;
        const aiMsg = {
          id: `local-${Date.now() + 1}`,
          type: "ai",
          text: displayText,
          routeData: norm || undefined,
          routeDataList: norm ? [norm] : undefined,
          routeIdList: norm ? [routeIdFromResponse ?? null] : undefined,
          routeFeedbackList: norm ? [null] : undefined,
          noRouteHint: !routeData && wasRouteRequest && !aiAskedFollowUp && !hadExistingRoute,
          isRouteEdit,
          time: formatMessageTime(new Date()),
        };
        setMessages((prev) => [...prev, aiMsg]);

        // Auto-update the map route card when AI edits an existing route via chat
        if (isRouteEdit && norm && onRouteGenerated) {
          onRouteGenerated(norm, {
            conversationId: activeConvId ?? undefined,
            routeId: routeIdFromResponse ?? undefined,
          });
        }

        const extractedPrefs =
          response.extracted_preferences ?? response.extractedPreferences ?? null;
        if (Array.isArray(extractedPrefs) && extractedPrefs.length > 0) {
          const snippets = extractedPrefs
            .map((p) => p.preference_value ?? p.preferenceValue)
            .filter((v) => v != null && String(v).trim() !== "")
            .map((v) => {
              const s = String(v).trim();
              return s.length > 48 ? `${s.slice(0, 45)}…` : s;
            })
            .slice(0, 2);
          const more =
            extractedPrefs.length > 2 ? ` (+${extractedPrefs.length - 2})` : "";
          message.success(
            snippets.length > 0
              ? `Preferences saved: ${snippets.join(" · ")}${more}`
              : `${extractedPrefs.length} preferences saved to your profile.`
          );
        }
      }
      await refreshConversations();
    } catch (e) {
      const isAbort =
        e?.name === "CanceledError" ||
        e?.code === "ERR_CANCELED" ||
        e?.name === "AbortError";
      if (!isAbort) {
        message.error("We are currently busy. Please try again in a few seconds.");
        setSendError(true);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleRetry = useCallback(() => {
    const text = lastSentTextRef.current;
    if (!text) return;
    setSendError(false);
    // Remove the optimistically added user message from the failed send
    setMessages((prev) => {
      const idx = [...prev].map((m, i) => ({ m, i }))
        .reverse()
        .find(({ m }) => m.type === "user" && m.text === text);
      if (idx == null) return prev;
      return prev.filter((_, i) => i !== idx.i);
    });
    handleSendMessage(text);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    if (!loading) { setCurrentTip(null); return; }
    const cityHint = lastSentTextRef.current || "";
    tipPoolRef.current = getTipsForCity(cityHint);
    tipIndexRef.current = 0;
    setCurrentTip(tipPoolRef.current[0] || null);
    const interval = setInterval(() => {
      tipIndexRef.current = (tipIndexRef.current + 1) % tipPoolRef.current.length;
      setCurrentTip(tipPoolRef.current[tipIndexRef.current]);
    }, 9000);
    return () => clearInterval(interval);
  }, [loading]);

  if (!isOpen) return null;

  const showMessageSpinner = initialLoading || messagesLoading;

  const isMobile = window.innerWidth <= 768;

  const content = (
    <div
      className={`ai-chat-container vacanza-chat ${isOpen ? "active" : ""}`}
      role="region"
      aria-label="Vacanza AI chat"
    >
      <div className="chat-header-refined">
        <div className="ai-info">
          <div className="ai-brand-avatar" aria-hidden>
            <svg
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z" />
            </svg>
          </div>
          <div className="ai-text-meta">
            <span className="ai-name" title={activeTitle}>
              {activeTitle}
            </span>
            <span className="ai-subline">Vacanza AI</span>
          </div>
        </div>
        <div className="chat-header-actions">
          <button
            type="button"
            className={`chat-header-icon-btn ${historyPanelOpen ? "chat-header-icon-btn-active" : ""}`}
            title="Chat history"
            aria-expanded={historyPanelOpen}
            aria-controls="vacanza-chat-history"
            onClick={() => {
              setHistoryPanelOpen((o) => {
                const next = !o;
                if (next) void refreshConversations();
                return next;
              });
            }}
          >
            <HistoryOutlined />
          </button>
          <button type="button" className="chat-header-icon-btn" title="New chat" onClick={handleNewChat}>
            <PlusOutlined />
          </button>
          <button type="button" className="chat-header-icon-btn" title="Close" onClick={onClose}>
            <CloseOutlined />
          </button>
        </div>
      </div>

      {historyPanelOpen ? (
        <div
          id="vacanza-chat-history"
          className="chat-history-full"
          role="region"
          aria-label="Chat history"
        >
          <div className="chat-history-full-scroll">
            <div className="chat-history-full-heading">Chat history</div>
            {!conversations.length ? (
              <div className="chat-history-full-empty">
                <div className="chat-history-full-empty-icon" aria-hidden>
                  <HistoryOutlined style={{ color: 'var(--vc-primary)' }} />
                </div>
                <p className="chat-history-full-empty-title">No saved chats yet</p>
                <p className="chat-history-full-empty-hint">
                  Start a conversation to see your chat history here.
                </p>
              </div>
            ) : (
              <ul className="chat-conv-list chat-conv-list-full">
                {conversations.map((c) => {
                  const selected = c.id === conversationId;
                  return (
                    <li key={c.id}>
                      <button
                        type="button"
                        className={`chat-conv-row ${selected ? "chat-conv-row-active" : ""}`}
                        onClick={() => handleSelectConversation(c.id)}
                      >
                        <div className="chat-conv-row-text">
                          <span className="chat-conv-row-title">{c.title || "Chat"}</span>
                          <span className="chat-conv-row-meta">{formatConversationDate(c.updatedAt)}</span>
                        </div>
                      </button>
                    </li>
                  );
                })}
              </ul>
            )}
          </div>
        </div>
      ) : (
        <>
      <div
        className="chat-content-scroll"
        ref={scrollContainerRef}
        role="log"
        aria-live="polite"
        aria-relevant="additions"
      >
        {showMessageSpinner ? (
          <div className="chat-loading-center">
            <Spin tip="Loading..." />
          </div>
        ) : (
          <>
            {messages.map((msg) => {
              const routeList = routesForMessage(msg);
              return (
              <div key={msg.id} className={`chat-row ${msg.type}-row`}>
                <div className={`message-bubble ${msg.type}-bubble`}>
                  <div className="msg-text">
                    <ChatBubbleRichText text={msg.text} />
                  </div>
                  {msg.time ? <span className="msg-time">{msg.time}</span> : null}
                </div>
                {routeList.map((rd, rIdx) => {
                  const totalDays = Number(
                    rd.total_days || rd.totalDays || (rd.days || []).length || 0
                  );
                  const totalPlaces = (rd.days || []).reduce(
                    (sum, d) => sum + (d.waypoints?.length || 0),
                    0
                  );
                  const hasWeather = Array.isArray(rd?.weather_forecast ?? rd?.weatherForecast)
                    ? (rd?.weather_forecast ?? rd?.weatherForecast).length > 0
                    : false;

                  const day1 = (rd.days || [])[0];
                  const day1Names = (day1?.waypoints || [])
                    .map((w) => stripEmojis(w.name))
                    .filter(Boolean);
                  const day1Preview = day1Names.slice(0, 2).join(" · ");
                  const day1More = Math.max(0, day1Names.length - 2);

                  return (
                  <div key={`${msg.id}-route-${rIdx}`} className="route-card-outer">
                    {msg.isRouteEdit && rIdx === 0 ? (
                      <div className="route-updated-badge" role="note">
                        <EditOutlined aria-hidden />
                        Updated via chat
                      </div>
                    ) : null}
                    {onRequestDrawToEdit ? (
                      <div
                        className={`route-card-preface ${rIdx > 0 ? "route-card-preface--stacked" : ""}`}
                        role="note"
                      >
                        <div className="route-card-preface-summary">
                          <span className="route-card-preface-label">Redraw</span>
                          <button
                            type="button"
                            className="route-draw-edit-btn"
                            aria-label="Replan the day by drawing an area on the map"
                            onClick={(e) => {
                              e.preventDefault();
                              e.stopPropagation();
                              onRequestDrawToEdit();
                              onClose();
                            }}
                          >
                            <EditOutlined aria-hidden />
                            Draw on map
                          </button>
                        </div>
                        <p className="route-card-preface-copy route-card-preface-copy--compact">
                          Draw an area, then select the day to <strong>reschedule</strong>.
                        </p>
                      </div>
                    ) : null}
                    <div className="route-card">
                      <div className="route-card-head">
                        <div className="route-card-head-main">
                          <div className="route-card-title">{rd.title}</div>
                          <div className="route-card-meta">
                            <span className="route-card-meta-item">{rd.destination}</span>
                            <span className="route-card-meta-dot" aria-hidden>
                              ·
                            </span>
                            <span className="route-card-meta-item">
                              {Number.isFinite(totalDays) && totalDays > 0 ? `${totalDays} days` : "—"}
                            </span>
                            <span className="route-card-meta-dot" aria-hidden>
                              ·
                            </span>
                            <span className="route-card-meta-item">{totalPlaces} places</span>
                          </div>
                          {day1Preview ? (
                            <div className="route-card-preview" aria-label="Itinerary preview">
                              Day 1: {day1Preview}
                              {day1More > 0 ? (
                                <span className="route-card-preview-more"> +{day1More}</span>
                              ) : null}
                            </div>
                          ) : null}
                        </div>
                      </div>
                    <button
                      type="button"
                      className="route-show-btn"
                      onClick={() => {
                        if (onRouteGenerated) {
                          onRouteGenerated(normalizeRouteForMap(rd), {
                            conversationId: conversationId ?? undefined,
                            routeId: msg.routeIdList?.[rIdx] ?? undefined,
                          });
                        }
                        onClose();
                      }}
                    >
                      <EnvironmentOutlined style={{ fontSize: 13 }} />
                      Show Route on Map
                    </button>
                    <details className="route-card-details">
                      <summary className="route-card-details-summary">
                        <span className="route-card-details-summary-left">
                          <CompassOutlined aria-hidden />
                          <span className="route-card-details-summary-title">Itinerary</span>
                          <span className="route-card-details-summary-subtitle">
                            Stops{hasWeather ? " · Weather" : ""} · Feedback
                          </span>
                        </span>
                        <span className="route-card-details-summary-kpi">
                          {Number.isFinite(totalDays) && totalDays > 0 ? `${totalDays}d` : "—"} ·{" "}
                          {totalPlaces} stops
                        </span>
                      </summary>
                      <div className="route-card-days">
                        {(rd.days || []).map((d) => (
                          <div key={d.day} className="route-card-day-row">
                            <span className="route-card-day-badge">Day {d.day}</span>
                            <span className="route-card-day-text">
                              {(d.waypoints || []).map((w) => stripEmojis(w.name)).join(", ")}
                            </span>
                          </div>
                        ))}
                      </div>
                      <RouteWeatherStrip rd={rd} />
                      <div className="route-card-feedback-wrap">
                        <RouteCardFeedback
                          route={rd}
                          storageKey={`${msg.id}-r${rIdx}`}
                          routeId={msg.routeIdList?.[rIdx] ?? null}
                          initialDbVote={msg.routeFeedbackList?.[rIdx] ?? null}
                        />
                      </div>
                    </details>
                    {(() => {
                      const routeIdForCard = msg.routeIdList?.[rIdx];
                      const hasRouteId = !!routeIdForCard;
                      const tk = ticketStateKey(msg.id, rIdx);
                      const ticketLoading = ticketLoadingByKey[tk];
                      const rawRows = ticketRowsByKey[tk];
                      const list =
                        rawRows === undefined
                          ? null
                          : (Array.isArray(rawRows) ? rawRows : []).map(normalizePricingRow).filter(Boolean);
                      const foundList = list ? list.filter((r) => r.found) : null;
                      const showTicketEmpty =
                        hasRouteId && list && !ticketLoading && foundList.length === 0;
                      const showTicketCards =
                        hasRouteId && list && !ticketLoading && foundList.length > 0;
                      return (
                        <details className="route-card-subsection route-card-subsection--viator">
                          <summary className="route-card-subsection-summary">
                            <span className="route-card-subsection-summary-text">
                              <span className="route-card-subsection-title">Museum &amp; tour prices</span>
                              <span className="route-card-subsection-desc">
                                Viator — museum / tour products based on route stops
                              </span>
                            </span>
                          </summary>
                          <div className="route-ticket-section">
                            {!hasRouteId ? (
                              <p className="ticket-route-id-hint">
                                This section shows Viator prices and only works for server-saved routes. If no route ID
                                was received, the button is disabled — request a new route or refresh the chat.
                              </p>
                            ) : null}
                            {hasRouteId ? (
                              <button
                                type="button"
                                className="route-tickets-btn"
                                onClick={() => handleTicketSearch(routeIdForCard, msg.id, rIdx)}
                                disabled={ticketLoading || messagesLoading}
                              >
                                Show prices
                              </button>
                            ) : (
                              <Tooltip title="Viator prices cannot be queried because no route_id was received for this route.">
                                <span className="route-tickets-btn-wrap">
                                  <button type="button" className="route-tickets-btn" disabled>
                                    Show prices
                                  </button>
                                </span>
                              </Tooltip>
                            )}
                            {ticketLoading ? (
                              <div className="ticket-loading-wrap" aria-live="polite">
                                <Spin size="small" />
                                <span className="ticket-loading-label">Loading prices...</span>
                              </div>
                            ) : null}
                            {showTicketEmpty ? (
                              <div className="ticket-empty" role="status">
                                No suitable museum / tour prices found
                              </div>
                            ) : null}
                            {showTicketCards ? (
                              <ul className="ticket-card-list">
                                {foundList.map((row, ti) => (
                                  <li
                                    key={`${tk}-t${ti}-${row.day}-${row.order}`}
                                    className="ticket-card"
                                  >
                                    <div className="ticket-card-head">
                                      <span className="ticket-waypoint-name">{row.waypointName}</span>
                                      <span className="ticket-day">Day {row.day}</span>
                                    </div>
                                    {row.productTitle ? (
                                      <div className="ticket-product-title">{row.productTitle}</div>
                                    ) : null}
                                    {(() => {
                                      const priceLine = formatTicketPriceLine(row);
                                      if (priceLine) {
                                        return <div className="ticket-price">{priceLine}</div>;
                                      }
                                      if (row.status === "PARTNER_UNAVAILABLE" && row.message) {
                                        return (
                                          <div className="ticket-price ticket-price--muted">{row.message}</div>
                                        );
                                      }
                                      return <div className="ticket-price ticket-price--muted">—</div>;
                                    })()}
                                    {row.found && row.bookingUrl ? (
                                      <button
                                        type="button"
                                        className="ticket-buy-btn"
                                        onClick={() =>
                                          window.open(row.bookingUrl, "_blank", "noopener,noreferrer")
                                        }
                                      >
                                        Get Tickets
                                      </button>
                                    ) : null}
                                  </li>
                                ))}
                              </ul>
                            ) : null}
                          </div>
                        </details>
                      );
                    })()}
                    {msg.routeIdList?.[rIdx] ? (
                      <details className="route-card-subsection route-card-subsection--events">
                        <summary className="route-card-subsection-summary">
                          <span className="route-card-subsection-summary-text">
                            <span className="route-card-subsection-title">Event Recommendations</span>
                            <span className="route-card-subsection-desc">
                              Ticketmaster — concerts, sports, shows; ranked by your preferences
                            </span>
                          </span>
                        </summary>
                        <EventRecommendations routeId={msg.routeIdList[rIdx]} />
                      </details>
                    ) : null}
                    </div>
                  </div>
                );
                })}
                {msg.type === "ai" && msg.noRouteHint && routeList.length === 0 ? (
                  <div className="route-card route-card-hint">
                    <span>Could not retrieve route data. Try one of the quick buttons above again.</span>
                  </div>
                ) : null}
              </div>
            );
            })}
            {loading && (
              <div className="chat-row ai-row">
                <div className="message-bubble ai-bubble chat-typing-bubble">
                  <span className="chat-typing-label">
                    <span className="chat-typing-dots" aria-hidden><span /><span /><span /></span>
                    Thinking…
                  </span>
                  {currentTip && (
                    <div className="chat-tip-card" key={currentTip.tip}>
                      <span className="chat-tip-label">Travel tip</span>
                      <p className="chat-tip-text">{currentTip.tip}</p>
                      <div className="chat-tip-footer">
                        {currentTip.city
                          ? <span className="chat-tip-city">{currentTip.city}</span>
                          : <span />
                        }
                        <button
                          type="button"
                          className="chat-tip-next"
                          onClick={() => {
                            tipIndexRef.current = (tipIndexRef.current + 1) % tipPoolRef.current.length;
                            setCurrentTip(tipPoolRef.current[tipIndexRef.current]);
                          }}
                        >
                          next tip →
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </>
        )}
      </div>

      {sendError && !loading && (
        <div className="chat-stop-bar">
          <button type="button" className="chat-retry-btn" onClick={handleRetry}>
            ↺ Retry
          </button>
        </div>
      )}

      {!initialLoading && (
        <div className="chat-footer-refined">
          {(() => {
            const hasExistingRoute = messages.some(
              (m) => m.routeDataList?.length > 0 || m.routeData
            );
            const lastRouteMsg = [...messages]
              .reverse()
              .find((m) => m.routeDataList?.length > 0 || m.routeData);
            const lastRoute =
              lastRouteMsg?.routeDataList?.[0] || lastRouteMsg?.routeData;
            const totalDays =
              lastRoute?.days?.length || lastRoute?.total_days || 0;

            if (hasExistingRoute) {
              return (
                <div className="chat-quick-actions">
                  <span className="chat-quick-label">Edit route:</span>
                  {totalDays >= 1 && (
                    <button
                      type="button"
                      className="chat-quick-chip"
                      onClick={() => handleSendMessage("Make day 1 more museum-focused")}
                      disabled={loading || messagesLoading}
                    >
                      Day 1: more museums
                    </button>
                  )}
                  {totalDays >= 2 && (
                    <button
                      type="button"
                      className="chat-quick-chip"
                      onClick={() => handleSendMessage("Slow down day 2")}
                      disabled={loading || messagesLoading}
                    >
                      Slow down day 2
                    </button>
                  )}
                  {totalDays >= 3 && (
                    <button
                      type="button"
                      className="chat-quick-chip"
                      onClick={() => handleSendMessage("Add more dining options to day 3")}
                      disabled={loading || messagesLoading}
                    >
                      Day 3: more dining
                    </button>
                  )}
                  <button
                    type="button"
                    className="chat-quick-chip"
                    onClick={() => handleSendMessage("Change the pace to slow for the whole trip")}
                    disabled={loading || messagesLoading}
                  >
                    Slower pace
                  </button>
                </div>
              );
            }

            return (
              <div className="chat-quick-actions">
                <span className="chat-quick-label">Plan a route:</span>
                <button
                  type="button"
                  className="chat-quick-chip"
                  onClick={() => handleSendMessage("Plan a 3-day trip to Istanbul")}
                  disabled={loading || messagesLoading}
                >
                  3-day Istanbul
                </button>
                <button
                  type="button"
                  className="chat-quick-chip"
                  onClick={() => handleSendMessage("Plan a 2-day trip to Rome")}
                  disabled={loading || messagesLoading}
                >
                  2-day Rome
                </button>
                <button
                  type="button"
                  className="chat-quick-chip"
                  onClick={() => handleSendMessage("Create a 4-day Antalya vacation plan for me")}
                  disabled={loading || messagesLoading}
                >
                  4-day Antalya
                </button>
              </div>
            );
          })()}
          <div className="chat-input-field-group">
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
              disabled={loading || messagesLoading}
            />
            <button
              type="button"
              className={`chat-send-icon${loading ? " chat-send-icon--stop" : ""}`}
              onClick={loading ? handleStop : () => handleSendMessage()}
              disabled={!loading && (!inputText.trim() || messagesLoading)}
              aria-label={loading ? "Stop generating" : "Send"}
            >
              {loading ? <span className="chat-stop-square" aria-hidden /> : <SendOutlined />}
            </button>
          </div>
        </div>
        )}
          </>
        )}
    </div>
  );

  if (isMobile) {
    return content;
  }

  return (
    <Rnd
      default={{
        x: window.innerWidth - 460,
        y: 100,
        width: 420,
        height: 620,
      }}
      minWidth={380}
      minHeight={400}
      dragHandleClassName="chat-header-refined"
      bounds="parent"
      enableResizing={{
        top: true,
        right: true,
        bottom: true,
        left: true,
        topRight: true,
        bottomRight: true,
        bottomLeft: true,
        topLeft: true,
      }}
      style={{ zIndex: 1001 }}
    >
      {content}
    </Rnd>
  );
}
