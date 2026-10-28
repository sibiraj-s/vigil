import { useEffect } from 'react'
import { Features } from './components/Features'
import { Footer } from './components/Footer'
import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { Install } from './components/Install'
import { Triggers } from './components/Triggers'
import { useLatestRelease } from './useLatestRelease'

export default function App() {
  const release = useLatestRelease()

  // The page renders after load, so the browser can't scroll to a #fragment by itself.
  useEffect(() => {
    const target = location.hash ? document.getElementById(decodeURIComponent(location.hash.slice(1))) : null
    target?.scrollIntoView()
  }, [])

  return (
    <div className="min-h-screen bg-bg font-sans text-base leading-normal text-text">
      <Header />
      <main>
        <Hero release={release} />
        <Features />
        <Triggers />
        <Install release={release} />
      </main>
      <Footer />
    </div>
  )
}
