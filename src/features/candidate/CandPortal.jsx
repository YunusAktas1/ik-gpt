import React from "react";

export default function CandPortal({ user, onLogout }) {
  return (
    <div style={{ padding: 24 }}>
      <h1>Candidate Portal</h1>
      <p>{user?.name}</p>
      <button onClick={onLogout}>Çýkýþ</button>
    </div>
  );
}