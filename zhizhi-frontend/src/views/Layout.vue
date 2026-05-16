<template>
  <el-container class="layout-shell">
    <el-aside width="248px" class="sidebar">
      <div class="brand">
        <div class="brand-mark"><el-icon><Connection /></el-icon></div>
        <div>
          <div class="brand-name">智知 ZhiZhi</div>
          <div class="brand-subtitle">AI Knowledge Hub</div>
        </div>
      </div>

      <el-menu :default-active="activeMenu" router class="side-menu">
        <el-menu-item index="/knowledge">
          <el-icon><Document /></el-icon>
          <span>知识库</span>
        </el-menu-item>
        <el-menu-item index="/graph">
          <el-icon><Share /></el-icon>
          <span>知识图谱</span>
        </el-menu-item>
        <el-menu-item index="/chat">
          <el-icon><ChatDotRound /></el-icon>
          <span>AI 问答</span>
        </el-menu-item>
      </el-menu>

      <div class="side-panel">
        <div class="panel-label">系统能力</div>
        <div class="ability-row">
          <el-icon><Search /></el-icon>
          <span>全文检索</span>
        </div>
        <div class="ability-row">
          <el-icon><MagicStick /></el-icon>
          <span>AI 摘要与标签</span>
        </div>
        <div class="ability-row">
          <el-icon><Cpu /></el-icon>
          <span>RAG 知识问答</span>
        </div>
      </div>
    </el-aside>

    <el-container class="workspace">
      <el-header class="topbar">
        <div>
          <div class="page-kicker">个人知识管理系统</div>
          <h1>{{ pageTitle }}</h1>
        </div>
        <div class="topbar-actions">
          <el-button type="primary" icon="Plus" @click="router.push('/knowledge/new')">新建知识</el-button>
          <el-dropdown @command="handleCommand">
            <span class="user-info">
              <el-avatar :size="36" :src="userStore.avatar" icon="UserFilled" />
              <span>{{ userStore.username || '用户' }}</span>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="logout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>

      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '@/stores/user'
import { authApi } from '@/api/auth'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const activeMenu = computed(() => '/' + route.path.split('/')[1])
const pageTitle = computed(() => {
  const map = {
    knowledge: '知识库',
    graph: '知识图谱',
    chat: 'AI 问答'
  }
  return map[route.path.split('/')[1]] || '工作台'
})

async function handleCommand(cmd) {
  if (cmd === 'logout') {
    await ElMessageBox.confirm('确认退出登录？', '提示', { type: 'warning' })
    await authApi.logout()
    userStore.clear()
    ElMessage.success('已退出登录')
    router.push('/login')
  }
}
</script>

<style scoped>
.layout-shell {
  height: 100vh;
  background: #f4f6fb;
}

.sidebar {
  display: flex;
  flex-direction: column;
  border-right: 1px solid #e5e7eb;
  background: #101828;
  color: #fff;
}

.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 24px 20px;
}

.brand-mark {
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border-radius: 12px;
  background: #22c55e;
  color: #062f1a;
  font-size: 22px;
}

.brand-name {
  font-size: 18px;
  font-weight: 800;
  letter-spacing: 0;
}

.brand-subtitle {
  margin-top: 2px;
  color: #98a2b3;
  font-size: 12px;
}

.side-menu {
  flex: 1;
  border-right: none;
  background: transparent;
  padding: 4px 12px;
}

.side-menu :deep(.el-menu-item) {
  height: 44px;
  margin-bottom: 8px;
  border-radius: 8px;
  color: #cbd5e1;
}

.side-menu :deep(.el-menu-item:hover),
.side-menu :deep(.el-menu-item.is-active) {
  background: rgba(255, 255, 255, .1);
  color: #fff;
}

.side-panel {
  margin: 12px;
  padding: 14px;
  border: 1px solid rgba(255, 255, 255, .08);
  border-radius: 8px;
  background: rgba(255, 255, 255, .06);
}

.panel-label {
  margin-bottom: 10px;
  color: #98a2b3;
  font-size: 12px;
}

.ability-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 8px;
  color: #e5e7eb;
  font-size: 13px;
}

.workspace {
  min-width: 0;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 78px;
  padding: 0 28px;
  border-bottom: 1px solid #e5e7eb;
  background: rgba(255, 255, 255, .92);
  backdrop-filter: blur(16px);
}

.page-kicker {
  color: #667085;
  font-size: 12px;
}

.topbar h1 {
  margin: 4px 0 0;
  color: #101828;
  font-size: 22px;
  line-height: 1.2;
}

.topbar-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #344054;
  cursor: pointer;
}

.main {
  padding: 24px 28px 32px;
  overflow-y: auto;
}

@media (max-width: 900px) {
  .sidebar {
    width: 76px !important;
  }

  .brand > div:last-child,
  .side-menu :deep(.el-menu-item span),
  .side-panel {
    display: none;
  }

  .topbar {
    padding: 0 16px;
  }
}
</style>
