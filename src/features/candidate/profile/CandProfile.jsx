import React from "react";

export default function CandProfile({ user }) {
  return (
    <div className="card">
      <h2 style={{ fontFamily: "var(--fr)", fontSize: 24, marginBottom: 8 }}>Profil</h2>
      <div style={{ display: "grid", gridTemplateColumns: "160px 1fr", rowGap: 6, fontSize: 14 }}>
        <strong>Ad Soyad</strong>
        <span>{user?.name || "-"}</span>
        <strong>E-posta</strong>
        <span>{user?.email || "-"}</span>
        <strong>Ünvan</strong>
        <span>{user?.title || "-"}</span>
      </div>
    </div>
  );
}
