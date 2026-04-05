import React, { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { aiApi } from "../../../api/aiApi";
import { Spin, message, Tooltip } from "antd";
import {
  CloseOutlined,
  CompassOutlined,
  EditOutlined,
  HistoryOutlined,
  PlusOutlined,
  SendOutlined,
} from "@ant-design/icons";
import "../styles/vacanzaChat.css";
import { normalizeRouteForMap } from "../utils/routeMap";
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
 * Rota kartı eklenecek asistan balonları (yemek önerisi, genel sohbet vb. hariç).
 * Zaman eşlemesi bu havuzda yapılır; aksi halde "en yakın asistan" yanlışlıkla yemek cevabı oluyordu.
 */
function looksLikeItineraryRouteReply(text) {
  const s = (text ?? "").trim();
  if (!s) return false;
  const lower = s.toLowerCase();
  if (/i['']?m here to help with travel/i.test(lower)) return false;
  if (/^i['']?m here to help\b/i.test(lower)) return false;
  if (/here is your .+ itinerary\b/i.test(lower)) return true;
  if (/\bitinerary\b/i.test(lower) && /here is\b/i.test(lower)) return true;
  if (/işte|rotanız|seyahat plan|tatil planınız|günlük plan/i.test(s)) return true;
  return false;
}

/** Harita replan / gün güncelleme gibi kısa asistan cevapları — rota kartı bu balonlara bağlanmalı. */
function looksLikeRouteRelatedReply(text) {
  if (looksLikeItineraryRouteReply(text)) return true;
  const s = (text ?? "").trim();
  if (!s) return false;
  const lower = s.toLowerCase();
  if (/day\s+\d+\s+is\s+updated\b/i.test(s)) return true;
  if (/updated\s+for\s+your\s+map\s+area/i.test(lower)) return true;
  if (/---\s*route_json\s*---/i.test(s)) return true;
  if (/işte\s+(güncellenmiş\s+)?rotan|gün\s+\d+.*(güncell|yenil)/i.test(s)) return true;
  return false;
}

/**
 * Kayıtlı rotaları, üretim zamanına göre en uygun asistan mesajına bağlar (aynı sohbette birden çok rota).
 * Her rotayı mümkünse ayrı asistan balonuna verir; aksi halde tüm “rota ile ilgili” balonlar havuza alınır.
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

  const assistantMsgs = msgs.filter((m) => m._isAssistant).sort((a, b) => a._createdAtMs - b._createdAtMs);
  let assistantPool = assistantMsgs.filter((m) => looksLikeRouteRelatedReply(m.text));
  if (assistantPool.length === 0) {
    assistantPool = assistantMsgs;
  }

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

/** İlk gün hava özeti — rota JSON’unda weather_forecast varsa sohbet kartında gösterilir. */
function RouteWeatherStrip({ rd }) {
  const wf = rd?.weather_forecast ?? rd?.weatherForecast;
  if (!Array.isArray(wf) || wf.length === 0) return null;
  const row = wf[0];
  const tMax = row.temp_max_celsius ?? row.tempMaxCelsius;
  const tMin = row.temp_min_celsius ?? row.tempMinCelsius;
  const precip =
    row.precipitation_probability_max_percent ?? row.precipitationProbabilityMaxPercent;
  const parts = [];
  if (tMax != null && tMin != null) {
    parts.push(`${Math.round(tMax)}° / ${Math.round(tMin)}°`);
  }
  if (precip != null && Number.isFinite(Number(precip))) {
    parts.push(`yağış ~%${Math.round(precip)}`);
  }
  if (parts.length === 0) return null;
  return (
    <div className="route-card-weather-strip" role="status">
      <span className="route-card-weather-strip-icon" aria-hidden>
        🌤️
      </span>
      <span className="route-card-weather-strip-text">Hava (1. gün): {parts.join(" · ")}</span>
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
  if (days === 1) return "Dün";
  if (days < 7) return `${days} gün önce`;
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

function mapHistoryMessage(m) {
  const role = (m.role ?? "").toLowerCase();
  const type = role === "user" ? "user" : "ai";
  let text = m.content ?? "";
  if (type === "user" && isPolygonMapRouteUserMessage(text)) {
    text = "Haritada çizilen alandan rota oluşturuldu.";
  }
  if (type === "user" && isReplanDayMapUserMessage(text)) {
    text = "Haritada çizilen alana göre seçili gün yeniden planlandı.";
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
  text: "Merhaba, ben Vacanza AI. Bugün nereyi keşfetmek istersin?",
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

  const ticketStateKey = (msgId, rIdx) => `${msgId}-r${rIdx}`;

  const handleTicketSearch = useCallback(async (routeId, msgId, rIdx) => {
    const key = ticketStateKey(msgId, rIdx);
    setTicketLoadingByKey((prev) => ({ ...prev, [key]: true }));
    try {
      const rows = await aiApi.getRoutePricing(routeId);
      setTicketRowsByKey((prev) => ({ ...prev, [key]: Array.isArray(rows) ? rows : [] }));
    } catch (e) {
      console.error(e);
      message.error("Bilet fiyatları yüklenemedi. Bağlantınızı kontrol edip tekrar deneyin.");
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
    if (!c) return "Yeni sohbet";
    return c.title || "Yeni sohbet";
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
            text: "Şu anda bağlantı kurulamıyor. Lütfen bir süre sonra tekrar deneyin.",
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
      await loadMessagesForConversation(id);
    } catch (e) {
      console.error(e);
      message.error("Mesajlar yüklenemedi.");
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

  const handleSendMessage = async (customText = null) => {
    const textToSend = (customText || inputText)?.trim();
    if (!textToSend || loading || messagesLoading) return;

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
      message.error("Sohbet başlatılamadı.");
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
      const response = await aiApi.sendMessage(activeConvId, textToSend);
      if (response && response.content) {
        const routeData = response.route_data || response.routeData || null;
        const wasRouteRequest = /plan|rota|gün|tatil|itinerary|day/i.test(textToSend);
        if (routeData) {
          const allWps = (routeData.days || []).flatMap((d) => d.waypoints || []);
          console.log("[VacanzaChat] route_data received:", {
            title: routeData.title,
            destination: routeData.destination,
            waypointCount: allWps.length,
            waypointCoords: allWps.map((w) => ({ name: w.name, lat: w.latitude, lon: w.longitude })),
          });
        }
        if (!routeData && wasRouteRequest) {
          console.warn("[VacanzaChat] Rota isteği gönderildi ama route_data gelmedi:", response);
        }
        const routeSummaryMessage = response.route_summary_message ?? response.routeSummaryMessage;
        const displayText =
          routeData && routeSummaryMessage ? routeSummaryMessage : response.content;

        const norm = routeData ? normalizeRouteForMap(routeData) : null;
        const routeIdFromResponse = response.route_id ?? response.routeId ?? null;
        const aiMsg = {
          id: `local-${Date.now() + 1}`,
          type: "ai",
          text: displayText,
          routeData: norm || undefined,
          routeDataList: norm ? [norm] : undefined,
          routeIdList: norm ? [routeIdFromResponse ?? null] : undefined,
          routeFeedbackList: norm ? [null] : undefined,
          noRouteHint: !routeData && wasRouteRequest,
          time: formatMessageTime(new Date()),
        };
        setMessages((prev) => [...prev, aiMsg]);

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
              ? `Tercihlerin kaydedildi: ${snippets.join(" · ")}${more}`
              : `${extractedPrefs.length} tercih profiline kaydedildi.`
          );
        }
      }
      await refreshConversations();
    } catch {
      message.error("Şu an yoğunuz. Birkaç saniye sonra tekrar deneyin.");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  const showMessageSpinner = initialLoading || messagesLoading;

  return (
    <div
      className={`ai-chat-container vacanza-chat ${isOpen ? "active" : ""}`}
      role="region"
      aria-label="Vacanza AI sohbet"
    >
      <div className="chat-header-refined">
        <div className="ai-info">
          <div className="ai-brand-avatar" aria-hidden>
            <CompassOutlined />
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
            title="Geçmiş sohbetler"
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
          <button type="button" className="chat-header-icon-btn" title="Yeni sohbet" onClick={handleNewChat}>
            <PlusOutlined />
          </button>
          <button type="button" className="chat-header-icon-btn" title="Kapat" onClick={onClose}>
            <CloseOutlined />
          </button>
        </div>
      </div>

      {historyPanelOpen ? (
        <div
          id="vacanza-chat-history"
          className="chat-history-full"
          role="region"
          aria-label="Geçmiş sohbetler"
        >
          <div className="chat-history-full-scroll">
            <div className="chat-history-full-heading">Geçmiş sohbetler</div>
            {!conversations.length ? (
              <div className="chat-history-full-empty">
                <span className="chat-history-full-empty-icon" aria-hidden>
                  💬
                </span>
                <p className="chat-history-full-empty-title">Henüz kayıtlı sohbet yok</p>
                <p className="chat-history-full-empty-hint">
                  Aşağıdan bir rota isteği yazın; geçmiş burada listelenecek.
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
                        <span className="chat-conv-row-title">{c.title || "Sohbet"}</span>
                        <span className="chat-conv-row-meta">{formatConversationDate(c.updatedAt)}</span>
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
            <Spin tip="Yükleniyor..." />
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
                {routeList.map((rd, rIdx) => (
                  <div key={`${msg.id}-route-${rIdx}`} className="route-card-outer">
                    {onRequestDrawToEdit ? (
                      <div
                        className={`route-card-preface ${rIdx > 0 ? "route-card-preface--stacked" : ""}`}
                        role="note"
                      >
                        <div className="route-card-preface-row">
                          <span className="route-card-preface-label">Yeniden çiz</span>
                          <button
                            type="button"
                            className="route-draw-edit-btn"
                            aria-label="Haritada alan çizerek günü yeniden planla"
                            onClick={() => {
                              onRequestDrawToEdit();
                              onClose();
                            }}
                          >
                            <EditOutlined aria-hidden />
                            Haritada çiz
                          </button>
                        </div>
                        <p className="route-card-preface-copy">
                          Haritada alan çiz, sağ panelden günü seç; turuncu banttan o günü seçtiğin alana göre
                          <strong> yenilersin</strong>.
                        </p>
                      </div>
                    ) : null}
                    <div className="route-card">
                    <div className="route-card-title">{rd.title}</div>
                    <div className="route-card-meta">
                      {rd.destination} &middot; {rd.total_days || rd.totalDays} gün &middot;{" "}
                      {(rd.days || []).reduce((sum, d) => sum + (d.waypoints?.length || 0), 0)} yer
                    </div>
                    <div className="route-card-days">
                      {(rd.days || []).map((d) => (
                        <div key={d.day} className="route-card-day-row">
                          <span className="route-card-day-badge">Gün {d.day}</span>
                          <span className="route-card-day-text">{(d.waypoints || []).map((w) => w.name).join(", ")}</span>
                        </div>
                      ))}
                    </div>
                    <RouteWeatherStrip rd={rd} />
                    <RouteCardFeedback
                      route={rd}
                      storageKey={`${msg.id}-r${rIdx}`}
                      routeId={msg.routeIdList?.[rIdx] ?? null}
                      initialDbVote={msg.routeFeedbackList?.[rIdx] ?? null}
                    />
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
                      Rotayı Haritada Göster
                    </button>
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
                      const showTicketEmpty =
                        hasRouteId &&
                        list &&
                        !ticketLoading &&
                        (list.length === 0 ||
                          (list.length > 0 && list.every((r) => !r.found)));
                      const showTicketCards =
                        hasRouteId &&
                        list &&
                        list.length > 0 &&
                        !ticketLoading &&
                        !list.every((r) => !r.found);
                      return (
                        <div className="route-card-subsection route-card-subsection--viator">
                          <div className="route-card-subsection-head">
                            <span className="route-card-subsection-title">Müze &amp; tur fiyatları</span>
                            <span className="route-card-subsection-desc">
                              Viator — rota duraklarına göre müze / tur ürünleri
                            </span>
                          </div>
                          <div className="route-ticket-section">
                          {!hasRouteId ? (
                            <p className="ticket-route-id-hint">
                              Bu blok Viator fiyatları içindir; yalnızca sunucuda kayıtlı rotada çalışır. AI yanıtında
                              rota kimliği yoksa düğme kapalıdır — yeni rota isteyin veya sohbeti yenileyin.
                            </p>
                          ) : null}
                          {hasRouteId ? (
                            <button
                              type="button"
                              className="route-tickets-btn"
                              onClick={() => handleTicketSearch(routeIdForCard, msg.id, rIdx)}
                              disabled={ticketLoading || messagesLoading}
                            >
                              Fiyatları göster
                            </button>
                          ) : (
                            <Tooltip title="Bu rota için route_id gelmediği için Viator fiyatları sorgulanamıyor.">
                              <span className="route-tickets-btn-wrap">
                                <button
                                  type="button"
                                  className="route-tickets-btn"
                                  disabled
                                >
                                  Fiyatları göster
                                </button>
                              </span>
                            </Tooltip>
                          )}
                          {ticketLoading ? (
                            <div className="ticket-loading-wrap" aria-live="polite">
                              <Spin size="small" />
                              <span className="ticket-loading-label">Fiyatlar yükleniyor…</span>
                            </div>
                          ) : null}
                          {showTicketEmpty ? (
                            <div className="ticket-empty" role="status">
                              Uygun müze / tur fiyatı bulunamadı
                            </div>
                          ) : null}
                          {showTicketCards ? (
                            <ul className="ticket-card-list">
                              {list.map((row, ti) => (
                                <li
                                  key={`${tk}-t${ti}-${row.day}-${row.order}`}
                                  className="ticket-card"
                                >
                                  <div className="ticket-card-head">
                                    <span className="ticket-waypoint-name">{row.waypointName}</span>
                                    <span className="ticket-day">Gün {row.day}</span>
                                  </div>
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
                                      Bilet Al
                                    </button>
                                  ) : null}
                                </li>
                              ))}
                            </ul>
                          ) : null}
                          </div>
                        </div>
                      );
                    })()}
                    {msg.routeIdList?.[rIdx] ? (
                      <div className="route-card-subsection route-card-subsection--events">
                        <div className="route-card-subsection-head">
                          <span className="route-card-subsection-title">Etkinlik önerileri</span>
                          <span className="route-card-subsection-desc">
                            Ticketmaster — konser, spor, gösteri; tercihlerine göre sıralı
                          </span>
                        </div>
                        <EventRecommendations routeId={msg.routeIdList[rIdx]} />
                      </div>
                    ) : null}
                    </div>
                  </div>
                ))}
                {msg.type === "ai" && msg.noRouteHint && routeList.length === 0 ? (
                  <div className="route-card route-card-hint">
                    <span>Rota verisi alınamadı. Yukarıdaki hızlı butonlardan birini tekrar deneyin.</span>
                  </div>
                ) : null}
              </div>
            );
            })}
            {loading && (
              <div className="chat-row ai-row">
                <div className="message-bubble ai-bubble chat-typing-bubble">
                  <Spin size="small" />
                  <span className="chat-typing-label">Yanıt hazırlanıyor…</span>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </>
        )}
      </div>

      {!initialLoading && (
        <div className="chat-footer-refined">
          <div className="chat-quick-actions">
            <span className="chat-quick-label">Rota planla:</span>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("3 günlük İstanbul planı yap")}
              disabled={loading || messagesLoading}
            >
              3 gün İstanbul
            </button>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("Plan a 2-day trip to Rome")}
              disabled={loading || messagesLoading}
            >
              2 gün Roma
            </button>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("Bana 4 günlük Antalya tatil planı oluştur")}
              disabled={loading || messagesLoading}
            >
              4 gün Antalya
            </button>
          </div>
          <div className="chat-input-field-group">
            <input
              type="text"
              placeholder="Rota planı için örn: 3 günlük Paris planı yap..."
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyDown={(e) => e.key === "Enter" && handleSendMessage()}
              disabled={loading || messagesLoading}
            />
            <button
              type="button"
              className="chat-send-icon"
              onClick={() => handleSendMessage()}
              disabled={loading || messagesLoading || !inputText.trim()}
              aria-label="Gönder"
            >
              <SendOutlined />
            </button>
          </div>
        </div>
      )}
        </>
      )}
    </div>
  );
}
