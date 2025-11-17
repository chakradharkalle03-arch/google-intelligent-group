'use client'

import { useState } from 'react'
import axios from 'axios'
import styles from './page.module.css'

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
      
      // Use streaming by default
      const useStreaming = true
      
      if (useStreaming) {
        // Use EventSource for streaming
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
                  
                  setAgentOutputs(prev => ({
                    ...prev,
                    [agentKey]: data.output
                  }))
                } else if (data.type === 'complete') {
                  setResponse(data.response || '')
                  if (data.agent_outputs) {
                    setAgentOutputs(prev => ({
                      ...prev,
                      ...data.agent_outputs
                    }))
                  }
                  setStatusMessage('')
                } else if (data.type === 'error') {
                  setResponse(`Error: ${data.error || data.message}`)
                  setStatusMessage('')
                }
              } catch (e) {
                console.error('Error parsing SSE data:', e)
              }
            }
          }
        }
      } else {
        // Fallback to non-streaming
      const res = await axios.post(`${apiUrl}/query`, {
          query: query,
          stream: false
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      })

      // Handle response data
      if (res.data.response) {
        setResponse(res.data.response)
      } else if (res.data.message) {
        setResponse(res.data.message)
      } else {
        setResponse('Response received')
      }
      
      // Update agent outputs if provided
      if (res.data.agent_outputs) {
        const outputs: any = {}
        if (res.data.agent_outputs.supervisor) outputs.supervisor = res.data.agent_outputs.supervisor
        if (res.data.agent_outputs.googleMap) outputs.googleMap = res.data.agent_outputs.googleMap
        if (res.data.agent_outputs.calendar) outputs.calendar = res.data.agent_outputs.calendar
        if (res.data.agent_outputs.telephone) outputs.telephone = res.data.agent_outputs.telephone
        if (res.data.agent_outputs.research) outputs.research = res.data.agent_outputs.research
        setAgentOutputs(outputs)
        }
      }
    } catch (error: any) {
      console.error('API Error:', error)
      
      // Better error handling
      let errorMessage = 'Failed to get response'
      
      if (error.code === 'ERR_NETWORK' || error.message?.includes('Network Error')) {
        errorMessage = 'Network Error: Cannot connect to backend server. Please make sure the backend is running on http://127.0.0.1:8000'
      } else if (error.response) {
        // Server responded with error status
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
    <main className={styles.main}>
      <div className={styles.container}>
        <header className={styles.header}>
          <h1 className={styles.title}>🧠 Google Intelligent Group</h1>
          <p className={styles.subtitle}>Multi-Agent System with LangChain 1.0 & Next.js</p>
        </header>

        <div className={styles.content}>
          <section className={styles.inputSection}>
            <form onSubmit={handleSubmit} className={styles.form}>
              <textarea
                className={styles.textarea}
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Enter your query... (e.g., Find a nice Italian restaurant near Taipei 101 and make a dinner reservation for tomorrow at 7 PM)"
                rows={4}
                disabled={loading}
              />
              <button
                type="submit"
                className={styles.button}
                disabled={loading || !query.trim()}
              >
                {loading ? '⏳ Processing...' : '🚀 Send Query'}
              </button>
            </form>
          </section>

          <section className={styles.responseSection}>
            <div className={styles.responseCard}>
              <h2 className={styles.cardTitle}>Supervisor Response</h2>
              {statusMessage && (
                <div className={styles.statusMessage}>
                  ⏳ {statusMessage}
                </div>
              )}
              <div className={`${styles.responseContent} ${loading ? styles.loading : ''}`}>
                {response || (loading ? (statusMessage || '⏳ Processing your query...') : '💬 No response yet')}
              </div>
            </div>
          </section>

          <section className={styles.dashboard}>
            <h2 className={styles.dashboardTitle}>Agent Dashboard</h2>
            <div className={styles.agentGrid}>
              <div className={styles.agentCard}>
                <h3 className={styles.agentTitle}>🗺️ GoogleMap Agent</h3>
              <div className={`${styles.agentOutput} ${loading && !agentOutputs.googleMap ? styles.loading : ''}`}>
                {agentOutputs.googleMap || '💭 Waiting for task...'}
              </div>
              </div>

              <div className={styles.agentCard}>
                <h3 className={styles.agentTitle}>📅 Calendar Agent</h3>
              <div className={`${styles.agentOutput} ${loading && !agentOutputs.calendar ? styles.loading : ''}`}>
                {agentOutputs.calendar || '💭 Waiting for task...'}
              </div>
              </div>

              <div className={styles.agentCard}>
                <h3 className={styles.agentTitle}>☎️ Telephone Agent</h3>
              <div className={`${styles.agentOutput} ${loading && !agentOutputs.telephone ? styles.loading : ''}`}>
                {agentOutputs.telephone || '💭 Waiting for task...'}
              </div>
              </div>

              <div className={styles.agentCard}>
                <h3 className={styles.agentTitle}>🔍 Research Agent</h3>
              <div className={`${styles.agentOutput} ${loading && !agentOutputs.research ? styles.loading : ''}`}>
                {agentOutputs.research || '💭 Waiting for task...'}
              </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </main>
  )
}

