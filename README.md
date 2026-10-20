# 茶茶手账 · Tea Diary

把每天的奶茶标签，变成日历里的一张蜡笔贴纸。一个优先本地、无需账号或 AI 密钥的奶茶打卡程序。

[下载 Mac 安装包](https://github.com/wxu430375-cloud/tea-diary/raw/refs/heads/main/downloads/TeaDiary-1.0.0-macos-arm64.dmg) · [下载源码](https://github.com/wxu430375-cloud/tea-diary/archive/refs/heads/main.zip)

![茶茶手账示例日历](docs/preview-desktop.png)

## 下载与安装

`dist/茶茶手账-1.0.0-macos-arm64.dmg` 是 Apple Silicon Mac 安装包，要求 macOS 13 或更新系统。打开后将「茶茶手账」拖入 Applications。安装版使用系统 WebKit 与 Apple Vision，无需 Node、Python 或 Java。

当前安装包为本地临时签名，未经过 Apple 开发者签名和公证；macOS 可能要求首次使用「右键 → 打开」。不建议关闭系统安全保护。Intel Mac 可在对应机器上从源码构建；Windows/Linux 当前只有浏览器本地版，没有原生安装包。

## 能做什么

- 上传 JPG、PNG、WebP 奶茶标签，使用 Apple Vision 离线识别简体/繁体中文和英文。
- 匹配品牌、单品；识别糖度与冰量，保存前可核对、修改。
- 首版收录 **11 个品牌、37 款单品**，每项有来源与核对日期；并非所有在售菜单，也不会后台联网更新。
- 记录日期、实际上传时间、品牌、单品、心情、备注、照片与识别文字。同一天可以记多杯。
- 月历、单日详情、品牌/原料搜索、贴纸图鉴、累计统计。
- 按食材主题创作的蜡笔插画与可复现的手绘贴纸；可导出独立 SVG 贴纸。
- 自定义单品、主要原料、颜色和手绘元素。
- JSON 完整导出/恢复，包含标签照片；恢复前明确确认替换。
- 空白启动。设置里的「示例手账」只存于内存，不会写入真实数据。

## 数据保存在何处

Mac 安装版：`~/Library/Application Support/TeaDiary/journal.json`。每次保存使用原子写入，并把上一个版本保存在 `journal.previous.json`。应用菜单可以打开数据目录。数据文件损坏时不自动覆盖。

照片压缩到最长边 2000 像素后和记录保存在一起，无远程上传、追踪脚本、云 API 或登录系统。请定期从「数据与备份」导出完整备份。

浏览器版：当前浏览器当前站点的 IndexedDB。它与 Mac 安装版是两个独立的数据空间，可以通过 JSON 导出与恢复迁移。清理浏览器数据、换浏览器或改端口前先备份。

## 从源码启动

Mac 安装版（需要 Apple Command Line Tools）：

```bash
bash scripts/build-mac.sh
open dist/茶茶手账.app
```

本地浏览器版（Python 3.9+）：

```bash
python3 server.py
```

然后打开 `http://127.0.0.1:8765`。Mac 也可双击 `启动茶茶手账.command`。服务只监听本机回环地址。

浏览器版离线 OCR：在 Mac 上先运行构建脚本，服务器会使用 `build/tea-ocr`。Windows/Linux 需自行安装 Tesseract 及 `chi_sim`、`eng` 语言包；未安装时可粘贴标签文字或手动选择单品。Mac 原生安装版无需此步骤。

## 匹配与插画说明

OCR 负责读字；单品匹配使用品牌别名、完整产品名、产品别名和相邻字相似度，没有在线大模型。品牌缺失、品牌冲突、未知单品或模糊照片需要人工确认。它不会根据看不见的标签内容猜测配料。上传文件中的文字始终作为数据，不执行指令。

插画是食材主题的创作印象，不是实物图或完整配方证明。当前有八张内置蜡笔插画素材，配合品牌标识与程序手绘元素复用；**并非已经为37款产品逐款绘制37张独立原画**。未覆盖主题及自定义款使用按配料主题、颜色、确定性笔触绘制的 SVG。图片生成仅发生在开发时，运行应用无需生成服务。

一点点、CoCo、霸王茶姬的部分标识来自品牌网站；其他标识为品牌文字版。品牌商标归原权利人所有，本项目与品牌无隶属或授权关系。官方与第三方菜单分开注明，海外/香港菜单有区域标记。资料只是风味与主要原料摘要，不用于过敏原判断，也不包含未经核实的营养数据。详见 `docs/sources.md`、`docs/illustrations.md` 与 `THIRD_PARTY_NOTICES.md`。

## 检查与发布

```bash
node tests/matching.cjs
node tests/backup.cjs
node --check web/app.js
bash scripts/build-mac.sh
bash scripts/package-mac.sh
```

验证记录见 `docs/validation.md`。开源源码使用 MIT；第三方品牌标识不适用 MIT 授权。

## 目录

- `web/`：无依赖界面、资料库、手绘贴纸、IndexedDB 存储。
- `native/TeaDiary.swift`：Mac 应用、离线 OCR、本地文件存储与原生文件选择/导出。
- `native/OCR.swift`：浏览器本地服务器使用的 Vision OCR 命令行辅助程序。
- `server.py`：Python 标准库本机服务器及可选离线 OCR。
- `scripts/`：可复现构建、打包与标识来源下载脚本。

欢迎通过补充来源、单品别名、OCR 样本和逐款独立插画完善资料库。
