import React, { useEffect, useState } from "react";

import JobsTab from "./jobs/JobsTab.jsx";
import AppsTab from "./apps/AppsTab.jsx";
import CandProfile from "./profile/CandProfile.jsx";
import ApplyFlow from "./apply/ApplyFlow.jsx";

const TABS = [
  ["jobs", "Jobs"],
  ["apps", "Apps"],
  ["profile", "Profile"],
];

export default function CandPortal({ services, user, onLogout }) {
  const [tab, setTab] = useState("jobs");
  const [jobs, setJobs] = useState([]);
  const [apps, setApps] = useState([]);
  const [applyJob, setApplyJob] = useState(null);

  async function refresh() {
    const jobMap = await services.jobRepo.getAll();
    const appMap = await services.appRepo.getAll();
    const jobList = Object.values(jobMap || {});
    const appList = Object.values(appMap || {}).filter((a) => a.candidateId === user.id);
    setJobs(jobList);
    setApps(appList);
  }

  useEffect(() => {
    refresh();
  }, []);

  const appByJobId = apps.reduce((acc, app) => {
    acc[app.jobId] = app;
    return acc;
  }, {});

  return (
    <div style={{ minHeight: "100vh", background: "var(--sand)", padding: 24 }}>
      <div style={{ maxWidth: 1100, margin: "0 auto" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 20 }}>
          <div>
            <h1 style={{ fontFamily: "var(--fr)", fontSize: 28, fontWeight: 600 }}>TalentFlow</h1>
            <p style={{ color: "var(--muted)", fontSize: 13 }}>Hoş geldin, {user?.name}</p>
          </div>
          <button className="btn bg" onClick={onLogout}>
            Çıkış
          </button>
        </div>

        <div style={{ display: "flex", gap: 8, marginBottom: 18 }}>
          {TABS.map(([id, label]) => (
            <button
              key={id}
              className="btn"
              onClick={() => setTab(id)}
              style={{
                background: tab === id ? "var(--ink)" : "#fff",
                color: tab === id ? "#fff" : "var(--ink3)",
                border: `1.5px solid ${tab === id ? "var(--ink)" : "var(--line)"}`,
                padding: "8px 16px",
              }}
            >
              {label}
            </button>
          ))}
        </div>

        {tab === "jobs" && <JobsTab jobs={jobs} appByJobId={appByJobId} onApply={(job) => setApplyJob(job)} />}
        {tab === "apps" && <AppsTab jobs={jobs} apps={apps} />}
        {tab === "profile" && <CandProfile user={user} />}
      </div>

      {applyJob && (
        <ApplyFlow
          user={user}
          job={applyJob}
          services={services}
          onClose={() => setApplyJob(null)}
          onApplied={async () => {
            setApplyJob(null);
            setTab("apps");
            await refresh();
          }}
        />
      )}
    </div>
  );
}
