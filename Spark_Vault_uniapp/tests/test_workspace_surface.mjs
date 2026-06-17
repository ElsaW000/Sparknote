// Spark_Vault_uniapp/tests/test_workspace_surface.mjs
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const workspace = fs.readFileSync(path.join(root, 'src/pages/workspace/index.vue'), 'utf8')
const pages = fs.readFileSync(path.join(root, 'src/pages.json'), 'utf8')

assert.equal(workspace.includes('CHAT_MODES'), true)
assert.equal(workspace.includes('getEnabledMentors'), true)
assert.equal(workspace.includes('startSession'), true)
assert.equal(workspace.includes('/pages/chat/session'), true)
assert.equal(workspace.includes('reflection-block'), true)
assert.equal(pages.includes('{ "pagePath": "pages/chat/index", "text": "照见" }'), false)
assert.equal(pages.includes('{ "pagePath": "pages/workspace/index", "text": "整理" }'), true)

console.log('workspace surface tests passed')
