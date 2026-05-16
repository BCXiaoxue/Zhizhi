import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/stores/user'
import router from '@/router'

const request = axios.create({
  baseURL: '/api',
  timeout: 30000
})

request.interceptors.request.use(config => {
  const userStore = useUserStore()
  if (userStore.token) {
    config.headers.Authorization = `Bearer ${userStore.token}`
  }
  return config
})

request.interceptors.response.use(
  res => {
    const data = res.data
    if (data.code === 200) return data
    ElMessage.error(data.message || '请求失败')
    return Promise.reject(new Error(data.message))
  },
  err => {
    if (err.response?.status === 401) {
      useUserStore().clear()
      router.push('/login')
      ElMessage.error('请先登录')
    } else if (err.response?.status === 403) {
      ElMessage.error('无权限访问')
    } else {
      ElMessage.error(err.response?.data?.message || '网络异常')
    }
    return Promise.reject(err)
  }
)

export default request
