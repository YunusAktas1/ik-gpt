import { useEffect } from "react";

const STYLE = `
*,*::before,*::after{box-sizing:border-box}
:root{--sand:#faf8f4}
body{margin:0;background:var(--sand)}
`;

export default function GlobalStyle() {
  useEffect(() => {
    const id = "tf-global-style";
    if (document.getElementById(id)) return;
    const tag = document.createElement("style");
    tag.id = id;
    tag.textContent = STYLE;
    document.head.appendChild(tag);
  }, []);

  return null;
}