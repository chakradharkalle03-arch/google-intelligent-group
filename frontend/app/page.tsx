'use client'

import { useState, FormEvent } from 'react'
import { useQueryStream } from './hooks/useQueryStream'
import ChatInterface from './components/ChatInterface'
import SupervisorResult from './components/SupervisorResult'
import AgentStatus from './components/AgentStatus'
import AgentResults from './components/AgentResults'

export default function Home() {
  const [query, setQuery] = useState('')
  const { response, loading, statusMessage, agentOutputs, submitQuery } = useQueryStream()

  const handleSubmit = async (e?: FormEvent) => {
    if (e) {
    e.preventDefault()
    }
    await submitQuery(query)
  }

  return (
    <main className="min-h-screen bg-gradient-to-br from-purple-50 via-pink-50 via-blue-50 to-indigo-50 relative overflow-hidden">
      {/* Enhanced Animated Background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        {/* Multiple Gradient Orbs for Depth */}
        <div className="absolute top-0 left-0 w-[900px] h-[900px] bg-gradient-to-br from-purple-300/30 via-pink-300/20 to-transparent rounded-full blur-3xl animate-float"></div>
        <div className="absolute top-0 right-0 w-[700px] h-[700px] bg-gradient-to-bl from-blue-300/30 via-cyan-300/20 to-transparent rounded-full blur-3xl animate-float-delayed"></div>
        <div className="absolute bottom-0 left-1/2 w-[800px] h-[800px] bg-gradient-to-tr from-indigo-300/30 via-purple-300/20 to-transparent rounded-full blur-3xl animate-float-slow"></div>
        <div className="absolute top-1/2 right-1/4 w-[500px] h-[500px] bg-gradient-to-br from-pink-200/25 to-transparent rounded-full blur-2xl animate-float"></div>
        
        {/* Enhanced Grid Pattern */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#d8b4fe20_1px,transparent_1px),linear-gradient(to_bottom,#d8b4fe20_1px,transparent_1px)] bg-[size:32px_32px]"></div>
        
        {/* Floating Particles */}
        <div className="absolute top-20 left-20 w-2 h-2 bg-purple-400/40 rounded-full animate-float"></div>
        <div className="absolute top-40 right-40 w-3 h-3 bg-pink-400/40 rounded-full animate-float-delayed"></div>
        <div className="absolute bottom-40 left-1/3 w-2 h-2 bg-blue-400/40 rounded-full animate-float-slow"></div>
              </div>

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 lg:py-12 max-w-[1600px] relative z-10">
        {/* Manus-Style Header */}
        <header className="mb-6 sm:mb-8">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black bg-clip-text text-transparent bg-gradient-to-r from-purple-600 via-pink-600 to-blue-600">
              Google Intelligent Group
            </h1>
            <div className="flex items-center gap-2 bg-green-50 border border-green-300 rounded-full px-4 py-1.5">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span className="text-green-700 text-xs font-bold">System Online</span>
            </div>
              </div>
          <p className="text-gray-600 text-sm sm:text-base">Multi-Agent System with LangChain 1.0 & Next.js</p>
        </header>

        {/* Manus-Style Two-Column Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column: Agent Interaction Area (2/3 width) */}
          <div className="lg:col-span-2 space-y-6">
            <SupervisorResult 
              response={response}
              loading={loading}
              statusMessage={statusMessage}
            />
            <AgentStatus statusMessage={statusMessage} />
            <ChatInterface
              query={query}
              onQueryChange={setQuery}
              onSubmit={handleSubmit}
              loading={loading}
            />
              </div>

          {/* Right Column: Results Display Area (1/3 width) */}
          <AgentResults agentOutputs={agentOutputs} />
        </div>
      </div>
    </main>
  )
}
