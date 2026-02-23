#!/usr/bin/env bash
set -euo pipefail
mkdir -p talentflow
cd talentflow
mkdir -p \
  src \
  src\app \
  src\components\common \
  src\constants \
  src\features\admin \
  src\features\admin\apps \
  src\features\admin\cands \
  src\features\admin\jobs \
  src\features\auth \
  src\features\candidate \
  src\features\candidate\apply \
  src\features\candidate\apps \
  src\features\candidate\interview \
  src\features\candidate\jobs \
  src\features\candidate\profile \
  src\repositories \
  src\services\ai \
  src\services\interview \
  src\services\recruitment \
  src\services\storage \
  src\styles \
  src\utils

cat > .env.example <<'EOF'
VITE_AI_ENDPOINT=https://api.anthropic.com/v1/messages
VITE_AI_MODEL=claude-sonnet-4-20250514
EOF

cat > index.html <<'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>TalentFlow</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > package.json <<'EOF'
{
  "name": "talentflow",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "vite": "^5.4.10"
  }
}
EOF

cat > src/app/App.jsx <<'EOF'
import { useState, useEffect, useCallback, useRef } from "react";

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

/* Constants */
const STAGES={applied:{l:"Başvuru",i:"📋"},interview:{l:"Mülakat",i:"💬"},offer:{l:"Teklif",i:"💰"},negotiation:{l:"Müzakere",i:"🤝"},hired:{l:"İşe Alındı",i:"🎉"},rejected:{l:"Red",i:"✕"}};
const STAGE_ORDER=["applied","interview","offer","negotiation","hired"];
const K={users:"tf6:u",jobs:"tf6:j",apps:"tf6:a",session:"tf6:s"};
const SEED_JOBS=[
  {id:"j1",title:"Senior Frontend Developer",dept:"Mühendislik",location:"İstanbul (Hibrit)",type:"Tam Zamanlı",level:"Senior",salaryMin:60000,salaryMax:90000,headcount:2,desc:"React ve TypeScript ile ürün geliştirme.",requirements:["React 5+ yıl","TypeScript","Redux/Zustand","REST API","Test yazımı"],status:"active",hiredCount:0,applicants:0,createdAt:new Date(Date.now()-14*864e5).toISOString()},
  {id:"j2",title:"Backend Developer (Python)",dept:"Mühendislik",location:"Uzaktan",type:"Tam Zamanlı",level:"Mid",salaryMin:50000,salaryMax:75000,headcount:1,desc:"Python/Django mikro servis backend.",requirements:["Python 3+ yıl","Django/FastAPI","PostgreSQL","Docker"],status:"active",hiredCount:0,applicants:0,createdAt:new Date(Date.now()-7*864e5).toISOString()},
  {id:"j3",title:"Product Manager",dept:"Ürün",location:"Uzaktan",type:"Tam Zamanlı",level:"Mid-Senior",salaryMin:70000,salaryMax:100000,headcount:1,desc:"Ürün stratejisi ve geliştirme koordinasyonu.",requirements:["3+ yıl PM","Agile/Scrum","Veri analizi","Paydaş yönetimi"],status:"active",hiredCount:0,applicants:0,createdAt:new Date(Date.now()-3*864e5).toISOString()},
];

/* Personality Test */
const PQ=[
  {q:"Toplantıda fikirlerinizi paylaşır mısınız?",a:["Hep ilk söz alan benim","Bağlamına göre değişir","Dinlemeyi tercih ederim","Söz almak tedirgin eder"],t:["D","C","A","S"]},
  {q:"Yeni projeye nasıl başlarsınız?",a:["Hemen uygularım","Beyin fırtınası yaparım","Araştırma/planlama yaparım","Detaylı analiz çıkartırım"],t:["D","C","A","S"]},
  {q:"Stresli durumda tepkiniz?",a:["Hızlı karar alırım","Ekiple konuşurum","Sakin kalıp analiz ederim","Gözlemler beklerim"],t:["D","C","A","S"]},
  {q:"Takımda sizi tanımlayan?",a:["Liderlik","Motive edici","Detaycı","Uyumlu destek"],t:["D","C","A","S"]},
  {q:"Karar verirken öncelik?",a:["Sonuç/verimlilik","İnsanlar/ilişkiler","Veriler/doğruluk","Denge/istikrar"],t:["D","C","A","S"]},
  {q:"Sizi motive eden?",a:["Başarı ve hedefler","Takdir ve sosyal","Doğruluk ve kalite","Güven ve düzen"],t:["D","C","A","S"]},
  {q:"Değişime tutumunuz?",a:["Heyecan duyarım","İkna ederim","Riskleri analiz ederim","Temkinli yaklaşırım"],t:["D","C","A","S"]},
  {q:"İletişim tarzınız?",a:["Doğrudan ve net","Enerjik ve ikna edici","Detaylı ve yazılı","Sabırlı ve dinleyici"],t:["D","C","A","S"]},
  {q:"Problem karşısında?",a:["Hemen çözüm üretirim","Başkalarına danışırım","Kök neden araştırırım","Acele etmem"],t:["D","C","A","S"]},
  {q:"Kendinizi tanımlayın:",a:["Kararlı, sonuç odaklı","İlham veren, sosyal","Analitik, titiz","Güvenilir, sabırlı"],t:["D","C","A","S"]},
];
const DISC={D:{n:"Dominant",c:"var(--red)",e:"🦁",d:"Sonuç odaklı, kararlı lider."},C:{n:"Etkileyen",c:"var(--amber)",e:"🌟",d:"Sosyal, ikna edici, motive edici."},A:{n:"Analitik",c:"var(--blue)",e:"🔬",d:"Detay odaklı, titiz, veri tabanlı."},S:{n:"Uyumlu",c:"var(--green)",e:"🕊️",d:"Sabırlı, güvenilir, takım oyuncusu."}};

/* Storage */
const sg=async k=>{try{const r=await window.storage.get(k);return r?JSON.parse(r.value):null}catch{return null}};
const ss=async(k,v)=>{try{await window.storage.set(k,JSON.stringify(v))}catch(e){console.error(e)}};

/* AI */
async function callAI(system,user){
  try{
    const r=await fetch("https://api.anthropic.com/v1/messages",{method:"POST",headers:{"Content-Type":"application/json"},body:JSON.stringify({model:"claude-sonnet-4-20250514",max_tokens:2000,system:system+"\nKRİTİK: Sadece geçerli JSON döndür.",messages:[{role:"user",content:user}]})});
    const d=await r.json();const raw=d.content?.[0]?.text||"{}";
    return JSON.parse(raw.replace(/```json|```/g, "").trim());
  }catch(e){return {error:true};}
}

/* Helpers */
const days=iso=>Math.floor((Date.now()-new Date(iso).getTime())/864e5);
const fmtD=iso=>new Date(iso).toLocaleDateString("tr-TR",{day:"2-digit",month:"long",year:"numeric"});
const fmtS=iso=>new Date(iso).toLocaleDateString("tr-TR");
const salK=n=>(n/1000).toFixed(0)+"K";
function profileOk(u){return u&&u.name&&u.summary&&u.experience&&u.education&&(u.skills||"").length>0;}

/* Micro components */
function Spin({s=16,c="var(--blue)"}){return <div style={{width:s,height:s,borderRadius:"50%",border:"2px solid var(--line)",borderTopColor:c,animation:"spin .8s linear infinite",display:"inline-block"}}/>}
function Pill({stage}){const s=STAGES[stage]||STAGES.applied;const m={applied:"bb",interview:"bpu",offer:"ba",negotiation:"bt",hired:"bgr",rejected:"br"};return <span className={"badge "+(m[stage]||"bgy")}>{s.i} {s.l}</span>}
function Bar({val,max=100,color="var(--blue)"}){return <div style={{background:"var(--sand3)",borderRadius:4,height:5,overflow:"hidden"}}><div style={{height:"100%",width:`${(val/max)*100}%`,background:color,borderRadius:4,transition:"width .4s"}}/></div>}
function StageBar({current}){const idx=STAGE_ORDER.indexOf(current);return(<div style={{display:"flex",alignItems:"center",width:"100%"}}>{STAGE_ORDER.map((s,i)=>{const done=i<idx;const act=i===idx;return(<div key={s} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center"}}><div style={{display:"flex",alignItems:"center",width:"100%"}}>{i>0&&<div style={{flex:1,height:2,background:done||act?"var(--blue)":"var(--line)"}}/>}<div style={{width:22,height:22,borderRadius:"50%",background:act?"var(--blue)":done?"var(--green)":"var(--sand3)",border:`2px solid ${act?"var(--blue)":done?"var(--green)":"var(--line)"}`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:9,flexShrink:0,color:act||done?"#fff":"var(--muted)",fontWeight:700}}>{done?"✓":i+1}</div>{i<4&&<div style={{flex:1,height:2,background:done?"var(--blue)":"var(--line)"}}/>}</div><div style={{fontSize:9,color:act?"var(--blue)":done?"var(--green)":"var(--muted)",marginTop:2,fontWeight:act?600:400}}>{STAGES[s].l}</div></div>)})}</div>)}

function AgentPipe({steps,cur}){const M={cv:"📄 CV Analizi",match:"🎯 Eşleştirme",questions:"💬 Soru Üretimi",notify:"✉️ Bildirim"};return(<div style={{background:"var(--sand2)",border:"1px solid var(--line)",borderRadius:"var(--r)",padding:14,marginTop:10}}><div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",marginBottom:8}}>⚡ AI İŞLEM HATTI</div>{steps.map((k,i)=>{const done=i<cur;const act=i===cur;return(<div key={k} style={{display:"flex",alignItems:"center",gap:10,padding:"4px 0",opacity: i > cur ? 0.4 : 1}}><div style={{width:20,height:20,borderRadius:"50%",background:done?"var(--green2)":act?"var(--blue3)":"var(--sand3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:9,flexShrink:0}}>{done?"✓":act?<Spin s={8}/>:i+1}</div><div style={{fontSize:12,fontWeight:600,color:done?"var(--green)":act?"var(--blue)":"var(--muted)"}}>{M[k]||k}{act&&<span style={{fontSize:10,color:"var(--muted)",marginLeft:6,animation:"pulse 1.5s infinite"}}>işleniyor...</span>}</div></div>)})}</div>)}

/* ═══ AUTH ═══ */
function AuthScreen({onLogin}){
  const [mode,setMode]=useState("login");const [role,setRole]=useState("candidate");
  const [form,setForm]=useState({name:"",email:"",password:"",title:""});
  const [err,setErr]=useState("");const [busy,setBusy]=useState(false);
  const set=k=>e=>setForm(f=>({...f,[k]:e.target.value}));
  async function login(){
    if(!form.email||!form.password){setErr("E-posta ve şifre zorunlu.");return;}
    setBusy(true);setErr("");const users=(await sg(K.users))||{};
    const u=Object.values(users).find(u=>u.email===form.email.toLowerCase().trim()&&u.password===form.password);
    if(!u){setErr("E-posta veya şifre hatalı.");setBusy(false);return;}
    await ss(K.session,u);onLogin(u);setBusy(false);
  }
  async function register(){
    if(!form.name||!form.email||!form.password){setErr("Tüm alanlar zorunlu.");return;}
    if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email)){setErr("Geçerli e-posta girin.");return;}
    setBusy(true);setErr("");const users=(await sg(K.users))||{};
    if(Object.values(users).some(u=>u.email===form.email.toLowerCase().trim())){setErr("Bu e-posta kayıtlı.");setBusy(false);return;}
    const u={id:`u_${Date.now()}`,name:form.name.trim(),email:form.email.toLowerCase().trim(),password:form.password,role,title:form.title,skills:"",skillRatings:[],certifications:[],exams:[],personalityResult:null,createdAt:new Date().toISOString()};
    users[u.id]=u;await ss(K.users,users);await ss(K.session,u);onLogin(u);setBusy(false);
  }
  async function demo(r){
    const users=(await sg(K.users))||{};const em=r==="admin"?"admin@d.com":"aday@d.com";
    let u=Object.values(users).find(x=>x.email===em);
    if(!u){u=r==="admin"?{id:"da",name:"Elif Yıldız",email:em,password:"d",role:"admin",title:"İK Müdürü",createdAt:new Date().toISOString()}:{id:"dc",name:"Ahmet Demir",email:em,password:"d",role:"candidate",title:"Frontend Dev",skills:"React, TypeScript, Node.js",skillRatings:[{name:"React",level:90},{name:"TypeScript",level:85},{name:"Node.js",level:70}],certifications:[{name:"AWS SA",org:"Amazon",date:"2024-03",certId:"AWS-12345"}],exams:[{name:"IELTS",score:"7.5",date:"2024-06",validUntil:"2026-06"}],summary:"5 yıl deneyimli React geliştirici.",experience:"TechCorp – Sr Frontend (2021-2024)",education:"İTÜ Bilgisayar Müh. 2019",city:"İstanbul",personalityResult:{dominant:"A",scores:{D:1,C:2,A:5,S:2},date:new Date().toISOString()},createdAt:new Date().toISOString()};users[u.id]=u;await ss(K.users,users);}
    let jm=await sg(K.jobs);if(!jm||!Object.keys(jm).length){jm={};SEED_JOBS.forEach(j=>jm[j.id]=j);await ss(K.jobs,jm);}
    await ss(K.session,u);onLogin(u);
  }
  return(
    <div style={{minHeight:"100vh",background:"var(--sand)",display:"flex"}}><style>{STYLE}</style>
      <div style={{flex:1,background:"var(--ink)",display:"flex",flexDirection:"column",justifyContent:"center",padding:"60px 80px",position:"relative",overflow:"hidden"}}>
        <div style={{position:"relative",zIndex:1}}>
          <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:56}}><div style={{width:44,height:44,borderRadius:14,background:"rgba(255,255,255,.12)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:22}}>⚡</div><span style={{fontFamily:"var(--fr)",fontSize:26,fontWeight:700,color:"#fff"}}>TalentFlow</span></div>
          <h1 style={{fontFamily:"var(--fr)",fontSize:38,fontWeight:600,color:"#fff",lineHeight:1.15,marginBottom:20}}>İşe alımın<br/>en akıllı hali</h1>
          <p style={{fontSize:15,color:"rgba(255,255,255,.5)",lineHeight:1.7,maxWidth:380}}>AI mülakat, şeffaf müzakere, uçtan uca süreç.</p>
        </div>
      </div>
      <div style={{width:440,display:"flex",alignItems:"center",justifyContent:"center",padding:40}}>
        <div style={{width:"100%"}} className="ai">
          <h2 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600,marginBottom:6}}>{mode==="login"?"Hoş geldiniz":"Hesap oluşturun"}</h2>
          <p style={{fontSize:14,color:"var(--muted)",marginBottom:24}}>{mode==="login"?"Bilgilerinizle giriş yapın":"Hemen başlayın"}</p>
          <div style={{display:"flex",gap:4,background:"var(--sand2)",borderRadius:"var(--r)",padding:4,marginBottom:20}}>{[["login","Giriş"],["register","Kayıt"]].map(([m,l])=>(<button key={m} onClick={()=>{setMode(m);setErr("")}} style={{flex:1,padding:"8px 0",borderRadius:6,background:mode===m?"#fff":"transparent",color:mode===m?"var(--ink)":"var(--muted)",fontWeight:mode===m?600:400,fontSize:13,boxShadow:mode===m?"var(--sh)":undefined}}>{l}</button>))}</div>
          {mode==="register"&&<div style={{marginBottom:14}}><label>Hesap Tipi</label><div style={{display:"flex",gap:8}}>{[["candidate","👤 Aday"],["admin","🛡️ İK"]].map(([r2,l])=>(<button key={r2} onClick={()=>setRole(r2)} style={{flex:1,padding:"9px 0",borderRadius:"var(--r)",background:role===r2?"var(--ink)":"#fff",border:`1.5px solid ${role===r2?"var(--ink)":"var(--line)"}`,color:role===r2?"#fff":"var(--ink3)",fontWeight:600,fontSize:13}}>{l}</button>))}</div></div>}
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {mode==="register"&&<><div><label>Ad Soyad</label><input value={form.name} onChange={set("name")}/></div><div><label>Ünvan</label><input value={form.title} onChange={set("title")}/></div></>}
            <div><label>E-posta</label><input type="email" value={form.email} onChange={set("email")}/></div>
            <div><label>Şifre</label><input type="password" value={form.password} onChange={set("password")}/></div>
          </div>
          {err&&<div style={{background:"var(--red2)",border:"1px solid #fecaca",borderRadius:"var(--r)",padding:"8px 12px",fontSize:13,color:"#991b1b",marginTop:10}}>{err}</div>}
          <button className="btn bp" style={{width:"100%",marginTop:14,padding:"11px 0",justifyContent:"center"}} onClick={mode==="login"?login:register} disabled={busy}>{busy?<Spin s={14} c="#fff"/>:mode==="login"?"Giriş Yap →":"Hesap Oluştur →"}</button>
          <div style={{marginTop:18,paddingTop:18,borderTop:"1px solid var(--line)"}}><div style={{fontSize:11,color:"var(--muted)",textAlign:"center",marginBottom:8}}>Demo</div><div style={{display:"flex",gap:8}}><button className="btn bg" style={{flex:1,justifyContent:"center",fontSize:12}} onClick={()=>demo("candidate")}>👤 Aday</button><button className="btn bg" style={{flex:1,justifyContent:"center",fontSize:12}} onClick={()=>demo("admin")}>🛡️ Admin</button></div></div>
        </div>
      </div>
    </div>
  );
}

/* ═══ CANDIDATE PROFILE ═══ */
function CandProfile({user,onUpdate}){
  const [tab,setTab]=useState("info");
  const [f,setF]=useState({name:user.name||"",title:user.title||"",phone:user.phone||"",city:user.city||"",summary:user.summary||"",skills:user.skills||"",experience:user.experience||"",education:user.education||""});
  const [skillR,setSkillR]=useState(user.skillRatings||[]);const [ns,setNs]=useState("");const [nl,setNl]=useState(50);
  const [certs,setCerts]=useState(user.certifications||[]);
  const [exams,setExams]=useState(user.exams||[]);
  const [saved,setSaved]=useState(false);
  const [pers,setPers]=useState(user.personalityResult||null);const [tq,setTq]=useState(-1);const [ta,setTa]=useState([]);
  const sv=k=>e=>setF(x=>({...x,[k]:e.target.value}));
  async function save(){await onUpdate({...f,skillRatings:skillR,certifications:certs,exams});setSaved(true);setTimeout(()=>setSaved(false),2500);}
  function ansTest(ai){const na=[...ta,ai];setTa(na);if(na.length>=PQ.length){const sc={D:0,C:0,A:0,S:0};na.forEach((a,qi)=>{const t=PQ[qi].t[a];if(sc[t]!==undefined)sc[t]++;});const dom=Object.entries(sc).sort((a,b)=>b[1]-a[1])[0][0];const res={dominant:dom,scores:sc,date:new Date().toISOString()};setPers(res);onUpdate({personalityResult:res});setTq(-1);}else setTq(na.length);}
  async function handleCv(e){const file=e.target.files?.[0];if(!file)return;const txt=await file.text();const r=await callAI("CV ayrıştır. JSON:{\"name\":\"...\",\"title\":\"...\",\"summary\":\"...\",\"experience\":\"...\",\"education\":\"...\",\"skills\":\"virgülle\"}","CV:\n"+txt.slice(0,3000));if(!r.error)setF(x=>({...x,name:r.name||x.name,title:r.title||x.title,summary:r.summary||x.summary,experience:r.experience||x.experience,education:r.education||x.education,skills:r.skills||x.skills}));}
  const TABS=[["info","👤 Bilgiler"],["skills","⚡ Yetkinlikler"],["certs","📜 Sertifikalar"],["exams","📝 Sınavlar"],["pers","🧠 Kişilik Testi"]];
  return(
    <div className="ai" style={{maxWidth:720}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:18}}>
        <div><h1 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600}}>Profilim</h1><p style={{color:"var(--muted)",fontSize:13}}>Başvurularda bu bilgiler kullanılır</p></div>
        <div style={{display:"flex",gap:8}}><label className="btn bg" style={{cursor:"pointer",fontSize:12}}>📎 CV Yükle<input type="file" accept=".txt,.md,.csv" onChange={handleCv} style={{display:"none"}}/></label><button className={"btn "+(saved?"":"bp")} style={saved?{background:"var(--green2)",color:"var(--green)",border:"1.5px solid #bbf7d0"}:{}} onClick={save}>{saved?"✓ Kaydedildi":"Kaydet"}</button></div>
      </div>
      {!profileOk({...user,...f})&&<div style={{background:"var(--amber2)",border:"1px solid #fde68a",borderRadius:"var(--r)",padding:"10px 14px",fontSize:13,color:"#92400e",marginBottom:14}}>⚠️ Profiliniz eksik. İlanlara başvurabilmek için bilgileri tamamlayın.</div>}
      <div style={{display:"flex",gap:4,marginBottom:18,flexWrap:"wrap"}}>{TABS.map(([t,l])=>(<button key={t} onClick={()=>setTab(t)} style={{padding:"7px 14px",borderRadius:20,background:tab===t?"var(--ink)":"#fff",color:tab===t?"#fff":"var(--ink3)",border:`1.5px solid ${tab===t?"var(--ink)":"var(--line)"}`,fontSize:12,fontWeight:tab===t?600:400}}>{l}</button>))}</div>

      {tab==="info"&&<div className="card ai"><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:14}}>Kişisel Bilgiler</h3><div className="g2" style={{gap:12,marginBottom:14}}><div><label>Ad Soyad *</label><input value={f.name} onChange={sv("name")}/></div><div><label>Ünvan</label><input value={f.title} onChange={sv("title")}/></div><div><label>Telefon</label><input value={f.phone} onChange={sv("phone")}/></div><div><label>Şehir</label><input value={f.city} onChange={sv("city")}/></div></div><div style={{marginBottom:12}}><label>Özet *</label><textarea rows={3} value={f.summary} onChange={sv("summary")}/></div><div style={{marginBottom:12}}><label>Beceriler * (virgülle)</label><input value={f.skills} onChange={sv("skills")}/></div><div style={{marginBottom:12}}><label>İş Deneyimi *</label><textarea rows={4} value={f.experience} onChange={sv("experience")}/></div><div><label>Eğitim *</label><textarea rows={2} value={f.education} onChange={sv("education")}/></div></div>}

      {tab==="skills"&&<div className="card ai"><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:4}}>Yetkinlik Seviyeleri</h3><p style={{fontSize:13,color:"var(--muted)",marginBottom:14}}>Her beceri için 0-100 seviye belirleyin.</p>{skillR.map((sk,i)=>(<div key={i} style={{display:"flex",alignItems:"center",gap:10,marginBottom:10,padding:"10px 12px",background:"var(--sand2)",borderRadius:"var(--r)"}}><div style={{flex:1}}><div style={{display:"flex",justifyContent:"space-between",marginBottom:3}}><span style={{fontSize:13,fontWeight:600}}>{sk.name}</span><span style={{fontSize:12,fontWeight:700,fontFamily:"var(--mono)",color:sk.level>=80?"var(--green)":sk.level>=50?"var(--blue)":"var(--amber)"}}>{sk.level}/100</span></div><Bar val={sk.level} color={sk.level>=80?"var(--green)":sk.level>=50?"var(--blue)":"var(--amber)"}/></div><button onClick={()=>setSkillR(s=>s.filter((_,idx)=>idx!==i))} style={{background:"none",color:"var(--red)",fontSize:14}}>✕</button></div>))}<div style={{display:"flex",gap:8,alignItems:"flex-end",padding:12,background:"var(--sand2)",borderRadius:"var(--r)"}}><div style={{flex:1}}><label>Beceri</label><input value={ns} onChange={e=>setNs(e.target.value)} onKeyDown={e=>{if(e.key==="Enter"&&ns.trim()){setSkillR(s=>[...s,{name:ns.trim(),level:Number(nl)}]);setNs("");}}} placeholder="React, Proje Yönetimi..."/></div><div style={{width:130}}><label>Seviye: {nl}</label><input type="range" min={10} max={100} value={nl} onChange={e=>setNl(e.target.value)} style={{padding:0,border:"none",background:"transparent"}}/></div><button className="btn bp" style={{fontSize:12,padding:"7px 14px"}} onClick={()=>{if(ns.trim()){setSkillR(s=>[...s,{name:ns.trim(),level:Number(nl)}]);setNs("");}}}>+ Ekle</button></div></div>}

      {tab==="certs"&&<div className="card ai"><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:14}}>Sertifikalar</h3>{certs.map((c,i)=>(<div key={i} style={{padding:12,background:"var(--sand2)",borderRadius:"var(--r)",marginBottom:8,position:"relative"}}><button onClick={()=>setCerts(x=>x.filter((_,idx)=>idx!==i))} style={{position:"absolute",top:8,right:8,background:"none",color:"var(--red)",fontSize:14}}>✕</button><div className="g2" style={{gap:8}}><div><label>Sertifika Adı</label><input value={c.name} onChange={e=>{const v=e.target.value;setCerts(x=>x.map((cc,idx)=>idx===i?{...cc,name:v}:cc))}}/></div><div><label>Kurum</label><input value={c.org} onChange={e=>{const v=e.target.value;setCerts(x=>x.map((cc,idx)=>idx===i?{...cc,org:v}:cc))}}/></div><div><label>Tarih</label><input type="month" value={c.date} onChange={e=>{const v=e.target.value;setCerts(x=>x.map((cc,idx)=>idx===i?{...cc,date:v}:cc))}}/></div><div><label>Sertifika ID</label><input value={c.certId} onChange={e=>{const v=e.target.value;setCerts(x=>x.map((cc,idx)=>idx===i?{...cc,certId:v}:cc))}}/></div></div></div>))}<button className="btn bg" style={{width:"100%",justifyContent:"center"}} onClick={()=>setCerts(c=>[...c,{name:"",org:"",date:"",certId:""}])}>+ Sertifika Ekle</button></div>}

      {tab==="exams"&&<div className="card ai"><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:14}}>Geçerli Sınavlar</h3>{exams.map((ex,i)=>(<div key={i} style={{padding:12,background:"var(--sand2)",borderRadius:"var(--r)",marginBottom:8,position:"relative"}}><button onClick={()=>setExams(x=>x.filter((_,idx)=>idx!==i))} style={{position:"absolute",top:8,right:8,background:"none",color:"var(--red)",fontSize:14}}>✕</button><div className="g2" style={{gap:8}}><div><label>Sınav</label><input value={ex.name} onChange={e=>{const v=e.target.value;setExams(x=>x.map((ee,idx)=>idx===i?{...ee,name:v}:ee))}}/></div><div><label>Skor</label><input value={ex.score} onChange={e=>{const v=e.target.value;setExams(x=>x.map((ee,idx)=>idx===i?{...ee,score:v}:ee))}}/></div><div><label>Tarih</label><input type="month" value={ex.date} onChange={e=>{const v=e.target.value;setExams(x=>x.map((ee,idx)=>idx===i?{...ee,date:v}:ee))}}/></div><div><label>Geçerlilik</label><input type="month" value={ex.validUntil} onChange={e=>{const v=e.target.value;setExams(x=>x.map((ee,idx)=>idx===i?{...ee,validUntil:v}:ee))}}/></div></div></div>))}<button className="btn bg" style={{width:"100%",justifyContent:"center"}} onClick={()=>setExams(e=>[...e,{name:"",score:"",date:"",validUntil:""}])}>+ Sınav Ekle</button></div>}

      {tab==="pers"&&<div className="card ai"><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:4}}>🧠 Kişilik Envanteri</h3><p style={{fontSize:13,color:"var(--muted)",marginBottom:14}}>10 soruluk envanter ile kişilik tipinizi belirleyin.</p>
        {pers&&tq===-1?(<div style={{textAlign:"center",padding:"16px 0"}}><div style={{width:72,height:72,borderRadius:"50%",background:DISC[pers.dominant]?.c+"20",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 10px",fontSize:32}}>{DISC[pers.dominant]?.e}</div><div style={{fontSize:18,fontWeight:700,fontFamily:"var(--fr)",color:DISC[pers.dominant]?.c}}>{DISC[pers.dominant]?.n}</div><p style={{fontSize:13,color:"var(--muted)",marginTop:6}}>{DISC[pers.dominant]?.d}</p><div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:6,marginTop:14}}>{Object.entries(pers.scores).map(([k,v])=>(<div key={k} style={{background:"var(--sand2)",borderRadius:"var(--r)",padding:8,textAlign:"center"}}><div style={{fontSize:16,fontWeight:700,color:DISC[k]?.c}}>{v}</div><div style={{fontSize:9,color:"var(--muted)"}}>{DISC[k]?.n}</div><Bar val={v} max={10} color={DISC[k]?.c||"var(--blue)"}/></div>))}</div><div style={{fontSize:11,color:"var(--muted)",marginTop:10}}>Test: {fmtD(pers.date)}</div></div>)
        :tq>=0?(<div><div style={{display:"flex",alignItems:"center",gap:8,marginBottom:14}}><div style={{flex:1,background:"var(--sand3)",borderRadius:4,height:5,overflow:"hidden"}}><div style={{height:"100%",width:`${(tq/PQ.length)*100}%`,background:"var(--purple)",borderRadius:4,transition:"width .3s"}}/></div><span style={{fontSize:11,fontWeight:600,color:"var(--purple)",fontFamily:"var(--mono)"}}>{tq+1}/{PQ.length}</span></div><div style={{fontSize:15,fontWeight:600,marginBottom:14,lineHeight:1.4}}>{PQ[tq].q}</div>{PQ[tq].a.map((a,ai)=>(<button key={ai} onClick={()=>ansTest(ai)} style={{display:"block",width:"100%",padding:"10px 14px",borderRadius:"var(--r)",border:"1.5px solid var(--line)",background:"#fff",textAlign:"left",fontSize:13,marginBottom:6}} onMouseEnter={e=>{e.currentTarget.style.borderColor="var(--purple)";e.currentTarget.style.background="var(--purple2)"}} onMouseLeave={e=>{e.currentTarget.style.borderColor="var(--line)";e.currentTarget.style.background="#fff"}}><span style={{fontWeight:600,color:"var(--purple)",marginRight:6}}>{String.fromCharCode(65+ai)}.</span>{a}</button>))}</div>)
        :(<div style={{textAlign:"center",padding:"24px 0"}}><div style={{fontSize:44,marginBottom:10}}>🧠</div><p style={{color:"var(--muted)",marginBottom:14}}>10 soruluk kişilik envanteri</p><button className="btn" style={{background:"var(--purple2)",color:"var(--purple)",border:"1.5px solid #ddd6fe"}} onClick={()=>{setTq(0);setTa([])}}>Teste Başla</button></div>)}
      </div>}
    </div>
  );
}


/* ═══ REQUIRED ONBOARDING DOCS ═══ */
const REQ_DOCS=[{l:"Nüfus Cüzdanı Fotokopisi",i:"🪪"},{l:"Diploma / Geçici Mezuniyet",i:"🎓"},{l:"Transkript",i:"📄"},{l:"SGK İşe Giriş Bildirgesi",i:"📋"},{l:"Adli Sicil Kaydı",i:"📜"},{l:"2 Adet Fotoğraf",i:"📷"},{l:"İş Sözleşmesi (İmzalı)",i:"📝"},{l:"Banka IBAN Bilgisi",i:"🏦"}];

/* ═══ CANDIDATE APPLICATION CARD ═══ */
function CandAppCard({app,job,onInterview,onRefresh}){
  const [counterAmt,setCounterAmt]=useState("");const [showCounter,setShowCounter]=useState(false);
  const a=app;const j=job;
  const need=a.stage==="interview"&&!a.interviewAnswers;
  const needO=a.stage==="offer"&&a.offerHistory?.at(-1)?.from==="admin"&&!a.offerHistory.at(-1).candidateResponse;
  const needH=a.stage==="hired"&&!a.candidateHireAccepted;
  const isHiredDone=a.stage==="hired"&&a.adminHireApproved;

  async function respond(type){
    const am=(await sg(K.apps))||{};const h=[...(am[a.id].offerHistory||[])];
    if(type==="accept"){h[h.length-1]={...h[h.length-1],candidateResponse:"accept",respondedAt:new Date().toISOString()};am[a.id].offerHistory=h;am[a.id].stage="hired";}
    else if(type==="reject"){h[h.length-1]={...h[h.length-1],candidateResponse:"reject",respondedAt:new Date().toISOString()};am[a.id].offerHistory=h;am[a.id].stage="rejected";}
    else if(type==="counter"){if(!counterAmt){alert("Karşı teklif tutarı girin.");return;}h[h.length-1]={...h[h.length-1],candidateResponse:"counter",counterAmount:Number(counterAmt),respondedAt:new Date().toISOString()};h.push({from:"candidate",amount:Number(counterAmt),note:"Karşı teklif",createdAt:new Date().toISOString()});am[a.id].offerHistory=h;am[a.id].stage="negotiation";setShowCounter(false);setCounterAmt("");}
    await ss(K.apps,am);onRefresh();
  }

  return(
    <div className="card" style={{padding:"14px 16px"}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start",marginBottom:10}}>
        <div style={{flex:1}}><div style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:15}}>{j?.title||"?"}</div><div style={{fontSize:12,color:"var(--muted)"}}>{j?.dept} · {fmtS(a.appliedAt)}</div></div>
        <div style={{display:"flex",gap:6,alignItems:"center"}}>{(need||needO||needH)&&<span style={{background:"var(--amber)",color:"#fff",fontSize:9,fontWeight:700,padding:"2px 7px",borderRadius:10,fontFamily:"var(--mono)"}}>AKSİYON</span>}<Pill stage={a.stage}/></div>
      </div>
      <StageBar current={a.stage==="rejected"?"applied":a.stage}/>

      {/* Skor satırı */}
      {a.agentResult?.cv&&<div style={{display:"flex",gap:10,marginTop:10}}>{[["CV",a.agentResult.cv.puan],["Eşleşme",a.agentResult.match?.eslesme_yuzdesi],["Mülakat",a.interviewScore?.toplam_puan]].map(([l,v])=>v!=null&&<span key={l} style={{fontSize:11,fontWeight:700,fontFamily:"var(--mono)",color:v>=70?"var(--green)":"var(--amber)"}}>{l}: {v}</span>)}</div>}

      {/* Mülakat sonuçları */}
      {a.interviewScore&&a.interviewAnswers&&<div style={{marginTop:12,background:"var(--sand2)",borderRadius:"var(--r)",padding:14}}>
        <div style={{fontSize:11,fontWeight:600,color:"var(--muted)",marginBottom:8}}>📊 Mülakat Sonucunuz</div>
        <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:8,marginBottom:10}}>
          {[["Toplam",a.interviewScore.toplam_puan,"var(--ink)"],["Açık Uçlu",a.interviewScore.acik_uclu_ort,"var(--purple)"],["Teknik Test",a.interviewScore.mc_ort,"var(--teal)"],["Kod",a.interviewScore.kod_ort,"var(--amber)"]].map(([l,v,c])=>v!=null&&<div key={l} style={{textAlign:"center",background:"#fff",borderRadius:"var(--r)",padding:6}}><div style={{fontSize:18,fontWeight:700,fontFamily:"var(--fr)",color:c}}>{typeof v==="number"?Math.round(v):v}</div><div style={{fontSize:8,color:"var(--muted)"}}>{l}</div></div>)}
        </div>
        {a.interviewScore.genel_yorum&&<div style={{fontSize:12,color:"var(--ink3)",lineHeight:1.5,marginBottom:6}}>{a.interviewScore.genel_yorum}</div>}
        <div style={{display:"flex",gap:4,flexWrap:"wrap"}}>{(a.interviewScore.guclu_yonler||[]).map(g=><span key={g} className="badge bgr" style={{fontSize:9}}>{g}</span>)}{(a.interviewScore.gelistirme_alanlari||[]).map(g=><span key={g} className="badge ba" style={{fontSize:9}}>△ {g}</span>)}</div>
      </div>}

      {/* Mülakat bekliyor */}
      {need&&<button className="btn bp" style={{marginTop:12,width:"100%",justifyContent:"center"}} onClick={onInterview}>💬 Mülakata Başla</button>}

      {/* Teklif — Kabul / Red / Karşı Teklif */}
      {needO&&<div style={{marginTop:12,background:"var(--sand2)",borderRadius:"var(--r)",padding:14}}>
        <div style={{fontSize:15,fontWeight:700,fontFamily:"var(--fr)",marginBottom:4}}>💰 Maaş Teklifi</div>
        <div style={{fontSize:22,fontWeight:700,color:"var(--green)",fontFamily:"var(--fr)"}}>{(a.offerHistory.at(-1).amount||0).toLocaleString("tr-TR")} ₺/ay</div>
        {a.offerHistory.at(-1).note&&<div style={{fontSize:12,color:"var(--muted)",marginTop:4}}>{a.offerHistory.at(-1).note}</div>}
        <div style={{display:"flex",gap:6,marginTop:10}}>
          <button className="btn" style={{flex:1,background:"var(--green2)",color:"var(--green)",border:"1.5px solid #bbf7d0",justifyContent:"center",fontWeight:700}} onClick={()=>respond("accept")}>✓ Kabul</button>
          <button className="btn" style={{flex:1,background:"var(--amber2)",color:"var(--amber)",border:"1.5px solid #fde68a",justifyContent:"center",fontWeight:700}} onClick={()=>setShowCounter(!showCounter)}>↔ Karşı Teklif</button>
          <button className="btn" style={{flex:1,background:"var(--red2)",color:"var(--red)",border:"1.5px solid #fecaca",justifyContent:"center",fontWeight:700}} onClick={()=>respond("reject")}>✗ Red</button>
        </div>
        {showCounter&&<div style={{marginTop:10,display:"flex",gap:8}}><input type="number" placeholder="Karşı teklif tutarı (₺/ay)" value={counterAmt} onChange={e=>setCounterAmt(e.target.value)} style={{flex:1}}/><button className="btn bp" onClick={()=>respond("counter")}>Gönder</button></div>}
      </div>}

      {/* Müzakere aşaması bilgisi */}
      {a.stage==="negotiation"&&<div style={{marginTop:12,background:"var(--purple2)",borderRadius:"var(--r)",padding:14}}>
        <div style={{fontSize:12,fontWeight:600,color:"var(--purple)",marginBottom:4}}>🤝 Müzakere Aşamasında</div>
        <div style={{fontSize:13,color:"var(--ink3)"}}>Karşı teklifiniz: <strong>{(a.offerHistory?.at(-1)?.amount||0).toLocaleString("tr-TR")} ₺/ay</strong></div>
        <div style={{fontSize:12,color:"var(--muted)",marginTop:4}}>Admin yanıtını bekliyor...</div>
      </div>}

      {/* İşe alındı — onay bekliyor (admin onayladı ama aday henüz onaylamadı) */}
      {needH&&<div style={{marginTop:12,background:"var(--green2)",borderRadius:"var(--r)",padding:14}}>
        <div style={{fontSize:14,fontWeight:700,color:"var(--green)",marginBottom:4}}>🎉 Tebrikler! Size teklif yapıldı.</div>
        <div style={{fontSize:12,color:"var(--ink3)",marginBottom:8}}>İşe başlamayı onaylamak için aşağıdaki butona tıklayın.</div>
        <button className="btn" style={{width:"100%",background:"var(--green)",color:"#fff",justifyContent:"center",fontWeight:700}} onClick={async()=>{const am=(await sg(K.apps))||{};am[a.id].candidateHireAccepted=true;am[a.id].candidateHireDate=new Date().toISOString();await ss(K.apps,am);onRefresh();}}>✓ İşe Başlamayı Onayla</button>
      </div>}

      {/* İşe alındı + admin onayladı — evrak listesi */}
      {isHiredDone&&<div style={{marginTop:12,background:"var(--green2)",borderRadius:"var(--r)",padding:14}}>
        <div style={{fontSize:14,fontWeight:700,color:"var(--green)",marginBottom:8}}>🎉 İşe alımınız kesinleşti!</div>
        <div style={{fontSize:12,fontWeight:600,color:"var(--ink3)",marginBottom:8}}>İşe başlama için aşağıdaki belgeleri hazırlayın:</div>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:6}}>{REQ_DOCS.map(d=>(<div key={d.l} style={{display:"flex",alignItems:"center",gap:6,padding:"6px 8px",background:"#fff",borderRadius:"var(--r)",fontSize:12}}><span>{d.i}</span>{d.l}</div>))}</div>
      </div>}
    </div>
  );
}

/* ═══ FULL SCREEN INTERVIEW (DataCamp-style) ═══ */
function FullInterview({app,job,user,onClose,onDone}){
  const oQ=app.interviewQuestions||[];const mQ=app.mcQuestions||[];const cQ=app.codeQuestions||[];
  const total=oQ.length+mQ.length+cQ.length;
  const [qi,setQi]=useState(0);const [ans,setAns]=useState({});const [mcA,setMcA]=useState({});
  const [codeA,setCodeA]=useState({});const [codeOut,setCodeOut]=useState({});const [codeLang,setCodeLang]=useState({});
  const [busy,setBusy]=useState(false);const [done,setDone]=useState(false);
  const [timer,setTimer]=useState(45*60);const ref=useRef(null);
  useEffect(()=>{ref.current=setInterval(()=>setTimer(t=>t<=1?(clearInterval(ref.current),0):t-1),1000);return()=>clearInterval(ref.current);},[]);
  const mm=Math.floor(timer/60),ss2=timer%60,tc=timer<300?"var(--red)":timer<600?"var(--amber)":"var(--green)";
  const all=[];oQ.forEach((q,i)=>all.push({type:"open",i,q}));mQ.forEach((q,i)=>all.push({type:"mc",i,q}));cQ.forEach((q,i)=>all.push({type:"code",i,q}));
  const cur=all[qi];const cnt=Object.keys(ans).filter(k=>ans[k]).length+Object.keys(mcA).length+Object.keys(codeA).filter(k=>typeof codeA[k]==="string"&&codeA[k].trim()).length;

  function runCode(idx){
    const code=codeA[idx]||"";const lang=codeLang[idx]||cQ[idx]?.lang||"javascript";
    if(lang==="sql"){
      /* SQL simulation with mock tables */
      const lower=code.toLowerCase();
      let result="";
      if(lower.includes("order by")&&lower.includes("desc")&&lower.includes("limit")){
        const limitMatch=lower.match(/limit\s+(\d+)/);const n=limitMatch?parseInt(limitMatch[1]):5;
        const mock=[{ad:"Mehmet",soyad:"Öztürk",yillik_gelir:250000},{ad:"Ayşe",soyad:"Kaya",yillik_gelir:220000},{ad:"Ali",soyad:"Yılmaz",yillik_gelir:195000},{ad:"Fatma",soyad:"Demir",yillik_gelir:180000},{ad:"Can",soyad:"Aksoy",yillik_gelir:175000},{ad:"Zeynep",soyad:"Çelik",yillik_gelir:160000}];
        result=mock.slice(0,n).map(r=>Object.values(r).join(" | ")).join("\n");
        result=n+" satır döndü:\n"+result;
      }else if(lower.includes("group by")&&lower.includes("having")){
        result="3 satır döndü:\nElektronik | 7625.00\nMobilya | 2340.00\nGiyim | 450.50";
      }else if(lower.includes("select")&&lower.includes("from")){
        result="5 satır döndü:\n1 | Ali | Yılmaz | İstanbul | 120000\n2 | Ayşe | Demir | Ankara | 95000\n3 | Can | Kaya | İzmir | 85000\n4 | Fatma | Öz | İstanbul | 78000\n5 | Mehmet | Ak | Bursa | 72000";
      }else{result="⚠️ Sorgu tanınamadı. SELECT ... FROM ... yapısı kullanın.";}
      setCodeOut(o=>({...o,[idx]:result}));return;
    }
    if(lang==="python"){
      const lower=code.toLowerCase();let result="";
      if(lower.includes("sorted")&&lower.includes("reverse")||lower.includes("sort")){result="[6, 4, 2]";}
      else if(lower.includes("filter")||lower.includes("lambda")){result="[{'ad': 'Ali', 'yas': 35}, {'ad': 'Can', 'yas': 42}]";}
      else if(lower.includes("def ")&&lower.includes("return")){
        try{/* Try basic Python-to-JS translation for simple functions */
          result="Fonksiyon başarıyla tanımlandı. Çıktı simülasyonu aktif.";
          if(lower.includes("factorial")||lower.includes("faktoriyel"))result="120";
          else if(lower.includes("reverse"))result="abahrem";
          else if(lower.includes("unique")||lower.includes("set"))result="[1, 2, 3, 4]";
        }catch{result="⚠️ Python simülasyonu başarısız.";}
      }else{result="Python çıktısı simüle edildi.";}
      setCodeOut(o=>({...o,[idx]:result}));return;
    }
    if(lang==="java"){setCodeOut(o=>({...o,[idx]:"☕ Java simülasyonu: Derleme başarılı. Çıktı bekleniyor..."}));return;}
    try{let out="";const log=(...a)=>{out+=a.map(x=>typeof x==="object"?JSON.stringify(x):String(x)).join(" ")+"\n";};const fn=new Function("console",code);fn({log,error:log,warn:log});setCodeOut(o=>({...o,[idx]:out||"(Çıktı yok)"}));}catch(e){setCodeOut(o=>({...o,[idx]:"❌ "+e.message}));}
  }

  function submitCode(idx){
    const code=codeA[idx]||"";
    if(!code.trim()){alert("Önce kod yazın.");return;}
    /* sadece kaydet, run yapma */
    setCodeOut(o=>({...o,[idx]:(o[idx]&&!o[idx].includes("⬆")?o[idx]+"\n":"")+"⬆ Cevap kaydedildi ✓"}));
  }

  async function submitAll(){
    setBusy(true);clearInterval(ref.current);
    const oP=oQ.map((q,i)=>"S"+(i+1)+": "+q+"\nCevap: "+(ans[i]||"-")).join("\n\n");
    const mP=mQ.map((q,i)=>"MC"+(i+1)+": "+q.soru+"\nDoğru: "+q.dogru+"\nAday: "+(mcA[i]||"-")).join("\n\n");
    const cP=cQ.map((q,i)=>"KOD"+(i+1)+" ["+((codeLang[i]||q.lang||"js").toUpperCase())+"]: "+q.gorev+"\nKod:\n"+(codeA[i]||"-")+"\nÇıktı: "+(codeOut[i]||"-")).join("\n\n");
    const sc=await callAI("Mülakat değerlendirmecisi.\n\nKRİTİK PUANLAMA:\n- Açık uçlu 3 soru: Her biri 0-100, toplamları 100 üzerinden ortalama = acik_uclu_ort\n- MC 3 soru: Her doğru 33.3 puan, mc_ort = (dogru_sayisi/toplam)*100\n- Kod 3 soru: Her biri 0-100, toplamları 100 üzerinden ortalama = kod_ort\n- toplam_puan = (acik_uclu_ort + mc_ort + kod_ort) / 3\n\nHer açık uçlu ve kod sorusu için 50/75/100 puan cevaplarını da ver.\n\nJSON:{\"toplam_puan\":<0-100>,\"acik_uclu_ort\":<0-100>,\"mc_ort\":<0-100>,\"kod_ort\":<0-100>,\"acik_uclu\":[{\"soru\":\"...\",\"puan\":<0-100>,\"yorum\":\"neden bu puan\",\"cevap_50\":\"50 puan cevap\",\"cevap_75\":\"75 puan cevap\",\"cevap_100\":\"100 puan cevap\"}],\"mc_dogru\":<sayi>,\"mc_toplam\":"+mQ.length+",\"kod\":[{\"gorev\":\"...\",\"puan\":<0-100>,\"yorum\":\"...\",\"cevap_50\":\"temel çözüm\",\"cevap_75\":\"iyi çözüm\",\"cevap_100\":\"optimal çözüm\"}],\"guclu_yonler\":[],\"gelistirme_alanlari\":[],\"genel_yorum\":\"...\",\"tavsiye\":\"İleri Al|Beklet|Reddet\"}","Pozisyon: "+(job?.title)+"\n\nAçık:\n"+oP+"\n\nMC:\n"+mP+"\n\nKod:\n"+cP);
    const fin=sc.error?{
      toplam_puan:50,acik_uclu_ort:50,mc_ort:50,kod_ort:50,
      genel_yorum:"AI değerlendirmesi yapılamadı, manuel inceleme gerekli.",tavsiye:"Beklet",
      acik_uclu:oQ.map((q,i)=>({soru:q,puan:50,yorum:"Değerlendirme bekleniyor",cevap_50:"Temel düzeyde cevap",cevap_75:"İyi düzeyde cevap",cevap_100:"Mükemmel, kapsamlı cevap"})),
      mc_dogru:Object.values(mcA).filter((v,i)=>v===mQ[i]?.dogru).length,mc_toplam:mQ.length,
      kod:cQ.map((q,i)=>({gorev:q.gorev,puan:50,yorum:"Değerlendirme bekleniyor",cevap_50:"Temel çözüm",cevap_75:"İyi çözüm",cevap_100:"Optimal çözüm"})),
      guclu_yonler:[],gelistirme_alanlari:[]
    }:sc;
    const am=(await sg(K.apps))||{};if(am[app.id]){am[app.id].interviewAnswers=ans;am[app.id].mcAnswers=mcA;am[app.id].codeAnswers=codeA;am[app.id].codeOutputs=codeOut;am[app.id].codeLangs=codeLang;am[app.id].interviewScore=fin;am[app.id].interviewTime=45*60-timer;await ss(K.apps,am);}
    setBusy(false);setDone(true);
  }

  if(!total)return(<div style={{position:"fixed",inset:0,background:"var(--sand)",zIndex:2000,display:"flex",alignItems:"center",justifyContent:"center",flexDirection:"column"}}><Spin s={30}/><p style={{color:"var(--muted)",marginTop:16}}>Sorular yükleniyor...</p><button className="btn bg" style={{marginTop:12}} onClick={onClose}>Geri</button></div>);
  if(done)return(<div style={{position:"fixed",inset:0,background:"var(--sand)",zIndex:2000,display:"flex",alignItems:"center",justifyContent:"center"}}><div style={{textAlign:"center",maxWidth:420}} className="ai"><div style={{fontSize:56,marginBottom:12}}>🎉</div><h1 style={{fontFamily:"var(--fr)",fontSize:28,fontWeight:600,marginBottom:8}}>Mülakat Tamamlandı!</h1><p style={{color:"var(--muted)",fontSize:14,marginBottom:20}}>Cevaplarınız değerlendirilecek.</p><button className="btn bp" style={{padding:"12px 32px",fontSize:15}} onClick={()=>{onDone();onClose();}}>Başvurularıma Dön →</button></div></div>);

  return(
    <div style={{position:"fixed",inset:0,background:"#fff",zIndex:2000,display:"flex",flexDirection:"column"}}>
      <div style={{background:"var(--ink)",color:"#fff",padding:"10px 24px",display:"flex",alignItems:"center",justifyContent:"space-between",flexShrink:0}}>
        <div style={{display:"flex",alignItems:"center",gap:14}}><span style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:15}}>⚡ Mülakat</span><span style={{opacity:.4}}>|</span><span style={{fontSize:13,opacity:.8}}>{job?.title}</span></div>
        <div style={{display:"flex",alignItems:"center",gap:16}}>
          <div style={{fontFamily:"var(--mono)",fontSize:16,fontWeight:700,color:tc}}>⏱ {String(mm).padStart(2,"0")}:{String(ss2).padStart(2,"0")}</div>
          <span style={{fontSize:12,opacity:.7}}>{cnt}/{total}</span>
          <button onClick={()=>{if(confirm("Mülakatı bırakmak istiyor musunuz?"))onClose();}} style={{background:"rgba(255,255,255,.15)",color:"#fff",padding:"5px 12px",borderRadius:6,fontSize:12}}>✕ Çık</button>
        </div>
      </div>
      <div style={{padding:"8px 24px",background:"var(--sand2)",borderBottom:"1px solid var(--line)",display:"flex",gap:4,alignItems:"center",flexShrink:0}}>
        {all.map((_,i)=>{const isO=i<oQ.length;const isM=i>=oQ.length&&i<oQ.length+mQ.length;const ok=isO?!!ans[i]:isM?mcA[i-oQ.length]!=null:!!(codeA[i-oQ.length-mQ.length]||"").trim();return <div key={i} onClick={()=>setQi(i)} style={{width:qi===i?28:14,height:7,borderRadius:4,background:ok?"var(--green)":qi===i?"var(--blue)":"var(--sand4)",cursor:"pointer",transition:"all .2s"}}/>})}
        <div style={{marginLeft:"auto",display:"flex",gap:10,fontSize:10}}><span style={{color:"var(--purple)"}}>📝 Açık: {oQ.length}</span><span style={{color:"var(--teal)"}}>☑ MC: {mQ.length}</span><span style={{color:"var(--amber)"}}>💻 Kod: {cQ.length}</span></div>
      </div>
      <div style={{flex:1,padding:28,overflowY:"auto"}}><div style={{maxWidth:760,margin:"0 auto"}}>
        <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:18}}>
          <div style={{width:30,height:30,borderRadius:8,background:cur?.type==="open"?"var(--purple2)":cur?.type==="mc"?"var(--teal2)":"var(--amber2)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:15}}>{cur?.type==="open"?"📝":cur?.type==="mc"?"☑":"💻"}</div>
          <div style={{fontSize:12,fontWeight:600,color:cur?.type==="open"?"var(--purple)":cur?.type==="mc"?"var(--teal)":"var(--amber)",textTransform:"uppercase"}}>{cur?.type==="open"?"Açık Uçlu":cur?.type==="mc"?"Çoktan Seçmeli":"Kod Sorusu"} {qi+1}/{total}</div>
        </div>
        {cur?.type==="open"&&<div><div style={{fontSize:17,fontWeight:600,lineHeight:1.5,marginBottom:18}}>{cur.q}</div><textarea rows={8} placeholder="Cevabınızı yazın..." value={ans[cur.i]||""} onChange={e=>setAns(a=>({...a,[cur.i]:e.target.value}))} style={{fontSize:14,lineHeight:1.7,padding:16,minHeight:200}}/></div>}
        {cur?.type==="mc"&&<div><div style={{fontSize:17,fontWeight:600,lineHeight:1.5,marginBottom:8}}>{cur.q.soru}</div>{cur.q.kod&&<pre style={{background:"var(--ink)",color:"#e2e8f0",padding:"14px 18px",borderRadius:"var(--r)",fontSize:13,fontFamily:"var(--mono)",marginBottom:16,lineHeight:1.6,overflow:"auto"}}>{cur.q.kod}</pre>}<div style={{display:"flex",flexDirection:"column",gap:8}}>{(cur.q.secenekler||[]).map((s,si)=>(<label key={si} onClick={()=>setMcA(a=>({...a,[cur.i]:s}))} style={{display:"flex",alignItems:"center",gap:12,padding:"14px 16px",borderRadius:"var(--r)",border:`2px solid ${mcA[cur.i]===s?"var(--blue)":"var(--line)"}`,background:mcA[cur.i]===s?"var(--blue3)":"#fff",cursor:"pointer",fontSize:14}}><div style={{width:20,height:20,borderRadius:"50%",border:`2px solid ${mcA[cur.i]===s?"var(--blue)":"var(--sand4)"}`,background:mcA[cur.i]===s?"var(--blue)":"transparent",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>{mcA[cur.i]===s&&<div style={{width:8,height:8,borderRadius:"50%",background:"#fff"}}/>}</div><code style={{fontFamily:"var(--mono)",fontSize:13}}>{s}</code></label>))}</div></div>}
        {cur?.type==="code"&&<div>
          <div style={{fontSize:16,fontWeight:600,lineHeight:1.6,marginBottom:10,whiteSpace:"pre-line"}}>{cur.q.gorev}</div>
          {cur.q.ipucu&&<div style={{fontSize:13,color:"#92400e",marginBottom:14,background:"var(--amber2)",padding:"8px 12px",borderRadius:"var(--r)"}}>💡 {cur.q.ipucu}</div>}
          <div style={{border:"1.5px solid var(--line)",borderRadius:"var(--r)",overflow:"hidden"}}>
            <div style={{background:"var(--ink)",padding:"8px 14px",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
              <div style={{display:"flex",alignItems:"center",gap:10}}>
                <select value={codeLang[cur.i]||cur.q.lang||"javascript"} onChange={e=>setCodeLang(l=>({...l,[cur.i]:e.target.value}))} style={{background:"#2a2d3a",color:"#e4e5eb",border:"1px solid #4a4d5a",borderRadius:4,padding:"4px 10px",fontSize:12,fontFamily:"var(--mono)",width:"auto",appearance:"auto"}}>
                  <option value="javascript">JavaScript</option><option value="python">Python</option><option value="sql">SQL</option><option value="java">Java</option>
                </select>
                <span style={{fontFamily:"var(--mono)",fontSize:10,color:"rgba(255,255,255,.35)"}}>main.{{"sql":"sql","python":"py","java":"java","javascript":"js"}[codeLang[cur.i]||cur.q.lang||"javascript"]}</span>
              </div>
              <div style={{display:"flex",gap:6}}>
                <button onClick={()=>runCode(cur.i)} style={{background:"var(--green)",color:"#fff",padding:"5px 14px",borderRadius:4,fontSize:11,fontWeight:700,fontFamily:"var(--mono)"}}>▶ Run</button>
                <button onClick={()=>submitCode(cur.i)} style={{background:"var(--blue)",color:"#fff",padding:"5px 14px",borderRadius:4,fontSize:11,fontWeight:700,fontFamily:"var(--mono)"}}>⬆ Submit</button>
              </div>
            </div>
            <textarea value={codeA[cur.i]!=null?codeA[cur.i]:(cur.q.baslangic||"")} onChange={e=>setCodeA(a=>({...a,[cur.i]:e.target.value}))} style={{width:"100%",minHeight:220,background:"#1e1e2e",color:"#cdd6f4",fontFamily:"var(--mono)",fontSize:13,lineHeight:1.6,padding:16,border:"none",borderRadius:0,resize:"vertical"}} spellCheck={false}/>
            <div style={{background:"#11111b",padding:12,borderTop:"1px solid #2e3140",minHeight:50}}>
              <div style={{fontFamily:"var(--mono)",fontSize:10,color:"rgba(255,255,255,.4)",marginBottom:4}}>ÇIKTI {cur.q.beklenen&&<span>· Beklenen: {cur.q.beklenen}</span>}</div>
              <pre style={{fontFamily:"var(--mono)",fontSize:12,color:codeOut[cur.i]?.includes("❌")?"#ef4444":"#a6e3a1",whiteSpace:"pre-wrap",margin:0,background:"transparent",border:"none",padding:0}}>{codeOut[cur.i]||"Henüz çalıştırılmadı"}</pre>
            </div>
          </div>
        </div>}
      </div></div>
      <div style={{padding:"12px 24px",background:"#fff",borderTop:"1px solid var(--line)",display:"flex",justifyContent:"space-between",alignItems:"center",flexShrink:0}}>
        <button className="btn bg" onClick={()=>setQi(Math.max(0,qi-1))} disabled={qi===0}>← Önceki</button>
        <span style={{fontSize:12,color:"var(--muted)"}}>{qi+1}/{total}</span>
        {qi<total-1?<button className="btn bp" onClick={()=>setQi(qi+1)}>Sonraki →</button>:<button className="btn" style={{background:"var(--green)",color:"#fff",fontWeight:700}} onClick={submitAll} disabled={busy}>{busy?<Spin s={14} c="#fff"/>:"✅ Mülakatı Tamamla"}</button>}
      </div>
    </div>
  );
}

/* ═══ APPLY FLOW ═══ */
function ApplyFlow({job,user,onClose,onDone}){
  const [step,setStep]=useState("form");const [cur,setCur]=useState(-1);const [res,setRes]=useState(null);
  const [cover,setCover]=useState("");const [yexp,setYexp]=useState("");
  const PIPE=["cv","match","questions","notify"];
  async function run(){
    setStep("run");const users=(await sg(K.users))||{};const fu=users[user.id]||user;
    const sr=(fu.skillRatings||[]).map(s=>s.name+":"+s.level).join(",");
    const prof="Ad: "+fu.name+"\nBeceri: "+(fu.skills||"-")+"\nYetkinlik: "+(sr||"-")+"\nDeneyim: "+yexp+" yıl\nÖzet: "+(fu.summary||"-")+"\nGeçmiş: "+(fu.experience||"-")+"\nEğitim: "+(fu.education||"-")+"\nÖn Yazı: "+cover;
    const jobT="Pozisyon: "+job.title+", Dept: "+job.dept+"\nGereksinimler: "+job.requirements.join(", ");
    const col={};
    setCur(0);col.cv=await callAI("İK uzmanı. JSON:{\"puan\":<0-100>,\"uygunluk\":\"Güçlü Aday|Uygun|Kısmen Uygun|Uygun Değil\",\"guclu\":[\"...\"],\"gelistirme\":[\"...\"],\"ozet\":\"max 150 karakter\"}","Aday:\n"+prof+"\n\nPozisyon:\n"+jobT);
    if(col.cv.error)col.cv={puan:50,uygunluk:"Değerlendiriliyor",guclu:["Profil mevcut"],gelistirme:[],ozet:"Değerlendirme bekleniyor."};
    await new Promise(r=>setTimeout(r,400));
    setCur(1);col.match=await callAI("Eşleştirme uzmanı. JSON:{\"eslesme_yuzdesi\":<0-100>,\"kritik_eksikler\":[],\"fazladan_beceriler\":[],\"tavsiye\":\"...\",\"not\":\"...\"}","Aday:\n"+prof+"\n\nPozisyon:\n"+jobT);
    if(col.match.error)col.match={eslesme_yuzdesi:50,tavsiye:"Değerlendirme Gerekli"};
    await new Promise(r=>setTimeout(r,400));
    setCur(2);const qR=await callAI("Mülakat uzmanı. 3 açık uçlu + 3 MC + 3 kod sorusu.\nKod soruları gerçek case-based olsun:\n- 1 SQL sorusu (tablo yapısı ver, kolonları göster)\n- 1 Python sorusu (veri işleme, filtreleme gibi)\n- 1 JavaScript sorusu (array/object manipülasyonu)\nHer kod sorusu için lang alanı ekle (sql/python/javascript)\n\nJSON:{\"acik_uclu\":[\"s1\",\"s2\",\"s3\"],\"coktan_secmeli\":[{\"soru\":\"...\",\"kod\":null,\"secenekler\":[\"A\",\"B\",\"C\",\"D\"],\"dogru\":\"A\"}],\"kod_sorulari\":[{\"gorev\":\"Tam soru metni, tablo yapısı vs dahil\",\"lang\":\"sql|python|javascript\",\"baslangic\":\"// başlangıç kodu\",\"beklenen\":\"beklenen çıktı\",\"ipucu\":\"kısa ipucu\"}]}","Aday:\n"+prof+"\n\nPozisyon:\n"+jobT);
    if(!qR.error&&qR.acik_uclu?.length)col.questions=qR;
    else col.questions={acik_uclu:[job.title+" pozisyonunda en büyük zorluk?","Takım fikir ayrılığını nasıl çözersiniz?","Son projenizde en gurur duyduğunuz karar?"],coktan_secmeli:[{soru:"Sprint retrospective amacı?",kod:null,secenekler:["Plan","Ölçüm","İyileştirme","Atama"],dogru:"İyileştirme"},{soru:"Code review kriteri?",kod:null,secenekler:["Stil","İşlevsellik","Hız","Yorum"],dogru:"İşlevsellik"},{soru:"Microservice avantajı?",kod:null,secenekler:["Az kod","Bağımsız deploy","Tek DB","Az test"],dogru:"Bağımsız deploy"}],kod_sorulari:[
      {gorev:"SQL: Aşağıdaki 'musteriler' tablosunda en yüksek gelire sahip ilk 5 müşteriyi getirin.\n\nTablo: musteriler\n| id | ad | soyad | sehir | yillik_gelir |\n|----|------|-------|-------|--------------|\n| 1  | Ali  | Yılmaz| İst   | 120000       |\n| 2  | Ayşe | Demir | Ank   | 95000        |\n| ...| ...  | ...   | ...   | ...          |",lang:"sql",baslangic:"-- En yüksek gelire sahip ilk 5 müşteriyi getirin\nSELECT ",beklenen:"SELECT ad, soyad, yillik_gelir FROM musteriler ORDER BY yillik_gelir DESC LIMIT 5;",ipucu:"ORDER BY ... DESC ve LIMIT kullanın"},
      {gorev:"Python: Verilen bir liste içindeki sayıları tersten sıralayıp, çift olanları filtreleyen bir fonksiyon yazın.\n\nÖrnek:\nGirdi: [3, 1, 4, 1, 5, 9, 2, 6]\nÇıktı: [6, 4, 2]",lang:"python",baslangic:"def filtre_ve_sirala(liste):\n    # Kodunuzu yazın\n    pass\n\nprint(filtre_ve_sirala([3, 1, 4, 1, 5, 9, 2, 6]))",beklenen:"[6, 4, 2]",ipucu:"sorted() ile ters sıralama, list comprehension ile filtre"},
      {gorev:"JavaScript: Aşağıdaki 'siparisler' dizisinden, her müşterinin toplam harcamasını hesaplayıp, en çok harcayan müşteriyi bulan fonksiyon yazın.\n\nVeri:\nconst siparisler = [\n  {musteri: 'Ali', tutar: 250},\n  {musteri: 'Ayşe', tutar: 180},\n  {musteri: 'Ali', tutar: 320},\n  {musteri: 'Ayşe', tutar: 420},\n  {musteri: 'Can', tutar: 150}\n];",lang:"javascript",baslangic:"const siparisler = [\n  {musteri: 'Ali', tutar: 250},\n  {musteri: 'Ayşe', tutar: 180},\n  {musteri: 'Ali', tutar: 320},\n  {musteri: 'Ayşe', tutar: 420},\n  {musteri: 'Can', tutar: 150}\n];\n\nfunction enCokHarcayan(data) {\n  // Kodunuzu yazın\n}\n\nconsole.log(enCokHarcayan(siparisler));",beklenen:"Ayşe (600)",ipucu:"reduce ile gruplama, Object.entries ile max bulma"}
    ]};
    if(!col.questions.kod_sorulari?.length)col.questions.kod_sorulari=[
      {gorev:"SQL: 'urunler' tablosundan kategoriye göre ortalama fiyatı 100 TL'den yüksek olan kategorileri listeleyin.\n\nTablo: urunler\n| id | urun_adi | kategori | fiyat |\n|----|----------|----------|-------|\n| 1  | Laptop   | Elektronik | 15000 |\n| 2  | Mouse    | Elektronik | 250 |",lang:"sql",baslangic:"-- Ortalama fiyatı 100 TL üstü kategoriler\n",beklenen:"SELECT kategori, AVG(fiyat) FROM urunler GROUP BY kategori HAVING AVG(fiyat) > 100;",ipucu:"GROUP BY + HAVING"},
      {gorev:"Python: Verilen sözlük listesinden yaşı 30'dan büyük kişileri isme göre alfabetik sıralayın.\n\nVeri: [{'ad':'Zeynep','yas':28}, {'ad':'Ali','yas':35}, {'ad':'Can','yas':42}, {'ad':'Banu','yas':25}]",lang:"python",baslangic:"kisiler = [{'ad':'Zeynep','yas':28}, {'ad':'Ali','yas':35}, {'ad':'Can','yas':42}, {'ad':'Banu','yas':25}]\n\ndef filtrele(data):\n    pass\n\nprint(filtrele(kisiler))",beklenen:"[{'ad':'Ali','yas':35}, {'ad':'Can','yas':42}]",ipucu:"filter + sorted(key=lambda)"},
      {gorev:"JavaScript: Aşağıdaki iç içe diziden tüm sayıları düz bir diziye çevirip toplamını hesaplayın.\n\nVeri: [[1, 2], [3, [4, 5]], [6, [7, [8]]]]",lang:"javascript",baslangic:"const nested = [[1, 2], [3, [4, 5]], [6, [7, [8]]]];\n\nfunction flatSum(arr) {\n  // Kodunuzu yazın\n}\n\nconsole.log(flatSum(nested));",beklenen:"36",ipucu:"flat(Infinity) veya recursive flatten"}
    ];
    await new Promise(r=>setTimeout(r,400));
    setCur(3);col.notify=await callAI("Mülakat bildirimi. JSON:{\"konu\":\"...\",\"icerik\":\"...\"}","Aday: "+fu.name+", Pozisyon: "+job.title);
    if(col.notify.error)col.notify={konu:"Mülakat Hazır",icerik:"Sorularınız hazır."};
    setCur(4);await new Promise(r=>setTimeout(r,300));
    const am=(await sg(K.apps))||{};const aid="app_"+Date.now();
    am[aid]={id:aid,jobId:job.id,candidateId:user.id,candidateName:fu.name,appliedAt:new Date().toISOString(),stage:"interview",coverLetter:cover,yearsExp:yexp,agentResult:col,interviewQuestions:col.questions?.acik_uclu||[],mcQuestions:col.questions?.coktan_secmeli||[],codeQuestions:col.questions?.kod_sorulari||[]};
    await ss(K.apps,am);const jm=(await sg(K.jobs))||{};if(jm[job.id]){jm[job.id].applicants=(jm[job.id].applicants||0)+1;await ss(K.jobs,jm);}
    setRes(col);setStep("done");
  }
  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,.5)",display:"flex",alignItems:"center",justifyContent:"center",zIndex:1000,padding:24}}>
      <div className="card ai" style={{width:"100%",maxWidth:540,maxHeight:"90vh",overflowY:"auto",padding:28}}>
        {step==="form"&&<><div style={{display:"flex",justifyContent:"space-between",marginBottom:18}}><div><h2 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:3}}>Başvur</h2><div style={{fontSize:13,color:"var(--muted)"}}>{job.title} · {job.dept}</div></div><button onClick={onClose} style={{background:"none",color:"var(--muted)",fontSize:18}}>✕</button></div><div style={{display:"flex",flexDirection:"column",gap:12}}><div><label>Deneyim (yıl)</label><input type="number" value={yexp} onChange={e=>setYexp(e.target.value)}/></div><div><label>Ön Yazı</label><textarea rows={4} value={cover} onChange={e=>setCover(e.target.value)}/></div><div style={{background:"var(--blue3)",borderRadius:"var(--r)",padding:"10px 14px",fontSize:13,border:"1px solid #bfdbfe"}}>💡 3 açık uçlu + 3 MC + 3 kod sorusu hazırlanacak.</div></div><div style={{display:"flex",gap:10,marginTop:16}}><button className="btn bg" style={{flex:1,justifyContent:"center"}} onClick={onClose}>İptal</button><button className="btn bp" style={{flex:2,justifyContent:"center"}} onClick={run}>⚡ Başvur</button></div></>}
        {step==="run"&&<div><h2 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:4}}>AI Çalışıyor...</h2><p style={{color:"var(--muted)",fontSize:13,marginBottom:14}}>CV analizi ve soru hazırlığı</p><AgentPipe steps={PIPE} cur={cur}/></div>}
        {step==="done"&&res&&<div style={{textAlign:"center"}} className="ai"><div style={{fontSize:44,marginBottom:8}}>✅</div><h2 style={{fontFamily:"var(--fr)",fontWeight:600}}>Başvuru Alındı!</h2><p style={{color:"var(--muted)",fontSize:13,marginTop:4,marginBottom:16}}>Mülakat soruları hazır.</p><button className="btn bp" style={{width:"100%",justifyContent:"center"}} onClick={onDone}>Mülakata Geç →</button></div>}
      </div>
    </div>
  );
}

function CandPortal({user,onLogout}){
  const [tab,setTab]=useState("jobs");const [jobs,setJobs]=useState([]);const [myApps,setMyApps]=useState([]);
  const [applyJob,setApplyJob]=useState(null);const [loading,setLoading]=useState(true);const [profile,setProfile]=useState(user);
  const [interviewApp,setInterviewApp]=useState(null);
  const load=useCallback(async()=>{setLoading(true);let jm=await sg(K.jobs);if(!jm||!Object.keys(jm).length){jm={};SEED_JOBS.forEach(j=>jm[j.id]=j);await ss(K.jobs,jm);}setJobs(Object.values(jm).filter(j=>j.status==="active"));const am=(await sg(K.apps))||{};setMyApps(Object.values(am).filter(a=>a.candidateId===user.id).sort((a,b)=>new Date(b.appliedAt)-new Date(a.appliedAt)));const us=(await sg(K.users))||{};if(us[user.id])setProfile(us[user.id]);setLoading(false);},[user.id]);
  useEffect(()=>{load();},[load]);
  const applied=myApps.map(a=>a.jobId);const pOk=profileOk(profile);
  /* Bildirim: aksiyon gerektiren başvuru var mı? */
  const hasAction=myApps.some(a=>(a.stage==="interview"&&!a.interviewAnswers)||(a.stage==="offer"&&a.offerHistory?.at(-1)?.from==="admin"&&!a.offerHistory.at(-1).candidateResponse)||(a.stage==="hired"&&!a.candidateHireAccepted)||(a.stage==="hired"&&a.adminHireApproved&&!a.candidateSawDocs));
  function tryApply(j){if(!pOk){alert("Önce profilinizi tamamlayın.");setTab("profile");return;}setApplyJob(j);}
  return(
    <div style={{minHeight:"100vh",background:"var(--sand)"}}><style>{STYLE}</style>
      <nav style={{background:"#fff",borderBottom:"1px solid var(--line)",padding:"0 24px",display:"flex",alignItems:"center",justifyContent:"space-between",height:56,position:"sticky",top:0,zIndex:100}}>
        <div style={{display:"flex",alignItems:"center",gap:28}}><div style={{display:"flex",alignItems:"center",gap:8}}><div style={{width:28,height:28,borderRadius:8,background:"var(--ink)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:14}}>⚡</div><span style={{fontFamily:"var(--fr)",fontWeight:700,fontSize:16}}>TalentFlow</span></div>
          {[["jobs","İlanlar"],["apps","Başvurularım"],["profile","Profilim"]].map(([t,l])=>(<button key={t} onClick={()=>{setTab(t);load()}} style={{background:"none",color:tab===t?"var(--blue)":"var(--ink3)",fontWeight:tab===t?600:400,fontSize:14,borderBottom:`2px solid ${tab===t?"var(--blue)":"transparent"}`,padding:"4px 0",position:"relative"}}>{l}{t==="apps"&&hasAction&&tab!=="apps"&&<span style={{position:"absolute",top:-2,right:-8,width:8,height:8,borderRadius:"50%",background:"var(--amber)",border:"2px solid #fff"}}/>}</button>))}
        </div>
        <div style={{display:"flex",alignItems:"center",gap:10}}><span style={{fontSize:13,color:"var(--ink3)"}}>👋 {profile.name}</span><button className="btn bg" style={{fontSize:12,padding:"5px 12px"}} onClick={onLogout}>Çıkış</button></div>
      </nav>
      <div style={{maxWidth:1100,margin:"0 auto",padding:"28px 20px"}}>
        {loading?<div style={{textAlign:"center",padding:80}}><Spin s={30}/></div>:<>
          {tab==="jobs"&&<div className="ai"><h1 style={{fontFamily:"var(--fr)",fontSize:28,fontWeight:600,marginBottom:18}}>Açık Pozisyonlar</h1>{!pOk&&<div style={{background:"var(--amber2)",border:"1px solid #fde68a",borderRadius:"var(--r)",padding:"10px 14px",fontSize:13,color:"#92400e",marginBottom:14}}>⚠️ Profil eksik. Önce tamamlayın.</div>}{jobs.map(j=>{const ap=applied.includes(j.id);const d=days(j.createdAt);return(<div key={j.id} className="card" style={{marginBottom:10,display:"flex",justifyContent:"space-between",alignItems:"flex-start",gap:16}}><div style={{flex:1}}><div style={{display:"flex",alignItems:"center",gap:8,marginBottom:6,flexWrap:"wrap"}}><h3 style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:17}}>{j.title}</h3><span className="badge bgy">{j.level}</span>{ap&&<span className="badge bgr">✓ Başvuruldu</span>}</div><div style={{display:"flex",gap:14,marginBottom:8,flexWrap:"wrap"}}>{[["🏢",j.dept],["📍",j.location],["💰",salK(j.salaryMin)+"–"+salK(j.salaryMax)+" ₺"]].map(([i,v])=><span key={v} style={{fontSize:13,color:"var(--ink3)"}}>{i} {v}</span>)}</div><p style={{fontSize:13,color:"var(--muted)",marginBottom:6}}>{j.desc}</p></div><div>{ap?<button className="btn bg" disabled style={{opacity:.5,fontSize:12}}>Başvuruldu ✓</button>:<button className="btn bp" onClick={()=>tryApply(j)}>Başvur</button>}</div></div>)})}</div>}
          {tab==="apps"&&<div className="ai"><h1 style={{fontFamily:"var(--fr)",fontSize:26,fontWeight:600,marginBottom:18}}>Başvurularım</h1>{myApps.length===0?<div style={{textAlign:"center",padding:60}}><div style={{fontSize:48,marginBottom:12}}>📋</div><p style={{color:"var(--muted)"}}>Henüz başvuru yok.</p></div>:<div style={{display:"flex",flexDirection:"column",gap:10}}>{myApps.map(a=><CandAppCard key={a.id} app={a} job={jobs.find(x=>x.id===a.jobId)} onInterview={()=>setInterviewApp(a)} onRefresh={load}/>)}</div>}</div>}
          {tab==="profile"&&<CandProfile user={profile} onUpdate={async u=>{const us=(await sg(K.users))||{};us[user.id]={...us[user.id],...u};await ss(K.users,us);await ss(K.session,{...user,...u});setProfile(p=>({...p,...u}));}}/>}
        </>}
      </div>
      {applyJob&&<ApplyFlow job={applyJob} user={profile} onClose={()=>setApplyJob(null)} onDone={()=>{setApplyJob(null);setTab("apps");load();}}/>}
      {interviewApp&&<FullInterview app={interviewApp} job={jobs.find(j=>j.id===interviewApp.jobId)} user={profile} onClose={()=>{setInterviewApp(null);load();}} onDone={load}/>}
    </div>
  );
}

/* ═══ ADMIN PANEL ═══ */
function AdminPanel({user,onLogout}){
  const [tab,setTab]=useState("dash");const [jobs,setJobs]=useState({});const [apps,setApps]=useState({});const [users,setUsers]=useState({});const [loading,setLoading]=useState(true);
  const load=useCallback(async()=>{setLoading(true);let jm=await sg(K.jobs);if(!jm||!Object.keys(jm).length){jm={};SEED_JOBS.forEach(j=>jm[j.id]=j);await ss(K.jobs,jm);}setJobs(jm||{});setApps((await sg(K.apps))||{});setUsers((await sg(K.users))||{});setLoading(false);},[]);
  useEffect(()=>{load();},[load]);
  const allA=Object.values(apps);const st={jobs:Object.values(jobs).filter(j=>j.status==="active").length,apps:allA.length,interview:allA.filter(a=>a.stage==="interview").length,offer:allA.filter(a=>["offer","negotiation"].includes(a.stage)).length,hired:allA.filter(a=>a.stage==="hired"&&a.adminHireApproved).length};
  return(
    <div style={{minHeight:"100vh",background:"var(--sand)",display:"flex"}}><style>{STYLE}</style>
      <aside style={{width:210,background:"#fff",borderRight:"1px solid var(--line)",padding:"0 12px",flexShrink:0,position:"sticky",top:0,height:"100vh",display:"flex",flexDirection:"column"}}>
        <div style={{padding:"16px 0 12px",borderBottom:"1px solid var(--line)",marginBottom:12}}><div style={{display:"flex",alignItems:"center",gap:8}}><div style={{width:28,height:28,borderRadius:8,background:"var(--ink)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:14}}>⚡</div><div><div style={{fontFamily:"var(--fr)",fontWeight:700,fontSize:15}}>TalentFlow</div><div style={{fontSize:9,color:"var(--muted)",fontFamily:"var(--mono)"}}>İK PANELİ</div></div></div></div>
        {[["dash","📊","Genel Bakış"],["jobs","💼","İlanlar"],["apps","📋","Başvurular"],["cands","👥","Adaylar"]].map(([t,ic,l])=>(<button key={t} onClick={()=>{setTab(t);load()}} style={{display:"flex",alignItems:"center",gap:8,padding:"8px 10px",borderRadius:"var(--r)",background:tab===t?"var(--sand2)":"transparent",color:tab===t?"var(--ink)":"var(--muted)",fontWeight:tab===t?600:400,fontSize:13,marginBottom:2,textAlign:"left",border:tab===t?"1px solid var(--line)":"1px solid transparent"}}><span>{ic}</span>{l}</button>))}
        <div style={{marginTop:"auto",paddingTop:12,borderTop:"1px solid var(--line)",marginBottom:14}}><div style={{fontSize:12,fontWeight:600,marginBottom:8}}>{user.name}</div><button className="btn bg" style={{width:"100%",justifyContent:"center",fontSize:12,padding:"6px 0"}} onClick={onLogout}>Çıkış</button></div>
      </aside>
      <main style={{flex:1,padding:"24px 28px",overflowY:"auto"}}>{loading?<div style={{textAlign:"center",padding:80}}><Spin s={30}/></div>:<>
        {tab==="dash"&&<div className="ai"><h1 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600,marginBottom:18}}>Genel Bakış</h1><div className="g2" style={{gridTemplateColumns:"repeat(5,1fr)",gap:12,marginBottom:20}}>{[["💼",st.jobs,"Aktif İlan","var(--blue)"],["📋",st.apps,"Başvuru","var(--ink3)"],["💬",st.interview,"Mülakatda","var(--purple)"],["💰",st.offer,"Teklif","var(--amber)"],["🎉",st.hired,"İşe Alındı","var(--green)"]].map(([ic,v,l,c])=>(<div key={l} className="card" style={{padding:14,display:"flex",alignItems:"center",gap:10}}><div style={{width:36,height:36,borderRadius:8,background:c+"18",display:"flex",alignItems:"center",justifyContent:"center",fontSize:18}}>{ic}</div><div><div style={{fontSize:20,fontWeight:700,fontFamily:"var(--fr)"}}>{v}</div><div style={{fontSize:11,color:"var(--muted)"}}>{l}</div></div></div>))}</div></div>}

        {tab==="jobs"&&<AdminJobs jobs={jobs} onRefresh={load}/>}
        {tab==="apps"&&<AdminApps apps={apps} jobs={jobs} users={users} onRefresh={load}/>}
        {tab==="cands"&&<AdminCands users={users} apps={apps}/>}
      </>}</main>
    </div>
  );
}

function AdminJobs({jobs,onRefresh}){
  const [show,setShow]=useState(false);const [f,setF]=useState({title:"",dept:"",location:"",level:"Mid",salaryMin:"",salaryMax:"",headcount:1,desc:"",requirements:""});const [busy,setBusy]=useState(false);
  const sv=k=>e=>setF(x=>({...x,[k]:e.target.value}));
  async function create(){if(!f.title||!f.dept)return;setBusy(true);const jm=(await sg(K.jobs))||{};const j={id:"j_"+Date.now(),...f,type:"Tam Zamanlı",salaryMin:Number(f.salaryMin),salaryMax:Number(f.salaryMax),headcount:Number(f.headcount)||1,requirements:f.requirements.split(",").map(s=>s.trim()).filter(Boolean),status:"active",hiredCount:0,applicants:0,createdAt:new Date().toISOString()};jm[j.id]=j;await ss(K.jobs,jm);setBusy(false);setShow(false);onRefresh();}
  async function toggle(j){const jm=(await sg(K.jobs))||{};jm[j.id].status=j.status==="active"?"passive":"active";await ss(K.jobs,jm);onRefresh();}
  const all=Object.values(jobs).sort((a,b)=>new Date(b.createdAt)-new Date(a.createdAt));
  return(<div className="ai"><div style={{display:"flex",justifyContent:"space-between",marginBottom:18}}><h1 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600}}>İlanlar</h1><button className="btn bp" onClick={()=>setShow(!show)}>+ Yeni İlan</button></div>
    {show&&<div className="card ai" style={{marginBottom:16,border:"1.5px solid var(--blue)"}}><div className="g2" style={{gap:10,marginBottom:10}}><div><label>Pozisyon *</label><input value={f.title} onChange={sv("title")}/></div><div><label>Departman *</label><input value={f.dept} onChange={sv("dept")}/></div><div><label>Lokasyon</label><input value={f.location} onChange={sv("location")}/></div><div><label>Seviye</label><input value={f.level} onChange={sv("level")}/></div><div><label>Min Maaş</label><input type="number" value={f.salaryMin} onChange={sv("salaryMin")}/></div><div><label>Max Maaş</label><input type="number" value={f.salaryMax} onChange={sv("salaryMax")}/></div></div><div style={{marginBottom:10}}><label>Açıklama</label><textarea rows={2} value={f.desc} onChange={sv("desc")}/></div><div style={{marginBottom:10}}><label>Gereksinimler (virgülle)</label><input value={f.requirements} onChange={sv("requirements")}/></div><button className="btn bp" onClick={create} disabled={busy}>{busy?<Spin s={14} c="#fff"/>:"Oluştur"}</button></div>}
    {all.map(j=>(<div key={j.id} className="card" style={{marginBottom:8,display:"flex",justifyContent:"space-between",alignItems:"center"}}><div><div style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:15}}>{j.title} <span className={"badge "+(j.status==="active"?"bgr":"bgy")}>{j.status==="active"?"Aktif":"Pasif"}</span></div><div style={{fontSize:12,color:"var(--muted)"}}>🏢 {j.dept} · 📍 {j.location} · 👥 {j.applicants||0} başvuru · {j.hiredCount||0}/{j.headcount} kadro</div></div><button className={"btn "+(j.status==="active"?"ba":"bgr")} style={{fontSize:12,padding:"6px 12px"}} onClick={()=>toggle(j)}>{j.status==="active"?"Pasife Al":"Aktife Al"}</button></div>))}
  </div>);
}

function AdminApps({apps,jobs,users,onRefresh}){
  const [sel,setSel]=useState(null);const [filter,setFilter]=useState("all");
  const jm=Object.fromEntries(Object.values(jobs).map(j=>[j.id,j]));
  const all=Object.values(apps).sort((a,b)=>new Date(b.appliedAt)-new Date(a.appliedAt));
  const filt=all.filter(a=>filter==="all"||a.stage===filter);
  const ref=async()=>{await onRefresh();if(sel){const am=(await sg(K.apps))||{};setSel(am[sel.id]||null);}};
  return(<div className="ai" style={{display:"grid",gridTemplateColumns:sel?"1fr 1.5fr":"1fr",gap:18,alignItems:"start"}}>
    <div><div style={{display:"flex",justifyContent:"space-between",marginBottom:14}}><h1 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600}}>Başvurular</h1><span style={{fontSize:12,color:"var(--muted)"}}>{filt.length}</span></div>
      <div style={{display:"flex",gap:4,marginBottom:14,flexWrap:"wrap"}}>{[["all","Tümü"],["interview","Mülakat"],["offer","Teklif"],["hired","İşe Alındı"],["rejected","Red"]].map(([v,l])=>(<button key={v} onClick={()=>setFilter(v)} style={{padding:"5px 12px",borderRadius:20,fontSize:11,fontWeight:600,background:filter===v?"var(--ink)":"#fff",color:filter===v?"#fff":"var(--ink3)",border:`1.5px solid ${filter===v?"var(--ink)":"var(--line)"}`}}>{l}</button>))}</div>
      {filt.map(a=>(<div key={a.id} onClick={()=>setSel(sel?.id===a.id?null:a)} className="card" style={{padding:"12px 14px",marginBottom:6,cursor:"pointer",border:`1.5px solid ${sel?.id===a.id?"var(--blue)":"var(--line)"}`}}><div style={{display:"flex",justifyContent:"space-between"}}><div><div style={{fontWeight:600,fontSize:13}}>{a.candidateName}</div><div style={{fontSize:11,color:"var(--muted)"}}>{jm[a.jobId]?.title} · {fmtS(a.appliedAt)}</div></div><Pill stage={a.stage}/></div>{a.agentResult?.cv?.puan!=null&&<div style={{display:"flex",gap:8,marginTop:6}}><span style={{fontSize:11,fontWeight:700,color:a.agentResult.cv.puan>=70?"var(--green)":"var(--amber)"}}>CV: {a.agentResult.cv.puan}</span>{a.interviewScore&&<span style={{fontSize:11,fontWeight:700,color:a.interviewScore.toplam_puan>=70?"var(--green)":"var(--amber)"}}>Int: {a.interviewScore.toplam_puan}</span>}</div>}</div>))}
    </div>
    {sel&&<AdminDetail key={sel.id} app={sel} job={jm[sel.jobId]} onRefresh={ref} onClose={()=>setSel(null)}/>}
  </div>);
}

/* Admin Detail with scoring — always shows Q&A, button for ideal answers */
function ScoreCard({item,type,code,output,answer}){
  const [showIdeal,setShowIdeal]=useState(false);
  const sc=item.puan;const c=sc>=70?"var(--green)":sc>=50?"var(--amber)":"var(--red)";
  return(<div style={{marginBottom:8,border:"1px solid var(--line2)",borderRadius:"var(--r)",overflow:"hidden",background:"#fff"}}>
    <div style={{padding:"10px 12px"}}>
      <div style={{display:"flex",alignItems:"flex-start",gap:8,marginBottom:6}}>
        <div style={{width:36,height:36,borderRadius:8,background:c+"18",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:"var(--mono)",fontWeight:700,fontSize:14,color:c,flexShrink:0}}>{sc}</div>
        <div style={{flex:1,minWidth:0}}>
          <div style={{fontSize:12,fontWeight:600,color:"var(--ink)",lineHeight:1.4,marginBottom:2}}>{type==="code"?item.gorev?.split("\n")[0]:item.soru}</div>
          <div style={{fontSize:11,color:c,fontWeight:600}}>{item.yorum}</div>
        </div>
      </div>
      {/* Adayın cevabı — her zaman görünür */}
      {type==="open"&&answer&&<div style={{marginTop:6,padding:"8px 10px",background:"var(--sand2)",borderRadius:"var(--r)",border:"1px solid var(--line2)"}}><div style={{fontSize:9,fontWeight:700,color:"var(--muted)",marginBottom:3,fontFamily:"var(--mono)"}}>ADAYIN CEVABI</div><div style={{fontSize:12,color:"var(--ink3)",lineHeight:1.6}}>{answer}</div></div>}
      {type==="code"&&<div style={{marginTop:6}}>
        {code&&<div style={{marginBottom:4}}><div style={{fontSize:9,fontWeight:700,color:"var(--muted)",marginBottom:3,fontFamily:"var(--mono)"}}>ADAYIN KODU</div><pre style={{fontSize:11,background:"#1e1e2e",color:"#cdd6f4",padding:10,borderRadius:"var(--r)",overflow:"auto",lineHeight:1.5,margin:0}}>{code}</pre></div>}
        {output&&<div style={{fontSize:11,color:"var(--muted)",padding:"4px 0"}}>Çıktı: <code style={{background:"var(--sand2)",padding:"1px 4px",borderRadius:3}}>{output}</code></div>}
      </div>}
      {/* Tam Cevabı Göster butonu */}
      <button onClick={()=>setShowIdeal(!showIdeal)} style={{marginTop:6,background:showIdeal?"var(--blue3)":"var(--sand2)",color:showIdeal?"var(--blue)":"var(--ink3)",border:`1px solid ${showIdeal?"var(--blue)":"var(--line)"}`,borderRadius:"var(--r)",padding:"5px 10px",fontSize:11,fontWeight:600,display:"flex",alignItems:"center",gap:4}}>
        {showIdeal?"▲ Gizle":"📋 Tam Puan Cevabını Göster"}
      </button>
      {showIdeal&&<div style={{marginTop:8,border:"1px solid var(--line2)",borderRadius:"var(--r)",overflow:"hidden"}}>
        {[["50","var(--red)","Temel",item.cevap_50],["75","var(--amber)","İyi",item.cevap_75],["100","var(--green)","Mükemmel",item.cevap_100]].map(([p,c2,label,txt])=>txt&&<div key={p} style={{padding:"8px 10px",borderBottom:"1px solid var(--line2)",background:p==="100"?"var(--green2)08":"transparent"}}>
          <div style={{display:"flex",alignItems:"center",gap:6,marginBottom:3}}><div style={{width:26,height:18,borderRadius:4,background:c2+"20",display:"flex",alignItems:"center",justifyContent:"center",fontSize:10,fontWeight:700,color:c2,fontFamily:"var(--mono)"}}>{p}</div><span style={{fontSize:10,fontWeight:600,color:c2}}>{label} Cevap</span></div>
          <div style={{fontSize:12,color:"var(--ink3)",lineHeight:1.5,paddingLeft:32}}>{txt}</div>
        </div>)}
      </div>}
    </div>
  </div>);
}

function AdminDetail({app,job,onRefresh,onClose}){
  const [busy,setBusy]=useState(false);const [amt,setAmt]=useState("");const [note,setNote]=useState("");
  const canOffer=app.stage==="interview"&&app.interviewAnswers&&!app.offerHistory?.length;
  const canHire=app.stage==="hired"&&app.candidateHireAccepted&&!app.adminHireApproved;
  const counterPending=app.stage==="negotiation"&&app.offerHistory?.at(-1)?.from==="candidate";
  async function sendOffer(){if(!amt)return;setBusy(true);const am=(await sg(K.apps))||{};am[app.id].stage="offer";am[app.id].offerHistory=[...(am[app.id].offerHistory||[]),{from:"admin",amount:Number(amt),note,createdAt:new Date().toISOString()}];await ss(K.apps,am);setBusy(false);setAmt("");onRefresh();}
  async function respondCounter(type){
    setBusy(true);const am=(await sg(K.apps))||{};
    if(type==="accept"){am[app.id].stage="hired";/* accept candidate's counter */}
    else if(type==="reject"){am[app.id].stage="rejected";}
    else{/* new counter from admin */if(!amt){setBusy(false);return;}am[app.id].offerHistory=[...(am[app.id].offerHistory||[]),{from:"admin",amount:Number(amt),note,createdAt:new Date().toISOString()}];am[app.id].stage="offer";}
    await ss(K.apps,am);setBusy(false);setAmt("");onRefresh();
  }
  async function approveHire(){setBusy(true);const am=(await sg(K.apps))||{};am[app.id].adminHireApproved=true;am[app.id].adminHireDate=new Date().toISOString();am[app.id].stage="hired";await ss(K.apps,am);const jm=(await sg(K.jobs))||{};if(jm[app.jobId]){jm[app.jobId].hiredCount=(jm[app.jobId].hiredCount||0)+1;if(jm[app.jobId].hiredCount>=jm[app.jobId].headcount)jm[app.jobId].status="passive";await ss(K.jobs,jm);}setBusy(false);onRefresh();}
  const cv=app.agentResult?.cv?.puan;const mt=app.agentResult?.match?.eslesme_yuzdesi;const iS=app.interviewScore?.toplam_puan;
  return(<div className="card" style={{maxHeight:"calc(100vh - 80px)",overflowY:"auto",position:"sticky",top:16}}>
    <div style={{display:"flex",justifyContent:"space-between",marginBottom:14}}><div><h2 style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:17}}>{app.candidateName}</h2><div style={{fontSize:12,color:"var(--muted)"}}>{job?.title} · {fmtD(app.appliedAt)}</div></div><div style={{display:"flex",gap:6}}><Pill stage={app.stage}/><button onClick={onClose} style={{background:"none",color:"var(--muted)",fontSize:16}}>✕</button></div></div>
    <StageBar current={app.stage==="rejected"?"applied":app.stage}/>
    <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:8,margin:"14px 0"}}>{[["CV",cv],["Eşleşme",mt!=null?mt+"%":null],["Mülakat",iS]].map(([l,v])=>(<div key={l} style={{background:"var(--sand2)",borderRadius:"var(--r)",padding:10,textAlign:"center"}}><div style={{fontSize:20,fontWeight:700,fontFamily:"var(--fr)",color:v!=null?(typeof v==="number"?v:parseInt(v))>=70?"var(--green)":"var(--amber)":"var(--muted)"}}>{v!=null?v:"—"}</div><div style={{fontSize:10,color:"var(--muted)"}}>{l}</div></div>))}</div>

    {/* Score Detail */}
    {app.interviewScore&&<div style={{marginBottom:14}}>
      {/* Category averages */}
      <div style={{display:"grid",gridTemplateColumns:"repeat(4,1fr)",gap:6,marginBottom:12}}>{[["Toplam",app.interviewScore.toplam_puan,"var(--ink)"],["Açık Uçlu",app.interviewScore.acik_uclu_ort,"var(--purple)"],["Teknik Test",app.interviewScore.mc_ort,"var(--teal)"],["Kod",app.interviewScore.kod_ort,"var(--amber)"]].map(([l,v,c])=>v!=null&&<div key={l} style={{background:"var(--sand2)",borderRadius:"var(--r)",padding:8,textAlign:"center"}}><div style={{fontSize:18,fontWeight:700,fontFamily:"var(--fr)",color:c}}>{Math.round(v)}</div><div style={{fontSize:9,color:"var(--muted)"}}>{l}</div><Bar val={v} color={c}/></div>)}</div>
      {app.interviewScore.genel_yorum&&<div style={{fontSize:12,color:"var(--ink3)",lineHeight:1.5,marginBottom:8,padding:"8px 10px",background:"var(--sand2)",borderRadius:"var(--r)"}}>{app.interviewScore.genel_yorum}</div>}
      {app.interviewScore.tavsiye&&<div style={{fontSize:12,fontWeight:700,marginBottom:10,color:app.interviewScore.tavsiye==="İleri Al"?"var(--green)":app.interviewScore.tavsiye==="Reddet"?"var(--red)":"var(--amber)"}}>Tavsiye: {app.interviewScore.tavsiye}</div>}
      <div style={{display:"flex",gap:4,flexWrap:"wrap",marginBottom:10}}>{(app.interviewScore.guclu_yonler||[]).map(g=><span key={g} className="badge bgr" style={{fontSize:9}}>{g}</span>)}{(app.interviewScore.gelistirme_alanlari||[]).map(g=><span key={g} className="badge ba" style={{fontSize:9}}>△ {g}</span>)}</div>

      {/* Açık Uçlu — AI scored or fallback from raw questions */}
      <div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",marginBottom:8}}>📝 AÇIK UÇLU SORULAR ({(app.interviewScore.acik_uclu||[]).length||(app.interviewQuestions||[]).length})</div>
      {(app.interviewScore.acik_uclu||[]).length>0
        ?(app.interviewScore.acik_uclu||[]).map((s,i)=><ScoreCard key={"o"+i} item={s} type="open" answer={app.interviewAnswers?.[i]}/> )
        :(app.interviewQuestions||[]).map((q,i)=><ScoreCard key={"of"+i} item={{soru:q,puan:50,yorum:"Manuel değerlendirme bekleniyor",cevap_50:"Temel düzeyde cevap",cevap_75:"İyi düzeyde, detaylı cevap",cevap_100:"Mükemmel: kapsamlı, somut örnekler içeren cevap"}} type="open" answer={app.interviewAnswers?.[i]}/> )
      }

      {/* MC sonuçları */}
      {(app.mcQuestions||[]).length>0&&<div style={{marginTop:8}}>
        <div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",marginBottom:8}}>☑ ÇOKTAN SEÇMELİ ({app.interviewScore.mc_dogru!=null?app.interviewScore.mc_dogru+"/"+(app.interviewScore.mc_toplam||3)+" doğru":""})</div>
        {(app.mcQuestions||[]).map((q,i)=>{const userAns=app.mcAnswers?.[i];const correct=userAns===q.dogru;return(<div key={"mc"+i} style={{padding:"8px 10px",background:correct?"var(--green2)":"var(--red2)",borderRadius:"var(--r)",marginBottom:4,border:`1px solid ${correct?"#bbf7d0":"#fecaca"}`}}>
          <div style={{fontSize:12,fontWeight:600,marginBottom:2}}>{q.soru}</div>
          <div style={{fontSize:11,display:"flex",gap:12}}><span>Aday: <strong style={{color:correct?"var(--green)":"var(--red)"}}>{userAns||"—"}</strong></span>{!correct&&<span>Doğru: <strong style={{color:"var(--green)"}}>{q.dogru}</strong></span>}<span style={{marginLeft:"auto",fontWeight:700,color:correct?"var(--green)":"var(--red)"}}>{correct?"✓":"✗"}</span></div>
        </div>)})}
      </div>}

      {/* Kod soruları — AI scored or fallback */}
      {((app.interviewScore.kod||[]).length>0||(app.codeQuestions||[]).length>0)&&<>
        <div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",margin:"10px 0 8px"}}>💻 KOD SORULARI ({(app.interviewScore.kod||[]).length||(app.codeQuestions||[]).length})</div>
        {(app.interviewScore.kod||[]).length>0
          ?app.interviewScore.kod.map((s,i)=><ScoreCard key={"c"+i} item={s} type="code" code={app.codeAnswers?.[i]} output={app.codeOutputs?.[i]}/> )
          :(app.codeQuestions||[]).map((q,i)=><ScoreCard key={"cf"+i} item={{gorev:q.gorev,puan:50,yorum:"Manuel değerlendirme bekleniyor",cevap_50:"Temel çözüm yaklaşımı",cevap_75:"Doğru ve iyi yapılandırılmış çözüm",cevap_100:"Optimal, edge case'leri kapsayan çözüm"}} type="code" code={app.codeAnswers?.[i]} output={app.codeOutputs?.[i]}/> )
        }
      </>}

      {app.interviewTime!=null&&<div style={{fontSize:10,color:"var(--muted)",marginTop:6}}>⏱ Süre: {Math.floor(app.interviewTime/60)}dk {app.interviewTime%60}sn</div>}
    </div>}

    {/* Mülakat cevaplandı ama score yok — raw data göster */}
    {!app.interviewScore&&app.interviewAnswers&&<div style={{marginBottom:14}}>
      <div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",marginBottom:8}}>📝 ADAYIN CEVAPLARI (puanlama bekleniyor)</div>
      {(app.interviewQuestions||[]).map((q,i)=>(<div key={"r"+i} style={{padding:"8px 10px",background:"var(--sand2)",borderRadius:"var(--r)",marginBottom:6}}><div style={{fontSize:12,fontWeight:600,marginBottom:2}}>{q}</div><div style={{fontSize:12,color:"var(--ink3)",lineHeight:1.5}}>{app.interviewAnswers[i]||"—"}</div></div>))}
    </div>}

    {/* Actions */}
    {canOffer&&<div style={{borderTop:"1px solid var(--line)",paddingTop:14}}><h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:10}}>💰 Teklif Gönder</h3><div className="g2" style={{gap:8,marginBottom:8}}><div><label>Tutar (₺/ay)</label><input type="number" value={amt} onChange={e=>setAmt(e.target.value)}/></div><div><label>Not</label><input value={note} onChange={e=>setNote(e.target.value)}/></div></div><button className="btn bp" onClick={sendOffer} disabled={busy}>{busy?<Spin s={14} c="#fff"/>:"Teklif Gönder"}</button></div>}
    {counterPending&&<div style={{borderTop:"1px solid var(--line)",paddingTop:14}}>
      <h3 style={{fontFamily:"var(--fr)",fontWeight:600,marginBottom:6}}>🤝 Karşı Teklif Geldi</h3>
      <div style={{fontSize:18,fontWeight:700,color:"var(--purple)",fontFamily:"var(--fr)",marginBottom:8}}>{(app.offerHistory.at(-1).amount||0).toLocaleString("tr-TR")} ₺/ay</div>
      <div style={{display:"flex",gap:6,marginBottom:8}}>
        <button className="btn" style={{flex:1,background:"var(--green2)",color:"var(--green)",border:"1.5px solid #bbf7d0",justifyContent:"center"}} onClick={()=>respondCounter("accept")}>✓ Kabul Et</button>
        <button className="btn" style={{flex:1,background:"var(--red2)",color:"var(--red)",border:"1.5px solid #fecaca",justifyContent:"center"}} onClick={()=>respondCounter("reject")}>✗ Reddet</button>
      </div>
      <div style={{fontSize:12,fontWeight:600,color:"var(--muted)",marginBottom:6}}>Veya yeni teklif ver:</div>
      <div style={{display:"flex",gap:8}}><input type="number" placeholder="Yeni tutar ₺/ay" value={amt} onChange={e=>setAmt(e.target.value)} style={{flex:1}}/><button className="btn bp" onClick={()=>respondCounter("counter")} disabled={busy}>Gönder</button></div>
    </div>}
    {canHire&&<div style={{borderTop:"1px solid var(--line)",paddingTop:14}}><button className="btn" style={{width:"100%",background:"var(--green2)",color:"var(--green)",border:"1.5px solid #bbf7d0",justifyContent:"center",fontSize:15}} onClick={approveHire} disabled={busy}>{busy?<Spin s={14}/>:"🎉 İşe Alımı Onayla"}</button></div>}
  </div>);
}

function AdminCands({users,apps}){
  const cands=Object.values(users).filter(u=>u.role==="candidate");const [sel,setSel]=useState(null);
  const byU={};Object.values(apps).forEach(a=>{if(!byU[a.candidateId])byU[a.candidateId]=[];byU[a.candidateId].push(a);});
  return(<div className="ai" style={{display:"grid",gridTemplateColumns:sel?"1fr 1.5fr":"1fr",gap:16,alignItems:"start"}}>
    <div><h1 style={{fontFamily:"var(--fr)",fontSize:24,fontWeight:600,marginBottom:16}}>Adaylar</h1>{cands.map(c=>{const ua=byU[c.id]||[];return(<div key={c.id} onClick={()=>setSel(sel?.id===c.id?null:c)} className="card" style={{padding:"12px 14px",marginBottom:6,cursor:"pointer",border:`1.5px solid ${sel?.id===c.id?"var(--blue)":"var(--line)"}`}}><div style={{display:"flex",alignItems:"center",gap:8}}><div style={{width:32,height:32,borderRadius:"50%",background:"var(--ink)",color:"#fff",display:"flex",alignItems:"center",justifyContent:"center",fontWeight:700,fontSize:13}}>{c.name?.charAt(0)}</div><div style={{flex:1}}><div style={{fontWeight:600,fontSize:13}}>{c.name}</div><div style={{fontSize:11,color:"var(--muted)"}}>{c.title||"—"} · {ua.length} başvuru</div></div></div></div>)})}{cands.length===0&&<p style={{color:"var(--muted)"}}>Aday yok.</p>}</div>
    {sel&&<div className="card" style={{maxHeight:"calc(100vh - 80px)",overflowY:"auto",position:"sticky",top:16}}>
      <div style={{display:"flex",justifyContent:"space-between",marginBottom:14}}><div style={{display:"flex",gap:10,alignItems:"center"}}><div style={{width:44,height:44,borderRadius:"50%",background:"var(--ink)",color:"#fff",display:"flex",alignItems:"center",justifyContent:"center",fontWeight:700,fontSize:18}}>{sel.name?.charAt(0)}</div><div><div style={{fontFamily:"var(--fr)",fontWeight:600,fontSize:17}}>{sel.name}</div><div style={{fontSize:12,color:"var(--muted)"}}>{sel.title} · {sel.city||""} · {sel.email}</div></div></div><button onClick={()=>setSel(null)} style={{background:"none",color:"var(--muted)",fontSize:16}}>✕</button></div>
      {sel.summary&&<div style={{background:"var(--sand2)",borderRadius:"var(--r)",padding:10,marginBottom:12,fontSize:13,lineHeight:1.6}}>{sel.summary}</div>}
      {(sel.skillRatings||[]).length>0&&<div style={{marginBottom:12}}><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:6}}>⚡ YETKİNLİKLER</div>{sel.skillRatings.map((sk,i)=>(<div key={i} style={{display:"flex",alignItems:"center",gap:6,marginBottom:4}}><span style={{fontSize:11,fontWeight:600,width:90,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{sk.name}</span><div style={{flex:1}}><Bar val={sk.level} color={sk.level>=80?"var(--green)":"var(--blue)"}/></div><span style={{fontSize:10,fontWeight:700,fontFamily:"var(--mono)",width:28,textAlign:"right"}}>{sk.level}</span></div>))}</div>}
      {(sel.certifications||[]).filter(c=>c.name).length>0&&<div style={{marginBottom:12}}><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:6}}>📜 SERTİFİKALAR</div>{sel.certifications.filter(c=>c.name).map((c,i)=>(<div key={i} style={{fontSize:12,marginBottom:4}}><strong>{c.name}</strong> — {c.org} · {c.date}</div>))}</div>}
      {(sel.exams||[]).filter(e=>e.name).length>0&&<div style={{marginBottom:12}}><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:6}}>📝 SINAVLAR</div>{sel.exams.filter(e=>e.name).map((e,i)=>(<div key={i} style={{fontSize:12,marginBottom:4}}><strong>{e.name}</strong>: {e.score} · Geçerli: {e.validUntil||"—"}</div>))}</div>}
      {sel.personalityResult&&<div style={{marginBottom:12}}><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:6}}>🧠 KİŞİLİK</div><div style={{display:"flex",alignItems:"center",gap:8,padding:8,background:DISC[sel.personalityResult.dominant]?.c+"12",borderRadius:"var(--r)"}}><span style={{fontSize:24}}>{DISC[sel.personalityResult.dominant]?.e}</span><div><div style={{fontWeight:700,color:DISC[sel.personalityResult.dominant]?.c}}>{DISC[sel.personalityResult.dominant]?.n}</div><div style={{fontSize:10,color:"var(--muted)"}}>{Object.entries(sel.personalityResult.scores).map(([k,v])=>k+":"+v).join(" · ")}</div></div></div></div>}
      {sel.experience&&<div style={{marginBottom:12}}><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:4}}>DENEYİM</div><div style={{fontSize:12,color:"var(--ink3)",whiteSpace:"pre-line"}}>{sel.experience}</div></div>}
      {sel.education&&<div><div style={{fontSize:10,fontWeight:600,color:"var(--muted)",marginBottom:4}}>EĞİTİM</div><div style={{fontSize:12,color:"var(--ink3)"}}>{sel.education}</div></div>}
    </div>}
  </div>);
}

/* ═══ ROOT ═══ */
export default function App(){
  const [user,setUser]=useState(null);const [loading,setLoading]=useState(true);
  useEffect(()=>{(async()=>{const s=await sg(K.session);if(s)setUser(s);setLoading(false);})();},[]);
  async function logout(){try{await window.storage.delete(K.session)}catch{}setUser(null);}
  if(loading)return <div style={{display:"flex",alignItems:"center",justifyContent:"center",minHeight:"100vh",background:"var(--sand)"}}><style>{STYLE}</style><Spin s={30}/></div>;
  if(!user)return <AuthScreen onLogin={setUser}/>;
  if(user.role==="admin")return <AdminPanel user={user} onLogout={logout}/>;
  return <CandPortal user={user} onLogout={logout}/>;
}
EOF

cat > src/app/services.js <<'EOF'
import { StorageAdapter } from "../services/storage/StorageAdapter";
import { AIService } from "../services/ai/AIService";
import { CodeRunner } from "../services/interview/CodeRunner";
import { ApplyPipelineService } from "../services/recruitment/ApplyPipelineService";
import { InterviewScoringService } from "../services/recruitment/InterviewScoringService";
import { UserRepository } from "../repositories/UserRepository";
import { JobRepository } from "../repositories/JobRepository";
import { ApplicationRepository } from "../repositories/ApplicationRepository";
import { SessionRepository } from "../repositories/SessionRepository";

export function buildServices() {
  const storage = new StorageAdapter();
  const aiService = new AIService();
  const codeRunner = new CodeRunner();
  const userRepo = new UserRepository(storage);
  const jobRepo = new JobRepository(storage);
  const appRepo = new ApplicationRepository(storage);
  const sessionRepo = new SessionRepository(storage);
  const applyPipeline = new ApplyPipelineService(aiService);
  const interviewScoring = new InterviewScoringService(aiService);
  return { storage, aiService, codeRunner, userRepo, jobRepo, appRepo, sessionRepo, applyPipeline, interviewScoring };
}
EOF

cat > src/components/common/AgentPipe.jsx <<'EOF'
import React from "react"; import Spin from "./Spin"; export default function AgentPipe({steps,cur}){const M={cv:"📄 CV Analizi",match:"🎯 Eşleştirme",questions:"💬 Soru Üretimi",notify:"✉️ Bildirim"};return(<div style={{background:"var(--sand2)",border:"1px solid var(--line)",borderRadius:"var(--r)",padding:14,marginTop:10}}><div style={{fontSize:10,fontFamily:"var(--mono)",color:"var(--muted)",marginBottom:8}}>⚡ AI İŞLEM HATTI</div>{steps.map((k,i)=>{const done=i<cur;const act=i===cur;return(<div key={k} style={{display:"flex",alignItems:"center",gap:10,padding:"4px 0",opacity: i > cur ? 0.4 : 1}}><div style={{width:20,height:20,borderRadius:"50%",background:done?"var(--green2)":act?"var(--blue3)":"var(--sand3)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:9,flexShrink:0}}>{done?"✓":act?<Spin s={8}/>:i+1}</div><div style={{fontSize:12,fontWeight:600,color:done?"var(--green)":act?"var(--blue)":"var(--muted)"}}>{M[k]||k}{act&&<span style={{fontSize:10,color:"var(--muted)",marginLeft:6,animation:"pulse 1.5s infinite"}}>işleniyor...</span>}</div></div>)})}</div>);}
EOF

cat > src/components/common/Bar.jsx <<'EOF'
import React from "react"; export default function Bar({val,max=100,color="var(--blue)"}){return <div style={{background:"var(--sand3)",borderRadius:4,height:5,overflow:"hidden"}}><div style={{height:"100%",width:`${(val/max)*100}%`,background:color,borderRadius:4,transition:"width .4s"}}/></div>;}
EOF

cat > src/components/common/Pill.jsx <<'EOF'
import React from "react"; import { STAGES } from "../../constants/stages"; export default function Pill({stage}){const s=STAGES[stage]||STAGES.applied;const m={applied:"bb",interview:"bpu",offer:"ba",negotiation:"bt",hired:"bgr",rejected:"br"};return <span className={"badge "+(m[stage]||"bgy")}>{s.i} {s.l}</span>; }
EOF

cat > src/components/common/Spin.jsx <<'EOF'
import React from "react"; export default function Spin({s=16,c="var(--blue)"}){return <div style={{width:s,height:s,borderRadius:"50%",border:"2px solid var(--line)",borderTopColor:c,animation:"spin .8s linear infinite",display:"inline-block"}}/>;}
EOF

cat > src/components/common/StageBar.jsx <<'EOF'
import React from "react"; export default function StageBar(){return null;}
EOF

cat > src/constants/personality.js <<'EOF'
export const PQ=[]; export const DISC={};
EOF

cat > src/constants/requiredDocs.js <<'EOF'
export const REQ_DOCS=[];
EOF

cat > src/constants/seedJobs.js <<'EOF'
export const SEED_JOBS=[];
EOF

cat > src/constants/stages.js <<'EOF'
export const STAGES={applied:{l:"Başvuru",i:"📋"},interview:{l:"Mülakat",i:"💬"},offer:{l:"Teklif",i:"💰"},negotiation:{l:"Müzakere",i:"🤝"},hired:{l:"İşe Alındı",i:"🎉"},rejected:{l:"Red",i:"✕"}}; export const STAGE_ORDER=["applied","interview","offer","negotiation","hired"];
EOF

cat > src/constants/storageKeys.js <<'EOF'
export const K={users:"tf6:u",jobs:"tf6:j",apps:"tf6:a",session:"tf6:s"};
EOF

cat > src/features/admin/AdminPanel.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/admin/apps/AdminApps.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/admin/apps/AdminDetail.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/admin/apps/ScoreCard.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/admin/cands/AdminCands.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/admin/jobs/AdminJobs.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/auth/AuthScreen.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/apply/ApplyFlow.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/apps/AppsTab.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/apps/CandAppCard.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/CandPortal.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/interview/FullInterview.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/jobs/JobsTab.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/features/candidate/profile/CandProfile.jsx <<'EOF'
import React from "react"; export default function X(){return null;}
EOF

cat > src/main.jsx <<'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./app/App.jsx";

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
EOF

cat > src/repositories/ApplicationRepository.js <<'EOF'
import { BaseRepository } from "./BaseRepository"; import { K } from "../constants/storageKeys"; export class ApplicationRepository extends BaseRepository{ constructor(storage){super(storage,K.apps);} async listAll(){const m=await this.readMap();return Object.values(m);} async listByCandidate(id){const m=await this.readMap();return Object.values(m).filter(a=>a.candidateId===id);} async getById(id){const m=await this.readMap();return m[id]||null;} async create(a){const m=await this.readMap();m[a.id]=a;await this.writeMap(m);return a;} async update(id,p){const m=await this.readMap();m[id]={...(m[id]||{}),...p};await this.writeMap(m);return m[id];}}
EOF

cat > src/repositories/BaseRepository.js <<'EOF'
export class BaseRepository {
  constructor(storage, key) { this.storage = storage; this.key = key; }
  async readMap() { return (await this.storage.getJSON(this.key)) || {}; }
  async writeMap(map) { await this.storage.setJSON(this.key, map); }
}
EOF

cat > src/repositories/JobRepository.js <<'EOF'
import { BaseRepository } from "./BaseRepository"; import { K } from "../constants/storageKeys"; export class JobRepository extends BaseRepository{ constructor(storage){super(storage,K.jobs);} async seedIfEmpty(seed=[]){const m=await this.readMap(); if(Object.keys(m).length) return m; const x={}; seed.forEach(j=>x[j.id]=j); await this.writeMap(x); return x;} async listActive(){const m=await this.readMap(); return Object.values(m).filter(j=>j.status==="active");} async getById(id){const m=await this.readMap(); return m[id]||null;} async create(j){const m=await this.readMap(); m[j.id]=j; await this.writeMap(m); return j;} async toggleStatus(id){const m=await this.readMap(); if(!m[id]) return null; m[id].status=m[id].status==="active"?"passive":"active"; await this.writeMap(m); return m[id];} async incrementApplicants(id){const m=await this.readMap(); if(m[id]){m[id].applicants=(m[id].applicants||0)+1; await this.writeMap(m);} } async incrementHiredAndMaybeClose(id){const m=await this.readMap(); if(m[id]){m[id].hiredCount=(m[id].hiredCount||0)+1; if(m[id].hiredCount>=m[id].headcount) m[id].status="passive"; await this.writeMap(m);} }}
EOF

cat > src/repositories/SessionRepository.js <<'EOF'
import { K } from "../constants/storageKeys"; export class SessionRepository{ constructor(storage){this.storage=storage;} get(){return this.storage.getJSON(K.session);} set(v){return this.storage.setJSON(K.session,v);} clear(){return this.storage.delete(K.session);} }
EOF

cat > src/repositories/UserRepository.js <<'EOF'
import { BaseRepository } from "./BaseRepository"; import { K } from "../constants/storageKeys"; export class UserRepository extends BaseRepository{ constructor(storage){super(storage,K.users);} async findByEmail(email){const m=await this.readMap(); return Object.values(m).find(u=>u.email===email)||null;} async getById(id){const m=await this.readMap();return m[id]||null;} async getAll(){const m=await this.readMap();return Object.values(m);} async create(u){const m=await this.readMap(); m[u.id]=u; await this.writeMap(m); return u;} async update(id,p){const m=await this.readMap(); m[id]={...(m[id]||{}),...p}; await this.writeMap(m); return m[id];}}
EOF

cat > src/services/ai/AIService.js <<'EOF'
export class AIService {
  constructor() {
    this.endpoint = import.meta.env.VITE_AI_ENDPOINT || "https://api.anthropic.com/v1/messages";
    this.model = import.meta.env.VITE_AI_MODEL || "claude-sonnet-4-20250514";
  }
  async call(system, user) {
    try {
      const r = await fetch(this.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: this.model,
          max_tokens: 2000,
          system: system + "\nKRİTİK: Sadece geçerli JSON döndür.",
          messages: [{ role: "user", content: user }],
        }),
      });
      const d = await r.json();
      const raw = d.content?.[0]?.text || "{}";
      return JSON.parse(raw.replace(/```json|```/g, "").trim());
    } catch { return { error: true }; }
  }
}
EOF

cat > src/services/interview/CodeRunner.js <<'EOF'
export class CodeRunner { run(){ return "(Çıktı yok)"; } }
EOF

cat > src/services/recruitment/ApplyPipelineService.js <<'EOF'
export class ApplyPipelineService { constructor(ai){ this.ai=ai; } }
EOF

cat > src/services/recruitment/InterviewScoringService.js <<'EOF'
export class InterviewScoringService { constructor(ai){ this.ai=ai; } }
EOF

cat > src/services/storage/StorageAdapter.js <<'EOF'
export class StorageAdapter {
  get engine() { return (typeof window !== "undefined" && window.storage) ? window.storage : null; }
  async getJSON(key) {
    try {
      if (this.engine) {
        const r = await this.engine.get(key);
        return r ? JSON.parse(r.value) : null;
      }
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : null;
    } catch { return null; }
  }
  async setJSON(key, value) {
    const raw = JSON.stringify(value);
    if (this.engine) return this.engine.set(key, raw);
    localStorage.setItem(key, raw);
  }
  async delete(key) {
    if (this.engine) return this.engine.delete(key);
    localStorage.removeItem(key);
  }
}
EOF

cat > src/styles/GlobalStyle.jsx <<'EOF'
export default function GlobalStyle(){ return null; }
EOF

cat > src/utils/format.js <<'EOF'
export const days=iso=>Math.floor((Date.now()-new Date(iso).getTime())/864e5); export const fmtD=iso=>new Date(iso).toLocaleDateString("tr-TR",{day:"2-digit",month:"long",year:"numeric"}); export const fmtS=iso=>new Date(iso).toLocaleDateString("tr-TR"); export const salK=n=>(n/1000).toFixed(0)+"K";
EOF

cat > src/utils/profile.js <<'EOF'
export function profileOk(u){return u&&u.name&&u.summary&&u.experience&&u.education&&(u.skills||"").length>0;}
EOF

cat > vite.config.js <<'EOF'
import { defineConfig } from "vite";

export default defineConfig({
  server: { port: 5173, host: true },
});
EOF

