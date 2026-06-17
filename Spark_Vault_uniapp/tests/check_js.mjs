// Spark_Vault_uniapp/tests/check_js.mjs
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import path from 'node:path'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const files = [
  'src/models/fragment.js',
  'src/models/report.js',
  'src/services/vaultLogic.js',
  'src/services/vaultRepository.js',
  'src/services/captureImport.js',
  'src/services/iconifyIcons.js',
  'src/store/vaultStore.js',
  'tests/test_vault_logic.mjs',
  'tests/test_home_surface.mjs',
  'tests/test_workspace_surface.mjs',
  'vite.config.js'
]

for (const file of files) {
  const result = spawnSync(process.execPath, ['--check', path.join(root, file)], {
    encoding: 'utf8'
  })
  if (result.status !== 0) {
    process.stderr.write(result.stderr || result.stdout)
    process.exit(result.status || 1)
  }
}

console.log('js syntax checks passed')
