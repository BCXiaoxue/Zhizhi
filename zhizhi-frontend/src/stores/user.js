import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(null)
  const userId = ref(null)
  const username = ref(null)
  const role = ref(0)
  const avatar = ref(null)

  function setUser(data) {
    token.value = data.token
    userId.value = data.userId
    username.value = data.username
    role.value = data.role
    avatar.value = data.avatar
  }

  function clear() {
    token.value = null
    userId.value = null
    username.value = null
    role.value = 0
    avatar.value = null
  }

  const isAdmin = () => role.value === 1

  return { token, userId, username, role, avatar, setUser, clear, isAdmin }
}, {
  persist: true
})
