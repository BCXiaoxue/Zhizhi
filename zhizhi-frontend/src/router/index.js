import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/user'

const routes = [
  { path: '/login', name: 'Login', component: () => import('@/views/Login.vue'), meta: { guest: true } },
  { path: '/register', name: 'Register', component: () => import('@/views/Register.vue'), meta: { guest: true } },
  {
    path: '/',
    component: () => import('@/views/Layout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/knowledge' },
      { path: 'knowledge', name: 'KnowledgeList', component: () => import('@/views/knowledge/KnowledgeList.vue') },
      { path: 'knowledge/new', name: 'KnowledgeNew', component: () => import('@/views/knowledge/KnowledgeEdit.vue') },
      { path: 'knowledge/:id', name: 'KnowledgeDetail', component: () => import('@/views/knowledge/KnowledgeDetail.vue') },
      { path: 'knowledge/:id/edit', name: 'KnowledgeEdit', component: () => import('@/views/knowledge/KnowledgeEdit.vue') },
      { path: 'graph', name: 'KnowledgeGraph', component: () => import('@/views/knowledge/KnowledgeGraph.vue') },
      { path: 'chat', name: 'Chat', component: () => import('@/views/ai/ChatView.vue') },
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/' }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to) => {
  const userStore = useUserStore()
  if (to.meta.requiresAuth && !userStore.token) return '/login'
  if (to.meta.guest && userStore.token) return '/'
})

export default router
