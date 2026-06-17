// Spark_Vault_uniapp/src/services/iconifyIcons.js
import { addCollection } from '@iconify/vue'
import { icons as lucideIcons } from '@iconify-json/lucide'
import { icons as phosphorIcons } from '@iconify-json/ph'
import { icons as remixIcons } from '@iconify-json/ri'
import { icons as materialIcons } from '@iconify-json/material-symbols'

let registered = false

export function ensureIconifyCollections() {
  if (registered) return
  addCollection(lucideIcons)
  addCollection(phosphorIcons)
  addCollection(remixIcons)
  addCollection(materialIcons)
  registered = true
}
