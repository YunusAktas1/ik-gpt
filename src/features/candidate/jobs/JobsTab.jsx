import React from "react";

export default function JobsTab({ jobs, appByJobId, onApply }) {
  if (!jobs.length) {
    return <div className="card">Aktif iş ilanı bulunamadı.</div>;
  }

  return (
    <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}>
      {jobs.map((job) => {
        const applied = appByJobId[job.id];

        return (
          <div key={job.id} className="card" style={{ padding: 18 }}>
            <div style={{ fontFamily: "var(--fr)", fontWeight: 600, fontSize: 20, marginBottom: 4 }}>{job.title}</div>
            <div style={{ color: "var(--muted)", fontSize: 13, marginBottom: 10 }}>
              {job.dept} · {job.location}
            </div>
            <p style={{ fontSize: 14, color: "var(--ink3)", marginBottom: 14 }}>{job.desc}</p>
            <button className="btn bp" onClick={() => onApply(job)} disabled={Boolean(applied)}>
              {applied ? "Başvuruldu" : "Başvur"}
            </button>
          </div>
        );
      })}
    </div>
  );
}
