'use client'

import { useState, useCallback } from 'react'
import { extractText } from '../utils/extractText'
import { AgentOutputs, StreamData, QueryResponse, ApiError } from '../types'
import axios from 'axios'

const INITIAL_OUTPUTS: AgentOutputs = {
  supervisor: '',
  googleMap: '',
  calendar: '',
  telephone: '',
  research: ''
}

export function useQueryStream() {
  const [response, setResponse] = useState('')
  const [loading, setLoading] = useState(false)
  const [statusMessage, setStatusMessage] = useState('')
  const [agentOutputs, setAgentOutputs] = useState<AgentOutputs>(INITIAL_OUTPUTS)

  const processStreamData = useCallback((data: StreamData) => {
    if (data.type === 'status' || data.type === 'task') {
      setStatusMessage(data.message || '')
      if (data.agent === 'supervisor') {
        setAgentOutputs(prev => ({
          ...prev,
          supervisor: data.message || ''
        }))
      }
    } else if (data.type === 'agent_output') {
      const agentKey = data.agent === 'googleMap' ? 'googleMap' : 
                      data.agent === 'calendar' ? 'calendar' :
                      data.agent === 'telephone' ? 'telephone' :
                      data.agent === 'research' ? 'research' : data.agent as keyof AgentOutputs
      
      const outputText = extractText(data.output)
      
      setAgentOutputs(prev => ({
        ...prev,
        [agentKey]: outputText
      }))
    } else if (data.type === 'complete') {
      const supervisorResponse = extractText(data.response || '')
      setResponse(supervisorResponse)
      
      if (data.agent_outputs) {
        const safeOutputs: Partial<AgentOutputs> = {}
        for (const [key, value] of Object.entries(data.agent_outputs)) {
          if (key in INITIAL_OUTPUTS) {
            safeOutputs[key as keyof AgentOutputs] = extractText(value)
          }
        }
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
  }, [])

  const handleError = useCallback((error: unknown) => {
    const apiError = error as ApiError
    let errorMessage = 'Failed to get response'
    
    if (apiError.code === 'ERR_NETWORK' || apiError.message?.includes('Network Error')) {
      errorMessage = 'Network Error: Cannot connect to backend server. Please make sure the backend is running on http://127.0.0.1:8080'
    } else if (apiError.response) {
      errorMessage = apiError.response.data?.detail || 
                    apiError.response.data?.message || 
                    `Server error: ${apiError.response.status}`
    } else if (apiError.message) {
      errorMessage = apiError.message
    }
    
    setResponse(`Error: ${errorMessage}`)
    setStatusMessage('')
  }, [])

  const submitQuery = useCallback(async (query: string, useStreaming = true) => {
    if (!query.trim()) return

    setLoading(true)
    setResponse('')
    setStatusMessage('')
    setAgentOutputs(INITIAL_OUTPUTS)

    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://127.0.0.1:8080'
      
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
                const data: StreamData = JSON.parse(line.slice(6))
                processStreamData(data)
              } catch (e) {
                console.error('Error parsing SSE data:', e)
              }
            }
          }
        }
      } else {
        const res = await axios.post<QueryResponse>(`${apiUrl}/query`, {
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
          const outputs: Partial<AgentOutputs> = {}
          if (res.data.agent_outputs.supervisor) outputs.supervisor = extractText(res.data.agent_outputs.supervisor)
          if (res.data.agent_outputs.googleMap) outputs.googleMap = extractText(res.data.agent_outputs.googleMap)
          if (res.data.agent_outputs.calendar) outputs.calendar = extractText(res.data.agent_outputs.calendar)
          if (res.data.agent_outputs.telephone) outputs.telephone = extractText(res.data.agent_outputs.telephone)
          if (res.data.agent_outputs.research) outputs.research = extractText(res.data.agent_outputs.research)
          setAgentOutputs(prev => ({ ...prev, ...outputs }))
        }
      }
    } catch (error) {
      console.error('API Error:', error)
      handleError(error)
    } finally {
      setLoading(false)
      setStatusMessage('')
    }
  }, [processStreamData, handleError])

  return {
    response,
    loading,
    statusMessage,
    agentOutputs,
    submitQuery
  }
}

