/**
 * TypeScript types for the Multi-Agent System Frontend
 */

export type AgentType = 'supervisor' | 'googleMap' | 'calendar' | 'telephone' | 'research'

export interface AgentOutputs {
  supervisor: string
  googleMap: string
  calendar: string
  telephone: string
  research: string
}

export interface StreamData {
  type: 'status' | 'task' | 'agent_output' | 'complete' | 'error'
  message?: string
  agent?: AgentType | string
  output?: unknown
  response?: unknown
  agent_outputs?: Record<string, unknown>
  error?: unknown
}

export interface QueryResponse {
  response?: unknown
  message?: unknown
  agent_outputs?: Record<string, unknown>
}

export interface ApiError {
  code?: string
  message?: string
  response?: {
    data?: {
      detail?: string
      message?: string
    }
    status?: number
  }
}

