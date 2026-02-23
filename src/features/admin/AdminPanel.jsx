import React from "react";

export default function AdminPanel({ user, onLogout }) {
  return (
    <div style={{ padding: 24 }}>
      <h1>Admin Panel</h1>
      <p>{user?.name}</p>
      <button onClick={onLogout}>Çýkýþ</button>
    </div>
  );
}