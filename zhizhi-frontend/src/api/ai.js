import request from './request'
import { useUserStore } from '@/stores/user'

export const aiApi = {
  createSession: (title) => request.post('/ai/sessions', { title }),
  sessions: () => request.get('/ai/sessions'),
  messages: (sessionId) => request.get(`/ai/sessions/${sessionId}/messages`),
  deleteSession: (sessionId) => request.delete(`/ai/sessions/${sessionId}`),
  vectorize: (knowledgeId) => request.post(`/ai/vectorize/${knowledgeId}`),
  vectorizeAll: () => request.post('/ai/vectorize-all'),
  summary: (knowledgeId) => request.post(`/ai/summary/${knowledgeId}`),
  recommendTags: (knowledgeId) => request.post(`/ai/recommend-tags/${knowledgeId}`),
}

// SSE 流式聊天，返回 EventSource-like 的 ReadableStream
export function streamChat(sessionId, question, onToken, onDone, onError) {
  const userStore = useUserStore()
  const url = `/api/ai/chat?sessionId=${sessionId}&question=${encodeURIComponent(question)}`

  fetch(url, {
    headers: { Authorization: `Bearer ${userStore.token}` }
  }).then(async res => {
    if (!res.ok) { onError(new Error('请求失败')); return }
    const reader = res.body.getReader()
    const decoder = new TextDecoder()
    while (true) {
      const { done, value } = await reader.read()
      if (done) { onDone(); break }
      const chunk = decoder.decode(value)
      chunk.split('\n').forEach(line => {
        if (line.startsWith('data:')) {
          const token = line.slice(5).trim()
          if (token && token !== '[DONE]') onToken(token)
          if (token === '[DONE]') onDone()
        }
      })
    }
  }).catch(onError)
}
