import React from "react";

export default function AppsTab({ jobs, apps }) {
  const jobById = jobs.reduce((acc, job) => {
    acc[job.id] = job;
    return acc;
  }, {});

  if (!apps.length) {
    return <div className="card">Henüz başvuru yok.</div>;
  }

  return (
    <div style={{ display: "grid", gap: 10 }}>
      {apps
        .slice()
        .sort((a, b) => (a.appliedAt < b.appliedAt ? 1 : -1))
        .map((app) => (
          <div key={app.id} className="card" style={{ padding: 16 }}>
            <div style={{ fontFamily: "var(--fr)", fontSize: 19, fontWeight: 600 }}>{jobById[app.jobId]?.title || "Pozisyon"}</div>
            <div style={{ color: "var(--muted)", fontSize: 12 }}>
              Başvuru: {new Date(app.appliedAt).toLocaleDateString("tr-TR")} · Aşama: {app.stage}
            </div>
          </div>
        ))}
    </div>
  );
}
