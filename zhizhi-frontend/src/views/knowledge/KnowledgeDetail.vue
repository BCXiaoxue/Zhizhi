<template>
  <div v-if="knowledge">
    <el-page-header @back="$router.push('/knowledge')" :content="knowledge.title" />
    <el-card style="margin-top:16px">
      <template #header>
        <div style="display:flex;align-items:center;gap:12px;flex-wrap:wrap">
          <el-tag v-if="knowledge.categoryName" type="success">{{ knowledge.categoryName }}</el-tag>
          <el-tag v-for="tag in knowledge.tags" :key="tag" size="small">{{ tag }}</el-tag>
          <span style="flex:1" />
          <el-button size="small" icon="Edit" @click="$router.push(`/knowledge/${id}/edit`)">编辑</el-button>
          <el-button size="small" :loading="summaryLoading" @click="genSummary">AI 生成摘要</el-button>
          <el-button size="small" :loading="tagsLoading" @click="genTags">AI 推荐标签</el-button>
          <el-button size="small" :loading="vectorLoading" @click="vectorize">向量化</el-button>
        </div>
      </template>

      <!-- AI 摘要 -->
      <el-alert v-if="knowledge.summary" :title="knowledge.summary" type="info" :closable="false" style="margin-bottom:16px" show-icon>
        <template #title><b>摘要：</b>{{ knowledge.summary }}</template>
      </el-alert>

      <!-- Markdown 渲染 -->
      <div class="markdown-body" v-html="renderedContent" />

      <!-- 元信息 -->
      <el-divider />
      <div style="color:#909399;font-size:12px">
        创建时间：{{ formatDate(knowledge.createdAt) }} &nbsp;|&nbsp;
        更新时间：{{ formatDate(knowledge.updatedAt) }} &nbsp;|&nbsp;
        浏览次数：{{ knowledge.viewCount }}
      </div>
    </el-card>
  </div>
  <el-skeleton v-else :rows="8" animated />

  <!-- AI 推荐标签确认弹窗 -->
  <el-dialog v-model="showTagsDialog" title="AI 推荐标签" width="400px">
    <el-tag v-for="tag in recommendedTags" :key="tag" style="margin:4px">{{ tag }}</el-tag>
    <template #footer>
      <el-button @click="showTagsDialog = false">关闭</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { marked } from 'marked'
import hljs from 'highlight.js'
import 'highlight.js/styles/github.css'
import { knowledgeApi } from '@/api/knowledge'
import { aiApi } from '@/api/ai'

marked.setOptions({
  highlight: (code, lang) => {
    return lang && hljs.getLanguage(lang)
      ? hljs.highlight(code, { language: lang }).value
      : hljs.highlightAuto(code).value
  }
})

const route = useRoute()
const id = route.params.id
const knowledge = ref(null)
const summaryLoading = ref(false)
const tagsLoading = ref(false)
const vectorLoading = ref(false)
const showTagsDialog = ref(false)
const recommendedTags = ref([])

const renderedContent = computed(() => {
  if (!knowledge.value?.content) return ''
  return marked.parse(knowledge.value.content)
})

async function load() {
  const res = await knowledgeApi.detail(id)
  const data = res.data
  // 处理后端 GROUP_CONCAT 返回的 tags 字符串
  if (typeof data.tags === 'string') {
    data.tags = data.tags ? data.tags.split(',') : []
  }
  knowledge.value = data
}

async function genSummary() {
  summaryLoading.value = true
  try {
    const res = await aiApi.summary(id)
    knowledge.value.summary = res.data
    ElMessage.success('摘要生成成功')
  } finally {
    summaryLoading.value = false
  }
}

async function genTags() {
  tagsLoading.value = true
  try {
    const res = await aiApi.recommendTags(id)
    recommendedTags.value = res.data
    showTagsDialog.value = true
  } finally {
    tagsLoading.value = false
  }
}

async function vectorize() {
  vectorLoading.value = true
  try {
    await aiApi.vectorize(id)
    knowledge.value.isVectorized = 1
    ElMessage.success('向量化成功，现在可以通过 AI 问答检索此条目')
  } finally {
    vectorLoading.value = false
  }
}

function formatDate(str) {
  return str ? str.substring(0, 16).replace('T', ' ') : ''
}

onMounted(load)
</script>

<style scoped>
.markdown-body { line-height: 1.8; }
.markdown-body :deep(h1), .markdown-body :deep(h2), .markdown-body :deep(h3) { margin-top: 16px; }
.markdown-body :deep(pre) { background: #f6f8fa; padding: 16px; border-radius: 6px; overflow-x: auto; }
.markdown-body :deep(code) { font-family: 'Fira Code', monospace; font-size: 13px; }
.markdown-body :deep(blockquote) { border-left: 4px solid #dfe2e5; margin: 0; padding-left: 16px; color: #6a737d; }
.markdown-body :deep(table) { border-collapse: collapse; width: 100%; }
.markdown-body :deep(td), .markdown-body :deep(th) { border: 1px solid #dfe2e5; padding: 8px 12px; }
</style>
