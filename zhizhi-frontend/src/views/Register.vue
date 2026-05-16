<template>
  <div class="auth-page">
    <section class="auth-intro">
      <div class="brand-mark"><el-icon><Connection /></el-icon></div>
      <h1>建立你的知识工作台</h1>
      <p>注册后即可创建知识条目、组织分类标签，并让 AI 帮你摘要、推荐和检索。</p>
    </section>
    <el-card class="auth-card">
      <h2 class="auth-title">创建账号</h2>
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="2-20位字符" prefix-icon="User" />
        </el-form-item>
        <el-form-item label="邮箱（选填）" prop="email">
          <el-input v-model="form.email" placeholder="请输入邮箱" prefix-icon="Message" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" placeholder="6-30位" prefix-icon="Lock" show-password />
        </el-form-item>
        <el-button type="primary" :loading="loading" style="width:100%" @click="submit">注册</el-button>
      </el-form>
      <p class="auth-footer">已有账号？<router-link to="/login">立即登录</router-link></p>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { authApi } from '@/api/auth'
import { useUserStore } from '@/stores/user'

const router = useRouter()
const userStore = useUserStore()
const formRef = ref()
const loading = ref(false)

const form = reactive({ username: '', email: '', password: '' })
const rules = {
  username: [{ required: true, min: 2, max: 20, message: '用户名长度2-20位' }],
  password: [{ required: true, min: 6, max: 30, message: '密码长度6-30位' }]
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  try {
    const res = await authApi.register(form)
    userStore.setUser(res.data)
    ElMessage.success('注册成功，已自动登录')
    router.push('/')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.auth-page { min-height: 100vh; display: grid; grid-template-columns: minmax(320px, 520px) 420px; align-items: center; justify-content: center; gap: 48px; padding: 32px; background: #f4f6fb; }
.auth-intro { color: #101828; }
.brand-mark { display: grid; place-items: center; width: 56px; height: 56px; border-radius: 14px; background: #101828; color: #22c55e; font-size: 28px; }
.auth-intro h1 { margin: 18px 0 10px; font-size: 40px; line-height: 1.1; }
.auth-intro p { margin: 0; color: #667085; font-size: 16px; line-height: 1.8; }
.auth-card { width: 420px; padding: 22px; border: 1px solid #e5e7eb; border-radius: 8px; box-shadow: 0 18px 50px rgba(16, 24, 40, .1); }
.auth-title { text-align: center; font-size: 24px; font-weight: bold; color: #101828; margin-bottom: 24px; }
.auth-footer { text-align: center; margin-top: 16px; color: #606266; font-size: 14px; }

@media (max-width: 860px) {
  .auth-page { grid-template-columns: 1fr; gap: 24px; }
  .auth-card { width: 100%; }
}
</style>
