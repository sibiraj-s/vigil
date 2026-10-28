import { links } from '../links'
import type { Release } from '../useLatestRelease'
import { CheckIcon, DownloadIcon, EyeIcon } from './Icons'

export function Hero({ release }: { release: Release }) {
  return (
    <section id="top" className="mx-auto flex max-w-290 flex-wrap items-center gap-14 px-6 pt-22 pb-24">
      <div className="flex min-w-0 flex-[1_1_440px] flex-col gap-7">
        <span className="self-start rounded-full bg-accent-soft px-3 py-1.5 text-[13px] font-semibold text-accent-dark">
          Free &amp; open source · macOS
        </span>
        <h1 className="text-[clamp(2.5rem,6vw,4.25rem)] leading-[1.02] font-extrabold tracking-[-0.035em]">
          Your Mac stays awake. For exactly as long as you need.
        </h1>
        <p className="max-w-136 text-[19px] leading-[1.55] text-text2">
          Start a session with one click, or let triggers keep your Mac awake on their own: during a Zoom call, on an
          external display, while a download finishes.
        </p>
        <div className="flex flex-wrap gap-3">
          <a
            href={release.downloadURL}
            className="flex h-13 items-center gap-2.5 rounded-[10px] bg-accent px-6 font-semibold text-white hover:bg-accent-dark"
          >
            <DownloadIcon className="size-4.5" />
            Download for Mac
          </a>
          <a
            href={links.repo}
            className="flex h-13 items-center rounded-[10px] border border-black/15 bg-card px-5.5 font-semibold text-text hover:bg-black/3"
          >
            View source
          </a>
        </div>
        <p className="text-[13px] text-text3">Version {release.version} · macOS 27 or later · Apple Silicon</p>
      </div>

      <MenuMockup />
    </section>
  )
}

const menuItems = [
  { label: 'Indefinitely', shortcut: '⌥⌘0' },
  { label: '30 minutes' },
  { label: '1 hour', shortcut: '⌥⌘1', selected: true },
  { label: '2 hours' },
  { label: 'Until a time…' },
  { label: 'While an app runs…' },
  { label: 'While a download finishes…' },
]

/** Vigil's menu open below the menu bar, keeping the Mac awake for an hour. */
function MenuMockup() {
  return (
    <div
      role="img"
      aria-label="Vigil's menu open in the macOS menu bar, keeping the Mac awake for one hour"
      className="flex min-w-0 flex-[1_1_440px] flex-col overflow-hidden rounded-[20px] bg-night"
    >
      <div className="flex h-7.5 items-center justify-end gap-4 bg-night-bar px-4 text-[13px] text-night-text">
        <span className="flex h-5.5 items-center gap-1.5 rounded-[5px] bg-white/14 px-2 text-xs text-amber">
          <EyeIcon className="h-3.5 w-5" />
          59m
        </span>
        <span>3:12 PM</span>
      </div>
      <div className="flex justify-end px-6 pt-2.5 pb-10">
        <div className="flex w-full max-w-75 flex-col gap-0.5 rounded-xl bg-menu p-1.5 text-[13px] text-text shadow-[0_18px_48px_rgba(0,0,0,0.45)]">
          <div className="flex flex-col gap-3 p-3">
            <div className="flex items-center gap-3">
              <div className="flex size-9 items-center justify-center rounded-[10px] bg-accent text-white">
                <EyeIcon className="h-4 w-5.5" />
              </div>
              <div className="flex flex-col">
                <span className="text-sm font-semibold">Mac is staying awake</span>
                <span className="text-xs text-text3">59 min left · until 4:12 PM</span>
              </div>
            </div>
            <span className="flex h-8 items-center justify-center rounded-lg bg-menu-button font-semibold">
              End session
            </span>
          </div>
          <div className="mx-2 h-px bg-black/10" />
          <span className="px-3 pt-2 pb-1 text-[11px] font-semibold tracking-[0.04em] text-menu-label uppercase">
            Keep awake
          </span>
          {menuItems.map((item) =>
            item.selected ? (
              <span key={item.label} className="flex h-7.5 items-center gap-2 rounded-md bg-accent px-3 text-white">
                <CheckIcon className="h-2.5 w-3.5" />
                <span className="grow">{item.label}</span>
                <span className="text-xs">{item.shortcut}</span>
              </span>
            ) : (
              <span key={item.label} className="flex h-7.5 items-center justify-between pr-3 pl-8.5">
                {item.label}
                {item.shortcut && <span className="text-xs text-menu-label">{item.shortcut}</span>}
              </span>
            ),
          )}
        </div>
      </div>
    </div>
  )
}
