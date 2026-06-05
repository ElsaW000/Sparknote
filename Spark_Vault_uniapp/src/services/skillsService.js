// Spark_Vault_uniapp/src/services/skillsService.js
// Manages AI mentor Skills (built-in + custom), stored in uni.storage.

import { BUILTIN_MENTORS } from './aiService.js'

const SKILLS_KEY = 'spark_vault_skills'

// Built-in skill enabled states
const BUILTIN_ENABLED_KEY = 'spark_vault_builtin_enabled'

function loadBuiltinEnabled() {
  try {
    const val = uni.getStorageSync(BUILTIN_ENABLED_KEY)
    if (val && typeof val === 'object') return val
  } catch (_) {}
  // Default: inamori and munger ON, socrates OFF
  return { inamori: true, munger: true, socrates: false }
}

function saveBuiltinEnabled(map) {
  try {
    uni.setStorageSync(BUILTIN_ENABLED_KEY, map)
  } catch (_) {}
}

function loadCustomSkills() {
  try {
    const val = uni.getStorageSync(SKILLS_KEY)
    if (Array.isArray(val)) return val
  } catch (_) {}
  return []
}

function saveCustomSkills(skills) {
  try {
    uni.setStorageSync(SKILLS_KEY, skills)
  } catch (_) {}
}

/**
 * Returns the full skill list: built-in (with enabled state) + custom.
 * @returns {Array<{id, name, emoji, desc, prompt, is_builtin, is_enabled}>}
 */
export function getSkills() {
  const enabledMap = loadBuiltinEnabled()
  const builtins = BUILTIN_MENTORS.map((m) => ({
    ...m,
    is_builtin: true,
    is_enabled: enabledMap[m.id] !== false
  }))
  const custom = loadCustomSkills().map((s) => ({
    ...s,
    is_builtin: false,
    is_enabled: true
  }))
  return [...builtins, ...custom]
}

/**
 * Returns only enabled skills (for Chat mentor selection).
 */
export function getEnabledMentors() {
  return getSkills().filter((s) => s.is_enabled)
}

/**
 * Toggle a built-in mentor's enabled state.
 * @param {string} id
 */
export function toggleBuiltin(id) {
  const map = loadBuiltinEnabled()
  map[id] = !map[id]
  saveBuiltinEnabled(map)
}

/**
 * Create a new custom skill.
 * @param {{name: string, emoji: string, desc: string, prompt: string}} input
 */
export function createSkill(input) {
  const skills = loadCustomSkills()
  const skill = {
    id: `custom_${Date.now()}`,
    name: (input.name || '').trim(),
    emoji: (input.emoji || '🎯').trim(),
    desc: (input.desc || '').trim(),
    prompt: (input.prompt || '').trim()
  }
  if (!skill.name) throw new Error('导师名称不能为空')
  skills.push(skill)
  saveCustomSkills(skills)
  return skill
}

/**
 * Update an existing custom skill.
 * @param {string} id
 * @param {{name?, emoji?, desc?, prompt?}} patch
 */
export function updateSkill(id, patch) {
  const skills = loadCustomSkills()
  const idx = skills.findIndex((s) => s.id === id)
  if (idx === -1) throw new Error('Skill not found')
  skills[idx] = { ...skills[idx], ...patch }
  saveCustomSkills(skills)
  return skills[idx]
}

/**
 * Delete a custom skill by id.
 * @param {string} id
 */
export function deleteSkill(id) {
  const skills = loadCustomSkills().filter((s) => s.id !== id)
  saveCustomSkills(skills)
}
