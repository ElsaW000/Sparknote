// Spark_Vault_uniapp/services/vaultLogic.js
let nextIdSeed = Date.now()

// Fragment content types, content forms, and capture methods.
// A capture method such as voice recording is not a content form.
export const CONTENT_TYPES = ['personal_content', 'reference_content']
export const SOURCE_TYPES = ['All', 'Book', 'Browser', 'Screenshot', 'Voice', 'Manual', 'Other']
export const SUBTYPE_MAP = {
  personal_content: ['想法', '日记', '观察'],
  reference_content: ['书摘', '网页', '文件']
}
export const SUBTYPE_ICONS = {
  '想法': '💡', '日记': '✍', '观察': '◌',
  '书摘': '📖', '网页': '🌐', '文件': '📎'
}
export const ALL_SUBTYPES = Object.values(SUBTYPE_MAP).flat()
export const CAPTURE_METHODS = ['manual', 'voice', 'ocr', 'web_clip', 'file_import']
export const CAPTURE_METHOD_LABELS = {
  manual: '手写',
  voice: '录音',
  ocr: 'OCR',
  web_clip: '网页剪藏',
  file_import: '文件导入'
}
// Filter chip labels for Library tab
export const FILTER_CHIPS = ['全部', '💡 想法', '✍ 日记', '📖 书摘', '🌐 网页']

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

export function fallbackSummary(text = '') {
  const normalized = normalizeText(text)
  if (normalized.length <= 80) return normalized
  return `${normalized.slice(0, 80).trimEnd()}...`
}

export function fallbackTags(text = '') {
  const tokens = normalizeText(text)
    .match(/[A-Za-z\u4e00-\u9fff]+/g) || []
  const stopWords = new Set(['a', 'an', 'and', 'or', 'the', 'to', 'of', 'in', 'on', 'with', 'for', 'ai'])
  const seen = new Set()
  const picked = []
  for (const token of tokens) {
    const lower = token.toLowerCase()
    if (lower.length < 4) continue
    if (stopWords.has(lower)) continue
    if (seen.has(lower)) continue
    seen.add(lower)
    picked.push(lower.charAt(0).toUpperCase() + lower.slice(1))
    if (picked.length >= 3) break
  }
  return picked
}

export function createFragment(input = {}) {
  const content = normalizeText(input.content || input.originalText)
  if (!content) throw new Error('Fragment text is required')

  const timestamp = Number.isFinite(input.created_at || input.createdAt)
    ? (input.created_at || input.createdAt)
    : now()
  const tags = parseTags(input.tags ?? input.tagsText)
  const content_type = CONTENT_TYPES.includes(input.content_type)
    ? input.content_type
    : 'personal_content'
  const legacySubtype = input.subtype === '录音' ? '想法' : input.subtype
  const form_kind = ALL_SUBTYPES.includes(input.form_kind || legacySubtype)
    ? (input.form_kind || legacySubtype)
    : '想法'
  const subtype = form_kind
  const acquisition_method = CAPTURE_METHODS.includes(input.acquisition_method)
    ? input.acquisition_method
    : (input.subtype === '录音' ? 'voice' : 'manual')
  const sourceType = normalizeText(input.sourceType) || null
  const sourceTitle = normalizeText(input.sourceTitle) || null
  const author = normalizeText(input.author) || null
  const userComment = normalizeText(input.userComment) || null
  const favoriteStatus = Boolean(input.favoriteStatus)
  const linked_fragment_ids = Array.isArray(input.linked_fragment_ids)
    ? input.linked_fragment_ids.map(Number).filter(Number.isInteger)
    : []
  const audio_path = normalizeText(input.audio_path || input.audioPath) || null
  const file_path = normalizeText(input.file_path || input.filePath) || null

  return {
    id: Number.isInteger(input.id) ? input.id : createId(),
    content,
    originalText: content,
    content_type,
    form_kind,
    subtype,
    acquisition_method,
    audio_path,
    file_path,
    sourceType,
    sourceTitle,
    author,
    userComment,
    favoriteStatus,
    linked_fragment_ids,
    blocks: Array.isArray(input.blocks) ? input.blocks : null,
    category: normalizeText(input.category) || null,
    source: normalizeText(input.source) || null,
    title: normalizeText(input.title) || null,
    tags,
    source_url: normalizeText(input.source_url || input.sourceUrl) || null,
    created_at: timestamp,
    createdAt: timestamp,
    updated_at: Number.isFinite(input.updated_at || input.updatedAt)
      ? (input.updated_at || input.updatedAt)
      : timestamp,
    updatedAt: Number.isFinite(input.updated_at || input.updatedAt)
      ? (input.updated_at || input.updatedAt)
      : timestamp,
    aiSummary: normalizeText(input.aiSummary) || fallbackSummary(content)
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
  const sourceType = normalizeText(filters.sourceType || 'All')
  const selectedTag = normalizeText(filters.selectedTag || 'All').toLowerCase()
  const onlyFavorites = Boolean(filters.onlyFavorites)

  return fragments.filter((f) => {
    if (!f) return false
    if (sourceType && sourceType !== 'All') {
      const currentSource = normalizeText(f.sourceType || 'Other')
      if (currentSource !== sourceType) return false
    }
    if (selectedTag && selectedTag !== 'all') {
      const tags = Array.isArray(f.tags) ? f.tags.map((t) => normalizeText(t).toLowerCase()) : []
      if (!tags.includes(selectedTag)) return false
    }
    if (onlyFavorites && !f.favoriteStatus) return false
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
  const favoriteCount = fragments.filter((f) => f && f.favoriteStatus).length
  const allTags = Array.from(
    new Set(fragments.flatMap((f) => (Array.isArray(f.tags) ? f.tags : [])))
  ).sort()
  const sourceCounts = fragments.reduce((acc, f) => {
    const source = normalizeText(f?.sourceType || 'Other') || 'Other'
    acc[source] = (acc[source] || 0) + 1
    return acc
  }, {})
  const primarySource = Object.entries(sourceCounts)
    .sort((a, b) => b[1] - a[1])[0]?.[0] || 'Other'

  return {
    totalFragments: fragments.length,
    weeklyFragments: weeklyCount,
    favoriteFragments: favoriteCount,
    chatCount: sessions.length,
    reportCount: reports.length,
    tagCount: allTags.length,
    allTags,
    primarySource
  }
}

export function mergeFragments(fragments = [], mergedTitle = '') {
  if (!Array.isArray(fragments) || fragments.length < 2) {
    throw new Error('At least two fragments are required')
  }
  const validFragments = fragments.filter(Boolean)
  if (validFragments.length < 2) {
    throw new Error('At least two fragments are required')
  }
  const mergedText = validFragments
    .map((f) => normalizeText(f.originalText || f.content))
    .filter(Boolean)
    .join('\n\n')
  const mergedTags = Array.from(new Set(validFragments.flatMap((f) => Array.isArray(f.tags) ? f.tags : [])))
  return createFragment({
    originalText: mergedText,
    sourceType: validFragments[0].sourceType || 'Other',
    sourceTitle: normalizeText(mergedTitle) || 'Merged Fragments',
    tags: mergedTags,
    favoriteStatus: validFragments.some((f) => Boolean(f.favoriteStatus))
  })
}

export function generateLocalWorkspaceReport(query = '', fragments = [], reportType = 'Outline') {
  const normalizedQuery = normalizeText(query).toLowerCase()
  const queryTokens = normalizedQuery.split(/\s+/).filter(Boolean)
  const candidates = Array.isArray(fragments) ? fragments : []
  const relevant = queryTokens.length
    ? candidates.filter((f) => {
      const haystack = [f?.originalText, f?.content, Array.isArray(f?.tags) ? f.tags.join(' ') : '']
        .join(' ')
        .toLowerCase()
      return queryTokens.every((token) => haystack.includes(token))
    })
    : candidates
  return {
    content: [
      `### Synthesized ${normalizeText(reportType) || 'Outline'}`,
      `Query: "${normalizeText(query)}"`,
      '',
      relevant.length
        ? relevant.map((f) => `- Fragment #${f.id}: ${(f.originalText || f.content || '').slice(0, 120)}`).join('\n')
        : '- No fragments are available yet. Capture notes before generating a richer synthesis.',
      '',
      'Actionable insight:',
      '- Cluster repeated tags and convert the strongest connection into a draft outline.'
    ].join('\n'),
    relevantIds: relevant.map((f) => f.id).filter(Number.isInteger)
  }
}

export function generateWeeklyDigest(fragments = []) {
  if (!fragments.length) {
    return 'Your MirrorMe vault is empty. Capture book quotes, browser snippets, screenshots, or manual thoughts first.'
  }
  const metrics = computeMetrics(fragments, [], [])
  const tags = metrics.allTags.slice(0, 6).join(', ') || 'none'
  return [
    '### MirrorMe Weekly Reflection Digest',
    '',
    `Total Fragments: ${metrics.totalFragments}`,
    `Favorite Fragments: ${metrics.favoriteFragments}`,
    `Primary Source: ${metrics.primarySource}`,
    `Active Tags: ${metrics.tagCount} (${tags})`,
    '',
    'Suggested next step: merge two related fragments and generate a workspace outline.'
  ].join('\n')
}
