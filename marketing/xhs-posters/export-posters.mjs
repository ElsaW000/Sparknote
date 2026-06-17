// File: marketing/xhs-posters/export-posters.mjs
import { spawnSync } from 'node:child_process'
import { existsSync, mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const htmlPath = resolve(__dirname, 'index.html')
const outputDir = resolve(__dirname, 'dist')

const candidates = [
  process.env.CHROME_PATH,
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe'
].filter(Boolean)

function findBrowser() {
  return candidates.find((candidate) => existsSync(candidate))
}

function assertReady() {
  if (!existsSync(htmlPath)) {
    throw new Error(`Poster HTML not found: ${htmlPath}`)
  }
  const browser = findBrowser()
  if (!browser) {
    throw new Error('Chrome or Microsoft Edge was not found. Set CHROME_PATH to a Chromium browser executable.')
  }
  return browser
}

function exportCard(browser, index) {
  const outputPath = resolve(outputDir, `mirrorme-xhs-${String(index).padStart(2, '0')}.png`)
  const url = `${pathToFileURL(htmlPath).href}?card=${index}`
  const result = spawnSync(browser, [
    '--headless=new',
    '--disable-gpu',
    '--hide-scrollbars',
    '--no-first-run',
    '--window-size=1080,1440',
    `--screenshot=${outputPath}`,
    url
  ], { encoding: 'utf8' })

  if (result.error) {
    throw result.error
  }
  if (result.status !== 0) {
    const details = [result.stderr, result.stdout].filter(Boolean).join('\n')
    throw new Error(`Browser export failed for card ${index}.\n${details}`)
  }
  if (!existsSync(outputPath)) {
    throw new Error(`Export did not create expected file: ${outputPath}`)
  }
  return outputPath
}

function main() {
  const browser = assertReady()
  mkdirSync(outputDir, { recursive: true })
  const outputs = []
  for (let index = 1; index <= 8; index += 1) {
    outputs.push(exportCard(browser, index))
  }
  console.log(outputs.join('\n'))
}

try {
  main()
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error))
  process.exit(1)
}
