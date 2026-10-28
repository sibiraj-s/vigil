import type { ReactNode } from 'react'
import { AppIcon, CalendarIcon, DisplayIcon, PlugIcon, WifiIcon } from './Icons'

const triggers: { icon: ReactNode; title: string; detail: string }[] = [
  { icon: <AppIcon className="size-4.5" />, title: 'Chosen apps are running', detail: 'Zoom, Xcode, your render queue' },
  {
    icon: <DisplayIcon className="size-4.5" />,
    title: 'An external display or drive is connected',
    detail: 'Docked at your desk, or a backup in progress',
  },
  {
    icon: <PlugIcon className="size-4.5" />,
    title: 'Plugged in, or on battery',
    detail: 'Whichever power state you choose',
  },
  {
    icon: <WifiIcon className="size-4.5" />,
    title: 'On a given Wi‑Fi network',
    detail: 'Awake at the office, normal at home',
  },
  { icon: <CalendarIcon className="size-4.5" />, title: 'Within a weekly schedule', detail: 'Say, weekdays 9 to 6' },
]

export function Triggers() {
  return (
    <section id="triggers" className="mx-auto flex max-w-290 flex-wrap items-center gap-14 px-6 py-24">
      <div className="flex min-w-0 flex-[1_1_380px] flex-col gap-4">
        <h2 className="text-[clamp(2rem,4vw,2.75rem)] leading-[1.1] font-extrabold tracking-[-0.03em]">
          Powerful triggers.
        </h2>
        <p className="text-lg text-text2">
          Set a rule once and Vigil does the rest. Your Mac stays awake while Zoom is open, while you're docked at your
          desk, or through the work day, and sleeps normally the moment the condition ends.
        </p>
        <p className="text-sm text-text3">
          Wi‑Fi triggers need Location Services, because macOS only shares the network name with apps that have
          location access.
        </p>
      </div>
      <ul className="flex min-w-0 flex-[1_1_440px] flex-col divide-y divide-black/7 rounded-2xl border border-black/10 bg-card">
        {triggers.map(({ icon, title, detail }) => (
          <li key={title} className="flex items-center gap-3.5 px-5 py-4.5">
            <span className="flex size-9 shrink-0 items-center justify-center rounded-[9px] bg-accent-soft text-accent">
              {icon}
            </span>
            <span className="flex flex-col">
              <span className="text-[15px] font-semibold">{title}</span>
              <span className="text-[13px] text-text3">{detail}</span>
            </span>
          </li>
        ))}
      </ul>
    </section>
  )
}
