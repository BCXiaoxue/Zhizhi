<template>
  <div class="knowledge-page">
    <section class="toolbar-card">
      <div>
        <div class="eyebrow">Knowledge Library</div>
        <h2>沉淀、检索并向量化你的技术知识</h2>
      </div>
      <div class="toolbar-actions">
        <el-input v-model="searchKeyword" placeholder="搜索标题、正文或标签" prefix-icon="Search" clearable @keyup.enter="doSearch" @clear="loadList" />
        <el-upload :show-file-list="false" accept=".txt,.md" :before-upload="importFile">
          <el-button icon="Upload">导入</el-button>
        </el-upload>
        <el-button type="primary" icon="Plus" @click="$router.push('/knowledge/new')">新建</el-button>
      </div>
    </section>

    <el-row :gutter="18" class="stat-row">
      <el-col :xs="12" :md="6">
        <el-card shadow="never" class="stat-card">
          <span>知识条目</span>
          <strong>{{ total || list.length }}</strong>
        </el-card>
      </el-col>
      <el-col :xs="12" :md="6">
        <el-card shadow="never" class="stat-card">
          <span>分类节点</span>
          <strong>{{ categoryCount }}</strong>
        </el-card>
      </el-col>
      <el-col :xs="12" :md="6">
        <el-card shadow="never" class="stat-card">
          <span>标签</span>
          <strong>{{ tags.length }}</strong>
        </el-card>
      </el-col>
      <el-col :xs="12" :md="6">
        <el-card shadow="never" class="stat-card">
          <span>已向量化</span>
          <strong>{{ vectorizedCount }}</strong>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="18">
      <el-col :xs="24" :lg="6">
        <el-card class="side-card" shadow="never">
          <div class="side-header">
            <span>分类导航</span>
            <el-button size="small" text icon="Plus" @click="showCategoryDialog = true" />
          </div>
          <el-tree
            :data="categoryTree"
            :props="{ label: 'name', children: 'children' }"
            node-key="id"
            highlight-current
            class="category-tree"
            @node-click="onCategoryClick"
          >
            <template #default="{ node, data }">
              <span class="tree-node">
                <span>{{ node.label }}</span>
                <el-button size="small" text type="danger" icon="Delete" @click.stop="deleteCategory(data.id)" />
              </span>
            </template>
          </el-tree>

          <el-divider />
          <div class="side-header">
            <span>标签筛选</span>
          </div>
          <div class="tag-list">
            <el-tag
              v-for="tag in tags"
              :key="tag.id"
              size="small"
              :type="selectedTagId === tag.id ? 'success' : 'info'"
              effect="plain"
              @click="onTagClick(tag.id)"
            >{{ tag.name }}</el-tag>
          </div>
        </el-card>
      </el-col>

      <el-col :xs="24" :lg="18">
        <el-card shadow="never" class="list-card">
          <template #header>
            <div class="list-header">
              <div>
                <strong>知识条目</strong>
                <span>支持全文检索、标签筛选、AI 摘要和向量化</span>
              </div>
              <el-button icon="Share" @click="$router.push('/graph')">打开图谱</el-button>
            </div>
          </template>

          <el-empty v-if="!list.length && !loading" description="暂无知识条目" />
          <el-skeleton :loading="loading" :rows="5" animated>
            <template #default>
              <div class="knowledge-list">
                <article
                  v-for="item in list"
                  :key="item.id"
                  class="knowledge-item"
                  @click="$router.push(`/knowledge/${item.id}`)"
                >
                  <div class="item-main">
                    <div class="item-title">{{ item.title }}</div>
                    <div v-if="item.summary" class="item-summary">{{ item.summary }}</div>
                    <div class="item-meta">
                      <el-tag v-if="item.categoryName" size="small" type="success" effect="plain">{{ item.categoryName }}</el-tag>
                      <el-tag v-if="item.isVectorized" size="small" type="warning" effect="plain">已向量化</el-tag>
                      <span class="item-date">{{ formatDate(item.updatedAt) }}</span>
                    </div>
                  </div>
                  <div class="item-actions" @click.stop>
                    <el-button circle icon="Edit" @click="$router.push(`/knowledge/${item.id}/edit`)" />
                    <el-button circle type="danger" icon="Delete" @click="deleteKnowledge(item.id)" />
                  </div>
                </article>
              </div>
            </template>
          </el-skeleton>

          <el-pagination
            v-if="total > pageSize"
            v-model:current-page="currentPage"
            :page-size="pageSize"
            :total="total"
            layout="prev, pager, next"
            class="pager"
            @current-change="loadList"
          />
        </el-card>
      </el-col>
    </el-row>
  </div>

  <!-- 新增分类弹窗 -->
  <el-dialog v-model="showCategoryDialog" title="新增分类" width="400px">
    <el-form :model="categoryForm" label-width="60px">
      <el-form-item label="名称"><el-input v-model="categoryForm.name" /></el-form-item>
      <el-form-item label="父分类">
        <el-tree-select v-model="categoryForm.parentId" :data="categoryTree" :props="{ label: 'name', value: 'id', children: 'children' }" clearable placeholder="根节点" />
      </el-form-item>
    </el-form>
    <template #footer>
      <el-button @click="showCategoryDialog = false">取消</el-button>
      <el-button type="primary" @click="createCategory">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, ref, onMounted, reactive } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { knowledgeApi, categoryApi, tagApi } from '@/api/knowledge'

const list = ref([])
const total = ref(0)
const currentPage = ref(1)
const pageSize = 10
const loading = ref(false)
const searchKeyword = ref('')
const categoryTree = ref([])
const tags = ref([])
const selectedCategoryId = ref(null)
const selectedTagId = ref(null)
const showCategoryDialog = ref(false)
const categoryForm = reactive({ name: '', parentId: null })
const vectorizedCount = computed(() => list.value.filter(item => item.isVectorized).length)
const categoryCount = computed(() => countTree(categoryTree.value))

function countTree(list) {
  return list.reduce((total, item) => total + 1 + countTree(item.children || []), 0)
}

async function loadList() {
  loading.value = true
  try {
    const res = await knowledgeApi.list({
      current: currentPage.value,
      size: pageSize,
      categoryId: selectedCategoryId.value,
      tagId: selectedTagId.value
    })
    list.value = res.data.records
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

async function doSearch() {
  if (!searchKeyword.value.trim()) { loadList(); return }
  loading.value = true
  try {
    const res = await knowledgeApi.search(searchKeyword.value)
    list.value = res.data
    total.value = res.data.length
  } finally {
    loading.value = false
  }
}

async function deleteKnowledge(id) {
  await ElMessageBox.confirm('确认删除该知识条目？', '提示', { type: 'warning' })
  await knowledgeApi.remove(id)
  ElMessage.success('删除成功')
  loadList()
}

function onCategoryClick(data) {
  selectedCategoryId.value = selectedCategoryId.value === data.id ? null : data.id
  selectedTagId.value = null
  currentPage.value = 1
  loadList()
}

function onTagClick(id) {
  selectedTagId.value = selectedTagId.value === id ? null : id
  selectedCategoryId.value = null
  currentPage.value = 1
  loadList()
}

async function createCategory() {
  if (!categoryForm.name.trim()) { ElMessage.warning('请输入分类名称'); return }
  await categoryApi.create({ name: categoryForm.name, parentId: categoryForm.parentId })
  showCategoryDialog.value = false
  categoryForm.name = ''
  categoryForm.parentId = null
  loadCategories()
}

async function deleteCategory(id) {
  await ElMessageBox.confirm('确认删除该分类？', '提示', { type: 'warning' })
  await categoryApi.remove(id)
  loadCategories()
}

async function importFile(file) {
  await knowledgeApi.importFile(file)
  ElMessage.success('导入成功')
  loadList()
  return false
}

function loadCategories() {
  categoryApi.tree().then(res => { categoryTree.value = res.data })
}

function formatDate(str) {
  if (!str) return ''
  return str.substring(0, 10)
}

onMounted(() => {
  loadList()
  loadCategories()
  tagApi.list().then(res => { tags.value = res.data })
})
</script>

<style scoped>
.knowledge-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.toolbar-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 18px;
  padding: 22px 24px;
  border-radius: 8px;
  background: #fff;
  box-shadow: 0 16px 40px rgba(16, 24, 40, .08);
}

.eyebrow {
  color: #2563eb;
  font-size: 12px;
  font-weight: 800;
  text-transform: uppercase;
}

.toolbar-card h2 {
  margin: 6px 0 0;
  color: #101828;
  font-size: 24px;
}

.toolbar-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.toolbar-actions .el-input {
  width: 320px;
}

.stat-card,
.side-card,
.list-card {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
}

.stat-card :deep(.el-card__body) {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-card span {
  color: #667085;
  font-size: 13px;
}

.stat-card strong {
  color: #101828;
  font-size: 28px;
}

.side-card {
  min-height: 560px;
}

.side-header,
.list-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-weight: 700;
}

.list-header span {
  display: block;
  margin-top: 3px;
  color: #667085;
  font-size: 12px;
  font-weight: 400;
}

.category-tree {
  margin-top: 10px;
}

.tree-node {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
}

.tag-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-list .el-tag {
  cursor: pointer;
}

.knowledge-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.knowledge-item {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 18px;
  border: 1px solid #edf0f5;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  transition: border-color .2s ease, box-shadow .2s ease, transform .2s ease;
}

.knowledge-item:hover {
  border-color: #bfdbfe;
  box-shadow: 0 12px 30px rgba(16, 24, 40, .08);
  transform: translateY(-1px);
}

.item-main {
  min-width: 0;
}

.item-title {
  margin-bottom: 8px;
  color: #101828;
  font-size: 17px;
  font-weight: 800;
}

.item-meta {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 10px;
}

.item-date {
  color: #98a2b3;
  font-size: 12px;
}

.item-summary {
  color: #667085;
  font-size: 13px;
  line-height: 1.6;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.item-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.pager {
  justify-content: center;
  margin-top: 18px;
}

@media (max-width: 900px) {
  .toolbar-card {
    align-items: flex-start;
    flex-direction: column;
  }

  .toolbar-actions,
  .toolbar-actions .el-input {
    width: 100%;
  }
}
</style>
