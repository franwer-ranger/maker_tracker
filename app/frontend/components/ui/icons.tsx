import type { SVGProps } from "react"

// Iconos de línea de la UI v1 (MT-101): un solo set, trazo 1.6, del color de su texto (currentColor).
// Los trazos salen de Paper («v1 · 1 · Sistema» y el marco de «v1 · 11»); los que Paper no dibuja siguen el mismo trazo.
const paths = {
  taller: <><path d="M4 20h4L19 9l-4-4L4 16z" /><path d="M13.5 6.5l4 4" /></>,
  product: <path d="M4 11l8-7 8 7v9H4z" />,
  stories: <><path d="M8 6h12M8 12h12M8 18h12" /><circle cx="4" cy="6" r="0.8" /><circle cx="4" cy="12" r="0.8" /><circle cx="4" cy="18" r="0.8" /></>,
  roadmap: <path d="M5 20L9 4M19 20L15 4M12 6v2M12 11v2M12 16v2" />,
  decision: <path d="M12 4v16M6 20h12M4 9l3-5 3 5a3 3 0 0 1-6 0zM14 9l3-5 3 5a3 3 0 0 1-6 0z" />,
  robot: <><rect x="5" y="8" width="14" height="11" rx="3" /><path d="M12 4v4" /><circle cx="12" cy="3.5" r="1" /><circle cx="9.5" cy="13" r="1" /><circle cx="14.5" cy="13" r="1" /><path d="M3 12v3M21 12v3" /></>,
  chevronDown: <path d="M6 9l6 6 6-6" />,
  chevronRight: <path d="M9 6l6 6-6 6" />,
  search: <><circle cx="11" cy="11" r="6.5" /><path d="M20 20l-4.2-4.2" /></>,
  copy: <><rect x="6" y="5" width="12" height="16" rx="2" /><path d="M9 5V3.5h6V5" /></>,
  check: <path d="M5 12.5l4.5 4.5L19 7.5" />,
  question: <><circle cx="12" cy="12" r="8.5" /><path d="M9.6 9.5a2.5 2.5 0 0 1 4.8 1c0 1.7-2.4 2-2.4 3.5" /><path d="M12 17h.01" /></>,
  pencil: <><path d="M4 20h4L19 9l-4-4L4 16z" /><path d="M13.5 6.5l4 4" /></>,
  design: <><rect x="6" y="3" width="12" height="18" rx="2" /><rect x="9" y="6" width="6" height="7" rx="0.5" /></>,
  spark: <path d="M12 3v5M12 16v5M3 12h5M16 12h5" />,
  pin: <><path d="M12 21s-6.5-5.7-6.5-11a6.5 6.5 0 0 1 13 0c0 5.3-6.5 11-6.5 11z" /><circle cx="12" cy="10" r="2.2" /></>,
  swap: <path d="M4 8h14l-3-3M20 16H6l3 3" />,
  contrast: <><circle cx="12" cy="12" r="8.5" /><path d="M12 3.5v17" /></>,
  menu: <path d="M4 8h16M4 16h16" />,
  file: <><path d="M6 3h8l4 4v14H6z" /><path d="M9 12h6M9 16h6" /></>,
  vibrate: <><rect x="9" y="5" width="6" height="14" rx="1.5" /><path d="M5 9v6M19 9v6M2.5 10.5v3M21.5 10.5v3" /></>,
  arrowRight: <path d="M5 12h14M14 7l5 5-5 5" />,
  enter: <path d="M19 6v6H6M9 9l-3 3 3 3" />,
  tab: <path d="M4 12h12M12 8l4 4-4 4M20 6v12" />,
} as const

export type IconName = keyof typeof paths

export function Icon({ name, size = 15, ...props }: { name: IconName; size?: number } & SVGProps<SVGSVGElement>) {
  return (
    <svg
      aria-hidden="true"
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.6}
      strokeLinecap="round"
      strokeLinejoin="round"
      {...props}
      className={["shrink-0", props.className].filter(Boolean).join(" ")}
    >
      {paths[name]}
    </svg>
  )
}

// Logo de Maker Tracker (marco de Paper): estrella blanca sobre el naranja.
export function Logo({ size = 22 }: { size?: number }) {
  return (
    <svg aria-hidden="true" width={size} height={size} viewBox="0 0 48 48" className="shrink-0">
      <rect width="48" height="48" rx="10" fill="var(--signal)" />
      <g transform="translate(9 9) scale(0.75)">
        <path transform="matrix(1 0 0 1 20.002 0)" fill="#FFFFFF" opacity="0.4" d="M4.375 8.124L5.453 11.898C5.554 12.257 5.882 12.499 6.25 12.499C6.617 12.499 6.945 12.257 7.046 11.898L8.124 8.124L11.898 7.046C12.257 6.945 12.499 6.617 12.499 6.25C12.499 5.882 12.257 5.554 11.898 5.453L8.124 4.375L7.046 0.602C6.945 0.242 6.617 0 6.25 0C5.882 0 5.554 0.242 5.453 0.602L4.375 4.375L0.602 5.453C0.242 5.554 0 5.882 0 6.25C0 6.617 0.242 6.945 0.602 7.046L4.375 8.124ZM13.499 18.999L14.358 22.014C14.437 22.295 14.702 22.498 14.999 22.498C15.296 22.498 15.554 22.303 15.64 22.014L16.499 18.999L19.514 18.139C19.796 18.061 19.999 17.796 19.999 17.499C19.999 17.202 19.803 16.944 19.514 16.858L16.499 15.999L15.64 12.984C15.561 12.702 15.296 12.499 14.999 12.499C14.702 12.499 14.444 12.694 14.358 12.984L13.499 15.999L10.484 16.858C10.202 16.936 9.999 17.202 9.999 17.499C9.999 17.796 10.195 18.053 10.484 18.139L13.499 18.999Z" />
        <path transform="matrix(1 0 0 1 0 11.247)" fill="#FFFFFF" d="M16.673 1.049C15.986 -0.35 13.994 -0.35 13.306 1.049L9.69 8.392L1.604 9.572C0.073 9.79 -0.544 11.681 0.565 12.767L6.416 18.485L5.041 26.555C4.776 28.086 6.385 29.258 7.76 28.531L14.994 24.719L22.228 28.531C23.603 29.258 25.212 28.086 24.946 26.555L23.564 18.485L29.415 12.767C30.524 11.681 29.915 9.79 28.376 9.572L20.29 8.392L16.673 1.049Z" />
      </g>
    </svg>
  )
}
