import { useState } from "react";
import axios from "axios";

function App() {
  const [mood, setMood] = useState("");
  const [recommendation, setRecommendation] = useState("");

  const getRecommendation = async () => {
    try {
      const res = await axios.post("http://127.0.0.1:8000/chatbot/recommend", {
        mood: mood,
        context: "alone",
        time_of_day: "evening"
      });
      setRecommendation(res.data.recommendation);
    } catch (err) {
      console.error("Error calling backend:", err);
    }
  };

  return (
    <div style={{ background: "black", color: "white", minHeight: "100vh", padding: "2rem" }}>
      <h1>StreamSmart 🎬</h1>
      <input
        value={mood}
        onChange={(e) => setMood(e.target.value)}
        placeholder="What's your mood?"
        style={{ padding: "0.5rem", marginRight: "0.5rem" }}
      />
      <button
        onClick={getRecommendation}
        style={{ padding: "0.5rem", background: "purple", color: "white" }}
      >
        Recommend
      </button>
      {recommendation && <p style={{ marginTop: "1rem" }}>{recommendation}</p>}
    </div>
  );
}

export default App;
