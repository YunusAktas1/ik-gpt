import React from "react";

export default function Spin({ s = 16, c = "#2563eb" }) {
  return (
    <div
      style={{
        width: s,
        height: s,
        borderRadius: "50%",
        border: "2px solid #ddd",
        borderTopColor: c,
        animation: "spin .8s linear infinite",
      }}
    />
  );
}