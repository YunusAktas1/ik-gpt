import { useEffect } from "react";

const STYLE = `
@import url('https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,300;0,9..144,600;0,9..144,700;1,9..144,400&family=DM+Sans:wght@300;400;500;600&family=Fira+Code:wght@400;500&display=swap');
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --sand:#faf8f4;--sand2:#f3f0ea;--sand3:#ede8de;--sand4:#ddd5c8;
  --ink:#1c1917;--ink2:#3d3530;--ink3:#6b5e56;--muted:#a09080;
  --line:#ddd5c8;--line2:#ede8de;
  --blue:#2563eb;--blue2:#1d4ed8;--blue3:#dbeafe;
  --green:#16a34a;--green2:#dcfce7;
  --amber:#d97706;--amber2:#fef3c7;
  --red:#dc2626;--red2:#fee2e2;
  --purple:#7c3aed;--purple2:#ede9fe;
  --teal:#0d9488;--teal2:#ccfbf1;
  --orange:#ea580c;--orange2:#ffedd5;
  --fr:'Fraunces',serif;--dm:'DM Sans',sans-serif;--mono:'Fira Code',monospace;
  --r:8px;--r2:14px;--sh:0 1px 3px rgba(0,0,0,.08),0 4px 12px rgba(0,0,0,.05);
}
body{background:var(--sand);color:var(--ink);font-family:var(--dm);min-height:100vh;line-height:1.55}
*:focus-visible{outline:2px solid var(--blue);outline-offset:2px;border-radius:4px}
input,textarea,select{background:#fff;border:1.5px solid var(--line);border-radius:var(--r);color:var(--ink);font-family:var(--dm);font-size:14px;padding:9px 13px;width:100%;outline:none;transition:border .2s,box-shadow .2s}
input:focus,textarea:focus,select:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(37,99,235,.1)}
input::placeholder,textarea::placeholder{color:var(--muted)}
button{cursor:pointer;font-family:var(--dm);border:none;border-radius:var(--r);transition:all .18s;font-weight:500}
.btn{padding:9px 18px;font-size:14px;font-weight:600;display:inline-flex;align-items:center;gap:6px}
.bp{background:var(--ink);color:#fff}.bp:hover{background:var(--ink2)}
.bg{background:transparent;color:var(--ink3);border:1.5px solid var(--line)}.bg:hover{border-color:var(--ink3)}
.card{background:#fff;border:1px solid var(--line);border-radius:var(--r2);padding:22px;box-shadow:var(--sh)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:11px;font-weight:600;font-family:var(--mono)}
.bb{background:var(--blue3);color:var(--blue)}.bgr{background:var(--green2);color:var(--green)}.ba{background:var(--amber2);color:var(--amber)}.br{background:var(--red2);color:var(--red)}.bpu{background:var(--purple2);color:var(--purple)}.bt{background:var(--teal2);color:var(--teal)}.bgy{background:var(--sand3);color:var(--ink3)}
label{font-size:12px;font-weight:500;color:var(--ink3);display:block;margin-bottom:5px}
.g2{display:grid;grid-template-columns:1fr 1fr;gap:14px}
@keyframes fadeIn{from{opacity:0;transform:translateY(6px)}to{opacity:1;transform:translateY(0)}}
@keyframes spin{to{transform:rotate(360deg)}}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.ai{animation:fadeIn .3s ease}
@media(max-width:768px){.g2{grid-template-columns:1fr!important}}
`;

export default function GlobalStyle() {
  useEffect(() => {
    const id = "tf-global-style";
    const existing = document.getElementById(id);
    if (existing) {
      existing.textContent = STYLE;
      return;
    }

    const tag = document.createElement("style");
    tag.id = id;
    tag.textContent = STYLE;
    document.head.appendChild(tag);
  }, []);

  return null;
}
