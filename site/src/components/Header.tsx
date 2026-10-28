import { links } from '../links'
import { GitHubIcon, appIcon } from './Icons'

export function Header() {
  return (
    <header className="border-b border-black/8">
      <div className="mx-auto flex max-w-290 flex-wrap items-center justify-between gap-4 px-6 py-4">
        <a href="#top" className="flex items-center gap-2.5 text-lg font-bold text-text">
          <img src={appIcon} alt="" className="size-8" />
          Vigil
        </a>
        <nav aria-label="Main" className="flex flex-wrap items-center gap-6 text-sm font-medium">
          <a href="#features" className="text-nav hover:text-text">
            Features
          </a>
          <a href="#triggers" className="text-nav hover:text-text">
            Triggers
          </a>
          <a href="#install" className="text-nav hover:text-text">
            Install
          </a>
          <a
            href={links.repo}
            className="flex h-9 items-center gap-2 rounded-lg border border-black/15 bg-card px-3.5 text-text hover:bg-black/3"
          >
            <GitHubIcon className="size-4" />
            GitHub
          </a>
        </nav>
      </div>
    </header>
  )
}
