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

// Agent configuration with icons and colors
const agentConfig = {
  googleMap: {
    icon: '🗺️',
    name: 'GoogleMap Agent',
    gradient: 'from-blue-500 via-cyan-500 to-teal-500',
    bgGradient: 'from-blue-500/20 via-cyan-500/20 to-teal-500/20',
    borderColor: 'border-blue-400/50',
    hoverBorder: 'hover:border-blue-400',
    shadowColor: 'shadow-blue-500/30',
    textColor: 'text-blue-300'
  },
  calendar: {
    icon: '📅',
    name: 'Calendar Agent',
    gradient: 'from-purple-500 via-pink-500 to-rose-500',
    bgGradient: 'from-purple-500/20 via-pink-500/20 to-rose-500/20',
    borderColor: 'border-purple-400/50',
    hoverBorder: 'hover:border-purple-400',
    shadowColor: 'shadow-purple-500/30',
    textColor: 'text-purple-300'
  },
  telephone: {
    icon: '☎️',
    name: 'Telephone Agent',
    gradient: 'from-red-500 via-orange-500 to-amber-500',
    bgGradient: 'from-red-500/20 via-orange-500/20 to-amber-500/20',
    borderColor: 'border-red-400/50',
    hoverBorder: 'hover:border-red-400',
    shadowColor: 'shadow-red-500/30',
    textColor: 'text-red-300'
  },
  research: {
    icon: '🔍',
    name: 'Research Agent',
    gradient: 'from-green-500 via-emerald-500 to-teal-500',
    bgGradient: 'from-green-500/20 via-emerald-500/20 to-teal-500/20',
    borderColor: 'border-green-400/50',
    hoverBorder: 'hover:border-green-400',
    shadowColor: 'shadow-green-500/30',
    textColor: 'text-green-300'
  }
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

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
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
                
                if (data.type === 'status') {
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

      <div className="container mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 lg:py-12 max-w-7xl relative z-10">
        {/* Enhanced Header with Attractive Design */}
        <header className="text-center mb-10 sm:mb-14 relative">
          <div className="inline-block mb-6 sm:mb-8 transform hover:scale-105 transition-transform duration-300">
            <div className="relative">
              {/* Multi-layer Glow Effect */}
              <div className="absolute -inset-1 bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 rounded-3xl blur-2xl opacity-40 animate-pulse"></div>
              <div className="absolute inset-0 bg-gradient-to-r from-purple-200 via-pink-200 to-blue-200 rounded-3xl blur-xl opacity-60"></div>
              
              {/* Main Header Card */}
              <div className="relative bg-white/95 backdrop-blur-2xl rounded-3xl px-10 sm:px-16 py-8 sm:py-12 border-2 border-purple-200/60 shadow-2xl transform hover:shadow-purple-200/50 transition-all duration-300">
                {/* Decorative Corner Elements */}
                <div className="absolute top-4 left-4 w-12 h-12 border-t-2 border-l-2 border-purple-300/50 rounded-tl-2xl"></div>
                <div className="absolute top-4 right-4 w-12 h-12 border-t-2 border-r-2 border-pink-300/50 rounded-tr-2xl"></div>
                <div className="absolute bottom-4 left-4 w-12 h-12 border-b-2 border-l-2 border-blue-300/50 rounded-bl-2xl"></div>
                <div className="absolute bottom-4 right-4 w-12 h-12 border-b-2 border-r-2 border-indigo-300/50 rounded-br-2xl"></div>
                
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8 relative z-10">
                  {/* Animated Icon */}
                  <div className="relative">
                    <div className="absolute inset-0 bg-gradient-to-r from-purple-400 to-pink-400 rounded-full blur-xl opacity-50 animate-pulse"></div>
                    <div className="relative text-6xl sm:text-8xl animate-bounce-slow filter drop-shadow-2xl transform hover:rotate-12 transition-transform duration-300">
                      🧠
                    </div>
                  </div>
                  
                  <div className="text-center sm:text-left">
                    <h1 className="text-5xl sm:text-7xl lg:text-8xl font-black bg-clip-text text-transparent bg-gradient-to-r from-purple-600 via-pink-600 via-blue-600 to-indigo-600 leading-tight mb-3 tracking-tight">
                      Google Intelligent Group
                    </h1>
                    <div className="flex items-center justify-center sm:justify-start gap-3 mt-2">
                      <div className="h-1 w-16 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"></div>
                      <p className="text-xl sm:text-2xl lg:text-3xl text-gray-700 font-bold">
                        Multi-Agent System
                      </p>
                      <div className="h-1 w-16 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full"></div>
                    </div>
                    <p className="text-base sm:text-lg lg:text-xl text-gray-600 font-semibold mt-2">
                      LangChain 1.0 & Next.js
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          {/* Enhanced Status Badge */}
          <div className="inline-flex items-center gap-3 bg-gradient-to-r from-green-50 to-emerald-50 backdrop-blur-sm border-2 border-green-300/60 rounded-full px-6 py-3 shadow-xl hover:shadow-2xl hover:scale-105 transition-all duration-300">
            <div className="relative">
              <div className="absolute inset-0 bg-green-400 rounded-full animate-ping opacity-75"></div>
              <div className="relative w-4 h-4 bg-gradient-to-r from-green-500 to-emerald-500 rounded-full shadow-lg"></div>
            </div>
            <span className="text-green-800 text-sm font-extrabold tracking-wide">System Online</span>
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
          </div>
        </header>

        <div className="space-y-6 sm:space-y-8">
          {/* Enhanced Query Input Section */}
          <section className="relative group">
            {/* Multi-layer Glow */}
            <div className="absolute -inset-1 bg-gradient-to-r from-purple-300 via-pink-300 to-blue-300 rounded-3xl blur-xl opacity-40 group-hover:opacity-60 transition duration-500"></div>
            <div className="absolute -inset-0.5 bg-gradient-to-r from-purple-200 via-pink-200 to-blue-200 rounded-3xl blur opacity-50 group-hover:opacity-70 transition duration-300"></div>
            
            <div className="relative bg-white/95 backdrop-blur-2xl rounded-3xl shadow-2xl p-8 sm:p-10 border-2 border-purple-200/60 transform hover:shadow-purple-200/50 transition-all duration-300">
              {/* Decorative Top Border */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-t-3xl"></div>
              
              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="relative">
                  <label className="block text-gray-800 font-extrabold mb-5 text-xl sm:text-2xl flex items-center gap-3">
                    <div className="relative">
                      <div className="absolute inset-0 bg-purple-200 rounded-full blur-lg opacity-50"></div>
                      <span className="relative text-3xl">💬</span>
                    </div>
                    <span className="bg-clip-text text-transparent bg-gradient-to-r from-purple-600 to-pink-600">
                      Enter Your Query
                    </span>
                  </label>
                  <div className="relative">
                    {/* Textarea with Enhanced Styling */}
                    <textarea
                      className="w-full px-6 sm:px-8 py-5 sm:py-6 bg-gradient-to-br from-gray-50 to-white border-2 border-purple-300/60 rounded-2xl focus:ring-4 focus:ring-purple-200/50 focus:border-purple-500 resize-none transition-all duration-300 text-gray-800 placeholder-gray-400 text-base sm:text-lg shadow-inner font-medium hover:border-purple-400"
                      value={query}
                      onChange={(e) => setQuery(e.target.value)}
                      placeholder="Please help me find a good Indian restaurant near Taipei 101 and make a reservation for tomorrow evening at 7:00 PM"
                      rows={4}
                      disabled={loading}
                    />
                    {/* Character Counter with Icon */}
                    <div className="absolute bottom-4 right-4 flex items-center gap-2 bg-white/80 backdrop-blur-sm px-3 py-1.5 rounded-full border border-purple-200/50 shadow-sm">
                      <span className="text-xs text-purple-600 font-semibold">{query.length}</span>
                      <span className="text-xs text-gray-400">chars</span>
                    </div>
                  </div>
                </div>
                
                {/* Enhanced Button */}
                <button
                  type="submit"
                  className="relative w-full group/btn overflow-hidden rounded-2xl"
                  disabled={loading || !query.trim()}
                >
                  {/* Animated Background Layers */}
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-600 via-pink-600 to-blue-600 rounded-2xl"></div>
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-2xl opacity-0 group-hover/btn:opacity-100 transition-opacity duration-300"></div>
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-400 via-pink-400 to-blue-400 rounded-2xl opacity-0 group-hover/btn:opacity-50 transition-opacity duration-500"></div>
                  
                  {/* Button Content */}
                  <div className="relative bg-gradient-to-r from-purple-600 via-pink-600 to-blue-600 hover:from-purple-500 hover:via-pink-500 hover:to-blue-500 text-white font-extrabold py-5 sm:py-6 px-8 rounded-2xl transition-all duration-300 transform hover:scale-[1.02] hover:shadow-2xl hover:shadow-purple-400/50 disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none flex items-center justify-center gap-4 text-lg sm:text-xl">
                    {loading ? (
                      <>
                        <svg className="animate-spin h-7 w-7" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                        <span>Processing...</span>
                      </>
                    ) : (
                      <>
                        <span className="text-3xl animate-pulse filter drop-shadow-lg">⚡</span>
                        <span className="tracking-wide">Send Query</span>
                        <span className="text-2xl transform group-hover/btn:translate-x-1 transition-transform duration-300">→</span>
                      </>
                    )}
                  </div>
                </button>
              </form>
            </div>
          </section>

          {/* Status Message - Light Theme */}
          {statusMessage && (
            <div className="relative group">
              <div className="absolute -inset-0.5 bg-gradient-to-r from-blue-200 to-cyan-200 rounded-2xl blur opacity-50"></div>
              <div className="relative bg-blue-50 backdrop-blur-xl border-l-4 border-blue-400 rounded-2xl p-5 sm:p-6 shadow-xl animate-slide-in-right">
                <div className="flex items-center gap-4">
                  <div className="relative">
                    <div className="absolute inset-0 bg-blue-400 rounded-full animate-ping opacity-75"></div>
                    <span className="relative text-3xl animate-spin">⏳</span>
                  </div>
                  <p className="text-blue-800 font-bold text-base sm:text-lg flex-1">{statusMessage}</p>
                </div>
              </div>
            </div>
          )}

          {/* Enhanced Supervisor Response Section */}
          <section className="relative group">
            <div className="absolute -inset-1 bg-gradient-to-r from-purple-300 via-pink-300 to-blue-300 rounded-3xl blur-xl opacity-30 group-hover:opacity-50 transition duration-500"></div>
            <div className="absolute -inset-0.5 bg-gradient-to-r from-purple-200 via-pink-200 to-blue-200 rounded-3xl blur opacity-40 group-hover:opacity-60 transition duration-300"></div>
            
            <div className="relative bg-white/95 backdrop-blur-2xl rounded-3xl shadow-2xl p-8 sm:p-10 border-2 border-purple-200/60 transform hover:shadow-purple-200/50 transition-all duration-300">
              {/* Decorative Top Border */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-purple-500 via-pink-500 to-blue-500 rounded-t-3xl"></div>
              
              <div className="flex items-center gap-5 mb-8">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-purple-300 to-pink-300 rounded-full blur-2xl opacity-60 animate-pulse"></div>
                  <div className="absolute inset-0 bg-purple-200 rounded-full blur-xl opacity-50"></div>
                  <span className="relative text-5xl sm:text-6xl filter drop-shadow-2xl transform hover:scale-110 transition-transform duration-300">🤖</span>
                </div>
                <div className="flex-1">
                  <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black bg-clip-text text-transparent bg-gradient-to-r from-purple-600 via-pink-600 to-blue-600 mb-2">
                    Supervisor Response
                  </h2>
                  <div className="flex items-center gap-2">
                    <div className="h-1 w-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"></div>
                    <p className="text-gray-600 text-sm sm:text-base font-semibold">AI-Powered Multi-Agent Coordination</p>
                    <div className="h-1 w-12 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-full"></div>
                  </div>
                </div>
              </div>
              
              <div className="relative bg-gradient-to-br from-gray-50 via-white to-purple-50/30 backdrop-blur-sm rounded-2xl p-8 sm:p-10 border-2 border-purple-200/50 min-h-[220px] sm:min-h-[280px] shadow-inner">
                {/* Corner Decorations */}
                <div className="absolute top-3 left-3 w-6 h-6 border-t-2 border-l-2 border-purple-300/40 rounded-tl-xl"></div>
                <div className="absolute top-3 right-3 w-6 h-6 border-t-2 border-r-2 border-pink-300/40 rounded-tr-xl"></div>
                
                <div className="absolute top-4 right-4">
                  {loading && (
                    <div className="flex items-center gap-2 bg-white/80 backdrop-blur-sm px-3 py-1.5 rounded-full border border-purple-200/50 shadow-sm">
                      <div className="w-2.5 h-2.5 bg-purple-500 rounded-full animate-pulse"></div>
                      <span className="text-purple-700 text-xs font-bold">Processing</span>
                    </div>
                  )}
                </div>
                
                <div className="whitespace-pre-wrap text-gray-800 leading-relaxed text-base sm:text-lg font-medium">
                  {response || (loading ? (
                    <div className="flex items-center justify-center h-full min-h-[180px]">
                      <div className="text-center">
                        <div className="relative inline-block mb-8">
                          <div className="absolute inset-0 bg-gradient-to-r from-purple-300 to-pink-300 rounded-full blur-3xl opacity-60 animate-pulse"></div>
                          <div className="relative animate-spin text-7xl filter drop-shadow-xl">⏳</div>
                        </div>
                        <p className="text-purple-700 font-extrabold text-xl sm:text-2xl mb-4">{statusMessage || 'Processing your query...'}</p>
                        <div className="mt-6 flex justify-center gap-3">
                          <div className="w-3 h-3 bg-purple-500 rounded-full animate-bounce shadow-lg" style={{ animationDelay: '0ms' }}></div>
                          <div className="w-3 h-3 bg-pink-500 rounded-full animate-bounce shadow-lg" style={{ animationDelay: '150ms' }}></div>
                          <div className="w-3 h-3 bg-blue-500 rounded-full animate-bounce shadow-lg" style={{ animationDelay: '300ms' }}></div>
                        </div>
                      </div>
                    </div>
                  ) : (
                    <div className="flex items-center justify-center h-full min-h-[180px] text-gray-400">
                      <div className="text-center">
                        <div className="relative inline-block mb-6">
                          <div className="absolute inset-0 bg-gray-200 rounded-full blur-2xl opacity-30"></div>
                          <span className="relative text-7xl sm:text-8xl block opacity-40">💬</span>
                        </div>
                        <p className="text-xl sm:text-2xl font-bold text-gray-500 mb-2">No response yet</p>
                        <p className="text-sm sm:text-base text-gray-400">Submit a query to see the AI response</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </section>

          {/* Enhanced Agent Dashboard */}
          <section className="relative group">
            <div className="absolute -inset-1 bg-gradient-to-r from-blue-300 via-purple-300 to-pink-300 rounded-3xl blur-xl opacity-30 group-hover:opacity-50 transition duration-500"></div>
            <div className="absolute -inset-0.5 bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200 rounded-3xl blur opacity-40 group-hover:opacity-60 transition duration-300"></div>
            
            <div className="relative bg-white/95 backdrop-blur-2xl rounded-3xl shadow-2xl p-8 sm:p-10 border-2 border-purple-200/60 transform hover:shadow-purple-200/50 transition-all duration-300">
              {/* Decorative Top Border */}
              <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 rounded-t-3xl"></div>
              
              <div className="flex items-center gap-5 mb-8 sm:mb-10">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-blue-300 to-purple-300 rounded-full blur-2xl opacity-60 animate-pulse"></div>
                  <div className="absolute inset-0 bg-blue-200 rounded-full blur-xl opacity-50"></div>
                  <span className="relative text-5xl sm:text-6xl filter drop-shadow-2xl transform hover:scale-110 transition-transform duration-300">📊</span>
                </div>
                <div className="flex-1">
                  <h2 className="text-3xl sm:text-4xl lg:text-5xl font-black bg-clip-text text-transparent bg-gradient-to-r from-blue-600 via-purple-600 to-cyan-600 mb-2">
                    Agent Dashboard
                  </h2>
                  <div className="flex items-center gap-2">
                    <div className="h-1 w-12 bg-gradient-to-r from-blue-500 to-purple-500 rounded-full"></div>
                    <p className="text-gray-600 text-sm sm:text-base font-semibold">Real-time Multi-Agent Status</p>
                    <div className="h-1 w-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"></div>
                  </div>
                </div>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 sm:gap-6">
                {/* Enhanced GoogleMap Agent */}
                {(() => {
                  const config = agentConfig.googleMap
                  const hasOutput = !!agentOutputs.googleMap
                  return (
                    <div className={`group relative overflow-hidden bg-white/90 backdrop-blur-sm rounded-2xl p-6 sm:p-7 border-2 ${config.borderColor} ${config.hoverBorder} hover:shadow-2xl hover:shadow-blue-300/50 transition-all duration-300 transform hover:scale-[1.03] ${hasOutput ? 'ring-2 ring-blue-400/60 shadow-lg' : ''}`}>
                      {/* Decorative Corner */}
                      <div className="absolute top-2 right-2 w-8 h-8 border-t-2 border-r-2 border-blue-300/50 rounded-tr-xl"></div>
                      
                      {/* Background Glow */}
                      <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-blue-200/40 to-transparent rounded-full blur-2xl"></div>
                      
                      <div className="relative">
                        <div className="flex items-center justify-between mb-5">
                          <div className="flex items-center gap-4">
                            <div className="relative">
                              <div className="absolute inset-0 bg-blue-200 rounded-full blur-lg opacity-50"></div>
                              <span className="relative text-4xl sm:text-5xl group-hover:scale-125 transition-transform duration-300 filter drop-shadow-xl">{config.icon}</span>
                            </div>
                            <h3 className={`text-xl sm:text-2xl font-extrabold text-blue-700`}>{config.name}</h3>
                          </div>
                          {hasOutput && (
                            <div className="flex items-center gap-2 bg-green-50 px-3 py-1.5 rounded-full border border-green-300/50">
                              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                              <span className="text-xs text-green-700 font-bold">Active</span>
                            </div>
                          )}
                        </div>
                        <div className={`bg-gradient-to-br from-gray-50 via-white to-blue-50/30 backdrop-blur-sm rounded-xl p-5 sm:p-6 border-2 ${config.borderColor} min-h-[160px] sm:min-h-[180px] shadow-inner ${loading && !hasOutput ? 'opacity-50' : ''}`}>
                          <div className="text-sm sm:text-base text-gray-800 whitespace-pre-wrap leading-relaxed font-medium">
                            {agentOutputs.googleMap || (
                              <div className="flex items-center justify-center h-full text-gray-400">
                                <span className="text-sm flex items-center gap-3">
                                  <span className="animate-pulse text-2xl">💭</span>
                                  <span className="font-semibold">Waiting for task...</span>
                                </span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })()}

                {/* Enhanced Calendar Agent */}
                {(() => {
                  const config = agentConfig.calendar
                  const hasOutput = !!agentOutputs.calendar
                  return (
                    <div className={`group relative overflow-hidden bg-white/90 backdrop-blur-sm rounded-2xl p-6 sm:p-7 border-2 ${config.borderColor} ${config.hoverBorder} hover:shadow-2xl hover:shadow-purple-300/50 transition-all duration-300 transform hover:scale-[1.03] ${hasOutput ? 'ring-2 ring-purple-400/60 shadow-lg' : ''}`}>
                      <div className="absolute top-2 right-2 w-8 h-8 border-t-2 border-r-2 border-purple-300/50 rounded-tr-xl"></div>
                      <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-purple-200/40 to-transparent rounded-full blur-2xl"></div>
                      <div className="relative">
                        <div className="flex items-center justify-between mb-5">
                          <div className="flex items-center gap-4">
                            <div className="relative">
                              <div className="absolute inset-0 bg-purple-200 rounded-full blur-lg opacity-50"></div>
                              <span className="relative text-4xl sm:text-5xl group-hover:scale-125 transition-transform duration-300 filter drop-shadow-xl">{config.icon}</span>
                            </div>
                            <h3 className={`text-xl sm:text-2xl font-extrabold text-purple-700`}>{config.name}</h3>
                          </div>
                          {hasOutput && (
                            <div className="flex items-center gap-2 bg-green-50 px-3 py-1.5 rounded-full border border-green-300/50">
                              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                              <span className="text-xs text-green-700 font-bold">Active</span>
                            </div>
                          )}
                        </div>
                        <div className={`bg-gradient-to-br from-gray-50 via-white to-purple-50/30 backdrop-blur-sm rounded-xl p-5 sm:p-6 border-2 ${config.borderColor} min-h-[160px] sm:min-h-[180px] shadow-inner ${loading && !hasOutput ? 'opacity-50' : ''}`}>
                          <div className="text-sm sm:text-base text-gray-800 whitespace-pre-wrap leading-relaxed font-medium">
                            {agentOutputs.calendar || (
                              <div className="flex items-center justify-center h-full text-gray-400">
                                <span className="text-sm flex items-center gap-3">
                                  <span className="animate-pulse text-2xl">💭</span>
                                  <span className="font-semibold">Waiting for task...</span>
                                </span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })()}

                {/* Enhanced Telephone Agent */}
                {(() => {
                  const config = agentConfig.telephone
                  const hasOutput = !!agentOutputs.telephone
                  return (
                    <div className={`group relative overflow-hidden bg-white/90 backdrop-blur-sm rounded-2xl p-6 sm:p-7 border-2 ${config.borderColor} ${config.hoverBorder} hover:shadow-2xl hover:shadow-red-300/50 transition-all duration-300 transform hover:scale-[1.03] ${hasOutput ? 'ring-2 ring-red-400/60 shadow-lg' : ''}`}>
                      <div className="absolute top-2 right-2 w-8 h-8 border-t-2 border-r-2 border-red-300/50 rounded-tr-xl"></div>
                      <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-red-200/40 to-transparent rounded-full blur-2xl"></div>
                      <div className="relative">
                        <div className="flex items-center justify-between mb-5">
                          <div className="flex items-center gap-4">
                            <div className="relative">
                              <div className="absolute inset-0 bg-red-200 rounded-full blur-lg opacity-50"></div>
                              <span className="relative text-4xl sm:text-5xl group-hover:scale-125 transition-transform duration-300 filter drop-shadow-xl">{config.icon}</span>
                            </div>
                            <h3 className={`text-xl sm:text-2xl font-extrabold text-red-700`}>{config.name}</h3>
                          </div>
                          {hasOutput && (
                            <div className="flex items-center gap-2 bg-green-50 px-3 py-1.5 rounded-full border border-green-300/50">
                              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                              <span className="text-xs text-green-700 font-bold">Active</span>
                            </div>
                          )}
                        </div>
                        <div className={`bg-gradient-to-br from-gray-50 via-white to-red-50/30 backdrop-blur-sm rounded-xl p-5 sm:p-6 border-2 ${config.borderColor} min-h-[160px] sm:min-h-[180px] shadow-inner ${loading && !hasOutput ? 'opacity-50' : ''}`}>
                          <div className="text-sm sm:text-base text-gray-800 whitespace-pre-wrap leading-relaxed font-medium">
                            {agentOutputs.telephone || (
                              <div className="flex items-center justify-center h-full text-gray-400">
                                <span className="text-sm flex items-center gap-3">
                                  <span className="animate-pulse text-2xl">💭</span>
                                  <span className="font-semibold">Waiting for task...</span>
                                </span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })()}

                {/* Enhanced Research Agent */}
                {(() => {
                  const config = agentConfig.research
                  const hasOutput = !!agentOutputs.research
                  return (
                    <div className={`group relative overflow-hidden bg-white/90 backdrop-blur-sm rounded-2xl p-6 sm:p-7 border-2 ${config.borderColor} ${config.hoverBorder} hover:shadow-2xl hover:shadow-green-300/50 transition-all duration-300 transform hover:scale-[1.03] ${hasOutput ? 'ring-2 ring-green-400/60 shadow-lg' : ''}`}>
                      <div className="absolute top-2 right-2 w-8 h-8 border-t-2 border-r-2 border-green-300/50 rounded-tr-xl"></div>
                      <div className="absolute top-0 right-0 w-40 h-40 bg-gradient-to-br from-green-200/40 to-transparent rounded-full blur-2xl"></div>
                      <div className="relative">
                        <div className="flex items-center justify-between mb-5">
                          <div className="flex items-center gap-4">
                            <div className="relative">
                              <div className="absolute inset-0 bg-green-200 rounded-full blur-lg opacity-50"></div>
                              <span className="relative text-4xl sm:text-5xl group-hover:scale-125 transition-transform duration-300 filter drop-shadow-xl">{config.icon}</span>
                            </div>
                            <h3 className={`text-xl sm:text-2xl font-extrabold text-green-700`}>{config.name}</h3>
                          </div>
                          {hasOutput && (
                            <div className="flex items-center gap-2 bg-green-50 px-3 py-1.5 rounded-full border border-green-300/50">
                              <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse shadow-lg shadow-green-400/50"></div>
                              <span className="text-xs text-green-700 font-bold">Active</span>
                            </div>
                          )}
                        </div>
                        <div className={`bg-gradient-to-br from-gray-50 via-white to-green-50/30 backdrop-blur-sm rounded-xl p-5 sm:p-6 border-2 ${config.borderColor} min-h-[160px] sm:min-h-[180px] shadow-inner ${loading && !hasOutput ? 'opacity-50' : ''}`}>
                          <div className="text-sm sm:text-base text-gray-800 whitespace-pre-wrap leading-relaxed font-medium">
                            {agentOutputs.research || (
                              <div className="flex items-center justify-center h-full text-gray-400">
                                <span className="text-sm flex items-center gap-3">
                                  <span className="animate-pulse text-2xl">💭</span>
                                  <span className="font-semibold">Waiting for task...</span>
                                </span>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    </div>
                  )
                })()}
              </div>
            </div>
          </section>
        </div>
      </div>
    </main>
  )
}
