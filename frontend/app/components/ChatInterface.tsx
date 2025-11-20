'use client'

import { useState, FormEvent } from 'react'

interface ChatInterfaceProps {
  query: string
  onQueryChange: (query: string) => void
  onSubmit: (e?: FormEvent) => void
  loading: boolean
}

export default function ChatInterface({
  query,
  onQueryChange,
  onSubmit,
  loading
}: ChatInterfaceProps) {
  return (
    <section className="bg-white/95 backdrop-blur-xl rounded-2xl shadow-xl p-6 border border-purple-200/50">
      <form onSubmit={onSubmit} className="space-y-4">
        <label className="block text-gray-700 font-bold text-lg mb-3">Input</label>
        <div className="flex gap-3">
          <textarea
            className="flex-1 px-4 py-3 bg-white border-2 border-purple-300/50 rounded-xl focus:ring-2 focus:ring-purple-400 focus:border-purple-500 resize-none transition-all text-gray-800 placeholder-gray-400 text-sm shadow-inner"
            value={query}
            onChange={(e) => onQueryChange(e.target.value)}
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
  )
}

