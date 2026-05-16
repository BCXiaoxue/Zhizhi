<template>
  <el-page-header @back="$router.go(-1)" :content="isEdit ? '编辑知识条目' : '新建知识条目'" />
  <el-card style="margin-top:16px">
    <el-form ref="formRef" :model="form" :rules="rules" label-position="top">
      <el-form-item label="标题" prop="title">
        <el-input v-model="form.title" placeholder="请输入标题" size="large" />
      </el-form-item>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="分类">
            <el-tree-select
              v-model="form.categoryId"
              :data="categoryTree"
              :props="{ label: 'name', value: 'id', children: 'children' }"
              clearable
              placeholder="选择分类（可选）"
              style="width:100%"
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="标签">
            <el-select v-model="form.tags" multiple filterable allow-create default-first-option style="width:100%" placeholder="输入或选择标签">
              <el-option v-for="tag in allTags" :key="tag.name" :label="tag.name" :value="tag.name" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="正文（Markdown）">
        <el-row :gutter="12" style="width:100%">
          <el-col :span="12">
            <el-input
              v-model="form.content"
              type="textarea"
              :autosize="{ minRows: 20, maxRows: 40 }"
              placeholder="支持 Markdown 格式..."
              style="font-family: monospace"
            />
          </el-col>
          <el-col :span="12">
            <div class="preview-box markdown-body" v-html="preview" />
          </el-col>
        </el-row>
      </el-form-item>
      <div style="display:flex;gap:12px">
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
        <el-button @click="$router.go(-1)">取消</el-button>
      </div>
    </el-form>
  </el-card>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { marked } from 'marked'
import { knowledgeApi, categoryApi, tagApi } from '@/api/knowledge'

const route = useRoute()
const router = useRouter()
const id = route.params.id
const isEdit = computed(() => !!id)

const formRef = ref()
const saving = ref(false)
const categoryTree = ref([])
const allTags = ref([])

const form = reactive({ title: '', content: '', categoryId: null, tags: [] })
const rules = { title: [{ required: true, message: '请输入标题' }] }

const preview = computed(() => form.content ? marked.parse(form.content) : '<span style="color:#ccc">预览区域</span>')

async function save() {
  await formRef.value.validate()
  saving.value = true
  try {
    if (isEdit.value) {
      await knowledgeApi.update(id, form)
      ElMessage.success('更新成功')
      router.push(`/knowledge/${id}`)
    } else {
      const res = await knowledgeApi.create(form)
      ElMessage.success('创建成功')
      router.push(`/knowledge/${res.data.id}`)
    }
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  categoryApi.tree().then(res => { categoryTree.value = res.data })
  tagApi.list().then(res => { allTags.value = res.data })
  if (isEdit.value) {
    const res = await knowledgeApi.detail(id)
    const data = res.data
    form.title = data.title
    form.content = data.content || ''
    form.categoryId = data.categoryId
    form.tags = typeof data.tags === 'string' ? (data.tags ? data.tags.split(',') : []) : (data.tags || [])
  }
})
</script>

<style scoped>
.preview-box {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  padding: 12px;
  min-height: 400px;
  overflow-y: auto;
  line-height: 1.8;
}
.markdown-body :deep(pre) { background: #f6f8fa; padding: 12px; border-radius: 4px; overflow-x: auto; }
.markdown-body :deep(blockquote) { border-left: 4px solid #dfe2e5; padding-left: 12px; color: #6a737d; }
</style>
