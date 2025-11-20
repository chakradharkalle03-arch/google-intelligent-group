/**
 * Helper function to safely extract text from various data types
 * This is a temporary solution until the backend API is standardized
 */

export function extractText(value: unknown): string {
  if (typeof value === 'string') return value
  if (typeof value === 'number' || typeof value === 'boolean') return String(value)
  if (value === null || value === undefined) return ''
  
  if (Array.isArray(value)) {
    return value.map(item => extractText(item)).join('\n')
  }
  
  if (typeof value === 'object') {
    const obj = value as Record<string, unknown>
    
    // Handle LangChain message objects
    if (obj.text) return extractText(obj.text)
    if (obj.content) return extractText(obj.content)
    if (obj.message) return extractText(obj.message)
    if (obj.formatted) return extractText(obj.formatted)
    if (obj.result) return extractText(obj.result)
    
    // Try to stringify if it's a complex object
    try {
      return JSON.stringify(value, null, 2)
    } catch {
      return String(value)
    }
  }
  
  return String(value)
}

