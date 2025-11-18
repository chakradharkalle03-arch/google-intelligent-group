'use client'

import { useState } from 'react'
import axios from 'axios'

// Helper function to safely extract text from objects
const extractText = (value: any): string => {
  if (typeof value === 'string') return value
  if (typeof value === 'number' || typeof value === 'boolean') return String(value)
  if (value === null || value === undefined) return ''
  if (Array.isArray(value)) {
    return value.map(item => extractText(item)).join('\n')
  }
  if (typeof value === 'object') {
    // Handle LangChain message objects
    if (value.text) return value.text
    if (value.content) return extractText(value.content)
    if (value.message) return extractText(value.message)
    if (value.formatted) return extractText(value.formatted)
    if (value.result) return extractText(value.result)
    // Try to stringify if it's a complex object
    try {
      return JSON.stringify(value, null, 2)
    } catch {
      return String(value)
    }
  }
  return String(value)
}


export default function Home() {
  const [query, setQuery] = useState('')
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)
  const [statusMessage, setStatusMessage] = useState('')
  const [agentOutputs, setAgentOutputs] = useState({
    supervisor: '',
    googleMap: '',
    calendar: '',
    telephone: '',
    research: ''
  })

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) {
    e.preventDefault()
    }
    if (!query.trim()) return

    setLoading(true)
    setResponse('')
    setStatusMessage('')
    setAgentOutputs({
      supervisor: '',
      googleMap: '',
      calendar: '',
      telephone: '',
      research: ''
    })

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8000'
      
      const useStreaming = true
      
      if (useStreaming) {
        const response = await fetch(`${apiUrl}/query`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ query: query, stream: true })
        })

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }

        const reader = response.body?.getReader()
        const decoder = new TextDecoder()

        if (!reader) {
          throw new Error('No response body')
        }

        let buffer = ''
        
        while (true) {
          const { done, value } = await reader.read()
          
          if (done) break

          buffer += decoder.decode(value, { stream: true })
          const lines = buffer.split('\n')
          buffer = lines.pop() || ''

          for (const line of lines) {
            if (line.startsWith('data: ')) {
              try {
                const data = JSON.parse(line.slice(6))
                
                if (data.type === 'status' || data.type === 'task') {
                  setStatusMessage(data.message)
                  if (data.agent === 'supervisor') {
                    setAgentOutputs(prev => ({
                      ...prev,
                      supervisor: data.message
                    }))
                  }
                } else if (data.type === 'agent_output') {
                  const agentKey = data.agent === 'googleMap' ? 'googleMap' : 
                                  data.agent === 'calendar' ? 'calendar' :
                                  data.agent === 'telephone' ? 'telephone' :
                                  data.agent === 'research' ? 'research' : data.agent
                  
                  // Safely extract text from output (handles objects)
                  const outputText = extractText(data.output)
                  
                  setAgentOutputs(prev => ({
                    ...prev,
                    [agentKey]: outputText
                  }))
                } else if (data.type === 'complete') {
                  // Set supervisor response
                  const supervisorResponse = extractText(data.response || '')
                  setResponse(supervisorResponse)
                  
                  // Update supervisor in agent outputs
                  if (data.agent_outputs) {
                    const safeOutputs: any = {}
                    for (const [key, value] of Object.entries(data.agent_outputs)) {
                      safeOutputs[key] = extractText(value)
                    }
                    // Ensure supervisor is set
                    if (supervisorResponse) {
                      safeOutputs.supervisor = supervisorResponse
                    }
                    setAgentOutputs(prev => ({
                      ...prev,
                      ...safeOutputs
                    }))
                  } else if (supervisorResponse) {
                    setAgentOutputs(prev => ({
                      ...prev,
                      supervisor: supervisorResponse
                    }))
                  }
                  setStatusMessage('')
                } else if (data.type === 'error') {
                  setResponse(`Error: ${extractText(data.error || data.message)}`)
                  setStatusMessage('')
                }
              } catch (e) {
                console.error('Error parsing SSE data:', e)
              }
            }
          }
        }
      } else {
      const res = await axios.post(`${apiUrl}/query`, {
          query: query,
          stream: false
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })

      if (res.data.response) {
          setResponse(extractText(res.data.response))
      } else if (res.data.message) {
          setResponse(extractText(res.data.message))
      } else {
        setResponse('Response received')
      }
      
      if (res.data.agent_outputs) {
        const outputs: any = {}
          if (res.data.agent_outputs.supervisor) outputs.supervisor = extractText(res.data.agent_outputs.supervisor)
          if (res.data.agent_outputs.googleMap) outputs.googleMap = extractText(res.data.agent_outputs.googleMap)
          if (res.data.agent_outputs.calendar) outputs.calendar = extractText(res.data.agent_outputs.calendar)
          if (res.data.agent_outputs.telephone) outputs.telephone = extractText(res.data.agent_outputs.telephone)
          if (res.data.agent_outputs.research) outputs.research = extractText(res.data.agent_outputs.research)
        setAgentOutputs(outputs)
        }
      }
    } catch (error: any) {
      console.error('API Error:', error)
      
      let errorMessage = 'Failed to get response'
      
      if (error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
        errorMessage = 'Network Error: Cannot connect to backend server. Please make sure the backend is running on http://127.0.0.1:8000'
      } else if (error.response) {
        errorMessage = error.response.data?.detail || error.response.data?.message || `Server error: ${error.response.status}`
      } else if (error.message) {
        errorMessage = error.message
      }
      
      setResponse(`Error: ${errorMessage}`)
      setStatusMessage('')
    } finally {
      setLoading(false)
      setStatusMessage('')
    }
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
            {/* Supervisor Agent Result - First (Top) */}
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

            {/* Task Status - Manus Style */}
            {statusMessage && (
              <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl p-6 border border-blue-200/50">
                <div className="flex items-center gap-3">
                  <span className="text-2xl animate-spin">⏳</span>
                  <p className="text-gray-700 font-semibold flex-1">Doing Task...</p>
                  <span className="text-sm text-gray-500">{statusMessage}</span>
                </div>
              </section>
            )}

            {/* Input Section - Bottom with Run button beside it */}
            <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl p-6 border border-purple-200/50">
              <form onSubmit={handleSubmit} className="space-y-4">
                <label className="block text-gray-700 font-bold text-lg mb-3">Input</label>
                <div className="flex gap-3">
              <textarea
                    className="flex-1 px-4 py-3 bg-white border-2 border-purple-300/50 rounded-xl focus:ring-2 focus:ring-purple-400 focus:border-purple-500 resize-none transition-all text-gray-800 placeholder-gray-400 text-sm shadow-inner"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                    placeholder="Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow evening at 7:00 PM"
                    rows={3}
                disabled={loading}
              />
              <button
                type="submit"
                    className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-500 hover:to-pink-500 text-white font-bold py-3 px-6 rounded-xl transition-all transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 shadow-lg self-start"
                disabled={loading || !query.trim()}
              >
                    {loading ? (
                      <>
                        <svg className="animate-spin h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Processing...</span>
                      </>
                    ) : (
                      <>
                        <span className="text-xl">⚡</span>
                        <span>Run</span>
                      </>
                    )}
              </button>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-xs text-gray-500">{query.length} chars</span>
                </div>
            </form>
          </section>

          </div>

          {/* Right Column: Results Display Area (1/3 width) - Manus Style */}
          <div className="lg:col-span-1 space-y-4">
            {/* Map Result Tab - Manus Style */}
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

            {/* Calendar Result Tab - Manus Style */}
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

            {/* Additional Results - Telephone & Research */}
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
        </div>
      </div>
    </main>
  )
}
