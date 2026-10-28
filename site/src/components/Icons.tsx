import type { ReactNode } from 'react'

type IconProps = { className?: string }

export const appIcon = `${import.meta.env.BASE_URL}app-icon.png`

export function GitHubIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" aria-hidden="true" className={className}>
      <path
        fill="currentColor"
        d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
      />
    </svg>
  )
}

export function DownloadIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 16 16" aria-hidden="true" className={className}>
      <path
        d="M8 1.5v9M4.5 7L8 10.5 11.5 7M2.5 14h11"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

/** The menu bar icon: an open eye, filled with `currentColor`. */
export function EyeIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 24 16" aria-hidden="true" className={className}>
      <path
        d="M1.5 8S5.5 1.5 12 1.5 22.5 8 22.5 8 18.5 14.5 12 14.5 1.5 8 1.5 8z"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
      />
      <circle cx="12" cy="8" r="3.4" fill="currentColor" />
    </svg>
  )
}

export function CheckIcon({ className }: IconProps) {
  return (
    <svg viewBox="0 0 12 10" aria-hidden="true" className={className}>
      <path
        d="M1 5.5l3.2 3L11 1.5"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

/** A 16×16 stroke icon; its paths and shapes are the children. */
function Glyph({ className, children }: IconProps & { children: ReactNode }) {
  return (
    <svg
      viewBox="0 0 16 16"
      aria-hidden="true"
      className={className}
      fill="none"
      stroke="currentColor"
      strokeWidth="1.4"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {children}
    </svg>
  )
}

export const ClockIcon = (p: IconProps) => (
  <Glyph {...p}>
    <circle cx="8" cy="8" r="6.5" />
    <path d="M8 4.5V8l2.5 1.5" />
  </Glyph>
)

export const BoltIcon = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M9 1.5L3 9h4.5L7 14.5 13 7H8.5z" />
  </Glyph>
)

export const KeyboardIcon = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="1.5" y="4" width="13" height="8" rx="2" />
    <path d="M4.5 9.5h7" />
  </Glyph>
)

export const BatteryIcon = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="1.5" y="4.5" width="11.5" height="7" rx="2" />
    <path d="M14.5 7v2M4 8h3" />
  </Glyph>
)

export const DisplayIcon = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="1.5" y="2.5" width="13" height="8.5" rx="1.5" />
    <path d="M5.5 14h5M8 11v3" />
  </Glyph>
)

export const AppIcon = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="2" y="2" width="12" height="12" rx="3" />
  </Glyph>
)

export const PlugIcon = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M6 1.5v3.5M10 1.5v3.5M4 5h8v3a4 4 0 0 1-8 0zM8 12v2.5" />
  </Glyph>
)

export const WifiIcon = (p: IconProps) => (
  <Glyph {...p}>
    <path d="M1.5 6a9 9 0 0 1 13 0M4 8.5a5.5 5.5 0 0 1 8 0M6.5 11a2 2 0 0 1 3 0" />
  </Glyph>
)

export const CalendarIcon = (p: IconProps) => (
  <Glyph {...p}>
    <rect x="2" y="3" width="12" height="11" rx="2" />
    <path d="M2 6.5h12M5.5 1.5v3M10.5 1.5v3" />
  </Glyph>
)
