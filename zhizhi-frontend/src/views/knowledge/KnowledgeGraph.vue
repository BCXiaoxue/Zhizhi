<template>
  <div class="graph-page">
    <section class="graph-hero">
      <div>
        <div class="eyebrow">Knowledge Graph</div>
        <h2>像 Obsidian 一样探索你的知识网络</h2>
        <p>从分类、标签和知识条目中动态拉取节点，支持拖拽、悬停高亮、筛选和重新布局，让知识关系不再只是静态示意图。</p>
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

    <el-row :gutter="18">
      <el-col :xs="24" :lg="17">
        <el-card shadow="never" class="graph-card">
          <template #header>
            <div class="card-header graph-toolbar">
              <div>
                <strong>动态知识图谱</strong>
                <span>拖拽节点可以固定位置，双击节点会释放并重新参与布局</span>
              </div>
              <div class="toolbar-actions">
                <el-tag type="success" effect="plain">{{ filteredNodes.length }} 个节点</el-tag>
                <el-button size="small" icon="Aim" @click="restartLayout">重新布局</el-button>
              </div>
            </div>
          </template>

          <div ref="canvasRef" class="graph-canvas">
            <svg
              :viewBox="`0 0 ${canvas.width} ${canvas.height}`"
              role="img"
              aria-label="知识图谱"
              @pointermove="onPointerMove"
              @pointerup="endDrag"
              @pointerleave="endDrag"
            >
              <defs>
                <radialGradient id="graphGlow" cx="50%" cy="50%" r="50%">
                  <stop offset="0%" stop-color="#d9fff3" stop-opacity=".9" />
                  <stop offset="55%" stop-color="#68e2c0" stop-opacity=".32" />
                  <stop offset="100%" stop-color="#12251f" stop-opacity="0" />
                </radialGradient>
              </defs>
              <rect :width="canvas.width" :height="canvas.height" class="graph-bg" />
              <circle :cx="canvas.width / 2" :cy="canvas.height / 2" r="210" fill="url(#graphGlow)" />

              <line
                v-for="edge in filteredEdges"
                :key="`${edge.from}-${edge.to}`"
                :x1="nodeMap[edge.from]?.x"
                :y1="nodeMap[edge.from]?.y"
                :x2="nodeMap[edge.to]?.x"
                :y2="nodeMap[edge.to]?.y"
                class="graph-edge"
                :class="{ active: isEdgeActive(edge), muted: hoveredNode && !isEdgeActive(edge) }"
              />

              <g
                v-for="node in filteredNodes"
                :key="node.id"
                class="graph-node"
                :class="[node.type, { active: selectedNode?.id === node.id, fixed: node.fixed }]"
                :transform="`translate(${node.x}, ${node.y})`"
                @pointerdown.stop="startDrag($event, node)"
                @dblclick.stop="releaseNode(node)"
                @mouseenter="hoveredNode = node"
                @mouseleave="hoveredNode = null"
                @click.stop="selectNode(node)"
              >
                <circle class="node-halo" :r="node.size + 14" />
                <circle class="node-core" :r="node.size" />
                <text text-anchor="middle" :y="node.size + 20">{{ node.label }}</text>
              </g>
            </svg>

            <div class="graph-legend">
              <button
                v-for="option in legendOptions"
                :key="option.value"
                type="button"
                :class="{ active: activeDomain === option.value }"
                @click="activeDomain = option.value"
              >
                <span :style="{ background: option.color }" />
                {{ option.label }}
              </button>
            </div>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :lg="7">
        <el-card shadow="never" class="detail-card">
          <template #header>
            <div class="card-header">
              <div>
                <strong>{{ selectedNode?.label || '选择一个节点' }}</strong>
                <span>{{ selectedNode?.group || '查看关联知识与建议动作' }}</span>
              </div>
              <el-tag v-if="selectedNode" :type="selectedNode.type === 'ai' ? 'warning' : 'primary'" effect="plain">
                {{ selectedNode.typeLabel }}
              </el-tag>
            </div>
          </template>

          <template v-if="selectedNode">
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
              <el-button v-for="action in selectedNode.actions" :key="action" plain @click="runAction(action)">
                {{ action }}
              </el-button>
            </div>
          </template>
        </el-card>

        <el-card shadow="never" class="flow-card">
          <template #header>
            <div class="card-header">
              <div>
                <strong>图谱使用流</strong>
                <span>从发现关系到沉淀知识的轻量闭环</span>
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

    <el-card shadow="never" class="matrix-card">
      <template #header>
        <div class="card-header">
          <div>
            <strong>功能矩阵</strong>
            <span>围绕知识管理、AI 问答和图谱探索整理出的 {{ functionCount }} 个操作入口</span>
          </div>
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
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Document } from '@element-plus/icons-vue'
import { categoryApi, knowledgeApi, tagApi } from '@/api/knowledge'

const router = useRouter()
const activeDomain = ref('全部')
const hoveredNode = ref(null)
const canvasRef = ref(null)
const canvas = reactive({ width: 920, height: 560 })
const runtime = ref({ categories: 0, tags: 0, knowledge: 0 })
const graphNodes = ref([])
const graphEdges = ref([])
const selectedNode = ref(null)
const dragState = reactive({ node: null, offsetX: 0, offsetY: 0 })
const actionDialog = reactive({
  visible: false,
  title: '',
  desc: '',
  path: '/knowledge',
  steps: []
})

let animationFrame = 0
let resizeObserver

const colors = {
  core: '#d7fbe8',
  backend: '#64b5ff',
  frontend: '#60dfa7',
  data: '#b58cff',
  ai: '#ffcb66',
  ops: '#5ad2d0',
  tag: '#ff8db7',
  category: '#9ee37d'
}

const domainOptions = ['全部', '后端', '前端', 'AI', '数据', '运维', '标签', '分类']
const legendOptions = [
  { label: '全部', value: '全部', color: '#d7fbe8' },
  { label: '后端', value: '后端', color: colors.backend },
  { label: '前端', value: '前端', color: colors.frontend },
  { label: 'AI', value: 'AI', color: colors.ai },
  { label: '数据', value: '数据', color: colors.data },
  { label: '标签', value: '标签', color: colors.tag },
  { label: '分类', value: '分类', color: colors.category }
]

const flows = [
  { stage: '发现', title: '探索关系', desc: '通过拖拽和筛选观察知识、分类、标签之间的真实连接。', type: 'primary' },
  { stage: '聚焦', title: '定位主题', desc: '点击节点后高亮相邻关系，快速判断当前主题的上下文。', type: 'success' },
  { stage: '行动', title: '进入知识', desc: '从侧栏跳转到关联条目，补充摘要、标签或向量化状态。', type: 'warning' },
  { stage: '沉淀', title: '持续生长', desc: '刷新数据后图谱会基于最新内容重新生成，形成可维护的知识地图。', type: 'info' }
]

const functionGroups = [
  {
    title: '用户入口',
    icon: 'UserFilled',
    items: [
      { title: '用户登录', desc: '进入知识工作台', path: '/login' },
      { title: '用户注册', desc: '创建新的知识账户', path: '/register' }
    ]
  },
  {
    title: '知识探索',
    icon: 'Share',
    items: [
      { title: '查询知识', desc: '搜索标题、正文和标签', path: '/knowledge' },
      { title: '图谱探索', desc: '按关系发现主题脉络', path: '/graph' }
    ]
  },
  {
    title: '知识管理',
    icon: 'Document',
    items: [
      { title: '新增知识', desc: '创建 Markdown 条目', path: '/knowledge/new' },
      { title: '编辑知识', desc: '维护正文、分类和标签', path: '/knowledge' },
      { title: '导入文件', desc: '导入 txt 或 md 文档', path: '/knowledge' }
    ]
  },
  {
    title: 'AI 协作',
    icon: 'Cpu',
    items: [
      { title: 'AI 问答', desc: '基于知识库进行提问', path: '/chat' },
      { title: '向量化知识', desc: '加入 RAG 检索范围', path: '/chat' }
    ]
  },
  {
    title: '记录追踪',
    icon: 'Tickets',
    items: [
      { title: '会话记录', desc: '查看历史 AI 对话', path: '/chat' },
      { title: '知识详情', desc: '查看摘要、标签和浏览量', path: '/knowledge' }
    ]
  }
]

const seedNodes = [
  createNode('hub', '项目导航', '核心', 'core', '中枢', '把知识条目、分类、标签和 AI 能力连接成一张可探索地图。', [
    { id: 1, title: 'Spring Boot 快速入门' },
    { id: 5, title: 'Vue 3 Composition API' }
  ], ['查看路径', '生成学习计划', '同步标签']),
  createNode('spring', 'Spring', 'Java 后端', 'backend', '后端', '覆盖 Spring Boot、Security、Gateway 与工程实践。', [
    { id: 1, title: 'Spring Boot 快速入门' }
  ], ['打开后端专题', '检索 Spring 知识']),
  createNode('vue', 'Vue 3', '前端开发', 'frontend', '前端', '面向 Composition API、组件设计和管理端交互体验。', [
    { id: 5, title: 'Vue 3 Composition API' }
  ], ['查看前端专题', '生成组件清单']),
  createNode('db', '数据库', '数据层', 'data', '数据', '覆盖 MySQL、Redis、全文索引和向量检索底座。', [
    { id: 6, title: 'MySQL 索引优化' }
  ], ['检查索引', '整理数据模型']),
  createNode('rag', 'RAG', '人工智能', 'ai', 'AI', '把检索、向量数据库、Prompt 和大模型问答串成增强链路。', [
    { id: 4, title: 'RAG 技术详解' }
  ], ['批量向量化', '测试召回效果']),
  createNode('agent', 'Agent', '人工智能', 'ai', 'AI', '面向工具调用、ReAct、多 Agent 协作与自动化。', [
    { id: 15, title: 'AI Agent 架构设计' }
  ], ['设计工具列表', '生成调试链路']),
  createNode('ops', '工程部署', 'DevOps', 'ops', '运维', '包含 Docker、Kubernetes、网关与发布策略。', [
    { id: 9, title: 'Docker 容器化部署' }
  ], ['生成部署清单', '检查服务依赖'])
]

const seedEdges = [
  ['hub', 'spring'],
  ['hub', 'vue'],
  ['hub', 'db'],
  ['hub', 'rag'],
  ['hub', 'agent'],
  ['hub', 'ops'],
  ['spring', 'db'],
  ['spring', 'rag'],
  ['db', 'rag'],
  ['rag', 'agent'],
  ['ops', 'spring'],
  ['ops', 'agent']
].map(([from, to]) => ({ from, to }))

const functionCount = computed(() => functionGroups.reduce((total, group) => total + group.items.length, 0))
const nodeMap = computed(() => Object.fromEntries(filteredNodes.value.map(node => [node.id, node])))
const filteredNodes = computed(() => {
  if (activeDomain.value === '全部') return graphNodes.value
  return graphNodes.value.filter(node => node.typeLabel === activeDomain.value || node.type === 'core')
})
const filteredEdges = computed(() => graphEdges.value.filter(edge => nodeMap.value[edge.from] && nodeMap.value[edge.to]))
const metrics = computed(() => [
  { label: '知识条目', value: runtime.value.knowledge || graphNodes.value.filter(node => node.type === 'knowledge').length, icon: 'Document' },
  { label: '分类节点', value: runtime.value.categories || graphNodes.value.filter(node => node.type === 'category').length, icon: 'FolderOpened' },
  { label: '标签实体', value: runtime.value.tags || graphNodes.value.filter(node => node.type === 'tag').length, icon: 'PriceTag' },
  { label: '图谱关系', value: graphEdges.value.length, icon: 'Share' }
])

function createNode(id, label, group, type, typeLabel, summary, items = [], actions = []) {
  return {
    id,
    label,
    group,
    type,
    typeLabel,
    summary,
    items,
    actions: actions.length ? actions : ['查看关联知识', '补充摘要', '同步标签'],
    size: type === 'core' ? 22 : type === 'knowledge' ? 15 : 13,
    x: canvas.width / 2 + (Math.random() - .5) * 360,
    y: canvas.height / 2 + (Math.random() - .5) * 240,
    vx: 0,
    vy: 0,
    fixed: false
  }
}

function classifyType(text = '') {
  const value = text.toLowerCase()
  if (/ai|rag|llm|agent|prompt|向量|模型/.test(value)) return ['ai', 'AI']
  if (/vue|react|前端|css|html|typescript|javascript/.test(value)) return ['frontend', '前端']
  if (/spring|java|jwt|gateway|后端|接口/.test(value)) return ['backend', '后端']
  if (/mysql|redis|sql|数据|索引|database/.test(value)) return ['data', '数据']
  if (/docker|k8s|kubernetes|部署|devops|运维/.test(value)) return ['ops', '运维']
  return ['knowledge', '知识']
}

function normalizeTags(tags) {
  if (Array.isArray(tags)) return tags.map(tag => (typeof tag === 'string' ? tag : tag?.name)).filter(Boolean)
  if (typeof tags === 'string') return tags.split(/[,，\s]+/).filter(Boolean)
  return []
}

function buildGraphFromRuntime(categories = [], tags = [], knowledge = []) {
  const nodes = [createNode('hub', '知识库', '核心', 'core', '中枢', '当前知识库的总入口，连接分类、标签和知识条目。')]
  const edges = []
  const pushEdge = (from, to) => {
    if (from && to && from !== to && !edges.some(edge => edge.from === from && edge.to === to)) edges.push({ from, to })
  }

  const flatCategories = flattenCategories(categories).slice(0, 18)
  flatCategories.forEach(category => {
    const id = `category-${category.id}`
    nodes.push(createNode(id, category.name || '未命名分类', '分类', 'category', '分类', `分类节点：${category.name || '未命名分类'}`))
    pushEdge(category.parentId ? `category-${category.parentId}` : 'hub', id)
  })

  ;(tags || []).slice(0, 22).forEach(tag => {
    const label = typeof tag === 'string' ? tag : tag.name
    if (!label) return
    const id = `tag-${label}`
    nodes.push(createNode(id, label, '标签', 'tag', '标签', `标签实体：${label}`))
    pushEdge('hub', id)
  })

  ;(knowledge || []).slice(0, 36).forEach(item => {
    const [type, typeLabel] = classifyType(`${item.title || ''} ${item.summary || ''} ${item.content || ''}`)
    const id = `knowledge-${item.id}`
    const itemTags = normalizeTags(item.tags)
    nodes.push(createNode(
      id,
      item.title || `知识 ${item.id}`,
      item.categoryName || typeLabel,
      type,
      typeLabel,
      item.summary || '这是一条来自知识库的动态节点，可继续进入详情维护内容。',
      [{ id: item.id, title: item.title || `知识 ${item.id}` }],
      ['查看关联知识', '补充摘要', '同步标签']
    ))
    pushEdge('hub', id)
    if (item.categoryId) pushEdge(`category-${item.categoryId}`, id)
    itemTags.slice(0, 4).forEach(tag => pushEdge(`tag-${tag}`, id))
  })

  return {
    nodes: nodes.length > 1 ? nodes : seedNodes.map(cloneNode),
    edges: edges.length ? edges : seedEdges
  }
}

function flattenCategories(list = [], parentId = null) {
  return list.flatMap(item => {
    const current = { ...item, parentId: item.parentId ?? parentId }
    return [current, ...flattenCategories(item.children || [], item.id)]
  })
}

function cloneNode(node) {
  return { ...node, items: [...node.items], actions: [...node.actions], x: node.x, y: node.y, vx: 0, vy: 0, fixed: false }
}

function seedGraph() {
  graphNodes.value = seedNodes.map(cloneNode)
  graphEdges.value = seedEdges
  runtime.value = { categories: 4, tags: 7, knowledge: 7 }
  selectedNode.value = graphNodes.value[0]
  restartLayout()
}

function isEdgeActive(edge) {
  const id = selectedNode.value?.id || hoveredNode.value?.id
  return id === edge.from || id === edge.to
}

function selectNode(node) {
  selectedNode.value = node
}

function getPointerPosition(event) {
  const svg = event.currentTarget.closest('svg')
  const rect = svg.getBoundingClientRect()
  return {
    x: ((event.clientX - rect.left) / rect.width) * canvas.width,
    y: ((event.clientY - rect.top) / rect.height) * canvas.height
  }
}

function startDrag(event, node) {
  const point = getPointerPosition(event)
  dragState.node = node
  dragState.offsetX = node.x - point.x
  dragState.offsetY = node.y - point.y
  node.fixed = true
  node.vx = 0
  node.vy = 0
  selectedNode.value = node
  event.target.setPointerCapture?.(event.pointerId)
}

function onPointerMove(event) {
  if (!dragState.node) return
  const point = getPointerPosition(event)
  dragState.node.x = clamp(point.x + dragState.offsetX, 34, canvas.width - 34)
  dragState.node.y = clamp(point.y + dragState.offsetY, 34, canvas.height - 34)
}

function endDrag() {
  dragState.node = null
}

function releaseNode(node) {
  node.fixed = false
  node.vx = (Math.random() - .5) * 2
  node.vy = (Math.random() - .5) * 2
}

function restartLayout() {
  graphNodes.value.forEach((node, index) => {
    const angle = (Math.PI * 2 * index) / Math.max(graphNodes.value.length, 1)
    const radius = node.type === 'core' ? 0 : 180 + (index % 4) * 26
    node.fixed = false
    node.x = canvas.width / 2 + Math.cos(angle) * radius
    node.y = canvas.height / 2 + Math.sin(angle) * radius
    node.vx = 0
    node.vy = 0
  })
  selectedNode.value = graphNodes.value[0] || null
}

function tick() {
  const nodes = filteredNodes.value
  const edges = filteredEdges.value
  const centerX = canvas.width / 2
  const centerY = canvas.height / 2

  nodes.forEach(node => {
    if (node.fixed) return
    node.vx += (centerX - node.x) * 0.0009
    node.vy += (centerY - node.y) * 0.0009
  })

  for (let i = 0; i < nodes.length; i++) {
    for (let j = i + 1; j < nodes.length; j++) {
      const a = nodes[i]
      const b = nodes[j]
      const dx = b.x - a.x || 0.01
      const dy = b.y - a.y || 0.01
      const distanceSq = Math.max(dx * dx + dy * dy, 80)
      const force = Math.min(900 / distanceSq, 0.16)
      const fx = dx * force
      const fy = dy * force
      if (!a.fixed) {
        a.vx -= fx
        a.vy -= fy
      }
      if (!b.fixed) {
        b.vx += fx
        b.vy += fy
      }
    }
  }

  edges.forEach(edge => {
    const from = nodeMap.value[edge.from]
    const to = nodeMap.value[edge.to]
    if (!from || !to) return
    const dx = to.x - from.x
    const dy = to.y - from.y
    const distance = Math.sqrt(dx * dx + dy * dy) || 1
    const target = from.type === 'core' || to.type === 'core' ? 150 : 120
    const force = (distance - target) * 0.006
    const fx = (dx / distance) * force
    const fy = (dy / distance) * force
    if (!from.fixed) {
      from.vx += fx
      from.vy += fy
    }
    if (!to.fixed) {
      to.vx -= fx
      to.vy -= fy
    }
  })

  nodes.forEach(node => {
    if (node.fixed) return
    node.vx *= 0.82
    node.vy *= 0.82
    node.x = clamp(node.x + node.vx, 30, canvas.width - 30)
    node.y = clamp(node.y + node.vy, 34, canvas.height - 42)
  })

  animationFrame = requestAnimationFrame(tick)
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value))
}

function openFunction(path) {
  if (path) router.push(path)
}

function runAction(action) {
  const config = {
    title: action,
    desc: `已基于“${selectedNode.value?.label || '当前节点'}”生成一个轻量操作建议。后续可以继续接入真实 AI 接口生成更细的执行计划。`,
    path: selectedNode.value?.items?.[0]?.id ? `/knowledge/${selectedNode.value.items[0].id}` : '/knowledge',
    steps: [
      `聚焦节点：${selectedNode.value?.label || '知识节点'}`,
      `关联领域：${selectedNode.value?.group || '知识库'}`,
      '查看关联条目并补充摘要、标签或向量化状态'
    ]
  }
  Object.assign(actionDialog, { ...config, visible: true })
  if (action === '同步标签') ElMessage.success('标签同步建议已生成')
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
    const categories = categoriesRes.data || []
    const tags = tagsRes.data || []
    const knowledge = knowledgeRes.data?.records || []
    const graph = buildGraphFromRuntime(categories, tags, knowledge)
    graphNodes.value = graph.nodes
    graphEdges.value = graph.edges
    runtime.value = {
      categories: countTree(categories),
      tags: tags.length,
      knowledge: knowledgeRes.data?.total || knowledge.length
    }
    selectedNode.value = graphNodes.value[0] || null
    restartLayout()
    ElMessage.success('图谱数据已刷新')
  } catch {
    seedGraph()
    ElMessage.info('后端暂不可用，已展示内置示例图谱')
  }
}

watch(activeDomain, () => {
  if (!filteredNodes.value.some(node => node.id === selectedNode.value?.id)) selectedNode.value = filteredNodes.value[0] || null
})

onMounted(async () => {
  await loadRuntimeData()
  await nextTick()
  resizeObserver = new ResizeObserver(entries => {
    const width = entries[0]?.contentRect?.width || 920
    canvas.width = Math.max(680, Math.round(width))
    canvas.height = width < 720 ? 620 : 560
  })
  if (canvasRef.value) resizeObserver.observe(canvasRef.value)
  animationFrame = requestAnimationFrame(tick)
})

onBeforeUnmount(() => {
  cancelAnimationFrame(animationFrame)
  resizeObserver?.disconnect()
})
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
  background: linear-gradient(135deg, #fbfff7 0%, #eefdf7 48%, #eff6ff 100%);
  border: 1px solid #d8eee7;
  box-shadow: 0 16px 40px rgba(16, 24, 40, .08);
}

.eyebrow {
  color: #047857;
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
}

.graph-hero h2 {
  max-width: 760px;
  margin: 8px 0;
  color: #10201b;
  font-size: 28px;
}

.graph-hero p {
  max-width: 760px;
  margin: 0;
  color: #51635d;
  line-height: 1.7;
}

.hero-actions,
.toolbar-actions {
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
  position: relative;
  min-height: 560px;
  overflow: hidden;
  border-radius: 8px;
  background: #111d18;
}

.graph-canvas svg {
  display: block;
  width: 100%;
  min-height: 560px;
  touch-action: none;
  user-select: none;
}

.graph-bg {
  fill: #111d18;
}

.graph-edge {
  stroke: rgba(174, 204, 194, .22);
  stroke-width: 1.4;
  transition: stroke .18s ease, opacity .18s ease;
}

.graph-edge.active {
  stroke: rgba(119, 243, 195, .82);
  stroke-width: 2.4;
}

.graph-edge.muted {
  opacity: .28;
}

.graph-node {
  cursor: grab;
}

.graph-node:active {
  cursor: grabbing;
}

.node-halo {
  fill: transparent;
  opacity: .2;
}

.node-core {
  stroke: rgba(255, 255, 255, .8);
  stroke-width: 2.5;
  filter: drop-shadow(0 10px 18px rgba(0, 0, 0, .35));
  transition: transform .18s ease, stroke .18s ease;
}

.graph-node:hover .node-core,
.graph-node.active .node-core {
  transform: scale(1.14);
  stroke: #ffffff;
}

.graph-node.fixed .node-core {
  stroke: #fef08a;
}

.graph-node text {
  fill: rgba(235, 248, 244, .88);
  font-size: 12px;
  font-weight: 700;
  pointer-events: none;
  paint-order: stroke;
  stroke: rgba(17, 29, 24, .9);
  stroke-width: 4px;
  stroke-linejoin: round;
}

.graph-node.core .node-core { fill: #d7fbe8; }
.graph-node.backend .node-core { fill: #64b5ff; }
.graph-node.frontend .node-core { fill: #60dfa7; }
.graph-node.data .node-core { fill: #b58cff; }
.graph-node.ai .node-core { fill: #ffcb66; }
.graph-node.ops .node-core { fill: #5ad2d0; }
.graph-node.tag .node-core { fill: #ff8db7; }
.graph-node.category .node-core { fill: #9ee37d; }
.graph-node.knowledge .node-core { fill: #d6dde4; }

.graph-legend {
  position: absolute;
  left: 16px;
  bottom: 16px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  max-width: calc(100% - 32px);
}

.graph-legend button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 30px;
  padding: 0 10px;
  border: 1px solid rgba(255, 255, 255, .16);
  border-radius: 8px;
  background: rgba(8, 16, 13, .72);
  color: rgba(235, 248, 244, .86);
  cursor: pointer;
}

.graph-legend button.active {
  border-color: rgba(119, 243, 195, .72);
  color: #ffffff;
}

.graph-legend span {
  width: 9px;
  height: 9px;
  border-radius: 50%;
}

.node-summary {
  margin: 0 0 18px;
  color: #475467;
  line-height: 1.7;
}

.section-title {
  margin: 18px 0 10px;
  color: #101828;
  font-size: 14px;
  font-weight: 800;
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
  font-weight: 800;
}

.flow-desc {
  margin-top: 4px;
  color: #667085;
  font-size: 13px;
  line-height: 1.6;
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
  font-weight: 800;
}

.function-item small {
  color: #667085;
  line-height: 1.5;
}

.action-dialog p {
  margin: 0 0 16px;
  color: #475467;
  line-height: 1.7;
}

@media (max-width: 900px) {
  .graph-hero,
  .graph-toolbar {
    align-items: flex-start;
    flex-direction: column;
  }

  .hero-actions,
  .toolbar-actions {
    justify-content: flex-start;
  }

  .function-matrix {
    grid-template-columns: 1fr;
  }

  .graph-canvas,
  .graph-canvas svg {
    min-height: 620px;
  }
}
</style>
