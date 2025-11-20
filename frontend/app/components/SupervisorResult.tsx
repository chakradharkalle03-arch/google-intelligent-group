'use client'

interface SupervisorResultProps {
  response: string
  loading: boolean
  statusMessage: string
}

export default function SupervisorResult({
  response,
  loading,
  statusMessage
}: SupervisorResultProps) {
  return (
    <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl p-6 border border-purple-200/50">
      <h2 className="text-gray-700 font-bold text-lg mb-4 flex items-center gap-2">
        <span>🤖</span>
        <span>Supervisor Agent result</span>
      </h2>
      <div className="bg-gray-50 rounded-xl p-4 min-h-[300px] max-h-[600px] overflow-y-auto border border-gray-200">
        <div className="whitespace-pre-wrap text-gray-800 leading-relaxed text-sm">
          {response || (loading ? (
            <div className="flex items-center justify-center h-full">
              <div className="text-center">
                <div className="animate-spin text-4xl mb-3">⏳</div>
                <p className="text-gray-600 font-semibold">{statusMessage || 'Processing...'}</p>
              </div>
            </div>
          ) : (
            <div className="flex items-center justify-center h-full text-gray-400">
              <span className="text-sm">No response yet</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}

