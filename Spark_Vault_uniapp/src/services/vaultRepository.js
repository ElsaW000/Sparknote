// Spark_Vault_uniapp/services/vaultRepository.js
import { createReport } from './vaultLogic.js'

const FRAGMENTS_KEY = 'spark_vault_fragments'
const REPORTS_KEY = 'spark_vault_reports'
const SESSIONS_KEY = 'spark_vault_sessions'

function resolveStorage(storage) {
  if (storage) return storage
  if (typeof uni !== 'undefined') return uni
  const memory = new Map()
  return {
    getStorageSync(key) {
      return memory.get(key)
    },
    setStorageSync(key, value) {
      memory.set(key, value)
    },
    removeStorageSync(key) {
      memory.delete(key)
    }
  }
}

function readList(storage, key) {
  try {
    const value = storage.getStorageSync(key)
    if (Array.isArray(value)) return value
    if (typeof value === 'string' && value.trim()) {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    }
  } catch (error) {
    console.error(`Failed to read ${key}`, error)
  }
  return []
}

function writeList(storage, key, value) {
  try {
    storage.setStorageSync(key, Array.isArray(value) ? value : [])
  } catch (error) {
    console.error(`Failed to write ${key}`, error)
    throw new Error('Failed to save vault data')
  }
}

function sortByCreatedAtDesc(items) {
  return [...items].sort((a, b) => (b.created_at || b.createdAt || 0) - (a.created_at || a.createdAt || 0))
}

export function createVaultRepository(options = {}) {
  const storage = resolveStorage(options.storage)

  function getFragments() {
    return sortByCreatedAtDesc(readList(storage, FRAGMENTS_KEY))
  }

  function getReports() {
    return sortByCreatedAtDesc(readList(storage, REPORTS_KEY))
  }

  function getSessions() {
    return sortByCreatedAtDesc(readList(storage, SESSIONS_KEY))
  }

  function saveSession(session) {
    if (!session || !Number.isInteger(session.id)) throw new Error('Valid session is required')
    const list = getSessions()
    const index = list.findIndex((item) => item.id === session.id)
    const next = index >= 0
      ? list.map((item) => item.id === session.id ? session : item)
      : [session, ...list]
    writeList(storage, SESSIONS_KEY, next)
    return session
  }

  function deleteSession(id) {
    if (!Number.isInteger(id)) throw new Error('Valid session id is required')
    writeList(storage, SESSIONS_KEY, getSessions().filter((item) => item.id !== id))
  }

  function getSessionById(id) {
    if (!Number.isInteger(id)) return null
    return getSessions().find((item) => item.id === id) || null
  }

  function saveFragment(fragment) {
    if (!fragment || !Number.isInteger(fragment.id)) {
      throw new Error('Valid fragment is required')
    }
    const list = getFragments()
    const index = list.findIndex((item) => item.id === fragment.id)
    const next = index >= 0
      ? list.map((item) => item.id === fragment.id ? fragment : item)
      : [fragment, ...list]
    writeList(storage, FRAGMENTS_KEY, next)
    return fragment
  }

  function updateFragment(id, patch = {}) {
    if (!Number.isInteger(id)) throw new Error('Valid fragment id is required')
    const existing = getFragments().find((item) => item.id === id)
    if (!existing) throw new Error('Fragment not found')
    return saveFragment({
      ...existing,
      ...patch,
      id,
      updatedAt: Date.now()
    })
  }

  function deleteFragment(id) {
    if (!Number.isInteger(id)) throw new Error('Valid fragment id is required')
    writeList(storage, FRAGMENTS_KEY, getFragments().filter((item) => item.id !== id))
  }

  function getFragmentById(id) {
    if (!Number.isInteger(id)) return null
    return getFragments().find((item) => item.id === id) || null
  }

  function saveReport(reportInput) {
    const report = createReport(reportInput)
    const list = getReports()
    const index = list.findIndex((item) => item.id === report.id)
    const next = index >= 0
      ? list.map((item) => item.id === report.id ? report : item)
      : [report, ...list]
    writeList(storage, REPORTS_KEY, next)
    return report
  }

  function deleteReport(id) {
    if (!Number.isInteger(id)) throw new Error('Valid report id is required')
    writeList(storage, REPORTS_KEY, getReports().filter((item) => item.id !== id))
  }

  function getReportById(id) {
    if (!Number.isInteger(id)) return null
    return getReports().find((item) => item.id === id) || null
  }

  function clearAll() {
    writeList(storage, FRAGMENTS_KEY, [])
    writeList(storage, REPORTS_KEY, [])
    writeList(storage, SESSIONS_KEY, [])
  }

  return {
    clearAll,
    deleteFragment,
    deleteReport,
    deleteSession,
    getFragmentById,
    getFragments,
    getReportById,
    getReports,
    getSessions,
    getSessionById,
    saveSession,
    saveFragment,
    saveReport,
    updateFragment
  }
}
