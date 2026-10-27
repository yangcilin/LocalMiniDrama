# LocalMiniDrama 启动与基础配置指南

研究日期：2026-10-27。对应本地项目 v1.2.9，Git 提交 `caea265`。

项目目录：`C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama`。

本文根据本地源码、配置、依赖锁文件和启动脚本整理；与仓库旧说明冲突时，以当前代码为准。初次研究完成静态核对和环境检查，后续安装结果见下方记录。

### 后续实机安装记录（2026-10-27）

- 已完成前端依赖安装与构建，后端依赖安装成功（352 个包）。
- 后端实际使用电脑已有的 Node.js `22.13.0`，SQLite 内存查询、Sharp 及三个 Mastra 助手模块加载均通过。
- `22.22.0` 是根据全部锁定依赖声明得出的推荐下限；实测本机 `22.13.0` 未阻塞上述安装与加载验证，因此无需为本次安装强制升级。尚未验证所有业务功能。
- Node.js `24.9.0` 试装后端失败，原因是当前 SQLite 依赖缺少该版本对应的预编译包，随后本机编译失败。建议本项目继续使用已验证的 `22.13.0`。
- 未下载新 Node.js，未修改全局默认版本，未启动前后端服务、初始化业务数据库或调用付费 AI。
- 可复用安装脚本：`AI视频/LocalMiniDrama_安装依赖.ps1`；日志：`AI视频/LocalMiniDrama_install_logs/`。脚本使用本机现有 Node.js 22.13.0，默认安装前后端；仅安装后端可传 `-Component backend-node`。

下方环境检查表是初次研究时的快照；当前安装状态以上述实机记录为准。

## 1. 先看结论

建议先用“浏览器开发模式”启动：在两个 PowerShell 窗口分别运行后端和前端，然后访问 <http://localhost:3013>。

| 项目 | 当前结论 |
| --- | --- |
| Node.js | 建议使用最新 Node.js 22.x，至少 `22.22.0`，原因见下文 |
| 后端 | `backend-node`，Express，默认端口 `5679` |
| 前端 | `frontweb`，Vue 3 + Vite，默认端口 `3013` |
| 数据库 | 内嵌 SQLite，自动建库和迁移，无需安装 MySQL/PostgreSQL |
| AI 服务 | 通过界面“AI 配置”添加，API Key 等存入 SQLite |
| FFmpeg | 仓库已包含可运行的 `ffmpeg.exe`；还缺 `ffprobe.exe` |
| 显卡 | 调用云端 API 的常规用法不要求本机有 NVIDIA 显卡 |
| Python | 常规运行不用配置 Python；原生依赖需要本机编译时才可能需要 |
| Electron | 浏览器模式不需要；需要桌面窗口或打包 exe 时再安装 |

“本地”指应用、数据库和生成文件主要保存在本机。调用云端 AI 时，剧本、提示词、参考图片等仍会发往对应服务商；部分流程还会使用公网图床。

## 2. 本机检查结果

| 检查项 | 本次结果 | 下一步 |
| --- | --- | --- |
| Node.js | `v22.13.0` | 建议升级到最新 22.x，至少 `22.22.0` |
| npm | `11.17.0` | 可使用 `npm.cmd` 执行下方命令 |
| 后端依赖 | 没有 `backend-node/node_modules` | 首次安装 |
| 前端依赖 | 没有 `frontweb/node_modules` | 首次安装 |
| 桌面依赖 | 没有 `desktop/node_modules` | 浏览器模式可暂不安装 |
| 后端配置 | 已有 `backend-node/configs/config.yaml` | 直接使用，不要覆盖 |
| 前端构建产物 | 没有 `frontweb/dist/index.html` | 开发模式不需要，单服务/桌面模式需要构建 |
| 内置 FFmpeg | 实测版本 `8.0.1`，`-version` 正常退出 | 源码模式可直接识别 |
| FFprobe | 内置目录没有，当前 PATH 也未找到 | 需要完整音视频后处理时补齐 |

### 为什么不按 README 使用 Node.js 18？

虽然项目 `package.json` 和 README 仍声明 Node.js `>=18`，当前锁文件中：

- `@mastra/core`、`@mastra/libsql`、`@mastra/memory` 要求 `>=22.13.0`。
- 间接依赖 `posthog-node@5.56.1` 要求 `^20.20.0 || >=22.22.0`。

合并这些要求，使用 Node.js 22 系列时应至少为 `22.22.0`。本机的 `22.13.0` 尚未满足全部锁定依赖的声明要求，安装时可能出现 `EBADENGINE`。这属于依赖声明检查结果，不代表已实测该版本一定无法启动。

升级后重新打开 PowerShell，检查：

```powershell
node --version
npm.cmd --version
Get-Command node
```

如电脑已通过 nvm 管理 Node.js，使用原来的版本管理方式升级即可。Node.js 官方下载：<https://nodejs.org/en/download>。

## 3. 首次启动：浏览器开发模式

下方使用 `npm.cmd`，可以避开 Windows PowerShell 因执行策略阻止 `npm.ps1` 的问题。每步需成功完成后再执行下一步。

### 3.1 窗口一：安装并启动后端

```powershell
Set-Location -LiteralPath 'C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama\backend-node'

npm.cmd ci
npm.cmd run migrate
npm.cmd run dev
```

说明：

- 仓库带有 `package-lock.json`，且与各自 `package.json` 的依赖声明一致，因此首次安装优先使用 `npm ci`。
- `configs/config.yaml` 已存在。本地仓库没有 `config.example.yaml`，不要执行旧文档里的复制模板命令。
- `npm run migrate` 会初始化数据库并执行迁移；应用启动本身也会执行迁移和补列。首次单独执行有助于提前发现数据库错误。
- 开发命令实际使用 `node --watch src/server.js`，不是 nodemon。
- 不修改代码时可用 `npm.cmd start`，运行同一后端但不监听文件变更。
- 保持当前终端运行。

后端默认地址：<http://localhost:5679>。健康检查：<http://localhost:5679/health>。

健康检查应返回类似：

```json
{"status":"ok","app":"LocalMiniDrama API","version":"1.0.0"}
```

这里的 `1.0.0` 来自 YAML 的 `app.version`，不代表项目包版本回退了；三个子项目包版本为 `1.2.9`。

### 3.2 窗口二：安装并启动前端

```powershell
Set-Location -LiteralPath 'C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama\frontweb'

npm.cmd ci
npm.cmd run dev
```

浏览器访问 <http://localhost:3013>，以 Vite 终端实际输出地址为准。端口被占用时，Vite 可能改用下一个端口。

Vite 将 `/api` 和 `/static` 代理到 `http://127.0.0.1:5679`，因此正常开发时前端、后端两个服务都要保持运行。

### 3.3 窗口三：确认后端状态

```powershell
Invoke-RestMethod -Uri 'http://127.0.0.1:5679/health'
Invoke-RestMethod -Uri 'http://127.0.0.1:5679/api/v1/dramas'
```

先确认健康检查返回 `status: ok`，再确认项目列表接口能返回 JSON。未配置 AI Key 时，可以打开界面和验证项目管理；实际 AI 生成功能需要相应配置。

### 3.4 后续启动与停止

依赖安装好后，日常只需分别进入 `backend-node`、`frontweb`，执行各自的 `npm.cmd run dev`。无需每次重新安装依赖或手动迁移。

在两个运行终端分别按 `Ctrl+C` 停止服务。若后续源码更新了依赖，再按更新后的锁文件重新安装。

### 3.5 仓库的一键脚本注意事项

首次建议使用上面的两个终端方式，方便判断失败发生在哪一侧。

| 文件 | 当前实际行为 | 注意事项 |
| --- | --- | --- |
| `run_dev.ps1` | 打开两个 PowerShell 窗口运行前后端开发命令 | 显示的 `3013/5173` 端口提示已过时；脚本本身不会打开浏览器 |
| `run_dev.bat` | 启动前后端并打开 `http://127.0.0.1:3013` | 会强制终止占用 `5679` 的进程，可能影响其他服务；末尾端口文字同样不准确 |

两个脚本均不负责安装依赖。真实默认端口为后端 `5679`、前端 `3013`。

## 4. 基础配置：YAML 与界面分别管什么

### 4.1 服务配置文件

源码模式配置文件：`LocalMiniDrama\backend-node\configs\config.yaml`。

端口、文件目录等基础设置放在 YAML；API Key、模型、接口规范等 AI 配置主要通过界面维护，保存在数据库中。仓库没有通过 `.env` 统一管理这些配置的启动流程。

当前重要配置：

| 配置项 | 仓库当前值 | 用途与建议 |
| --- | --- | --- |
| `app.language` | `zh` | 提示词语言，中文/英文；也可通过界面语言设置管理 |
| `server.port` | `5679` | 后端端口；源码 `server.js` 也支持环境变量 `PORT` 覆盖 |
| `server.host` | `0.0.0.0` | 源码后端监听全部网卡；仅本机使用可改为 `127.0.0.1` |
| `server.cors_origins` | `http://localhost:3012` | 是遗留值；若浏览器跨域直连后端，填写实际前端来源 |
| `server.insecure_tls` | `true` | 源码 `server.js` 会全局关闭 TLS 证书校验；网络证书正常时建议改为 `false` |
| `database.path` | `./data/drama_generator.db` | SQLite 文件路径 |
| `storage.local_path` | `./data/storage` | 素材保存根目录 |
| `storage.base_url` | `http://localhost:5679/static` | 本地素材 URL 基址；远程使用或改端口时要核对 |
| `video.generation_timeout_minutes` | `30` | 异步视频任务总轮询超时，单位分钟 |
| `style.default_image_ratio` | `16:9` | 默认图片比例 |
| `style.default_video_ratio` | `16:9` | 默认视频比例 |
| `style.default_prop_ratio` | `1:1` | 默认道具图片比例 |
| `vendor_lock.enabled` | `false` | 普通个人使用保持关闭，启用后限制 AI 配置修改 |
| `image_proxy.use_for_video` | `true` | 视频参考图的部分处理路径会使用公网图床 |

如只在本机运行，可以修改已有配置里的以下字段。这里只展示局部字段，不要用它覆盖整个 YAML：

```yaml
server:
  port: 5679
  host: 127.0.0.1
  cors_origins:
    - http://localhost:3013
    - http://127.0.0.1:3013
  insecure_tls: false
```

通过 Vite 的相对路径代理访问通常不需要浏览器直接跨域请求后端，因此默认 CORS 列表的旧端口不一定导致界面立即报错。

`insecure_tls` 的处理位于源码入口 `server.js`；Electron 直接调用 `createApp()`，不要假设桌面版会执行相同的 TLS 开关逻辑。

### 4.2 工作目录很重要

数据库和存储的相对路径按进程当前工作目录解析。请先进入 `backend-node` 再执行启动命令，避免在项目根目录直接运行 `node backend-node/src/server.js`，导致数据写到另一个 `data` 目录。

修改启动相关 YAML 后重启后端，确认生效。AI 配置通常保存后可直接用于下一次请求。

### 4.3 修改后端端口要同步哪些地方

例如把 `5679` 改为 `5680`，至少核对：

1. YAML 的 `server.port`，以及是否存在覆盖它的 `PORT` 环境变量。
2. YAML 的 `storage.base_url`。
3. `frontweb/vite.config.js` 中 `/api`、`/static` 两处代理的 `target`。
4. 健康检查地址和启动脚本里的旧端口。

修改前端端口则调整 Vite 的 `server.port`；如直接跨域访问后端，还要同步 `cors_origins`。

### 4.4 超时与并发

在“AI 配置 → 生成设置”中可设置图片和视频并发数，分别保存于数据库，默认均为 `3`，后端允许 `1–20`。初次验证建议都设为 `1`，确认模型额度、接口和生成流程正常后再增加。

异步视频总轮询时间使用 YAML 的 `video.generation_timeout_minutes`，默认 30 分钟。Vite 代理和前端 Axios 另外设有 10 分钟请求超时；这是不同层次的限制。不要只改 YAML 中的 `read_timeout/write_timeout` 就认为所有请求超时都已改变，源码入口没有把这两个字段直接接到 HTTP server 的超时设置。

## 5. AI 基础配置

### 5.1 当前版本需要区分的服务类型

打开 <http://localhost:3013/ai-config>，或点击界面的“AI 配置”。当前界面在同一张配置表中区分以下类型，并非旧文档所说的只有三个 Tab。

| 类型 | 内部值 | 作用 | 初次使用 |
| --- | --- | --- | --- |
| 文本生成 | `text` | 故事、剧本、角色/场景提取、分镜和助手 | 需要 |
| 文本生成图片 | `image` | 角色、场景、道具图 | 需要 |
| 分镜图片生成 | `storyboard_image` | 带参考图的分镜图片 | 经典分镜完整流程建议单独配置 |
| 视频生成 | `video` | 分镜视频片段 | 需要 |
| 语音合成 TTS | `tts` | 对白/旁白配音 | 按需 |
| 即梦2角色认证 | `jimeng2_character_auth` | 对接对应网关的角色认证 | 按需 |
| SD2 资产库 | `model_ark_asset` | 火山 ModelArk 私有资产管理 | 按需 |

同一种服务类型只保留一个默认配置；一条配置里也可以填写多个模型，并指定一个默认模型。剧内助手读取默认且启用的 `text` 配置，未设默认文本模型时无法正常使用助手。

### 5.2 推荐的首次配置顺序

1. 先添加一条文本配置，填写服务商、Base URL、API Key、模型名，设为默认并测试。
2. 添加 `image` 和 `storyboard_image` 配置，确认分镜图片模型支持所需参考图能力。
3. 添加视频配置，核对接口规范、提交端点、任务查询端点。
4. 将并发降到 `1`，用一个分镜测试图片和短视频。
5. 单镜头正常后再尝试整集一键生成、全能模式和语音。

模型名必须以账号实际开通并可调用的 API 模型 ID 为准。下文是本地代码中的接入方式和模板示例，未在线核验服务商当前可用性、价格或模型权限。

### 5.3 方案 A：火山方舟

界面提供“一键配置火山”，会创建文本、普通图片、分镜图片、视频四类配置。填写自己的 Key 后，逐条检查默认模型和接口规范。

- 控制台：<https://console.volcengine.com/ark>。
- Base URL：`https://ark.cn-beijing.volces.com/api/v3`。
- 文本接口：`/chat/completions`。
- 图片接口：`/images/generations`。
- 官方视频提交接口：`/contents/generations/tasks`。
- 官方视频查询接口：`/contents/generations/tasks/{taskId}`。

代码模板中的视频模型包括 `doubao-seedance-2-0-fast-260128`、`doubao-seedance-2-0-260128`。使用 Seedance 2.0 全能模式时，应核对接口规范为 `volcengine_omni`，并使用支持该能力的模型。

全能模式以片段描述和多张参考图为核心，可用 `@图片1` 等标记；经典模式通常先生成分镜图，再以图生成视频。不要把不同模式的参考图要求混为一谈。

### 5.4 方案 B：通义百炼 / DashScope

控制台：<https://bailian.console.aliyun.com/>。界面虽有“一键配置通义”，但当前按钮标注“不推荐”；应先小规模验证自己的模型和接口。

| 服务类型 | Base URL | 说明 |
| --- | --- | --- |
| 文本 | `https://dashscope.aliyuncs.com/compatible-mode/v1` | 例如账号可用的 `qwen-plus`，使用 Chat Completions |
| 图片 / 分镜图片 | `https://dashscope.aliyuncs.com` | 使用 DashScope 专用接口；代码模板包含 `wan2.6-image` 等 |
| 视频 | `https://dashscope.aliyuncs.com` | 使用专用视频接口并查询异步任务；模板包含 `wan2.2-kf2v-flash` |

关键点：不要把文本用的 `/compatible-mode/v1` 基址直接套给所有图片、视频配置。优先从界面模板创建，再按实际模型能力修改。

### 5.5 方案 C：兼容 Chat Completions 的文本服务

适合接入已有文本模型服务或中转服务。Base URL 填服务文档规定的 API 基址，通常包含 `/v1`，不是完整的 `/chat/completions` URL。

本地 Ollama 的典型文本配置：

```text
类型：文本生成
提供商 / 接口规范：选择对应的 OpenAI 兼容项
Base URL：http://127.0.0.1:11434/v1
API Key：ollama
模型：本机已下载的实际模型名，例如 qwen2.5:7b
提交端点：/chat/completions
设为默认：是
```

Ollama 需要另行安装、下载模型并运行。这里只替代文本服务，不会自动提供图片、视频生成。配置中的占位 Key 是为了适配本项目的表单及连接测试要求。

本地 ComfyUI 等图像服务也有单独接入说明，见仓库的 `各大平台中转站配置/comfyui配置.md`；该方案需要额外 API 适配层，不是项目默认安装的一部分。

### 5.6 中转配置导入

仓库的 `各大平台中转站配置/` 下有 JSON 示例，可以在“AI 配置 → 导入配置”中导入后编辑。根据自己使用的服务选择，核对 Base URL、接口规范、模型与 Key。

Base URL 与 endpoint 会组合成实际请求地址。出现 404 时，重点检查是否拼出了重复的 `/v1/v1` 或重复的 `/chat/completions`。只支持文本协议的中转，不代表同时支持图片、视频及异步任务查询协议。

### 5.7 “测试成功”的实际含义

连接测试不能证明整条生成链路可用：

- 多种视频服务实际通过文本接口探测 Key；除 401/403 外的部分错误也会被视为联通。
- 图片测试在部分分支会把参数错误、限流等响应视为网络可达。
- 部分图片测试会发送真实的生图请求，文本测试也会调用服务，可能产生少量费用。

可靠的最终验证方式是：生成一段短文本、一张图、一个短视频，确认视频任务查询、下载和本地播放均成功。

### 5.8 图床与参考图片

当前 YAML：

```yaml
image_proxy:
  expire_hours: 2
  use_for_video: true
  upload_timeout_seconds: 180
  upload_max_attempts: 2
```

未填写 `upload_url` 时，上传代码默认使用 `https://imageproxy.zhongzhuan.chat/api/upload`，部分参考图会上传到该服务。

`upload_url` 可更换为兼容的自有上传服务。关闭 `use_for_video` 后，火山全能模式的对应本地图路径可以走 base64，但其他服务仍可能要求公网 URL；这个开关不保证关闭所有上传路径。Gemini 图片的 `use_for_gemini` 是另一项开关，代码缺省为 false。

云端服务无法访问本机的 `http://localhost:5679/static/...`。若遇到参考图下载失败，需根据具体接口选择 base64、可达图床或符合接口要求的公网素材 URL。

## 6. FFmpeg 与 FFprobe

仓库已有：`backend-node\tools\ffmpeg\ffmpeg.exe`。本次实测可运行，无需为基本 FFmpeg 操作再安装一份。

`ffprobe.exe` 未随当前仓库提供；音轨探测、旁白时长及部分合成后处理会调用它，建议补到同一个目录。可从 <https://ffmpeg.org/download.html> 选择 Windows 构建，取得配套的两个可执行文件。

后端目录下验证：

```powershell
.\tools\ffmpeg\ffmpeg.exe -version
.\tools\ffmpeg\ffprobe.exe -version
```

也可以用环境变量明确指定文件，须在启动后端的同一个 PowerShell 中设置：

```powershell
$env:FFMPEG_PATH = 'D:\ffmpeg\bin\ffmpeg.exe'
$env:FFPROBE_PATH = 'D:\ffmpeg\bin\ffprobe.exe'
npm.cmd run dev
```

路径示例需替换为实际文件。源码中的查找顺序是：有效环境变量 → 当前工作目录的 `tools/ffmpeg` → 运行程序旁的相关目录 → 源码内置目录 → 系统 PATH。仓库 FFmpeg README 所写的优先级与当前实现不同。

## 7. 另外两种运行方式

### 7.1 构建前端，只运行一个后端进程

适合日常固定使用，不需要前端热更新。

```powershell
Set-Location -LiteralPath 'C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama\frontweb'
npm.cmd ci
npm.cmd run build

Set-Location -LiteralPath 'C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama\backend-node'
npm.cmd ci
npm.cmd start
```

依赖安装过且未变化时可省略 `ci`。后端自动托管相邻的 `frontweb/dist`，访问 <http://localhost:5679> 即可，无需另起 Vite。修改前端代码后需要重新构建。

后端支持环境变量 `WEB_DIST_PATH` 指向其他前端构建目录。普通本机使用保持默认即可。

### 7.2 Electron 桌面开发与 Windows 打包

先完成前端依赖安装及 `npm.cmd run build`，然后执行：

```powershell
Set-Location -LiteralPath 'C:\Users\yangc\AppData\UserProFile\QiMiao\AI视频\LocalMiniDrama\desktop'
npm.cmd ci
npm.cmd start
```

当前 Electron 依赖为 `44.x`。安装过程会复制后端并为 Electron ABI 重建原生依赖；`npm start` 的前置脚本还会重新复制后端。

开发数据实际通常位于 `desktop/backend-app/data`，因为当前 Electron 开发逻辑优先运行复制后的 `backend-app`。它与浏览器源码模式的 `backend-node/data` 不共用数据。

注意：`prestart` 会先删除并重建 `desktop/backend-app`，不复制其中的 `data`。因此不要把 Electron 开发副本里的数据当作可靠的持久工作数据；再次执行 `npm start` 前先备份。这是开发模式的行为，正式打包运行使用下述用户目录。

打包前先关闭运行中的桌面开发程序并备份数据，再执行：

```powershell
npm.cmd run dist
```

也可用 `npm.cmd run pack` 生成未压缩应用目录。`npm.cmd run dist:cn` 设置国内二进制镜像，脚本会依次生成标准版和 Lite 版，并非只更换 npm registry。该脚本同样会重新准备后端副本。

打包结果目录：`desktop/release/`。需要的前端依赖必须预先安装；仅在 `desktop` 安装依赖不能代替前端安装。Electron 下载和原生模块重建可能需要额外网络与编译环境。

也可以直接从项目 Releases 下载成品，省去源码安装和打包：<https://github.com/xuanyustudio/LocalMiniDrama/releases>。本次没有下载或验证 Release 安装包。

## 8. 数据、日志与备份

| 模式 | 实际主要数据位置 |
| --- | --- |
| 浏览器源码模式 | `LocalMiniDrama/backend-node/data/` |
| Electron 源码开发模式 | 通常为 `LocalMiniDrama/desktop/backend-app/data/`，有上述重建风险 |
| 正式打包桌面版 | `%APPDATA%\localminidrama-desktop\backend\data\` |

正式桌面版的其他路径：

```text
配置：%APPDATA%\localminidrama-desktop\backend\configs\config.yaml
后端日志：%APPDATA%\localminidrama-desktop\backend\logs\app.log
主进程启动日志：%APPDATA%\localminidrama-desktop\main-startup.log
```

当前 `desktop/main.js` 明确固定了 `localminidrama-desktop` 用户目录；旧文档里的 `%APPDATA%\LocalMiniDrama` 不宜直接照用。已有旧版本数据时，先确认真实目录并备份，不要只依赖自动迁移。

源码后端日志默认打印到运行终端，如需同时写文件，可在后端目录启动前设置：

```powershell
$env:LOG_FILE = Join-Path (Get-Location).Path 'logs\app.log'
npm.cmd start
```

`data/` 中主要包括：

- `drama_generator.db`：剧集、分镜、AI 配置等；AI Key 在表中直接保存，应把数据库视为含凭据文件。
- `agent.db`：助手启用后使用的独立记忆库。
- `storage/`：本地图片、视频、音频等文件。当前代码包含 `projects/...` 与 `library/...` 分层，不应只按旧文档中的扁平目录寻找素材。

备份建议：

1. 备份单部作品时，优先用界面的工程 ZIP 导出/导入。
2. 完整迁移时，停止所有相关进程，备份对应模式的整个 `data/` 和 `configs/config.yaml`；AI 配置另行通过界面导出可方便恢复。
3. SQLite 使用 WAL 模式；不要只复制正在运行的 `.db` 主文件而忽略尚在 WAL 中的数据。最简单的方法是停服务后再整体备份。
4. 分享工程、数据库或 AI 配置 JSON 前检查其中是否含真实 Key。

## 9. 常见问题与定位顺序

| 现象 | 优先处理 |
| --- | --- |
| `npm.ps1 cannot be loaded` / 禁止运行脚本 | 使用本文的 `npm.cmd`，无需为此全局放宽执行策略 |
| `EBADENGINE` | 核对当前终端实际 Node 版本；升级至最新 22.x，至少 `22.22.0` |
| 找不到 `config.example.yaml` | 当前仓库未提供该模板，已有 `configs/config.yaml` |
| `Cannot find module` / 找不到 Vite | 在报错对应的子目录安装依赖，项目根目录没有统一安装脚本 |
| `better-sqlite3` / `sharp` 安装失败 | 先核对 Node、CPU 架构和二进制下载网络；若日志显示转源码编译，再准备 Python、Visual Studio C++ Build Tools |
| `NODE_MODULE_VERSION` 不一致 | 不要混用源码 Node 与 Electron 的 `node_modules`；分别在各目录安装/重建 |
| `EADDRINUSE` | 查明端口占用者，再停自己的旧服务或改端口；不要直接强杀未知进程 |
| 前端 `ECONNREFUSED` / 代理失败 | 先访问 `5679/health`，检查后端是否启动、代理端口是否匹配 |
| 前端 404 | API 路径为 `/api/v1/...`；确认 Base URL、代理及 endpoint 没有重复路径 |
| 访问 `5679` 只有后端提示页 | 未构建前端时属正常；开发模式访问 `3013`，或构建 `frontweb/dist` |
| 后端提示 `cd web / pnpm` | 这是旧兜底页面文字；当前真实目录为 `frontweb`，用 `npm.cmd run build` |
| 401 / 403 | 检查 Key、服务商、账号权限及模型是否开通 |
| 模型不存在 / 400 参数错误 | 使用账号实际可用的 API 模型 ID，并匹配接口规范与模式 |
| 429 | 降低图片/视频并发，检查余额和速率配额；重试可能继续产生费用 |
| 测试绿灯但生成失败 | 连接测试只覆盖部分链路；查看实际任务错误，分别验证提交、轮询、下载 |
| 参考图片无法读取 | 云端不能访问 localhost；检查图床上传、base64 支持及 URL 有效期 |
| 合成或旁白失败 | 检查 FFmpeg 与 FFprobe 两个文件，特别是当前缺失的 FFprobe |
| 剧内助手不可用 | 检查默认文本配置、Node 版本及启动日志中的“助手未就绪” |
| 桌面版启动后找不到源码里的项目 | 核对运行模式，不同模式使用不同数据目录 |

查看端口占用的只读命令：

```powershell
Get-NetTCPConnection -State Listen -LocalPort 5679,3013 -ErrorAction SilentlyContinue |
    Select-Object LocalAddress,LocalPort,OwningProcess
```

仓库的 `backend-node/.npmrc`、`desktop/.npmrc` 已设 `registry.npmmirror.com`，并设了 `strict-ssl=false`。前端没有相同的本地配置，依赖下载来源还受锁文件中的 resolved URL 影响。安装网络失败时先查看失败的实际 URL；恢复正常证书校验比长期依赖跳过校验更适合日常使用。

## 10. 第一次创作的最小验证流程

1. 启动两个服务，健康检查及项目列表接口正常。
2. 配好默认文本、普通图片、分镜图片和视频模型，将并发设为 `1`。
3. 新建一个短剧，先用一集、少量分镜验证。
4. 生成/填写剧本，提取角色、场景，生成必要的参考图。
5. 生成分镜，先生成一张分镜图片，再生成一个短视频并播放。
6. 补齐 FFprobe，测试两段视频合成；需要配音再配置 TTS。
7. 导出一次工程 ZIP，确认作品和素材能够备份，再扩大生成规模。

## 11. 本次核对依据

以下链接均指向当前 AI视频目录中的源码或原始说明，可继续查阅。

| 文件 | 核对内容 |
| --- | --- |
| [backend-node/package.json](LocalMiniDrama/backend-node/package.json)、[锁文件](LocalMiniDrama/backend-node/package-lock.json) | 启动命令、依赖、实际 Node 版本约束 |
| [frontweb/package.json](LocalMiniDrama/frontweb/package.json)、[Vite 配置](LocalMiniDrama/frontweb/vite.config.js) | 前端启动/构建命令、端口、代理 |
| [config.yaml](LocalMiniDrama/backend-node/configs/config.yaml)、[配置加载器](LocalMiniDrama/backend-node/src/config/index.js) | 现有配置及查找顺序 |
| [server.js](LocalMiniDrama/backend-node/src/server.js)、[app.js](LocalMiniDrama/backend-node/src/app.js) | 后端入口、TLS、自动迁移、健康检查、静态托管 |
| [AIConfigContent.vue](LocalMiniDrama/frontweb/src/components/AIConfigContent.vue) | 当前界面、服务类型、一键配置模板和并发设置 |
| [aiConfigService.js](LocalMiniDrama/backend-node/src/services/aiConfigService.js) | AI 配置保存、默认配置、连接测试的实际行为 |
| [settings.js](LocalMiniDrama/backend-node/src/routes/settings.js) | 并发范围及视频超时设置 |
| [ffmpegPath.js](LocalMiniDrama/backend-node/src/utils/ffmpegPath.js) | FFmpeg / FFprobe 路径解析 |
| [uploadService.js](LocalMiniDrama/backend-node/src/services/uploadService.js) | 默认图床地址和上传参数 |
| [storageLayout.js](LocalMiniDrama/backend-node/src/services/storageLayout.js) | 工程与公共素材目录分层 |
| [desktop/main.js](LocalMiniDrama/desktop/main.js)、[copy-backend.js](LocalMiniDrama/desktop/scripts/copy-backend.js) | 桌面数据目录、开发副本重建、端口选择 |
| [desktop/package.json](LocalMiniDrama/desktop/package.json)、[dist-cn.js](LocalMiniDrama/desktop/scripts/dist-cn.js) | Electron 版本与 Windows 打包流程 |
| [quickstart.md](LocalMiniDrama/docs/quickstart.md)、[configuration.md](LocalMiniDrama/docs/configuration.md) | 原有使用说明，部分内容滞后于代码 |

验证边界：已读取并交叉核对上述文件，检查 Node/npm 版本和 FFmpeg，并实际执行 FFmpeg 版本命令成功。后续已完成前后端依赖安装、前端构建、Node.js 22.13.0 下 SQLite 内存查询及关键模块加载验证。未执行业务数据库初始化、服务启动、界面操作或 AI 端到端生成；上文启动流程与配置说明不应视为已跑通全部功能的测试报告。
