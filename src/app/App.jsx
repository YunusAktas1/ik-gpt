import React, { useEffect, useMemo, useState } from "react";

import { buildServices } from "./services.js";
import GlobalStyle from "../styles/GlobalStyle.jsx";
import Spin from "../components/common/Spin.jsx";
import AuthScreen from "../features/auth/AuthScreen.jsx";
import AdminPanel from "../features/admin/AdminPanel.jsx";
import CandPortal from "../features/candidate/CandPortal.jsx";

export default function App() {
  const services = useMemo(() => buildServices(), []);
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    (async () => {
      const session = await services.sessionRepo.get();
      if (active && session) setUser(session);
      if (active) setLoading(false);
    })();
    return () => {
      active = false;
    };
  }, [services]);

  const handleLogout = async () => {
    await services.sessionRepo.clear();
    setUser(null);
  };

  if (loading) {
    return (
      <>
        <GlobalStyle />
        <div
          style={{
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "var(--sand)",
          }}
        >
          <Spin s={30} />
        </div>
      </>
    );
  }

  if (!user) {
    return (
      <>
        <GlobalStyle />
        <AuthScreen services={services} onLogin={setUser} />
      </>
    );
  }

  if (user.role === "admin") {
    return (
      <>
        <GlobalStyle />
        <AdminPanel services={services} user={user} onLogout={handleLogout} />
      </>
    );
  }

  return (
    <>
      <GlobalStyle />
      <CandPortal services={services} user={user} onLogout={handleLogout} />
    </>
  );
}