<template>
  <el-row :gutter="18" class="chat-layout">
    <el-col :xs="24" :lg="6">
      <el-card class="session-card" shadow="never">
        <template #header>
          <div class="panel-header">
            <div>
              <strong>对话列表</strong>
              <span>基于知识库的 RAG 问答</span>
            </div>
            <el-button type="primary" size="small" icon="Plus" @click="newSession">新对话</el-button>
          </div>
        </template>
        <div class="session-list">
          <div
            v-for="s in sessions"
            :key="s.id"
            class="session-item"
            :class="{ active: currentSession?.id === s.id }"
            @click="selectSession(s)"
          >
            <span class="session-title">{{ s.title }}</span>
            <el-button size="small" text type="danger" icon="Delete" @click.stop="deleteSession(s.id)" />
          </div>
          <el-empty v-if="!sessions.length" description="暂无对话" :image-size="60" />
        </div>
      </el-card>
    </el-col>

    <el-col :xs="24" :lg="18">
      <el-card class="chat-card" shadow="never">
        <template #header>
          <div class="chat-header">
            <div>
              <strong>{{ currentSession?.title || '选择或新建对话' }}</strong>
              <span>AI 会优先参考已向量化的知识条目，并返回来源引用</span>
            </div>
            <el-tooltip content="批量向量化所有未向量化的知识条目">
              <el-button size="small" icon="Cpu" :loading="vectorizing" @click="vectorizeAll">批量向量化</el-button>
            </el-tooltip>
          </div>
        </template>

        <div ref="msgContainer" class="message-area">
          <el-empty v-if="!messages.length" description="开始提问，AI将基于您的知识库回答" />
          <div v-for="msg in messages" :key="msg.id" :class="['msg-row', msg.role]">
            <el-avatar :icon="msg.role === 'user' ? 'UserFilled' : 'Cpu'" :class="['msg-avatar', msg.role]" />
            <div class="msg-bubble">
              <div v-if="msg.role === 'assistant'" class="markdown-body" v-html="renderMd(msg.content)" />
              <div v-else>{{ msg.content }}</div>
              <!-- 来源引用 -->
              <div v-if="msg.sources && parseSources(msg.sources).length" class="sources">
                <span style="font-size:12px;color:#909399">参考来源：</span>
                <el-tag
                  v-for="sid in parseSources(msg.sources)"
                  :key="sid"
                  size="small"
                  type="info"
                  style="cursor:pointer;margin:2px"
                  @click="$router.push(`/knowledge/${sid}`)"
                >查看来源 #{{ sid }}</el-tag>
              </div>
            </div>
          </div>
          <!-- 流式输出中的消息 -->
          <div v-if="streaming" class="msg-row assistant">
            <el-avatar icon="Cpu" class="msg-avatar assistant" />
            <div class="msg-bubble">
              <div class="markdown-body" v-html="renderMd(streamingText)" />
              <span class="cursor-blink">|</span>
            </div>
          </div>
        </div>

        <div class="input-area">
          <el-input
            v-model="inputText"
            type="textarea"
            :autosize="{ minRows: 2, maxRows: 4 }"
            placeholder="输入问题，AI将基于您的知识库回答..."
            :disabled="streaming || !currentSession"
            @keydown.ctrl.enter="sendMessage"
          />
          <el-button
            type="primary"
            :loading="streaming"
            :disabled="!currentSession || !inputText.trim()"
            icon="Position"
            @click="sendMessage"
          >发送 (Ctrl+Enter)</el-button>
        </div>
      </el-card>
    </el-col>
  </el-row>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { marked } from 'marked'
import { aiApi, streamChat } from '@/api/ai'

const sessions = ref([])
const currentSession = ref(null)
const messages = ref([])
const inputText = ref('')
const streaming = ref(false)
const streamingText = ref('')
const vectorizing = ref(false)
const msgContainer = ref()

function renderMd(text) {
  return text ? marked.parse(text) : ''
}

function parseSources(sourcesStr) {
  if (!sourcesStr) return []
  try {
    return JSON.parse(sourcesStr)
  } catch {
    return []
  }
}

async function loadSessions() {
  const res = await aiApi.sessions()
  sessions.value = res.data
}

async function newSession() {
  const res = await aiApi.createSession('新对话')
  sessions.value.unshift(res.data)
  selectSession(res.data)
}

async function selectSession(session) {
  currentSession.value = session
  const res = await aiApi.messages(session.id)
  messages.value = res.data
  scrollToBottom()
}

async function deleteSession(id) {
  await ElMessageBox.confirm('确认删除该对话？', '提示', { type: 'warning' })
  await aiApi.deleteSession(id)
  sessions.value = sessions.value.filter(s => s.id !== id)
  if (currentSession.value?.id === id) {
    currentSession.value = null
    messages.value = []
  }
}

async function sendMessage() {
  if (!inputText.value.trim() || !currentSession.value || streaming.value) return
  const question = inputText.value.trim()
  inputText.value = ''

  messages.value.push({ role: 'user', content: question })
  streaming.value = true
  streamingText.value = ''
  scrollToBottom()

  streamChat(
    currentSession.value.id,
    question,
    (token) => {
      streamingText.value += token
      scrollToBottom()
    },
    async () => {
      const assistantContent = streamingText.value
      streaming.value = false
      streamingText.value = ''
      // 重新加载消息（获取含 sources 的完整记录）
      const res = await aiApi.messages(currentSession.value.id)
      messages.value = res.data
      scrollToBottom()
    },
    (err) => {
      streaming.value = false
      ElMessage.error('AI 回答出错，请重试')
      console.error(err)
    }
  )
}

async function vectorizeAll() {
  vectorizing.value = true
  try {
    await aiApi.vectorizeAll()
    ElMessage.success('批量向量化完成')
  } finally {
    vectorizing.value = false
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (msgContainer.value) {
      msgContainer.value.scrollTop = msgContainer.value.scrollHeight
    }
  })
}

onMounted(loadSessions)
</script>

<style scoped>
.chat-layout { height: calc(100vh - 134px); }
.session-card,
.chat-card {
  height: 100%;
  display: flex;
  flex-direction: column;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}
.panel-header,
.chat-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}
.panel-header strong,
.chat-header strong {
  display: block;
  color: #101828;
}
.panel-header span,
.chat-header span {
  display: block;
  margin-top: 3px;
  color: #667085;
  font-size: 12px;
}
.session-list { flex: 1; overflow-y: auto; }
.session-item { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px; border-radius: 8px; cursor: pointer; margin-bottom: 6px; color: #475467; }
.session-item:hover { background: #f9fafb; }
.session-item.active { background: #ecfdf3; color: #067647; }
.session-title { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: 14px; }
.message-area { flex: 1; overflow-y: auto; height: calc(100vh - 300px); padding: 10px 4px; }
.msg-row { display: flex; gap: 12px; margin-bottom: 16px; }
.msg-row.user { flex-direction: row-reverse; }
.msg-avatar { flex-shrink: 0; }
.msg-avatar.assistant { background: #2563eb; }
.msg-avatar.user { background: #16a34a; }
.msg-bubble { max-width: 75%; padding: 12px 14px; border-radius: 8px; line-height: 1.7; box-shadow: 0 8px 22px rgba(16, 24, 40, .06); }
.msg-row.user .msg-bubble { background: #eff6ff; color: #1e3a8a; }
.msg-row.assistant .msg-bubble { background: #fff; border: 1px solid #edf0f5; color: #344054; }
.sources { margin-top: 8px; border-top: 1px solid #eee; padding-top: 6px; }
.input-area { display: flex; gap: 12px; align-items: flex-end; margin-top: 12px; border-top: 1px solid #edf0f5; padding-top: 14px; }
.input-area .el-textarea { flex: 1; }
.cursor-blink { animation: blink 1s infinite; }
@keyframes blink { 0%,100% { opacity: 1 } 50% { opacity: 0 } }
.markdown-body :deep(pre) { background: #f6f8fa; padding: 10px; border-radius: 4px; overflow-x: auto; }
.markdown-body :deep(p) { margin: 6px 0; }
.markdown-body :deep(code) { font-family: monospace; background: rgba(0,0,0,0.05); padding: 1px 4px; border-radius: 3px; }

@media (max-width: 900px) {
  .chat-layout {
    height: auto;
  }

  .session-card {
    height: 280px;
    margin-bottom: 18px;
  }

  .chat-card {
    height: 620px;
  }
}
</style>
