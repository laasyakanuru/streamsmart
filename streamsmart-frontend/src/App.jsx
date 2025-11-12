import { useState, useRef, useEffect } from "react";
import axios from "axios";
import "./App.css";

function App() {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [userId] = useState("user_1"); // In production, this would come from auth
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    // Add user message to chat
    const userMessage = {
      type: "user",
      content: inputMessage,
      timestamp: new Date().toLocaleTimeString()
    };
    setMessages(prev => [...prev, userMessage]);
    setInputMessage("");
    setIsLoading(true);

    try {
      const res = await axios.post("http://127.0.0.1:8000/api/chat", {
        user_id: userId,
        message: inputMessage,
        top_n: 5
      });

      // Add bot response to chat
      const botMessage = {
        type: "bot",
        content: res.data.message,
        recommendations: res.data.recommendations,
        mood: res.data.extracted_mood,
        timestamp: new Date().toLocaleTimeString()
      };
      setMessages(prev => [...prev, botMessage]);
    } catch (err) {
      console.error("Error calling backend:", err);
      const errorMessage = {
        type: "bot",
        content: "Sorry, I encountered an error. Please try again!",
        timestamp: new Date().toLocaleTimeString()
      };
      setMessages(prev => [...prev, errorMessage]);
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
    <div className="app-container">
      <header className="app-header">
        <h1>🎬 StreamSmart</h1>
        <p>Your AI-Powered OTT Recommendation Assistant</p>
      </header>

      <div className="chat-container">
        <div className="messages-container">
          {messages.length === 0 && (
            <div className="welcome-message">
              <h2>👋 Welcome to StreamSmart!</h2>
              <p>Tell me what you're in the mood for, and I'll recommend the perfect show or movie!</p>
              <div className="example-prompts">
                <p><strong>Try saying:</strong></p>
                <ul>
                  <li>"I'm feeling happy and want something funny"</li>
                  <li>"Something thrilling for tonight"</li>
                  <li>"I'm sad and need a pick-me-up"</li>
                </ul>
              </div>
            </div>
          )}

          {messages.map((msg, idx) => (
            <div key={idx} className={`message ${msg.type}`}>
              <div className="message-header">
                <span className="message-sender">
                  {msg.type === "user" ? "You" : "StreamSmart AI"}
                </span>
                <span className="message-time">{msg.timestamp}</span>
              </div>
              <div className="message-content">
                <p>{msg.content}</p>
                {msg.recommendations && (
                  <div className="recommendations">
                    {msg.mood && (
                      <div className="mood-info">
                        <span className="mood-badge">
                          Mood: {msg.mood.mood}
                        </span>
                        <span className="mood-badge">
                          Tone: {msg.mood.tone}
                        </span>
                      </div>
                    )}
                    <div className="recommendations-grid">
                      {msg.recommendations.map((rec, i) => (
                        <div key={i} className="recommendation-card">
                          <h3>{rec.title}</h3>
                          <div className="rec-meta">
                            <span className="genre">{rec.genre}</span>
                            <span className="rating">⭐ {rec.rating}</span>
                          </div>
                          <p className="description">{rec.description}</p>
                          <div className="rec-tags">
                            <span className="tag">{rec.mood_tag}</span>
                            <span className="tag">{rec.tone}</span>
                          </div>
                          <div className="match-score">
                            Match: {(rec.hybrid_score * 100).toFixed(0)}%
                          </div>
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
              <div className="message-header">
                <span className="message-sender">StreamSmart AI</span>
              </div>
              <div className="message-content">
                <div className="typing-indicator">
                  <span></span>
                  <span></span>
                  <span></span>
                </div>
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
    </div>
  );
}

export default App;
