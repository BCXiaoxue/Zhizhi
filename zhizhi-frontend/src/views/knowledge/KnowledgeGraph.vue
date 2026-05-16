<template>
  <div class="graph-page">
    <section class="graph-hero">
      <div>
        <div class="eyebrow">Knowledge Graph</div>
        <h2>把开发与 AI 知识串成可探索的技术地图</h2>
        <p>基于 SQL 示例中的分类、标签与知识条目，抽取 Spring、Vue、数据库、RAG、LLM、Agent 等主题关系。</p>
      </div>
      <div class="hero-actions">
        <el-segmented v-model="activeDomain" :options="domainOptions" />
        <el-button icon="Refresh" @click="loadRuntimeData">刷新数据</el-button>
      </div>
    </section>

    <el-row :gutter="18" class="metric-row">
      <el-col v-for="metric in metrics" :key="metric.label" :xs="12" :md="6">
        <el-card shadow="never" class="metric-card">
          <div class="metric-icon"><el-icon><component :is="metric.icon" /></el-icon></div>
          <div>
            <div class="metric-value">{{ metric.value }}</div>
            <div class="metric-label">{{ metric.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never" class="matrix-card">
      <template #header>
        <div class="card-header">
          <div>
            <strong>功能矩阵</strong>
            <span>按图书管理系统的层级数量映射到知识管理场景，共 {{ functionCount }} 个具体功能点</span>
          </div>
          <el-tag type="primary" effect="plain">约等于示例图 13 项</el-tag>
        </div>
      </template>
      <div class="function-matrix">
        <section v-for="group in functionGroups" :key="group.title" class="function-group">
          <div class="group-title">
            <el-icon><component :is="group.icon" /></el-icon>
            <span>{{ group.title }}</span>
          </div>
          <div class="function-list">
            <button
              v-for="item in group.items"
              :key="item.title"
              class="function-item"
              type="button"
              @click="openFunction(item.path)"
            >
              <span>{{ item.title }}</span>
              <small>{{ item.desc }}</small>
            </button>
          </div>
        </section>
      </div>
    </el-card>

    <el-row :gutter="18">
      <el-col :xs="24" :lg="17">
        <el-card shadow="never" class="graph-card">
          <template #header>
            <div class="card-header">
              <div>
                <strong>主题关系图</strong>
                <span>点击节点查看关联知识与建议动作</span>
              </div>
              <el-tag type="success" effect="plain">{{ filteredNodes.length }} 个节点</el-tag>
            </div>
          </template>

          <div class="graph-canvas">
            <svg viewBox="0 0 860 520" role="img" aria-label="知识图谱">
              <line
                v-for="edge in filteredEdges"
                :key="`${edge.from}-${edge.to}`"
                :x1="nodeMap[edge.from]?.x"
                :y1="nodeMap[edge.from]?.y"
                :x2="nodeMap[edge.to]?.x"
                :y2="nodeMap[edge.to]?.y"
                class="graph-edge"
                :class="{ active: isEdgeActive(edge) }"
              />
              <g
                v-for="node in filteredNodes"
                :key="node.id"
                class="graph-node"
                :class="[node.type, { active: selectedNode.id === node.id }]"
                :transform="`translate(${node.x}, ${node.y})`"
                @click="selectedNode = node"
              >
                <circle :r="node.size" />
                <text text-anchor="middle" dominant-baseline="middle">{{ node.label }}</text>
              </g>
            </svg>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :lg="7">
        <el-card shadow="never" class="detail-card">
          <template #header>
            <div class="card-header">
              <div>
                <strong>{{ selectedNode.label }}</strong>
                <span>{{ selectedNode.group }}</span>
              </div>
              <el-tag :type="selectedNode.type === 'ai' ? 'warning' : 'primary'" effect="plain">{{ selectedNode.typeLabel }}</el-tag>
            </div>
          </template>

          <p class="node-summary">{{ selectedNode.summary }}</p>
          <div class="section-title">关联知识</div>
          <div class="related-list">
            <div v-for="item in selectedNode.items" :key="item.title" class="related-item">
              <el-icon><Document /></el-icon>
              <span>{{ item.title }}</span>
              <el-button v-if="item.id" text size="small" icon="View" @click="$router.push(`/knowledge/${item.id}`)" />
            </div>
          </div>

          <div class="section-title">推荐动作</div>
          <div class="action-list">
            <el-button v-for="action in selectedNode.actions" :key="action" plain @click="runAction(action)">{{ action }}</el-button>
          </div>
        </el-card>

        <el-card shadow="never" class="flow-card">
          <template #header>
            <div class="card-header">
              <div>
                <strong>新增功能流</strong>
                <span>参考图书管理流程改造为知识管理</span>
              </div>
            </div>
          </template>
          <el-timeline>
            <el-timeline-item v-for="flow in flows" :key="flow.title" :type="flow.type" :timestamp="flow.stage">
              <div class="flow-title">{{ flow.title }}</div>
              <div class="flow-desc">{{ flow.desc }}</div>
            </el-timeline-item>
          </el-timeline>
        </el-card>
      </el-col>
    </el-row>

    <el-dialog v-model="actionDialog.visible" :title="actionDialog.title" width="560px">
      <div class="action-dialog">
        <p>{{ actionDialog.desc }}</p>
        <el-timeline v-if="actionDialog.steps.length">
          <el-timeline-item v-for="step in actionDialog.steps" :key="step" type="success">
            {{ step }}
          </el-timeline-item>
        </el-timeline>
      </div>
      <template #footer>
        <el-button @click="actionDialog.visible = false">关闭</el-button>
        <el-button type="primary" @click="router.push(actionDialog.path)">打开相关页面</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { categoryApi, knowledgeApi, tagApi } from '@/api/knowledge'

const router = useRouter()
const activeDomain = ref('全部')
const runtime = ref({ categories: 12, tags: 24, knowledge: 18 })
const actionDialog = reactive({
  visible: false,
  title: '',
  desc: '',
  path: '/knowledge',
  steps: []
})

const nodes = [
  {
    id: 'dev',
    label: '开发体系',
    group: '核心域',
    type: 'core',
    typeLabel: '中枢',
    x: 430,
    y: 250,
    size: 58,
    summary: '串联前端、后端、数据库与工程化知识，是知识库的主干。',
    items: [{ id: 1, title: 'Spring Boot 3 快速入门' }, { id: 5, title: 'Vue 3 Composition API 核心用法' }],
    actions: ['查看路径', '生成学习计划', '同步标签']
  },
  {
    id: 'spring',
    label: 'Spring',
    group: 'Java 开发',
    type: 'backend',
    typeLabel: '后端',
    x: 250,
    y: 150,
    size: 44,
    summary: '包含 Spring Boot、Spring Security、Spring Cloud、Gateway 与 Spring AI。',
    items: [{ id: 1, title: 'Spring Boot 3 快速入门' }, { id: 3, title: 'Spring Security + JWT 实现无状态鉴权' }, { id: 18, title: 'Spring Cloud Gateway 网关配置实践' }],
    actions: ['打开后端专题', '检索 Spring 知识', '补充代码片段']
  },
  {
    id: 'vue',
    label: 'Vue 3',
    group: '前端开发',
    type: 'frontend',
    typeLabel: '前端',
    x: 210,
    y: 360,
    size: 40,
    summary: '面向 Composition API、TypeScript、状态管理和管理端交互体验。',
    items: [{ id: 5, title: 'Vue 3 Composition API 核心用法' }, { id: 16, title: 'TypeScript 核心类型系统速查' }],
    actions: ['查看前端专题', '生成组件清单', '创建 UI 任务']
  },
  {
    id: 'db',
    label: '数据库',
    group: '数据层',
    type: 'data',
    typeLabel: '数据',
    x: 430,
    y: 95,
    size: 42,
    summary: '覆盖 MySQL、Redis、全文索引与向量化检索，为 RAG 提供底座。',
    items: [{ id: 6, title: 'MySQL 索引原理与优化实践' }, { id: 7, title: 'Redis 缓存设计与实战' }],
    actions: ['检查索引', '标记向量化', '整理数据模型']
  },
  {
    id: 'rag',
    label: 'RAG',
    group: '人工智能',
    type: 'ai',
    typeLabel: 'AI',
    x: 615,
    y: 150,
    size: 45,
    summary: '将检索、向量数据库、Prompt 与大模型问答串成可落地的知识增强链路。',
    items: [{ id: 4, title: 'RAG（检索增强生成）技术详解' }, { id: 14, title: 'Prompt Engineering 实战技巧' }],
    actions: ['批量向量化', '测试召回效果', '优化 Prompt']
  },
  {
    id: 'agent',
    label: 'Agent',
    group: '人工智能',
    type: 'ai',
    typeLabel: 'AI',
    x: 655,
    y: 350,
    size: 43,
    summary: '面向工具调用、ReAct、多 Agent 协作与知识助手自动化。',
    items: [{ id: 15, title: 'AI Agent 自主智能体架构设计' }],
    actions: ['设计工具列表', '新增执行记录', '生成调试链路']
  },
  {
    id: 'ops',
    label: '工程部署',
    group: 'DevOps',
    type: 'ops',
    typeLabel: '运维',
    x: 430,
    y: 430,
    size: 40,
    summary: '包括 Docker、Kubernetes、网关与发布策略，让知识系统具备工程闭环。',
    items: [{ id: 9, title: 'Docker 容器化部署实战' }, { id: 17, title: 'Kubernetes 入门与核心概念' }],
    actions: ['生成部署清单', '检查服务依赖', '记录发布经验']
  }
]

const edges = [
  { from: 'dev', to: 'spring' },
  { from: 'dev', to: 'vue' },
  { from: 'dev', to: 'db' },
  { from: 'dev', to: 'rag' },
  { from: 'dev', to: 'agent' },
  { from: 'dev', to: 'ops' },
  { from: 'spring', to: 'db' },
  { from: 'spring', to: 'rag' },
  { from: 'rag', to: 'agent' },
  { from: 'db', to: 'rag' },
  { from: 'ops', to: 'spring' },
  { from: 'ops', to: 'agent' }
]

const flows = [
  { stage: '推荐', title: '新知推荐', desc: '按标签热度和向量化状态推荐下一篇要补齐的知识。', type: 'primary' },
  { stage: '借阅', title: '知识借阅', desc: '把图书借阅改造成“暂存学习”，记录当前阅读与复习队列。', type: 'success' },
  { stage: '归还', title: '学习归档', desc: '完成阅读后归档为已掌握，并沉淀摘要、标签和相关问题。', type: 'warning' },
  { stage: '记录', title: '学习记录', desc: '追踪检索、问答、编辑、向量化等关键操作，形成知识成长轨迹。', type: 'info' }
]

const functionGroups = [
  {
    title: '用户入口',
    icon: 'UserFilled',
    items: [
      { title: '用户登录', desc: '账号登录进入工作台', path: '/login' },
      { title: '用户注册', desc: '创建新账号', path: '/register' },
      { title: '退出登录', desc: '清理会话与令牌' }
    ]
  },
  {
    title: '新知推荐',
    icon: 'Star',
    items: [
      { title: '查询知识', desc: '搜索标题、正文和标签', path: '/knowledge' },
      { title: '图谱推荐', desc: '按技术路径发现主题', path: '/graph' }
    ]
  },
  {
    title: '知识管理',
    icon: 'Document',
    items: [
      { title: '新增知识', desc: '创建 Markdown 条目', path: '/knowledge/new' },
      { title: '编辑知识', desc: '维护正文、分类、标签', path: '/knowledge' },
      { title: '导入文件', desc: '导入 txt 或 md 文档', path: '/knowledge' },
      { title: '分类管理', desc: '新增与删除分类节点', path: '/knowledge' }
    ]
  },
  {
    title: 'AI 借阅',
    icon: 'Cpu',
    items: [
      { title: '当前问答', desc: '基于知识库提问', path: '/chat' },
      { title: '向量化知识', desc: '加入 RAG 检索范围', path: '/chat' },
      { title: '来源引用', desc: '回看回答依据条目', path: '/chat' }
    ]
  },
  {
    title: '记录追踪',
    icon: 'Tickets',
    items: [
      { title: '会话记录', desc: '查看历史 AI 对话', path: '/chat' },
      { title: '知识详情', desc: '查看摘要、标签、浏览量', path: '/knowledge' }
    ]
  }
]

const selectedNode = ref(nodes[0])
const domainOptions = ['全部', '后端', '前端', 'AI', '数据', '运维']

const functionCount = computed(() => functionGroups.reduce((total, group) => total + group.items.length, 0))
const nodeMap = computed(() => Object.fromEntries(filteredNodes.value.map(node => [node.id, node])))
const filteredNodes = computed(() => {
  if (activeDomain.value === '全部') return nodes
  return nodes.filter(node => node.typeLabel === activeDomain.value || node.type === 'core')
})
const filteredEdges = computed(() => edges.filter(edge => nodeMap.value[edge.from] && nodeMap.value[edge.to]))
const metrics = computed(() => [
  { label: '知识条目', value: runtime.value.knowledge, icon: 'Document' },
  { label: '分类节点', value: runtime.value.categories, icon: 'FolderOpened' },
  { label: '标签实体', value: runtime.value.tags, icon: 'PriceTag' },
  { label: '图谱关系', value: edges.length, icon: 'Share' }
])

function isEdgeActive(edge) {
  return selectedNode.value.id === edge.from || selectedNode.value.id === edge.to
}

function openFunction(path) {
  if (path) router.push(path)
}

function runAction(action) {
  const actionMap = {
    查看路径: {
      title: '开发体系学习路径',
      desc: '从基础开发知识进入工程化，再连接 RAG 与 Agent，适合按专题补齐知识库。',
      path: '/graph',
      steps: ['Spring Boot / Vue 3 基础入门', 'MySQL / Redis 数据层能力', 'RAG 检索增强与向量化', 'AI Agent 工具调用与自动化']
    },
    生成学习计划: {
      title: '学习计划',
      desc: `已基于“${selectedNode.value.label}”生成一个轻量计划，后续可以接入 AI 接口生成个性化版本。`,
      path: '/knowledge',
      steps: selectedNode.value.items.map(item => `复习：${item.title}`).concat(['整理摘要与标签', '向量化后用 AI 问答自测'])
    },
    同步标签: {
      title: '同步标签',
      desc: '演示版会提示同步结果，正式版可调用标签接口批量补齐主题标签。',
      path: '/knowledge',
      steps: [`识别主题：${selectedNode.value.label}`, `关联领域：${selectedNode.value.group}`, '同步到知识条目标签']
    },
    '打开后端专题': {
      title: '后端专题',
      desc: '聚合 Spring、JWT、Gateway、MyBatis 等后端知识。',
      path: '/knowledge',
      steps: ['筛选 Java / Spring 标签', '查看关联条目', '补充工程实践案例']
    },
    '检索 Spring 知识': {
      title: 'Spring 知识检索',
      desc: '跳转到知识库后可继续使用搜索框检索 Spring 相关内容。',
      path: '/knowledge',
      steps: ['输入 Spring', '查看分类结果', '进入详情阅读']
    },
    '补充代码片段': {
      title: '补充代码片段',
      desc: '建议进入知识编辑页，为当前主题补充可运行代码片段。',
      path: '/knowledge/new',
      steps: ['创建知识条目', '粘贴代码示例', '添加 Spring / Java 标签']
    },
    '查看前端专题': {
      title: '前端专题',
      desc: '聚合 Vue 3、TypeScript、组件设计与后台交互经验。',
      path: '/knowledge',
      steps: ['筛选前端标签', '阅读 Vue 3 条目', '补齐组件实践']
    },
    '生成组件清单': {
      title: '组件清单',
      desc: '根据当前前端主题生成可建设的组件清单。',
      path: '/knowledge/new',
      steps: ['搜索表单', '知识卡片', '图谱节点', 'AI 问答输入框']
    },
    '创建 UI 任务': {
      title: 'UI 任务',
      desc: '可将当前图谱主题转化为待办式 UI 改造任务。',
      path: '/knowledge/new',
      steps: ['定义页面目标', '拆分组件', '补充交互状态', '记录验收标准']
    },
    检查索引: {
      title: '索引检查',
      desc: '对应 SQL 中全文索引、分类索引和用户索引的检查建议。',
      path: '/knowledge',
      steps: ['检查 FULLTEXT title/content', '检查 category_id 查询', '评估标签关联表查询']
    },
    标记向量化: {
      title: '标记向量化',
      desc: '可进入 AI 问答页执行批量向量化，让知识进入 RAG 检索范围。',
      path: '/chat',
      steps: ['打开 AI 问答', '点击批量向量化', '用问题验证召回效果']
    },
    '整理数据模型': {
      title: '数据模型整理',
      desc: '围绕 user、category、knowledge、tag、chat_session、chat_message 形成模型说明。',
      path: '/knowledge/new',
      steps: ['梳理实体表', '梳理关联表', '补充典型查询', '沉淀 ER 说明']
    },
    批量向量化: {
      title: '批量向量化',
      desc: '跳转到 AI 问答页后，可使用现有批量向量化按钮。',
      path: '/chat',
      steps: ['检查未向量化条目', '批量写入向量库', '进行 RAG 问答测试']
    },
    '测试召回效果': {
      title: '召回测试',
      desc: '用固定问题验证 RAG 是否能召回正确知识来源。',
      path: '/chat',
      steps: ['提出技术问题', '检查来源引用', '补充召回失败的知识条目']
    },
    '优化 Prompt': {
      title: 'Prompt 优化',
      desc: '围绕回答格式、来源引用、未知问题处理来优化系统提示词。',
      path: '/knowledge/new',
      steps: ['定义角色', '限定基于知识库回答', '要求列出来源', '设置无答案兜底']
    },
    '设计工具列表': {
      title: 'Agent 工具列表',
      desc: '为 Agent 规划搜索知识、生成摘要、推荐标签等工具。',
      path: '/knowledge/new',
      steps: ['search_knowledge', 'summarize_knowledge', 'recommend_tags', 'vectorize_document']
    },
    '新增执行记录': {
      title: '执行记录',
      desc: '可扩展为记录 Agent 每次 Thought / Action / Observation。',
      path: '/knowledge/new',
      steps: ['记录用户目标', '记录工具调用', '记录来源与结果', '记录失败原因']
    },
    '生成调试链路': {
      title: '调试链路',
      desc: '将 Agent 调试过程拆成可追踪步骤，方便定位问题。',
      path: '/knowledge/new',
      steps: ['输入问题', '检索知识', '调用工具', '生成答案', '评估结果']
    },
    '生成部署清单': {
      title: '部署清单',
      desc: '围绕 Docker、Kubernetes、Gateway 生成上线前检查清单。',
      path: '/knowledge/new',
      steps: ['镜像构建', '环境变量', '健康检查', '网关路由', '回滚策略']
    },
    '检查服务依赖': {
      title: '服务依赖',
      desc: '检查前端、后端、数据库、Redis、向量库之间的依赖。',
      path: '/knowledge',
      steps: ['前端 API 地址', '后端数据源', 'Redis 连接', '向量库配置']
    },
    '记录发布经验': {
      title: '发布经验',
      desc: '创建一篇发布复盘知识，沉淀问题和解决方案。',
      path: '/knowledge/new',
      steps: ['记录版本', '记录变更', '记录异常', '记录回滚方案']
    }
  }
  const config = actionMap[action] || {
    title: action,
    desc: '该动作当前以演示交互呈现，后续可接入真实接口。',
    path: '/knowledge',
    steps: ['打开相关页面', '查看关联知识', '补充操作记录']
  }
  Object.assign(actionDialog, { ...config, visible: true })
  if (action === '同步标签') ElMessage.success('标签同步流程已生成')
}

function countTree(list) {
  return list.reduce((total, item) => total + 1 + countTree(item.children || []), 0)
}

async function loadRuntimeData() {
  try {
    const [categoriesRes, tagsRes, knowledgeRes] = await Promise.all([
      categoryApi.tree(),
      tagApi.list(),
      knowledgeApi.list({ current: 1, size: 200 })
    ])
    runtime.value = {
      categories: countTree(categoriesRes.data || []),
      tags: (tagsRes.data || []).length,
      knowledge: knowledgeRes.data?.total || knowledgeRes.data?.records?.length || 18
    }
    ElMessage.success('图谱数据已刷新')
  } catch {
    ElMessage.info('已使用内置示例图谱')
  }
}

onMounted(loadRuntimeData)
</script>

<style scoped>
.graph-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.graph-hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 18px;
  padding: 24px;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 16px 40px rgba(16, 24, 40, .08);
}

.eyebrow {
  color: #059669;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
}

.graph-hero h2 {
  max-width: 720px;
  margin: 8px 0;
  color: #101828;
  font-size: 28px;
}

.graph-hero p {
  max-width: 720px;
  margin: 0;
  color: #667085;
}

.hero-actions {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.metric-card :deep(.el-card__body) {
  display: flex;
  align-items: center;
  gap: 12px;
}

.metric-icon {
  display: grid;
  place-items: center;
  width: 42px;
  height: 42px;
  border-radius: 8px;
  background: #ecfdf3;
  color: #079455;
  font-size: 20px;
}

.metric-value {
  color: #101828;
  font-size: 24px;
  font-weight: 800;
}

.metric-label {
  color: #667085;
  font-size: 13px;
}

.graph-card,
.detail-card,
.flow-card,
.matrix-card,
.metric-card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}

.function-matrix {
  display: grid;
  grid-template-columns: repeat(5, minmax(0, 1fr));
  gap: 12px;
}

.function-group {
  padding: 14px;
  border: 1px solid #edf0f5;
  border-radius: 8px;
  background: #f9fafb;
}

.group-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  color: #101828;
  font-weight: 800;
}

.function-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.function-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
  padding: 10px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
  color: #344054;
  text-align: left;
  cursor: pointer;
}

.function-item:hover {
  border-color: #93c5fd;
  color: #1d4ed8;
}

.function-item span {
  font-weight: 700;
}

.function-item small {
  color: #667085;
  line-height: 1.5;
}

.detail-card {
  margin-bottom: 18px;
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.card-header strong {
  display: block;
  color: #101828;
}

.card-header span {
  display: block;
  margin-top: 3px;
  color: #667085;
  font-size: 12px;
}

.graph-canvas {
  min-height: 520px;
  overflow: hidden;
}

.graph-canvas svg {
  width: 100%;
  min-height: 520px;
}

.graph-edge {
  stroke: #d0d5dd;
  stroke-width: 2;
}

.graph-edge.active {
  stroke: #22c55e;
  stroke-width: 3;
}

.graph-node {
  cursor: pointer;
}

.graph-node circle {
  stroke: #fff;
  stroke-width: 4;
  filter: drop-shadow(0 10px 18px rgba(16, 24, 40, .18));
  transition: transform .2s ease, stroke .2s ease;
}

.graph-node:hover circle,
.graph-node.active circle {
  transform: scale(1.06);
  stroke: #101828;
}

.graph-node text {
  fill: #fff;
  font-size: 13px;
  font-weight: 700;
  pointer-events: none;
}

.graph-node.core circle { fill: #101828; }
.graph-node.backend circle { fill: #2563eb; }
.graph-node.frontend circle { fill: #16a34a; }
.graph-node.data circle { fill: #7c3aed; }
.graph-node.ai circle { fill: #f59e0b; }
.graph-node.ops circle { fill: #0f766e; }

.node-summary {
  margin: 0 0 18px;
  color: #475467;
  line-height: 1.7;
}

.section-title {
  margin: 18px 0 10px;
  color: #101828;
  font-size: 14px;
  font-weight: 700;
}

.related-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.related-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px;
  border-radius: 8px;
  background: #f9fafb;
  color: #344054;
}

.related-item span {
  flex: 1;
  min-width: 0;
}

.action-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.flow-title {
  color: #101828;
  font-weight: 700;
}

.flow-desc {
  margin-top: 4px;
  color: #667085;
  font-size: 13px;
  line-height: 1.6;
}

.action-dialog p {
  margin: 0 0 16px;
  color: #475467;
  line-height: 1.7;
}

@media (max-width: 900px) {
  .graph-hero {
    align-items: flex-start;
    flex-direction: column;
  }

  .function-matrix {
    grid-template-columns: 1fr;
  }
}
</style>
