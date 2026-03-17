import React, { useState, useEffect, useRef } from "react";
import { aiApi } from "../../../api/aiApi";
import { Spin, message } from "antd";
import "../styles/vacanzaChat.css";

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

export default function VacanzaChat({ isOpen, onClose, onRouteGenerated }) {
  const [messages, setMessages] = useState([]);
  const [inputText, setInputText] = useState("");
  const [loading, setLoading] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const [initialLoading, setInitialLoading] = useState(true);
  const messagesEndRef = useRef(null);
  const scrollContainerRef = useRef(null);

  const scrollToBottom = () => {
    if (scrollContainerRef.current) {
      scrollContainerRef.current.scrollTop = scrollContainerRef.current.scrollHeight;
    }
  };

  useEffect(() => {
    if (isOpen) {
      loadConversation();
    }
  }, [isOpen]);

  useEffect(() => {
    if (isOpen) {
      scrollToBottom();
    }
  }, [messages, isOpen]);

  const loadConversation = async () => {
    try {
      setInitialLoading(true);
      // Try to get latest conversation
      const conversations = await aiApi.listConversations(1, 0);

      let currentId;
      if (conversations && conversations.length > 0) {
        currentId = conversations[0].id;
        setConversationId(currentId);
        // Load messages
        const history = await aiApi.getMessages(currentId);
        setMessages(history.map(m => ({
          id: m.id,
          type: m.role?.toLowerCase() === 'user' ? 'user' : 'ai',
          text: m.content,
          time: new Date(m.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        })));
      } else {
        // Create new if none exists
        const newConv = await aiApi.createConversation();
        setConversationId(newConv.id);
        // Default greeting
        setMessages([{
          id: 'greeting',
          type: 'ai',
          text: "Hi! ✨ I'm Vacanza AI. How can I help you explore today?",
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        }]);
      }
    } catch (err) {
      console.error("Failed to load chat:", err);
      // If unauthorized or other error, fallback to initial state
      setMessages([{
        id: 'error',
        type: 'ai',
        text: "I'm having trouble connecting to my brain right now. Please try again later! 🧠",
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      }]);
    } finally {
      setInitialLoading(false);
    }
  };

  const handleSendMessage = async (customText = null) => {
    const textToSend = (customText || inputText)?.trim();
    if (!textToSend || loading || !conversationId) return;

    const userMsg = {
      id: Date.now(),
      type: "user",
      text: textToSend,
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages(prev => [...prev, userMsg]);
    setInputText("");
    setLoading(true);

    try {
      const response = await aiApi.sendMessage(conversationId, textToSend);
      if (response && response.content) {
        const routeData = response.route_data || response.routeData || null;
        const wasRouteRequest = /plan|rota|gün|tatil|itinerary|day/i.test(textToSend);
        if (routeData) {
          const allWps = (routeData.days || []).flatMap(d => d.waypoints || []);
          console.log("[VacanzaChat] route_data received:", {
            title: routeData.title,
            destination: routeData.destination,
            waypointCount: allWps.length,
            waypointCoords: allWps.map(w => ({ name: w.name, lat: w.latitude, lon: w.longitude })),
          });
        }
        if (!routeData && wasRouteRequest) {
          console.warn("[VacanzaChat] Rota isteği gönderildi ama route_data gelmedi:", response);
        }
        // When we have a route, show backend-generated summary (e.g. "Müzeleri sevdiğini biliyordum...") instead of raw AI content
        const routeSummaryMessage = response.route_summary_message ?? response.routeSummaryMessage;
        const displayText =
          routeData && routeSummaryMessage
            ? routeSummaryMessage
            : response.content;

        const aiMsg = {
          id: Date.now() + 1,
          type: "ai",
          text: displayText,
          routeData,
          noRouteHint: !routeData && wasRouteRequest,
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
        };
        setMessages(prev => [...prev, aiMsg]);
      }
    } catch (err) {
      message.error("AI service is busy. Please try again in a moment.");
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className={`ai-chat-container ${isOpen ? "active" : ""}`}>
      {/* Header Area */}
      <div className="chat-header-refined">
        <div className="ai-info">
          <div className="ai-sparkle-avatar">✨</div>
          <div className="ai-text-meta">
            <span className="ai-name">Vacanza AI</span>
            <span className="ai-status-dot">Online</span>
          </div>
        </div>
        <button className="chat-close-btn" onClick={onClose}>✕</button>
      </div>

      {/* Messages Area */}
      <div className="chat-content-scroll" ref={scrollContainerRef}>
        {initialLoading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
            <Spin tip="Connecting..." />
          </div>
        ) : (
          <>
            {messages.map((msg) => (
              <div key={msg.id} className={`chat-row ${msg.type}-row`}>
                <div className={`message-bubble ${msg.type}-bubble`}>
                  {msg.text}
                  <span className="msg-time">{msg.time}</span>
                </div>
                {msg.routeData ? (
                  <div className="route-card">
                    <div className="route-card-title">{msg.routeData.title}</div>
                    <div className="route-card-meta">
                      {msg.routeData.destination} &middot; {msg.routeData.total_days || msg.routeData.totalDays} gün &middot;{" "}
                      {(msg.routeData.days || []).reduce((sum, d) => sum + (d.waypoints?.length || 0), 0)} yer
                    </div>
                    <div className="route-card-days">
                      {(msg.routeData.days || []).map((d) => (
                        <div key={d.day} className="route-card-day-row">
                          <span className="route-card-day-badge">Gün {d.day}</span>
                          <span className="route-card-day-text">
                            {(d.waypoints || []).map(w => w.name).join(", ")}
                          </span>
                        </div>
                      ))}
                    </div>
                    <button
                      className="route-show-btn"
                      onClick={() => {
                        if (onRouteGenerated) onRouteGenerated(normalizeRouteForMap(msg.routeData));
                        onClose();
                      }}
                    >
                      Rotayı Haritada Göster
                    </button>
                  </div>
                ) : msg.type === "ai" && msg.noRouteHint ? (
                  <div className="route-card route-card-hint">
                    <span>Rota verisi alınamadı. Yukarıdaki hızlı butonlardan birini tekrar deneyin.</span>
                  </div>
                ) : null}
              </div>
            ))}
            {loading && (
              <div className="chat-row ai-row">
                <div className="message-bubble ai-bubble" style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px' }}>
                  <Spin size="small" />
                  <span style={{ fontSize: 12, color: '#888' }}>Thinking...</span>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </>
        )}
      </div>

      {/* Footer Area (Input & Quick Actions) */}
      {!initialLoading && (
        <div className="chat-footer-refined">
          <div className="chat-quick-actions">
            <span className="chat-quick-label">Rota planla:</span>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("3 günlük İstanbul planı yap")}
              disabled={loading}
            >
              3 gün İstanbul
            </button>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("Plan a 2-day trip to Rome")}
              disabled={loading}
            >
              2 gün Roma
            </button>
            <button
              type="button"
              className="chat-quick-chip"
              onClick={() => handleSendMessage("Bana 4 günlük Antalya tatil planı oluştur")}
              disabled={loading}
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
              onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
              disabled={loading}
            />
            <button
              className="chat-send-icon"
              onClick={() => handleSendMessage()}
              disabled={loading || !inputText.trim()}
              style={{ opacity: loading || !inputText.trim() ? 0.5 : 1 }}
            >
              🚀
            </button>
          </div>
        </div>
      )}
    </div>
  );
}