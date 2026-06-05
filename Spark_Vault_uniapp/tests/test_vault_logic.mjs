// Spark_Vault_uniapp/tests/test_vault_logic.mjs
import assert from 'node:assert/strict'

import {
  createFragment,
  fallbackSummary,
  fallbackTags,
  filterFragments,
  generateLocalWorkspaceReport,
  generateWeeklyDigest,
  mergeFragments
} from '../src/services/vaultLogic.js'
import { createVaultRepository } from '../src/services/vaultRepository.js'
import { createVaultStore } from '../src/store/vaultStore.js'

function createMemoryStorage() {
  const data = new Map()
  return {
    getStorageSync(key) {
      return data.get(key)
    },
    setStorageSync(key, value) {
      data.set(key, value)
    },
    removeStorageSync(key) {
      data.delete(key)
    }
  }
}

function assertIncludes(text, expected) {
  assert.equal(typeof text, 'string')
  assert.ok(text.includes(expected), `Expected "${text}" to include "${expected}"`)
}

const longText = 'Systems compound when repeated with intention, context, and careful review across different sources.'

{
  const fragment = createFragment({
    originalText: longText,
    sourceType: 'Book',
    sourceTitle: 'Atomic Habits',
    author: 'James Clear',
    tagsText: 'Systems, Growth, Systems',
    userComment: 'Use process over goals.'
  })

  assert.equal(fragment.originalText, longText)
  assert.equal(fragment.sourceType, 'Book')
  assert.deepEqual(fragment.tags, ['Systems', 'Growth'])
  assert.equal(fragment.favoriteStatus, false)
  assert.ok(Number.isInteger(fragment.id))
  assert.ok(fragment.createdAt > 0)
  assertIncludes(fragment.aiSummary, 'Systems compound')
}

{
  assert.throws(() => createFragment({ originalText: '   ' }), /Fragment text is required/)
  assert.deepEqual(fallbackTags('AI systems connect creativity and research systems.'), ['Systems', 'Connect', 'Creativity'])
  assert.equal(fallbackSummary('short note'), 'short note')
  assert.equal(fallbackSummary(`${'a'.repeat(90)} trailing`).length, 83)
}

{
  const fragments = [
    createFragment({ originalText: 'AI writing workflow', sourceType: 'Browser', tags: ['AI'], favoriteStatus: true }),
    createFragment({ originalText: 'Reading method', sourceType: 'Book', tags: ['Reading'], favoriteStatus: false }),
    createFragment({ originalText: 'Research synthesis', sourceType: 'Book', tags: ['AI', 'Research'], favoriteStatus: true })
  ]

  assert.equal(filterFragments(fragments, { query: 'research' }).length, 1)
  assert.equal(filterFragments(fragments, { sourceType: 'Book' }).length, 2)
  assert.equal(filterFragments(fragments, { selectedTag: 'AI', onlyFavorites: true }).length, 2)
}

{
  const first = createFragment({ originalText: 'First thought', sourceType: 'Book', sourceTitle: 'Book A', tags: ['Ideas'] })
  const second = createFragment({ originalText: 'Second thought', sourceType: 'Book', sourceTitle: 'Book B', tags: ['Ideas', 'Draft'] })
  const merged = mergeFragments([first, second], 'Merged title')

  assert.equal(merged.sourceTitle, 'Merged title')
  assert.deepEqual(merged.tags, ['Ideas', 'Draft'])
  assertIncludes(merged.originalText, 'First thought')
  assertIncludes(merged.originalText, 'Second thought')
  assert.throws(() => mergeFragments([first], 'Too few'), /At least two fragments/)
}

{
  const fragments = [
    createFragment({ originalText: 'AI systems for writing', tags: ['AI'], favoriteStatus: true }),
    createFragment({ originalText: 'Garden notes', tags: ['Nature'], favoriteStatus: false })
  ]
  const report = generateLocalWorkspaceReport('AI writing', fragments, 'Outline')

  assertIncludes(report.content, 'Synthesized Outline')
  assert.deepEqual(report.relevantIds, [fragments[0].id])
  assertIncludes(generateWeeklyDigest(fragments), 'Total Fragments')
}

{
  const repository = createVaultRepository({ storage: createMemoryStorage() })
  repository.clearAll()
  const saved = repository.saveFragment(createFragment({ originalText: 'Repository note', tags: ['Storage'] }))
  assert.equal(repository.getFragments().length, 1)
  repository.updateFragment(saved.id, { favoriteStatus: true })
  assert.equal(repository.getFragmentById(saved.id).favoriteStatus, true)
  repository.deleteFragment(saved.id)
  assert.equal(repository.getFragments().length, 0)
}

{
  const store = createVaultStore({ repository: createVaultRepository({ storage: createMemoryStorage() }) })
  const emptySave = store.saveFragment({ originalText: '' })
  assert.equal(emptySave.ok, false)
  assertIncludes(emptySave.error, 'required')

  const saved = store.saveFragment({ originalText: 'Store note for workspace', sourceType: 'Book', tagsText: 'Store' })
  assert.equal(saved.ok, true)
  assert.equal(store.state.metrics.totalFragments, 1)

  const reportResult = store.generateWorkspaceReport({ prompt: 'workspace', reportType: 'Ideas' })
  assert.equal(reportResult.ok, true)
  assert.equal(store.state.reports.length, 1)
  assert.equal(store.state.workspaceResult.reportId, reportResult.report.id)
}

console.log('vault logic tests passed')
