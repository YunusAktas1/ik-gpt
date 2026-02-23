import React, { useState } from "react";

const SEED_JOBS = [
  {
    id: "j1",
    title: "Senior Frontend Developer",
    dept: "Mühendislik",
    location: "İstanbul (Hibrit)",
    type: "Tam Zamanlı",
    level: "Senior",
    salaryMin: 60000,
    salaryMax: 90000,
    headcount: 2,
    desc: "React ve TypeScript ile ürün geliştirme.",
    requirements: ["React 5+ yıl", "TypeScript", "Redux/Zustand", "REST API", "Test yazımı"],
    status: "active",
    hiredCount: 0,
    applicants: 0,
    createdAt: new Date(Date.now() - 14 * 864e5).toISOString(),
  },
  {
    id: "j2",
    title: "Backend Developer (Python)",
    dept: "Mühendislik",
    location: "Uzaktan",
    type: "Tam Zamanlı",
    level: "Mid",
    salaryMin: 50000,
    salaryMax: 75000,
    headcount: 1,
    desc: "Python/Django mikro servis backend.",
    requirements: ["Python 3+ yıl", "Django/FastAPI", "PostgreSQL", "Docker"],
    status: "active",
    hiredCount: 0,
    applicants: 0,
    createdAt: new Date(Date.now() - 7 * 864e5).toISOString(),
  },
  {
    id: "j3",
    title: "Product Manager",
    dept: "Ürün",
    location: "Uzaktan",
    type: "Tam Zamanlı",
    level: "Mid-Senior",
    salaryMin: 70000,
    salaryMax: 100000,
    headcount: 1,
    desc: "Ürün stratejisi ve geliştirme koordinasyonu.",
    requirements: ["3+ yıl PM", "Agile/Scrum", "Veri analizi", "Paydaş yönetimi"],
    status: "active",
    hiredCount: 0,
    applicants: 0,
    createdAt: new Date(Date.now() - 3 * 864e5).toISOString(),
  },
];

export default function AuthScreen({ services, onLogin }) {
  const [mode, setMode] = useState("login");
  const [role, setRole] = useState("candidate");
  const [form, setForm] = useState({ name: "", email: "", password: "", title: "" });
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  async function login() {
    if (!form.email || !form.password) {
      setErr("E-posta ve şifre zorunlu.");
      return;
    }

    setBusy(true);
    setErr("");
    const users = await services.userRepo.getAll();
    const u = Object.values(users).find((x) => x.email === form.email.toLowerCase().trim() && x.password === form.password);

    if (!u) {
      setErr("E-posta veya şifre hatalı.");
      setBusy(false);
      return;
    }

    await services.sessionRepo.set(u);
    onLogin(u);
    setBusy(false);
  }

  async function register() {
    if (!form.name || !form.email || !form.password) {
      setErr("Tüm alanlar zorunlu.");
      return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)) {
      setErr("Geçerli e-posta girin.");
      return;
    }

    setBusy(true);
    setErr("");
    const users = await services.userRepo.getAll();

    if (Object.values(users).some((x) => x.email === form.email.toLowerCase().trim())) {
      setErr("Bu e-posta kayıtlı.");
      setBusy(false);
      return;
    }

    const u = {
      id: `u_${Date.now()}`,
      name: form.name.trim(),
      email: form.email.toLowerCase().trim(),
      password: form.password,
      role,
      title: form.title,
      skills: "",
      skillRatings: [],
      certifications: [],
      exams: [],
      personalityResult: null,
      createdAt: new Date().toISOString(),
    };

    await services.userRepo.upsert(u);
    await services.sessionRepo.set(u);
    onLogin(u);
    setBusy(false);
  }

  async function demo(r) {
    const em = r === "admin" ? "admin@d.com" : "aday@d.com";
    let u = await services.userRepo.findByEmail(em);

    if (!u) {
      u =
        r === "admin"
          ? { id: "da", name: "Elif Yıldız", email: em, password: "d", role: "admin", title: "İK Müdürü", createdAt: new Date().toISOString() }
          : {
              id: "dc",
              name: "Ahmet Demir",
              email: em,
              password: "d",
              role: "candidate",
              title: "Frontend Dev",
              skills: "React, TypeScript, Node.js",
              skillRatings: [
                { name: "React", level: 90 },
                { name: "TypeScript", level: 85 },
                { name: "Node.js", level: 70 },
              ],
              certifications: [{ name: "AWS SA", org: "Amazon", date: "2024-03", certId: "AWS-12345" }],
              exams: [{ name: "IELTS", score: "7.5", date: "2024-06", validUntil: "2026-06" }],
              summary: "5 yıl deneyimli React geliştirici.",
              experience: "TechCorp – Sr Frontend (2021-2024)",
              education: "İTÜ Bilgisayar Müh. 2019",
              city: "İstanbul",
              personalityResult: { dominant: "A", scores: { D: 1, C: 2, A: 5, S: 2 }, date: new Date().toISOString() },
              createdAt: new Date().toISOString(),
            };
      await services.userRepo.upsert(u);
    }

    await services.jobRepo.seedIfEmpty(SEED_JOBS);
    await services.sessionRepo.set(u);
    onLogin(u);
  }

  return (
    <div style={{ minHeight: "100vh", background: "var(--sand)", display: "flex" }}>
      <div style={{ flex: 1, background: "var(--ink)", display: "flex", flexDirection: "column", justifyContent: "center", padding: "60px 80px", position: "relative", overflow: "hidden" }}>
        <div style={{ position: "relative", zIndex: 1 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 56 }}>
            <div style={{ width: 44, height: 44, borderRadius: 14, background: "rgba(255,255,255,.12)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 22 }}>⚡</div>
            <span style={{ fontFamily: "var(--fr)", fontSize: 26, fontWeight: 700, color: "#fff" }}>TalentFlow</span>
          </div>
          <h1 style={{ fontFamily: "var(--fr)", fontSize: 38, fontWeight: 600, color: "#fff", lineHeight: 1.15, marginBottom: 20 }}>İşe alımın<br />en akıllı hali</h1>
          <p style={{ fontSize: 15, color: "rgba(255,255,255,.5)", lineHeight: 1.7, maxWidth: 380 }}>AI mülakat, şeffaf müzakere, uçtan uca süreç.</p>
        </div>
      </div>

      <div style={{ width: 440, display: "flex", alignItems: "center", justifyContent: "center", padding: 40 }}>
        <div style={{ width: "100%" }} className="ai">
          <h2 style={{ fontFamily: "var(--fr)", fontSize: 24, fontWeight: 600, marginBottom: 6 }}>{mode === "login" ? "Hoş geldiniz" : "Hesap oluşturun"}</h2>
          <p style={{ fontSize: 14, color: "var(--muted)", marginBottom: 24 }}>{mode === "login" ? "Bilgilerinizle giriş yapın" : "Hemen başlayın"}</p>

          <div style={{ display: "flex", gap: 4, background: "var(--sand2)", borderRadius: "var(--r)", padding: 4, marginBottom: 20 }}>
            {[
              ["login", "Giriş"],
              ["register", "Kayıt"],
            ].map(([m, l]) => (
              <button
                key={m}
                onClick={() => {
                  setMode(m);
                  setErr("");
                }}
                style={{
                  flex: 1,
                  padding: "8px 0",
                  borderRadius: 6,
                  background: mode === m ? "#fff" : "transparent",
                  color: mode === m ? "var(--ink)" : "var(--muted)",
                  fontWeight: mode === m ? 600 : 400,
                  fontSize: 13,
                  boxShadow: mode === m ? "var(--sh)" : undefined,
                }}
              >
                {l}
              </button>
            ))}
          </div>

          {mode === "register" && (
            <div style={{ marginBottom: 14 }}>
              <label>Hesap Tipi</label>
              <div style={{ display: "flex", gap: 8 }}>
                {[
                  ["candidate", "👤 Aday"],
                  ["admin", "🛡️ İK"],
                ].map(([r2, l]) => (
                  <button
                    key={r2}
                    onClick={() => setRole(r2)}
                    style={{
                      flex: 1,
                      padding: "9px 0",
                      borderRadius: "var(--r)",
                      background: role === r2 ? "var(--ink)" : "#fff",
                      border: `1.5px solid ${role === r2 ? "var(--ink)" : "var(--line)"}`,
                      color: role === r2 ? "#fff" : "var(--ink3)",
                      fontWeight: 600,
                      fontSize: 13,
                    }}
                  >
                    {l}
                  </button>
                ))}
              </div>
            </div>
          )}

          <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
            {mode === "register" && (
              <>
                <div>
                  <label>Ad Soyad</label>
                  <input value={form.name} onChange={set("name")} />
                </div>
                <div>
                  <label>Ünvan</label>
                  <input value={form.title} onChange={set("title")} />
                </div>
              </>
            )}
            <div>
              <label>E-posta</label>
              <input type="email" value={form.email} onChange={set("email")} />
            </div>
            <div>
              <label>Şifre</label>
              <input type="password" value={form.password} onChange={set("password")} />
            </div>
          </div>

          {err && <div style={{ background: "var(--red2)", border: "1px solid #fecaca", borderRadius: "var(--r)", padding: "8px 12px", fontSize: 13, color: "#991b1b", marginTop: 10 }}>{err}</div>}

          <button className="btn bp" style={{ width: "100%", marginTop: 14, padding: "12px 0", justifyContent: "center", fontWeight: 600 }} onClick={mode === "login" ? login : register} disabled={busy}>
            {busy ? "Lütfen bekleyin..." : mode === "login" ? "Giriş Yap" : "Hesap Oluştur"}
          </button>

          <div style={{ marginTop: 18, textAlign: "center", fontSize: 12, color: "var(--muted)", marginBottom: 10 }}>veya demo ile devam edin</div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8 }}>
            <button className="btn bg" style={{ justifyContent: "center", fontSize: 13, padding: "10px 0" }} onClick={() => demo("candidate")}>👤 Demo Aday</button>
            <button className="btn bg" style={{ justifyContent: "center", fontSize: 13, padding: "10px 0" }} onClick={() => demo("admin")}>🛡️ Demo İK</button>
          </div>
        </div>
      </div>
    </div>
  );
}
