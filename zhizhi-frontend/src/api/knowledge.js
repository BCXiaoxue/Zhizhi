import request from './request'

export const knowledgeApi = {
  list: (params) => request.get('/knowledge', { params }),
  search: (q) => request.get('/knowledge/search', { params: { q } }),
  detail: (id) => request.get(`/knowledge/${id}`),
  create: (data) => request.post('/knowledge', data),
  update: (id, data) => request.put(`/knowledge/${id}`, data),
  remove: (id) => request.delete(`/knowledge/${id}`),
  importFile: (file) => {
    const form = new FormData()
    form.append('file', file)
    return request.post('/knowledge/import', form)
  }
}

export const categoryApi = {
  tree: () => request.get('/categories'),
  create: (data) => request.post('/categories', data),
  update: (id, data) => request.put(`/categories/${id}`, data),
  remove: (id) => request.delete(`/categories/${id}`)
}

export const tagApi = {
  list: () => request.get('/tags'),
  remove: (id) => request.delete(`/tags/${id}`)
}
