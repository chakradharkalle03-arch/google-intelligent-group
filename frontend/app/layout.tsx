import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Google Intelligent Group - Multi-Agent System',
  description: 'Intelligent Supervisor Agent System with LangChain & Next.js',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}

