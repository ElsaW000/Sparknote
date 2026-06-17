// File: tests/test_xhs_posters.mjs
import { readFileSync, existsSync } from 'node:fs'
import { resolve } from 'node:path'

const root = process.cwd()
const htmlPath = resolve(root, 'marketing/xhs-posters/index.html')
const scriptPath = resolve(root, 'marketing/xhs-posters/export-posters.mjs')

function assert(condition, message) {
  if (!condition) {
    throw new Error(message)
  }
}

assert(existsSync(htmlPath), 'index.html should exist')
assert(existsSync(scriptPath), 'export-posters.mjs should exist')

const html = readFileSync(htmlPath, 'utf8')
const posterCount = (html.match(/<section class="poster">/g) || []).length

assert(posterCount === 8, `expected 8 posters, got ${posterCount}`)
assert(html.includes('width: 1080px;'), 'poster width should be 1080px')
assert(html.includes('height: 1440px;'), 'poster height should be 1440px')
assert(html.includes('#004a77'), 'current UI primary color should be reused')
assert(html.includes('MirrorMe'), 'brand name should be present')
assert(html.includes('小红书') || html.includes('建议收藏'), 'XHS-friendly CTA should be present')

console.log('xhs poster source checks passed')
