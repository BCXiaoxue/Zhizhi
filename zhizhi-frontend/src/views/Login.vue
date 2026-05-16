<template>
  <div class="auth-page">
    <section class="auth-intro">
      <div class="brand-mark"><el-icon><Connection /></el-icon></div>
      <h1>智知 ZhiZhi</h1>
      <p>把 Markdown 笔记、AI 摘要、标签体系和 RAG 问答收束到一个工作台里。</p>
      <div class="intro-grid">
        <span>全文检索</span>
        <span>知识图谱</span>
        <span>AI 问答</span>
      </div>
    </section>
    <el-card class="auth-card">
      <h2 class="auth-title">智知 ZhiZhi</h2>
      <p class="auth-sub">AI 驱动的个人知识管理系统</p>
      <el-form ref="formRef" :model="form" :rules="rules" label-position="top" @keyup.enter="submit">
        <el-form-item label="用户名" prop="username">
          <el-input v-model="form.username" placeholder="请输入用户名" prefix-icon="User" />
        </el-form-item>
        <el-form-item label="密码" prop="password">
          <el-input v-model="form.password" type="password" placeholder="请输入密码" prefix-icon="Lock" show-password />
        </el-form-item>
        <el-button type="primary" :loading="loading" style="width:100%" @click="submit">登录</el-button>
      </el-form>
      <p class="auth-footer">还没有账号？<router-link to="/register">立即注册</router-link></p>
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

const form = reactive({ username: '', password: '' })
const rules = {
  username: [{ required: true, message: '请输入用户名' }],
  password: [{ required: true, message: '请输入密码' }]
}

async function submit() {
  await formRef.value.validate()
  loading.value = true
  try {
    const res = await authApi.login(form)
    userStore.setUser(res.data)
    ElMessage.success('登录成功')
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
.auth-intro h1 { margin: 18px 0 10px; font-size: 42px; line-height: 1.1; }
.auth-intro p { margin: 0; color: #667085; font-size: 16px; line-height: 1.8; }
.intro-grid { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 22px; }
.intro-grid span { padding: 8px 12px; border: 1px solid #d0d5dd; border-radius: 8px; background: #fff; color: #344054; font-size: 13px; }
.auth-card { width: 420px; padding: 22px; border: 1px solid #e5e7eb; border-radius: 8px; box-shadow: 0 18px 50px rgba(16, 24, 40, .1); }
.auth-title { text-align: center; font-size: 28px; font-weight: bold; color: #101828; margin-bottom: 4px; }
.auth-sub { text-align: center; color: #667085; font-size: 14px; margin-bottom: 24px; }
.auth-footer { text-align: center; margin-top: 16px; color: #606266; font-size: 14px; }

@media (max-width: 860px) {
  .auth-page { grid-template-columns: 1fr; gap: 24px; }
  .auth-card { width: 100%; }
}
</style>
