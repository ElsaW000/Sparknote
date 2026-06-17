// Spark_Vault_uniapp/src/services/captureImport.js
import { normalizeText } from './vaultLogic.js'

const URL_PATTERN = /(?:https?:\/\/|www\.)[^\s<>"'，。；、]+/gi

export function normalizeUrl(url = '') {
  const trimmed = normalizeText(url).replace(/[)\]}.,;!?]+$/g, '')
  if (!trimmed) return ''
  return /^https?:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`
}

export function extractLinks(text = '') {
  const matches = String(text || '').match(URL_PATTERN) || []
  const seen = new Set()
  return matches
    .map(normalizeUrl)
    .filter(Boolean)
    .filter((url) => {
      const key = url.toLowerCase()
      if (seen.has(key)) return false
      seen.add(key)
      return true
    })
}

export function analyzeImportText(text = '') {
  const content = normalizeText(text)
  const links = extractLinks(content)
  const lines = content ? content.split(/\r?\n/).map((line) => line.trim()).filter(Boolean) : []
  return {
    content,
    links,
    linkCount: links.length,
    lineCount: lines.length,
    hasContent: Boolean(content)
  }
}
