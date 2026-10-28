import { links } from '../links'
import { appIcon } from './Icons'

export function Footer() {
  return (
    <footer className="border-t border-black/8">
      <div className="mx-auto flex max-w-290 flex-wrap items-center justify-between gap-4 px-6 py-8 text-sm text-text3">
        <span className="flex items-center gap-2.5">
          <img src={appIcon} alt="" className="size-6" />
          Vigil · © {new Date().getFullYear()} Sibiraj · MIT License
        </span>
        <nav aria-label="Footer" className="flex flex-wrap gap-5">
          {[
            ['GitHub', links.repo],
            ['Releases', links.releases],
            ['Changelog', links.changelog],
            ['Report an issue', links.issues],
          ].map(([label, href]) => (
            <a key={label} href={href} className="text-accent hover:text-accent-dark">
              {label}
            </a>
          ))}
        </nav>
      </div>
    </footer>
  )
}
