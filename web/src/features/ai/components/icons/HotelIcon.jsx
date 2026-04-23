import React from "react";

/**
 * Minimal hotel icon (SVG) that inherits currentColor.
 * Use with CSS color tokens for theme alignment.
 */
export default function HotelIcon({ size = 16, className, title = "Hotel" }) {
  const s = Number(size);
  const px = Number.isFinite(s) ? s : 16;
  return (
    <svg
      width={px}
      height={px}
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      role="img"
      aria-label={title}
    >
      <path
        d="M7 21V4.75C7 3.784 7.784 3 8.75 3H18a2 2 0 0 1 2 2v16"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M3 21h18"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
      <path
        d="M10 7h2.5M10 10h2.5M10 13h2.5"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
      <path
        d="M15.5 9.5h2.75"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
      <path
        d="M15.5 13.5h2.75"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
      />
    </svg>
  );
}

