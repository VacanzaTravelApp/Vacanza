import React, { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { aiApi } from "../../../api/aiApi";
import { Spin, message } from "antd";
import { CloseOutlined, CompassOutlined, HistoryOutlined, PlusOutlined, SendOutlined } from "@ant-design/icons";
import "../styles/vacanzaChat.css";

/**
 * Sayfa yenilenene kadar (modül yeniden yüklenene kadar) aktif konuşmayı tutar.
 * Panel kapatılınca state sıfırlanır ama bu değer kalır — tekrar açılınca aynı sohbet yüklenir.
 * Tam sayfa yenilemede modül sıfırlanır → ilk açılışta yeni sohbet.
 */
let sessionConversationId = null;
let sessionHasOpenedChatThisPageLoad = false;

/** Normalize route for map: ensure every waypoint has numeric latitude/longitude (backend may send either key style). */
function normalizeRouteForMap(route) {
  if (!route) return null;
  const days = (route.days || []).map((d) => ({
    ...d,
    waypoints: (d.waypoints || []).map((w) => {
      const lat = Number(w.latitude ?? w.lat ?? NaN);
      const lon = Number(w.longitude ?? w.lon ?? NaN);
      return { ...w, latitude: lat, longitude: lon };
    }),
  }));
  return { ...route, days };
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
 * Kayıtlı rotaları, üretim zamanına göre en uygun asistan mesajına bağlar (aynı sohbette birden çok rota).
 */
function mergeHistoryWithSavedRoutes(historyRaw, routeDetails) {
  const list = Array.isArray(routeDetails) ? routeDetails : [];
  const msgs = historyRaw.map((m) => {
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
      t: parseDate(detail.generatedAt ?? detail.generated_at)?.getTime() ?? 0,
    }))
    .filter((x) => x.data)
    .sort((a, b) => a.t - b.t);

  const byMessageId = new Map();
  for (const rr of routes) {
    let best = null;
    let bestT = -1;
    for (const msg of msgs) {
      if (!msg._isAssistant) continue;
      if (msg._createdAtMs <= rr.t && msg._createdAtMs >= bestT) {
        best = msg;
        bestT = msg._createdAtMs;
      }
    }
    if (best) {
      const arr = byMessageId.get(best.id) ?? [];
      arr.push(rr.data);
      byMessageId.set(best.id, arr);
    }
  }
  for (const msg of msgs) {
    const arr = byMessageId.get(msg.id);
    if (arr?.length) {
      msg.routeDataList = arr;
      msg.routeData = arr[arr.length - 1];
    }
    delete msg._createdAtMs;
    delete msg._isAssistant;
  }
  return msgs;
}

function parseDate(value) {
  if (value == null) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
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

function mapHistoryMessage(m) {
  const role = (m.role ?? "").toLowerCase();
  const type = role === "user" ? "user" : "ai";
  return {
    id: String(m.id ?? `${Date.now()}-${Math.random()}`),
    type,
    text: m.content ?? "",
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

export default function VacanzaChat({ isOpen, onClose, onRouteGenerated }) {
  const [messages, setMessages] = useState([]);
  const [inputText, setInputText] = useState("");
  const [loading, setLoading] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const [conversations, setConversations] = useState([]);
  const [initialLoading, setInitialLoading] = useState(true);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [historyPanelOpen, setHistoryPanelOpen] = useState(false);
  const messagesEndRef = useRef(null);
  const scrollContainerRef = useRef(null);

  const scrollToBottom = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
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
    const history = await aiApi.getMessages(convId);
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
          const newConv = await aiApi.createConversation();
          if (cancelled) return;
          const id = String(newConv.id ?? "");
          sessionConversationId = id;
          setConversationId(id);
          const t = formatMessageTime(new Date());
          setMessages([{ ...GREETING, time: t }]);
          await refreshConversations();
        } else {
          const id = sessionConversationId;
          if (!id) {
            const newConv = await aiApi.createConversation();
            if (cancelled) return;
            const nid = String(newConv.id ?? "");
            sessionConversationId = nid;
            setConversationId(nid);
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

  const handleNewChat = async () => {
    try {
      setMessagesLoading(true);
      const newConv = await aiApi.createConversation();
      const id = String(newConv.id ?? "");
      sessionConversationId = id;
      setConversationId(id);
      const t = formatMessageTime(new Date());
      setMessages([{ ...GREETING, time: t }]);
      setHistoryPanelOpen(false);
      await refreshConversations();
    } catch (e) {
      console.error(e);
      message.error("Yeni sohbet başlatılamadı.");
    } finally {
      setMessagesLoading(false);
    }
  };

  const handleSendMessage = async (customText = null) => {
    const textToSend = (customText || inputText)?.trim();
    if (!textToSend || loading || !conversationId) return;

    const userMsg = {
      id: `local-${Date.now()}`,
      type: "user",
      text: textToSend,
      time: formatMessageTime(new Date()),
    };

    setMessages((prev) => [...prev, userMsg]);
    setInputText("");
    setLoading(true);

    try {
      const response = await aiApi.sendMessage(conversationId, textToSend);
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
        const aiMsg = {
          id: `local-${Date.now() + 1}`,
          type: "ai",
          text: displayText,
          routeData: norm || undefined,
          routeDataList: norm ? [norm] : undefined,
          noRouteHint: !routeData && wasRouteRequest,
          time: formatMessageTime(new Date()),
        };
        setMessages((prev) => [...prev, aiMsg]);
      }
      await refreshConversations();
    } catch {
      message.error("AI service is busy. Please try again in a moment.");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  const showMessageSpinner = initialLoading || messagesLoading;

  return (
    <div className={`ai-chat-container vacanza-chat ${isOpen ? "active" : ""}`}>
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
        <div className="chat-history-full" role="region" aria-label="Geçmiş sohbetler">
          <div className="chat-history-full-scroll">
            <div className="chat-history-full-heading">Geçmiş sohbetler</div>
            {!conversations.length ? (
              <div className="chat-history-full-empty">Henüz başka sohbet yok.</div>
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
      <div className="chat-content-scroll" ref={scrollContainerRef}>
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
                  {msg.text}
                  {msg.time ? <span className="msg-time">{msg.time}</span> : null}
                </div>
                {routeList.map((rd, rIdx) => (
                  <div key={`${msg.id}-route-${rIdx}`} className="route-card">
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
                    <button
                      type="button"
                      className="route-show-btn"
                      onClick={() => {
                        if (onRouteGenerated) onRouteGenerated(normalizeRouteForMap(rd));
                        onClose();
                      }}
                    >
                      Rotayı Haritada Göster
                    </button>
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
