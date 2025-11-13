import { useState, useEffect } from "react";
import Chatbot from "./Chatbot";
import "./App.css";
import "./Chatbot.css"; // for tooltip and launcher styles

function App() {
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [showTooltip, setShowTooltip] = useState(true);

  // hide tooltip after 5 seconds
  useEffect(() => {
    const timer = setTimeout(() => setShowTooltip(false), 5000);
    return () => clearTimeout(timer);
  }, []);

  return (
    <div className="app-container">
      {/* Nav Bar */}
      <nav className="navbar">
        <h1 className="logo">🎬 StreamSmart</h1>
        <ul className="nav-links">
          <li>Home</li>
          <li>Movies</li>
          <li>Series</li>
          <li>My List</li>
        </ul>
      </nav>

      {/* Movie Grid */}
      <div className="movie-grid">
        {Array.from({ length: 12 }).map((_, idx) => (
          <div key={idx} className="movie-card">
            <img src={`https://picsum.photos/200/300?random=${idx}`} alt="Movie Poster" />
            <h3>Movie {idx + 1}</h3>
            <p>Genre: Action</p>
            <span>⭐ {Math.random().toFixed(1) * 10}</span>
          </div>
        ))}
      </div>

      {/* Floating Chat Button + Tooltip Popup */}
      <div className="chat-launcher">
        {showTooltip && (
          <div className="chat-tooltip">
            Don't know what to watch? StreamSmart can help!
          </div>
        )}
        <button
          className="chat-icon"
          onClick={() => setIsChatOpen(!isChatOpen)}
        >
          💬
        </button>
      </div>

      {/* Chatbot Overlay */}
      {isChatOpen && (
        <div className="chat-overlay">
          <Chatbot onClose={() => setIsChatOpen(false)} />
        </div>
      )}
    </div>
  );
}

export default App;
