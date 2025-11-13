import { useState, useRef, useEffect } from "react";
import axios from "axios";
import "./Chatbot.css"; // optional: separate styling

function Chatbot({ onClose }) {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [userId] = useState("user_1"); // static for demo
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const userMessage = {
      type: "user",
      content: inputMessage,
      timestamp: new Date().toLocaleTimeString()
    };
    setMessages(prev => [...prev, userMessage]);
    setInputMessage("");
    setIsLoading(true);

    try {
      const apiUrl = import.meta.env.VITE_API_URL || "https://streamsmart-backend-2091.azurewebsites.net";
      const res = await axios.post(`${apiUrl}/api/chat`, {
        user_id: userId,
        message: inputMessage,
        top_n: 5
      });

      const botMessage = {
        type: "bot",
        content: res.data.message,
        recommendations: res.data.recommendations,
        mood: res.data.extracted_mood,
        timestamp: new Date().toLocaleTimeString()
      };
      setMessages(prev => [...prev, botMessage]);
    } catch (err) {
      console.error("Backend error:", err);
      setMessages(prev => [
        ...prev,
        {
          type: "bot",
          content: "Sorry, I ran into an error. Please try again!",
          timestamp: new Date().toLocaleTimeString()
        }
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  return (
    <div className="chatbot-container">
      <button className="close-btn" onClick={onClose}>✖</button>

      <div className="messages-container">
        {messages.length === 0 && (
          <div className="welcome-message">
            <h2>👋 Welcome to StreamSmart!</h2>
            <p>Tell me what you're in the mood for, and I'll recommend something great.</p>
            <ul>
              <li>"I'm feeling happy and want something funny"</li>
              <li>"Something thrilling for tonight"</li>
              <li>"I'm sad and need a pick-me-up"</li>
            </ul>
          </div>
        )}

        {messages.map((msg, idx) => (
          <div key={idx} className={`message ${msg.type}`}>
            <div className="message-header">
              <span>{msg.type === "user" ? "You" : "StreamSmart AI"}</span>
              <span>{msg.timestamp}</span>
            </div>
            <div className="message-content">
              <p>{msg.content}</p>
              {msg.recommendations && (
                <div className="recommendations">
                  {msg.mood && (
                    <div className="mood-info">
                      <span>Mood: {msg.mood.mood}</span>
                      <span>Tone: {msg.mood.tone}</span>
                    </div>
                  )}
                  <div className="recommendations-grid">
                    {msg.recommendations.map((rec, i) => (
                      <div key={i} className="recommendation-card">
                        <h3>{rec.title}</h3>
                        <p>{rec.genre} • ⭐ {rec.rating}</p>
                        <p>{rec.tags}</p>
                        <p>📅 {rec.release_year}</p>
                        <p>Match: {(rec.hybrid_score * 100).toFixed(0)}%</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="message bot loading">
            <div className="typing-indicator">
              <span></span><span></span><span></span>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      <div className="input-container">
        <textarea
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Tell me what you're in the mood for..."
          disabled={isLoading}
          rows={1}
        />
        <button onClick={sendMessage} disabled={isLoading || !inputMessage.trim()}>
          {isLoading ? "..." : "Send"}
        </button>
      </div>
    </div>
  );
}

export default Chatbot;
