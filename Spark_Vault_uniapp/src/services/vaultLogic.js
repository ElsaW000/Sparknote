// Spark_Vault_uniapp/services/vaultLogic.js
let nextIdSeed = Date.now()

// Fragment content types and subtypes
export const CONTENT_TYPES = ['personal_content', 'reference_content']
export const SUBTYPE_MAP = {
  personal_content: ['想法', '日记', '录音'],
  reference_content: ['书摘', '网页', '文件']
}
export const SUBTYPE_ICONS = {
  '想法': '💡', '日记': '✍', '录音': '🎙',
  '书摘': '📖', '网页': '🌐', '文件': '📎'
}
export const ALL_SUBTYPES = Object.values(SUBTYPE_MAP).flat()
// Filter chip labels for Library tab
export const FILTER_CHIPS = ['全部', '💡 想法', '📖 书摘', '🌐 网页', '🎙 录音']

// Chat session modes
export const CHAT_MODES = [
  { id: 'memory', icon: '🧠', name: '记忆纠偏', desc: '发现误解与惯性记忆，重新校准认知' },
  { id: 'mentor', icon: '👤', name: '大师导师', desc: '选择一位 Mentor，深度探讨问题' },
  { id: 'writing', icon: '✍', name: '创作辅助', desc: '基于 Library 碎片，辅助写作输出' },
  { id: 'report', icon: '📋', name: '生成报告', desc: '整理对话 & 碎片，输出结构化报告' }
]

function now() {
  return Date.now()
}

export function createId() {
  nextIdSeed += 1
  return nextIdSeed
}

export function normalizeText(value) {
  return typeof value === 'string' ? value.trim() : ''
}

export function parseTags(input) {
  const source = Array.isArray(input) ? input : normalizeText(input).split(',')
  const seen = new Set()
  return source
    .map((item) => normalizeText(item))
    .filter(Boolean)
    .filter((tag) => {
      const key = tag.toLowerCase()
      if (seen.has(key)) return false
      seen.add(key)
      return true
    })
}

export function createFragment(input = {}) {
  const content = normalizeText(input.content || input.originalText)
  if (!content) throw new Error('Fragment content is required')

  const timestamp = Number.isFinite(input.created_at || input.createdAt)
    ? (input.created_at || input.createdAt)
    : now()
  const tags = parseTags(input.tags ?? input.tagsText)
  const content_type = CONTENT_TYPES.includes(input.content_type)
    ? input.content_type
    : 'personal_content'
  const subtype = ALL_SUBTYPES.includes(input.subtype) ? input.subtype : '想法'

  return {
    id: Number.isInteger(input.id) ? input.id : createId(),
    content,
    content_type,
    subtype,
    title: normalizeText(input.title) || null,
    tags,
    source_url: normalizeText(input.source_url || input.sourceUrl) || null,
    created_at: timestamp,
    updated_at: Number.isFinite(input.updated_at || input.updatedAt)
      ? (input.updated_at || input.updatedAt)
      : timestamp
  }
}

export function createChatSession(input = {}) {
  const mode = CHAT_MODES.find((m) => m.id === input.mode) ? input.mode : 'memory'
  const modeInfo = CHAT_MODES.find((m) => m.id === mode)
  const timestamp = now()
  return {
    id: Number.isInteger(input.id) ? input.id : createId(),
    mode,
    title: normalizeText(input.title) || `${modeInfo.name} · 新会话`,
    messages: Array.isArray(input.messages) ? input.messages : [],
    created_at: timestamp,
    updated_at: timestamp
  }
}

export function createReport(input = {}) {
  const title = normalizeText(input.title)
  const generatedContent = normalizeText(input.generatedContent || input.content)
  if (!title) throw new Error('Report title is required')
  if (!generatedContent) throw new Error('Report content is required')
  const timestamp = Number.isFinite(input.created_at || input.createdAt)
    ? (input.created_at || input.createdAt) : now()
  return {
    id: Number.isInteger(input.id) ? input.id : createId(),
    title,
    month: normalizeText(input.month) || new Date(timestamp).toISOString().slice(0, 7),
    generatedContent,
    relatedFragmentIds: Array.isArray(input.relatedFragmentIds)
      ? input.relatedFragmentIds.filter(Number.isInteger) : [],
    created_at: timestamp
  }
}

export function filterFragments(fragments = [], filters = {}) {
  const query = normalizeText(filters.query).toLowerCase()
  const chip = normalizeText(filters.chip || 'All')

  return fragments.filter((f) => {
    if (!f) return false
    // chip filter: matches subtype label (e.g. "💡 想法" → subtype "想法")
    if (chip && chip !== 'All' && chip !== '全部') {
      const chipSubtype = chip.replace(/^[\p{Emoji}\s]+/u, '').trim()
      if (normalizeText(f.subtype) !== chipSubtype) return false
    }
    if (!query) return true
    const haystack = [f.content, f.title, Array.isArray(f.tags) ? f.tags.join(' ') : ''].join(' ').toLowerCase()
    return haystack.includes(query)
  })
}

export function computeMetrics(fragments = [], reports = [], sessions = []) {
  const oneWeekAgo = Date.now() - 7 * 24 * 60 * 60 * 1000
  const weeklyCount = fragments.filter((f) => f && f.created_at >= oneWeekAgo).length
  const allTags = Array.from(
    new Set(fragments.flatMap((f) => (Array.isArray(f.tags) ? f.tags : [])))
  ).sort()

  return {
    totalFragments: fragments.length,
    weeklyFragments: weeklyCount,
    chatCount: sessions.length,
    reportCount: reports.length,
    tagCount: allTags.length,
    allTags
  }
}

export function generateWeeklyDigest(fragments = []) {
  if (!fragments.length) {
    return '还没有碎片记录。先在 Library 里记录一些想法或书摘吧。'
  }
  const recent = fragments
    .slice()
    .sort((a, b) => (b.created_at || 0) - (a.created_at || 0))
    .slice(0, 10)
  const allTags = recent.flatMap((f) => (Array.isArray(f.tags) ? f.tags : []))
  const tagCounts = allTags.reduce((acc, t) => { acc[t] = (acc[t] || 0) + 1; return acc }, {})
  const topTags = Object.entries(tagCounts).sort((a, b) => b[1] - a[1]).slice(0, 2).map(([t]) => t)
  if (!topTags.length) return `本周录入了 ${recent.length} 条碎片。继续保持记录习惯！`
  return `本周你记录最多的主题是「${topTags.join('」和「')}」。AI 正在分析你的思维模式，建议开启一次纠偏对话。`
}