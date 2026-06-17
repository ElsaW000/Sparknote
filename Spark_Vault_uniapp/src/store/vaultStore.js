// Spark_Vault_uniapp/store/vaultStore.js
import {
  computeMetrics,
  createChatSession,
  createFragment,
  filterFragments,
  generateLocalWorkspaceReport,
  generateWeeklyDigest,
  normalizeText,
  parseTags
} from '../services/vaultLogic.js'
import { createVaultRepository } from '../services/vaultRepository.js'

function createInitialState() {
  return {
    fragments: [],
    reports: [],
    sessions: [],
    filters: { query: '', chip: '全部' },
    metrics: computeMetrics([], [], []),
    filteredFragments: [],
    weeklyDigest: '',
    workspaceResult: null,
    error: ''
  }
}

function toResult(fn) {
  try {
    return { ok: true, ...fn() }
  } catch (error) {
    return { ok: false, error: error?.message || 'Unexpected vault error' }
  }
}

export function createVaultStore(options = {}) {
  const repository = options.repository || createVaultRepository()
  const state = createInitialState()

  function refresh() {
    state.fragments = repository.getFragments()
    state.reports = repository.getReports()
    state.sessions = repository.getSessions()
    state.filteredFragments = filterFragments(state.fragments, state.filters)
    state.metrics = computeMetrics(state.fragments, state.reports, state.sessions)
    state.weeklyDigest = generateWeeklyDigest(state.fragments)
    return state
  }

  function clearError() { state.error = '' }

  // --- Fragment CRUD ---
  function saveFragment(input = {}) {
    return toResult(() => {
      clearError()
      const fragment = createFragment(input)
      repository.saveFragment(fragment)
      refresh()
      return { fragment }
    })
  }

  function updateFragment(id, input = {}) {
    return toResult(() => {
      clearError()
      const existing = repository.getFragmentById(Number(id))
      if (!existing) throw new Error('Fragment not found')
      const fragment = createFragment({
        ...existing,
        ...input,
        id: existing.id,
        tags: input.tags ?? parseTags(input.tagsText ?? existing.tags ?? []),
        created_at: existing.created_at,
        updated_at: Date.now()
      })
      repository.saveFragment(fragment)
      refresh()
      return { fragment }
    })
  }

  function deleteFragment(id) {
    return toResult(() => {
      clearError()
      repository.deleteFragment(Number(id))
      refresh()
      return {}
    })
  }

  function getFragmentById(id) {
    return repository.getFragmentById(Number(id))
  }

  // --- Filters ---
  function updateFilters(patch = {}) {
    state.filters = { ...state.filters, ...patch }
    state.filteredFragments = filterFragments(state.fragments, state.filters)
    return state.filteredFragments
  }

  // --- Sessions ---
  function saveSession(input = {}) {
    return toResult(() => {
      clearError()
      const session = createChatSession(input)
      repository.saveSession(session)
      refresh()
      return { session }
    })
  }

  function updateSession(id, patch = {}) {
    return toResult(() => {
      clearError()
      const existing = repository.getSessionById(Number(id))
      if (!existing) throw new Error('Session not found')
      const updated = { ...existing, ...patch, id: existing.id, updated_at: Date.now() }
      repository.saveSession(updated)
      refresh()
      return { session: updated }
    })
  }

  function deleteSession(id) {
    return toResult(() => {
      clearError()
      repository.deleteSession(Number(id))
      refresh()
      return {}
    })
  }

  function getSessionById(id) {
    return repository.getSessionById(Number(id))
  }

  // --- Reports ---
  function getReportById(id) {
    return repository.getReportById(Number(id))
  }

  function saveReport(input = {}) {
    return toResult(() => {
      clearError()
      const report = repository.saveReport(input)
      refresh()
      return { report }
    })
  }

  function deleteReport(id) {
    return toResult(() => {
      clearError()
      repository.deleteReport(Number(id))
      refresh()
      return {}
    })
  }

  function generateWorkspaceReport(input = {}) {
    return toResult(() => {
      clearError()
      const prompt = normalizeText(input.prompt)
      const reportType = normalizeText(input.reportType) || 'Outline'
      const localReport = generateLocalWorkspaceReport(prompt, state.fragments, reportType)
      const report = repository.saveReport({
        title: `${reportType} · ${prompt || 'Workspace'}`,
        content: localReport.content,
        relatedFragmentIds: localReport.relevantIds
      })
      state.workspaceResult = {
        reportId: report.id,
        prompt,
        reportType,
        relevantIds: localReport.relevantIds
      }
      refresh()
      return { report, workspaceResult: state.workspaceResult }
    })
  }

  // --- Init ---
  refresh()

  return {
    state,
    refresh,
    saveFragment,
    updateFragment,
    deleteFragment,
    getFragmentById,
    updateFilters,
    saveSession,
    updateSession,
    deleteSession,
    getSessionById,
    getReportById,
    saveReport,
    deleteReport,
    generateWorkspaceReport
  }
}

// Singleton for app-wide use
let _store = null
export function getVaultStore() {
  if (!_store) _store = createVaultStore()
  return _store
}

export const vaultStore = getVaultStore()
