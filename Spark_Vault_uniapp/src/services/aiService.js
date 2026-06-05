// Spark_Vault_uniapp/src/services/aiService.js

import { fallbackSummary, fallbackTags, normalizeText } from './vaultLogic.js'

export const AI_TAB_SOURCE = 'AI Tab'

const API_BASE = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000'

// ── Mentor persona definitions (mirrors skillsService built-in list) ──────────
// 设计原则：体现思维框架/方法论，不声称"我是某个真实人物"
// 参考：research 报告提示名人模拟存在合规风险（Ofcom OSA）
export const BUILTIN_MENTORS = [
  {
    id: 'inamori',
    name: '工匠视角',
    emoji: '🏮',
    desc: '极致与内在驱动',
    prompt: '以工匠精神的视角回应——关注极致、持续改善、内在动机。用这个框架分析用户说的内容，给出具体洞察。'
  },
  {
    id: 'munger',
    name: '逆向思维',
    emoji: '🎩',
    desc: '多元框架识别偏见',
    prompt: '以多元思维框架的视角回应——识别认知偏见、反向推演、跨学科分析。用这个框架分析用户说的内容，风格直接犀利。'
  },
  {
    id: 'socrates',
    name: '苏格拉底提问法',
    emoji: '🏛️',
    desc: '层层追问假设',
    prompt: '以苏格拉底式对话的方式回应——通过追问帮助用户自己发现逻辑漏洞。每次只提一个问题。'
  }
]

/**
 * 基于关键词相关性从 fragments 中筛选最相关的条目
 * @param {Array} fragments - 所有 personal_content fragments
 * @param {string} query - 当前用户输入（用于相关性计算）
 * @param {number} topN - 返回最多条数
 * @returns {Array}
 */
export function selectRelevantFragments(fragments, query = '', topN = 8) {
  if (!fragments.length) return []

  const queryWords = query
    .toLowerCase()
    .split(/[\s，。！？、；：""''【】（）\n\r]+/)
    .filter((w) => w.length >= 2)

  if (!queryWords.length) return fragments.slice(0, topN)

  const scored = fragments.map((f) => {
    const text = (f.content || f.originalText || '').toLowerCase()
    const tags = (f.tags || []).join(' ').toLowerCase()
    let score = 0
    for (const word of queryWords) {
      if (text.includes(word)) score += 1
      if (tags.includes(word)) score += 2
    }
    return { f, score }
  })

  scored.sort((a, b) => b.score - a.score)
  return scored.slice(0, topN).map((s) => s.f)
}

/**
 * 构建对话 system prompt
 * @param {'memory'|'mentor'|'writing'|'report'} mode
 * @param {object|null} mentor - mentor object from BUILTIN_MENTORS or custom skill
 * @param {Array} contextFragments - 已经过相关性筛选的 fragments
 */
export function buildSystemPrompt(mode, mentor, contextFragments = []) {
  const fragmentSummary = contextFragments
    .map((f, i) => `[${i + 1}] ${(f.content || f.originalText || '').slice(0, 400)}`)
    .join('\n')

  const contextBlock = fragmentSummary
    ? `\n\n用户的相关记录（优先结合这些内容回复）：\n${fragmentSummary}`
    : ''

  if (mode === 'memory') {
    return `识别用户说的内容里的认知偏差、矛盾或盲点，给出具体分析。${contextBlock}`
  }

  if (mode === 'mentor') {
    const viewpointPrompt = mentor?.prompt || BUILTIN_MENTORS[0].prompt
    return `${viewpointPrompt}${contextBlock}`
  }

  if (mode === 'writing') {
    return `帮助用户把想法写成文字——扩展、组织结构、提升表达。给出具体建议。${contextBlock}`
  }

  if (mode === 'report') {
    return `根据对话，生成简洁的成长分析报告：核心主题、发现的思维模式、建议行动（3条以内）。${contextBlock}`
  }

  return `回答用户的问题，结合他们的记录给出有价值的洞察。${contextBlock}`
}

/**
 * Agent chat — mentor agents with skill tool-calling (backend /v1/agent/chat).
 * The backend agent decides when to call search_memory using DashScope embeddings.
 *
 * @param {Array<{role: string, content: string}>} messages  - Conversation history (no system msg)
 * @param {string} mentorPrompt   - Task-focused perspective prompt
 * @param {Array}  allFragments   - All user personal fragments (backend does the retrieval)
 * @returns {Promise<string>}     - AI reply text
 */
export function agentChat(messages, mentorPrompt, allFragments = []) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: `${API_BASE}/v1/agent/chat`,
      method: 'POST',
      header: { 'Content-Type': 'application/json' },
      data: {
        messages,
        mentor_prompt: mentorPrompt,
        fragments: allFragments
      },
      timeout: 60000,
      success(res) {
        if (res.statusCode === 200 && res.data?.choices?.[0]?.message?.content) {
          resolve(res.data.choices[0].message.content)
        } else {
          reject(new Error(res.data?.error?.detail || res.data?.detail || `请求失败 (${res.statusCode})`))
        }
      },
      fail(err) {
        reject(new Error(err.errMsg || '网络连接失败，请检查后端服务是否运行'))
      }
    })
  })
}

/**
 * 调用 AI 对话接口（简单代理，无 tool-calling，保留用于 report/writing 等模式）
 * @param {Array<{role: string, content: string}>} messages
 * @param {string} systemPrompt
 * @returns {Promise<string>} - AI 回复文本
 */
export function chatCompletion(messages, systemPrompt) {
  return new Promise((resolve, reject) => {
    const fullMessages = [
      { role: 'system', content: systemPrompt },
      ...messages
    ]

    uni.request({
      url: `${API_BASE}/v1/chat/completions`,
      method: 'POST',
      header: { 'Content-Type': 'application/json' },
      data: {
        model: 'qwen-plus',
        messages: fullMessages,
        temperature: 0.7,
        max_tokens: 1000
      },
      timeout: 30000,
      success(res) {
        if (res.statusCode === 200 && res.data?.choices?.[0]?.message?.content) {
          resolve(res.data.choices[0].message.content)
        } else {
          reject(new Error(res.data?.error?.message || `请求失败 (${res.statusCode})`))
        }
      },
      fail(err) {
        reject(new Error(err.errMsg || '网络连接失败，请检查后端服务是否运行'))
      }
    })
  })
}

/**
 * 本地 organize（无需 API）
 * @param {string} text
 * @returns {{ summary: string, tags: string[], cleanedText: string }}
 */
export function organize(text) {
  const raw = normalizeText(text)
  const summary = fallbackSummary(raw)
  const tags = fallbackTags(raw)
  const cleanedText = raw.replace(/\r\n/g, '\n').replace(/\n{3,}/g, '\n\n').trim()
  return { summary, tags, cleanedText }
}
