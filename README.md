# Model Desktop Manager

一个独立的 `Vue 3 + Electron` 桌面应用骨架，用来管理本地模型运行时目录中的 `auth.json` 和 `config.toml`，并为后续接入不同大模型 provider 保留复用层。

这个项目默认假设：

- 你已经安装或将要安装目标模型运行时或 CLI 工具
- 默认兼容目录是 `~/.codex`
- 也可以通过环境变量 `MODEL_DESKTOP_HOME` 覆盖目录
- 为了兼容现有环境，也支持读取 `CODEX_HOME`
- 你后续会把真正的 `auth.json` 和 `config.toml` 内容补全

## 目标

- 桌面端统一管理模型运行时配置文件
- `auth.json` 与 `config.toml` 可视化编辑
- 可扩展 provider 清单，后续新增模型不需要重做 UI
- 支持 Windows / macOS / Linux 打包
- 支持 GitHub Actions 自动构建和发布

## 技术栈

- `Electron`
- `electron-vite`
- `Vue 3`
- `electron-builder`

## 目录结构

```text
model-desktop-manager/
├── .github/workflows/release.yml
├── electron.vite.config.ts
├── package.json
├── resources/
│   ├── providers/
│   │   ├── azure-openai.json
│   │   ├── qwen-local.json
│   │   └── openai-compatible.json
│   └── templates/
│       ├── auth.example.json
│       └── config.example.toml
├── src/
│   ├── main/
│   │   ├── index.ts
│   │   └── services/
│   │       ├── app-config.ts
│   │       └── workspace-home.ts
│   ├── preload/
│   │   └── index.ts
│   ├── renderer/
│   │   ├── index.html
│   │   └── src/
│   │       ├── App.vue
│   │       ├── env.d.ts
│   │       ├── main.ts
│   │       └── styles.css
│   └── shared/
│       └── contracts.ts
└── tsconfig.json
```

## 本地开发

1. 安装依赖

```bash
cd model-desktop-manager
npm install
```

2. 启动开发环境

```bash
npm run dev
```

3. 类型检查

```bash
npm run typecheck
```

## 打包

全部平台的最终产物仍然要在各自平台 runner 上构建。

本地命令：

```bash
npm run dist
npm run dist:win
npm run dist:mac
npm run dist:linux
```

## GitHub Actions

工作流文件：

- `.github/workflows/release.yml`

行为：

- `workflow_dispatch` 可手动触发
- 推送 `v*` tag 时自动发布 GitHub Release 草稿
- `ubuntu-latest / macos-latest / windows-latest` 三平台矩阵构建

如果是 tag 发布，工作流会使用：

- `GITHUB_TOKEN`

如果你后续需要签名或 notarization，还需要额外补：

- macOS 证书相关 secrets
- Windows 签名相关 secrets

未签名构建通常仍可生成安装包，但发行体验和系统信任链需要你后续补完。

## 默认兼容目录

默认路径：

```text
~/.codex
```

覆盖方式：

```bash
MODEL_DESKTOP_HOME=/custom/path npm run dev
```

应用会管理这两个文件：

- `auth.json`
- `config.toml`

如果文件不存在，点击 UI 中的“写入模板”会自动生成示例文件。

## 后续如何扩展新模型

这个项目故意把“模型类型”抽象成 provider 清单，而不是写死在界面里。

你后续接新模型时，优先这样做：

1. 在 `resources/providers/` 新增一个 provider manifest
2. 按需要调整 `auth.example.json` 和 `config.example.toml` 模板
3. 如果新 provider 只是配置结构不同，通常不用改 UI
4. 只有当新模型需要新交互流程时，才扩展 `src/main/services/app-config.ts`

### Provider manifest 示例

```json
{
  "id": "openai-compatible",
  "name": "OpenAI Compatible",
  "vendor": "OpenAI / compatible APIs",
  "description": "Reusable config surface for OpenAI-compatible endpoints.",
  "tags": ["Hosted API", "Compatible Endpoint"],
  "managedFiles": ["auth.json", "config.toml"]
}
```

## 当前实现边界

当前版本先解决的是“桌面配置台”和“跨平台打包骨架”，不包含以下内容：

- 自动下载具体模型运行时二进制
- 自动登录第三方平台
- 自动推断每个 provider 的真实鉴权字段
- 自动更新
- 证书签名和 notarization

这些能力都可以在这个骨架上继续加，但不应该一开始就耦合进基础结构里。

## 参考

这个脚手架的技术选型参考了官方文档：

- electron-vite: https://electron-vite.org/
- electron-builder 配置: https://www.electron.build/configuration.html
- electron-builder 发布: https://www.electron.build/publish.html
- Vite: https://vite.dev/guide/
