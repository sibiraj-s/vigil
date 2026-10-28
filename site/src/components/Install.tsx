import type { ReactNode } from 'react'
import type { Release } from '../useLatestRelease'
import { DownloadIcon, appIcon } from './Icons'

export function Install({ release }: { release: Release }) {
  const steps: { title: string; body: ReactNode }[] = [
    {
      title: 'Download the disk image',
      body: (
        <>
          Grab <span className="font-mono text-sm text-amber">Vigil-{release.version}.dmg</span> from the latest
          GitHub release.
        </>
      ),
    },
    {
      title: 'Drag Vigil to Applications',
      body: 'Open the disk image and drop the app into your Applications folder.',
    },
    {
      title: 'Look for the eye',
      body: 'Launch Vigil and it appears in your menu bar. Click it to start your first session.',
    },
  ]

  return (
    <section id="install" className="bg-night text-night-text">
      <div className="mx-auto flex max-w-290 flex-wrap items-start gap-14 px-6 py-24">
        <div className="flex min-w-0 flex-[1_1_360px] flex-col gap-5">
          <img src={appIcon} alt="Vigil app icon" className="size-22" />
          <h2 className="text-[clamp(2rem,4vw,2.75rem)] leading-[1.1] font-extrabold tracking-[-0.03em] text-white">
            Free, open source, and three steps away.
          </h2>
          <p className="text-[17px] text-night-text2">
            Requires macOS 27 or later on Apple Silicon. Vigil checks for updates once a day, installs them from inside
            the app, and can open at login.
          </p>
          <div className="flex flex-wrap gap-3 pt-2">
            <a
              href={release.downloadURL}
              className="flex h-13 items-center gap-2.5 rounded-[10px] bg-amber px-6 font-bold text-text hover:brightness-95"
            >
              <DownloadIcon className="size-4.5" />
              Download the latest release
            </a>
          </div>
        </div>
        <ol className="flex min-w-0 flex-[1_1_440px] flex-col gap-4">
          {steps.map(({ title, body }, i) => (
            <li key={title} className="flex gap-4.5 rounded-[14px] border border-white/10 bg-white/6 p-6">
              <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-amber font-bold text-text">
                {i + 1}
              </span>
              <span className="flex flex-col gap-1">
                <span className="text-[17px] font-semibold text-white">{title}</span>
                <span className="text-[15px] text-night-text2">{body}</span>
              </span>
            </li>
          ))}
        </ol>
      </div>
    </section>
  )
}
