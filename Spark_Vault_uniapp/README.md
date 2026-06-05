# Spark Vault uni-app

Spark Vault is a Vue 3 uni-app migration of the Android prototype in `../google_ai_studio_android`.

## What Works Now

- Local fragment storage through `uni.setStorageSync` / `uni.getStorageSync`
- Dashboard metrics and weekly local digest
- Capture, edit, delete, favorite, filter, and merge fragments
- Workspace local synthesis reports with linked references
- Archive report history
- H5, App, Weixin, Alipay, Baidu, and Toutiao build script entries

## Current Position

This project is the active local-phone MVP candidate. H5, Weixin mini program, and App resource builds have been verified, but Android APK packaging through DCloud/HBuilderX has not been started.

The current short-term goal is to install and test it on a local Android phone.

## Project Layout

```text
src/models/      Field contracts for fragments and reports
src/services/    Pure vault logic and storage repository
src/store/       Shared page state and actions
src/pages/       uni-app pages
tests/           Node-based logic and syntax checks
```

## Setup

```bash
npm install
npm run verify
```

## Run

```bash
npm run dev:h5
npm run dev:mp-weixin
npm run dev:app
```

HBuilderX can also open this folder directly. This is a Vue 3 CLI-style uni-app project, so app source files live under `src/`: `src/manifest.json`, `src/pages.json`, `src/App.vue`, and `src/main.js`.

## Android Phone Test

Use this path for the first local phone install test:

```text
1. Open HBuilderX.
2. Open this folder: D:\02-Projects\01-Sparknote\Spark_Vault_uniapp
3. Open src/manifest.json in HBuilderX.
4. Get or fill a DCloud AppID.
5. Connect an Android phone with USB debugging enabled.
6. Use Run -> Run to phone or emulator -> Android App base.
```

For a standalone APK later, use HBuilderX:

```text
Release -> Native App cloud packaging
```

The current Android permissions are intentionally minimal: internet, network state, camera, and vibration. Broad legacy permissions such as reading phone state, reading system logs, changing Wi-Fi, changing system settings, and mounting file systems were removed because the current MVP does not need them.

## Build

```bash
npm run build:h5
npm run build:mp-weixin
npm run build:app
```

## Notes

- The current MVP is local-first. API integration should replace `src/services/vaultRepository.js` behind the same store API.
- Configure platform app IDs in `src/manifest.json` before publishing mini programs or native apps.
- Keep `tests/test_vault_logic.mjs` passing when changing vault behavior.
