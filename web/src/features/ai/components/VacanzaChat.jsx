import React from "react";
import "../styles/vacanzaChat.css";

export default function VacanzaChat({ isOpen, onClose }) {
  if (!isOpen) return null;

  // Şimdilik Python'dan veri gelmediği için statik örnek mesajlar
  const staticMessages = [
    { id: 1, type: "ai", text: "Hi! ✨ I'm Vacanza AI. How can I help you explore today?", time: "10:30" },
    { id: 2, type: "user", text: "Find some Italian restaurants nearby.", time: "10:31" },
    { id: 3, type: "ai", text: "I found 3 great spots! 'La Bella Vita' is highly rated and just 5 mins away. 🍝", time: "10:31" }
  ];

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
      <div className="chat-content-scroll">
        {staticMessages.map((msg) => (
          <div key={msg.id} className={`chat-row ${msg.type}-row`}>
            <div className={`message-bubble ${msg.type}-bubble`}>
              {msg.text}
              <span className="msg-time">{msg.time}</span>
            </div>
          </div>
        ))}
      </div>

      {/* Footer Area (Input & Quick Actions) */}
      <div className="chat-footer-refined">
        <div className="quick-action-pills">
          <button>🍝 Best Pasta</button>
          <button>🗼 City Tour</button>
        </div>
        <div className="chat-input-field-group">
          <input type="text" placeholder="Ask anything..." disabled />
          <button className="chat-send-icon" disabled>🚀</button>
        </div>
      </div>
    </div>
  );
}