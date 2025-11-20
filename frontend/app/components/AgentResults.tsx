'use client'

import { AgentOutputs } from '../types'

interface AgentResultsProps {
  agentOutputs: AgentOutputs
}

export default function AgentResults({ agentOutputs }: AgentResultsProps) {
  return (
    <div className="lg:col-span-1 space-y-4">
      {/* Map Result */}
      <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl border border-blue-200/50 overflow-hidden">
        <div className="bg-blue-100 px-4 py-2 border-b border-blue-200">
          <h3 className="text-blue-700 font-bold text-sm">Map</h3>
        </div>
        <div className="p-4 min-h-[200px] max-h-[400px] overflow-y-auto">
          <div className="text-gray-800 text-sm whitespace-pre-wrap leading-relaxed">
            {agentOutputs.googleMap || (
              <div className="flex items-center justify-center h-full text-gray-400">
                <span className="text-xs">Map result</span>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Calendar Result */}
      <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl border border-purple-200/50 overflow-hidden">
        <div className="bg-purple-100 px-4 py-2 border-b border-purple-200">
          <h3 className="text-purple-700 font-bold text-sm">Calendar</h3>
        </div>
        <div className="p-4 min-h-[200px] max-h-[400px] overflow-y-auto">
          <div className="text-gray-800 text-sm whitespace-pre-wrap leading-relaxed">
            {agentOutputs.calendar || (
              <div className="flex items-center justify-center h-full text-gray-400">
                <span className="text-xs">Calendar result</span>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Telephone Result */}
      <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl border border-red-200/50 overflow-hidden">
        <div className="bg-red-100 px-4 py-2 border-b border-red-200">
          <h3 className="text-red-700 font-bold text-sm">Telephone</h3>
        </div>
        <div className="p-4 min-h-[120px] max-h-[200px] overflow-y-auto">
          <div className="text-gray-800 text-sm whitespace-pre-wrap leading-relaxed">
            {agentOutputs.telephone || (
              <div className="flex items-center justify-center h-full text-gray-400">
                <span className="text-xs">Telephone result</span>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Research Result */}
      <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl border border-green-200/50 overflow-hidden">
        <div className="bg-green-100 px-4 py-2 border-b border-green-200">
          <h3 className="text-green-700 font-bold text-sm">Research</h3>
        </div>
        <div className="p-4 min-h-[120px] max-h-[200px] overflow-y-auto">
          <div className="text-gray-800 text-sm whitespace-pre-wrap leading-relaxed">
            {agentOutputs.research || (
              <div className="flex items-center justify-center h-full text-gray-400">
                <span className="text-xs">Research result</span>
              </div>
            )}
          </div>
        </div>
      </section>
    </div>
  )
}

