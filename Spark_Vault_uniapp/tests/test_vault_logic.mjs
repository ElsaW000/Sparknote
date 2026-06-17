// Spark_Vault_uniapp/tests/test_vault_logic.mjs
import assert from 'node:assert/strict'

import {
  createFragment,
  fallbackSummary,
  fallbackTags,
  filterFragments,
  generateLocalWorkspaceReport,
  generateWeeklyDigest,
  mergeFragments,
  SOURCE_TYPES
} from '../src/services/vaultLogic.js'
import { createVaultRepository } from '../src/services/vaultRepository.js'
import { createVaultStore, vaultStore } from '../src/store/vaultStore.js'
import { analyzeImportText, extractLinks } from '../src/services/captureImport.js'

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
  assert.ok(SOURCE_TYPES.includes('Book'))
  assert.ok(vaultStore?.state)
}

{
  const links = extractLinks('Read https://example.com/a, then www.test.com/path. Again https://example.com/a')
  assert.deepEqual(links, ['https://example.com/a', 'https://www.test.com/path'])
  const analysis = analyzeImportText('one\nhttps://a.com\nwww.b.com')
  assert.equal(analysis.lineCount, 3)
  assert.equal(analysis.linkCount, 2)
  assert.equal(analysis.hasContent, true)
}

{
  const rich = createFragment({
    title: 'Rich note',
    content: 'Paragraph text',
    blocks: [{ id: 'paragraph_1', type: 'paragraph', text: 'Paragraph text' }],
    category: 'thought',
    source: '我自己'
  })
  assert.equal(rich.title, 'Rich note')
  assert.equal(rich.blocks.length, 1)
  assert.equal(rich.category, 'thought')
  assert.equal(rich.source, '我自己')
}

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
  assert.equal(fragment.form_kind, '想法')
  assert.equal(fragment.acquisition_method, 'manual')
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
  const voiceThought = createFragment({
    originalText: 'Walking note transcribed from voice',
    subtype: '录音',
    tags: ['Voice']
  })
  assert.equal(voiceThought.form_kind, '想法')
  assert.equal(voiceThought.subtype, '想法')
  assert.equal(voiceThought.acquisition_method, 'voice')

  const reference = createFragment({
    originalText: 'Reference paragraph',
    content_type: 'reference_content',
    form_kind: '书摘'
  })
  const fileReference = createFragment({
    originalText: 'Uploaded file note',
    content_type: 'reference_content',
    form_kind: '文件',
    file_path: 'blob:http://localhost/file.pdf'
  })
  const thought = createFragment({
    originalText: 'My reflection based on the reference',
    content_type: 'personal_content',
    form_kind: '想法',
    acquisition_method: 'manual',
    linked_fragment_ids: [reference.id, 'bad-id', 1.5]
  })
  assert.equal(reference.form_kind, '书摘')
  assert.equal(fileReference.file_path, 'blob:http://localhost/file.pdf')
  assert.equal(thought.form_kind, '想法')
  assert.deepEqual(thought.linked_fragment_ids, [reference.id])
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

  const savedReport = store.saveReport({ title: 'Local report', content: 'Report content' })
  assert.equal(savedReport.ok, true)
  assert.equal(store.getReportById(savedReport.report.id).title, 'Local report')
}

console.log('vault logic tests passed')
