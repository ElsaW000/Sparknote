// Spark_Vault_uniapp/tests/test_home_surface.mjs
import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const home = fs.readFileSync(path.join(root, 'src/pages/home/index.vue'), 'utf8')
const pages = JSON.parse(fs.readFileSync(path.join(root, 'src/pages.json'), 'utf8'))
const tabPaths = pages.tabBar.list.map((item) => item.pagePath)

assert.equal(home.includes('已保存的内容'), false)
assert.equal(home.includes('重点记录'), false)
assert.equal(home.includes('已创建标签'), false)
assert.equal(home.includes('最近内容来源'), false)
assert.equal(home.includes('图片 / 录音 / 随手记'), false)
assert.equal(home.includes('把内容整理成摘要'), false)
assert.equal(home.includes('把多条记录生成回顾'), false)
assert.equal(home.includes('查看保存过的整理'), false)
assert.equal(home.includes('按时间更新'), false)
assert.equal(home.includes('LibraryPage'), true)
assert.equal(home.includes('embedded'), true)
assert.equal(home.includes('openEmbeddedQuickComposer'), true)
const library = fs.readFileSync(path.join(root, 'src/pages/library/index.vue'), 'utf8')
assert.equal(library.includes('.library-embedded'), true)
assert.equal(library.includes('margin-top: 30rpx'), true)
assert.equal(home.includes('metrics.totalFragments'), true)
assert.equal(home.includes('metrics.favoriteFragments'), true)
assert.equal(home.includes('metrics.tagCount'), true)
assert.equal(home.includes('metrics.primarySource'), true)
assert.equal(tabPaths.includes('pages/library/index'), false)
assert.equal(tabPaths.includes('pages/home/index'), true)

console.log('home surface tests passed')
