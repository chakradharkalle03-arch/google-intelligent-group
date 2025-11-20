'use client'

interface AgentStatusProps {
  statusMessage: string
}

export default function AgentStatus({ statusMessage }: AgentStatusProps) {
  if (!statusMessage) return null

  return (
    <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl p-6 border border-blue-200/50">
      <div className="flex items-center gap-3">
        <span className="text-2xl animate-spin">⏳</span>
        <p className="text-gray-700 font-semibold flex-1">Doing Task...</p>
        <span className="text-sm text-gray-500">{statusMessage}</span>
      </div>
    </section>
  )
}

