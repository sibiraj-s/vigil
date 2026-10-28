import type { ReactNode } from 'react'
import { BatteryIcon, BoltIcon, ClockIcon, DisplayIcon, EyeIcon, KeyboardIcon } from './Icons'

const Keys = ({ children }: { children: ReactNode }) => <span className="font-mono text-sm">{children}</span>

const features: { icon: ReactNode; title: string; body: ReactNode }[] = [
  {
    icon: <ClockIcon className="size-5" />,
    title: 'Sessions on your terms',
    body: 'Stay awake indefinitely or for 15 minutes to 5 hours, until a set time, while an app runs, or until a download finishes.',
  },
  {
    icon: <EyeIcon className="h-4 w-5.5" />,
    title: 'A countdown at a glance',
    body: 'Timed sessions show the time left right beside the menu bar icon.',
  },
  {
    icon: <BoltIcon className="size-5" />,
    title: 'Triggers that run themselves',
    body: "Stay awake automatically while a condition holds, and go back to normal sleep the moment it doesn't.",
  },
  {
    icon: <KeyboardIcon className="size-5" />,
    title: 'Global shortcuts',
    body: (
      <>
        Start or end a session from any app. <Keys>⌥⌘0</Keys> for indefinitely, <Keys>⌥⌘1</Keys> for an hour, or set
        your own.
      </>
    ),
  },
  {
    icon: <BatteryIcon className="size-5" />,
    title: 'Battery guard',
    body: 'Sessions end on their own when the battery drops below a level you choose while unplugged.',
  },
  {
    icon: <DisplayIcon className="size-5" />,
    title: 'Let the display rest',
    body: 'Optionally turn the screen off while the Mac keeps running.',
  },
]

export function Features() {
  return (
    <section id="features" className="border-y border-black/7 bg-card">
      <div className="mx-auto flex max-w-290 flex-col gap-12 px-6 py-24">
        <div className="flex max-w-160 flex-col gap-3">
          <h2 className="text-[clamp(2rem,4vw,2.75rem)] leading-[1.1] font-extrabold tracking-[-0.03em]">
            Tell your Mac “not yet.”
          </h2>
          <p className="text-lg text-text2">For an hour. Until the build finishes. Until you say so.</p>
        </div>
        <div className="flex flex-wrap gap-5">
          {features.map(({ icon, title, body }) => (
            <div
              key={title}
              className="flex min-w-0 flex-[1_1_300px] flex-col gap-2.5 rounded-2xl border border-black/8 bg-bg p-7"
            >
              <div className="flex size-10 items-center justify-center rounded-[10px] bg-accent-soft text-accent">
                {icon}
              </div>
              <h3 className="text-lg font-bold">{title}</h3>
              <p className="text-[15px] text-text2">{body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
