# MirrorMe 小红书海报

这组海报参考了当前 uni-app UI 的暖白纸感、深海蓝主色、金色强调、白卡片和仪表盘信息层级，尺寸为小红书常用的 `1080x1440`。

## 文件

- `index.html`: 可编辑海报源文件，浏览器打开即可预览 8 张连续海报。
- `export-posters.mjs`: 使用本机 Chrome 或 Edge 导出 PNG。
- `dist/`: 导出的 PNG 文件目录。

## 导出

```powershell
node .\marketing\xhs-posters\export-posters.mjs
```

如果浏览器不在默认路径，可以设置 `CHROME_PATH` 指向 Chromium 浏览器可执行文件。
