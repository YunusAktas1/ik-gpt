import React from "react";

export default function AuthScreen({ onLogin }) {
  return (
    <div style={{ minHeight: "100vh", display: "grid", placeItems: "center" }}>
      <button onClick={() => onLogin({ id: "demo", role: "candidate", name: "Demo" })}>Demo Login</button>
    </div>
  );
}