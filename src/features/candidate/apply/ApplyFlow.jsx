import React from "react";

export default function ApplyFlow({ services, user, job, onClose, onApplied }) {
  async function apply() {
    await services.appRepo.create({
      id: `a_${Date.now()}`,
      candidateId: user.id,
      jobId: job.id,
      stage: "applied",
      appliedAt: new Date().toISOString(),
    });
    await onApplied();
  }

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        background: "rgba(0,0,0,.35)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1000,
      }}
    >
      <div className="card" style={{ width: 520, maxWidth: "90vw" }}>
        <h3 style={{ fontFamily: "var(--fr)", fontSize: 24, marginBottom: 8 }}>Başvuruyu Onayla</h3>
        <p style={{ color: "var(--ink3)", marginBottom: 16 }}>
          <strong>{job.title}</strong> pozisyonuna başvurmak istediğinize emin misiniz?
        </p>
        <div style={{ display: "flex", justifyContent: "flex-end", gap: 8 }}>
          <button className="btn bg" onClick={onClose}>
            Vazgeç
          </button>
          <button className="btn bp" onClick={apply}>
            Başvur
          </button>
        </div>
      </div>
    </div>
  );
}
