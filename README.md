# Desktop Starter

一个给小白也能继续维护的桌面工具项目。

这个项目的作用很简单：
- 打开一个桌面应用
- 管理本地模型目录里的 `auth.json` 和 `config.toml`
- 通过按钮调起终端，执行对应模型的安装脚本
- 支持打包成 `Windows / macOS / Linux` 三个平台版本

## 这个项目适合做什么

你可以把它理解成一个“模型环境安装 + 配置管理”的桌面壳。

它本身不负责训练模型，也不是聊天界面。
它主要负责：
- 帮用户管理配置文件
- 帮用户点击按钮后打开终端执行安装脚本
- 帮你后续继续扩展更多模型入口

## 目前已经支持什么

- 编辑 `auth.json`
- 编辑 `config.toml`
- 选择不同模型目标
- 调起安装脚本
- Windows 下原生 `.bat` 安装流程
- GitHub Actions 自动构建三平台安装包

## 推荐使用流程

建议按这个顺序使用：

### 第 1 步：先检查终端环境

- Windows：使用原生 `cmd/PowerShell + .bat` 流程
- macOS / Linux：检查 `bash`
- macOS / Linux 的 `bash` 一般是系统自带的，通常不需要额外安装

### 第 2 步：安装前置环境

确认终端环境没问题后，再执行：

```text
安装前置环境
```

这个按钮会按平台执行：

- Windows：`resources/scripts/install.bat`
- macOS / Linux：`resources/scripts/install.sh`

它会优先补齐大模型运行前需要的基础环境；在支持的平台上，也可以顺带安装 Ghostty、Clash Verge 这类常用工具。

### 第 3 步：检查前置环境是否齐全

安装完成后，回到应用里点击“刷新”，确认这些环境是否已经准备好：

- `uv`
- `miniconda / conda`
- `nvm`
- `bun`
- `nodejs`
- `homebrew`（仅 macOS）

如果这些环境都已经齐全，应用会提示前置环境已经准备好。

不同平台的前置环境逻辑是：

- Windows：
  - 再检查 `uv / bun / nodejs / conda`
  - Windows 不走 `homebrew`
  - Windows 也不走 `nvm`

- macOS：
  - 检查 `bash`
  - 检查 `homebrew / uv / nvm / nodejs / bun / conda`

- Linux：
  - 检查 `bash`
  - 检查 `uv / nvm / nodejs / bun / conda`
  - Linux 不走 `homebrew`

### 第 4 步：最后再做大模型配置

当前置环境都准备好之后，再进行最后一步：

- 选择模型
- 执行模型安装脚本
- 如果该模型有模板，就套用配置
- 保存 `auth.json` 和 `config.toml`

## 别人怎么下载安装包使用

如果别人不想自己拉代码，而是直接下载安装包使用，可以按下面流程操作。

### 1. 先下载对应系统的安装包

下载时只需要选自己系统对应的版本：

- Windows：下载 Windows 安装包
- macOS：下载 macOS 安装包
- Linux：下载 Linux 安装包

### 2. 安装并打开应用

安装完成后，直接打开应用即可。

首次打开后，应用会自动管理配置文件。

### 3. 打开应用后先检查终端环境

打开应用后，建议先点环境检查相关按钮。

系统处理逻辑是：

- Windows：使用原生 `.bat` 脚本流程
- macOS / Linux：检查 `bash`
- macOS / Linux 一般系统自带 `bash`，通常直接可用

### 4. 再安装前置环境

终端环境没问题后，再点击：

```text
安装前置环境
```

这个按钮会按平台执行：

- Windows：`resources/scripts/install.bat`
- macOS / Linux：`resources/scripts/install.sh`

它的作用是补齐模型 CLI 运行需要的基础环境。

### 5. 前置环境装好后，刷新检查结果

执行完安装脚本后，回到应用点击刷新，确认环境状态。

会按平台检查这些项目：

- Windows：`uv / bun / nodejs / conda`
- macOS：`homebrew / uv / nvm / nodejs / bun / conda`
- Linux：`uv / nvm / nodejs / bun / conda`

如果这些环境都已经存在，应用会提示前置环境已经准备好。

### 6. 最后安装模型 CLI 并填写配置

前置环境没问题后，再进行模型部分：

- 在下拉框里选择目标模型
- 点击对应安装按钮
- Windows 会调起对应 `.bat` 脚本，macOS / Linux 会调起对应 `.sh` 脚本
- 如果该模型需要配置，就再填写 `auth.json` 和 `config.toml`

这一步完成之后，用户就可以继续在自己的终端里使用对应模型 CLI。

### 7. 如果配置文件还没有生成

应用管理的是这两个文件：

- `auth.json`
- `config.toml`

如果本地还没有这两个文件，可以在应用里点击“写入模板”自动生成，再按实际需要修改。

## 别人怎么拉代码和使用

如果别人不是直接拿安装包，而是要自己拉代码运行，可以按下面流程操作。

### 1. 先拉代码

```bash
git clone https://gitclone.com/github.com/H-Genius/desktop-starter.git
cd desktop-starter
npm install
```

如果你的网络可以直连 GitHub，也可以使用原始地址：

```bash
git clone https://github.com/H-Genius/desktop-starter.git
cd desktop-starter
npm install
```

### 2. 启动应用

```bash
npm run dev
```

如果本机环境里带了 `ELECTRON_RUN_AS_NODE=1`，就这样启动：

```bash
env -u ELECTRON_RUN_AS_NODE npm run dev
```

### 3. 打开应用后先检查终端环境

打开应用后，建议先点环境检查相关按钮。

系统处理逻辑是：

- Windows：使用原生 `.bat` 脚本流程
- macOS / Linux：检查 `bash`
- macOS / Linux 一般系统自带 `bash`，通常直接可用

### 4. 再安装前置环境

终端环境没问题后，再点击：

```text
安装前置环境
```

这个按钮会按平台执行：

- Windows：`resources/scripts/install.bat`
- macOS / Linux：`resources/scripts/install.sh`

它的作用是补齐模型 CLI 运行需要的基础环境。

### 5. 前置环境装好后，刷新检查结果

执行完安装脚本后，回到应用点击刷新，确认环境状态。

会按平台检查这些项目：

- Windows：`uv / bun / nodejs / conda`
- macOS：`homebrew / uv / nvm / nodejs / bun / conda`
- Linux：`uv / nvm / nodejs / bun / conda`

如果这些环境都已经存在，应用会提示前置环境已经准备好。

### 6. 最后安装模型 CLI 并填写配置

前置环境没问题后，再进行模型部分：

- 在下拉框里选择目标模型
- 点击对应安装按钮
- Windows 会调起对应 `.bat` 脚本，macOS / Linux 会调起对应 `.sh` 脚本
- 如果该模型需要配置，就再填写 `auth.json` 和 `config.toml`

这一步完成之后，用户就可以继续在自己的终端里使用对应模型 CLI。

### 7. 如果配置文件还没有生成

应用管理的是这两个文件：

- `auth.json`
- `config.toml`

如果本地还没有这两个文件，可以在应用里点击“写入模板”自动生成，再按实际需要修改。

## 先看目录

最常改的地方只有这几个：

- `src/renderer/src/App.vue`
  页面界面，按钮、下拉框、文案基本都在这里

- `src/main/services/app-config.ts`
  桌面端核心逻辑，负责：
  - 读取和保存配置
  - 打开目录
  - 打开终端
  - 执行安装脚本
  - 平台脚本分发（Windows `.bat` / macOS Linux `.sh`）

- `resources/providers/`
  这里放“模型提供方配置”
  一个 json 对应一个模型入口

- `resources/scripts/`
  这里放安装脚本
  比如：
  - `qwen_install.sh` / `qwen_install.bat`
  - `install-openai-cli.sh` / `install-openai-cli.bat`
  - `install.sh` / `install.bat`

- `resources/templates/`
  这里放默认模板：
  - `auth.example.json`
  - `config.example.toml`

- `.github/workflows/release.yml`
  GitHub Actions 自动打包配置

## 本地怎么跑

先装依赖：

```bash
npm install
```

启动开发环境：

```bash
npm run dev
```

如果你的环境里有 `ELECTRON_RUN_AS_NODE=1`，启动时要这样跑：

```bash
env -u ELECTRON_RUN_AS_NODE npm run dev
```

类型检查：

```bash
npm run typecheck
```

## 打包命令

本地打包命令：

```bash
npm run dist
```

单独打某个平台：

```bash
npm run dist:win
npm run dist:mac
npm run dist:linux
```

说明：
- Windows 包最好在 Windows runner 上打
- macOS 包最好在 macOS runner 上打
- Linux 包最好在 Linux runner 上打

所以正式发布时，最推荐直接走 GitHub Actions。

## GitHub Actions 怎么工作

当前已经配置好三平台自动构建。

文件：

```text
.github/workflows/release.yml
```

现在的行为是：
- 普通 `push`：自动构建 `Windows / macOS / Linux`
- 构建结果会作为 Actions artifacts 上传
- 推送 `v*` 标签：会走 release 发布流程

例子：

```bash
git tag v0.1.0
git push origin v0.1.0
```

## 怎么新增一个模型

如果后面要接一个新模型，通常只需要改 2 个地方。

### 1. 新增 provider 配置

在 `resources/providers/` 下新建一个 json。

例如：

```json
{
  "id": "qwen-local",
  "name": "Qwen / Local Runtime",
  "vendor": "Qwen",
  "description": "Install the base Qwen CLI through your local terminal workflow.",
  "tags": ["Local", "Qwen"],
  "managedFiles": ["auth.json", "config.toml"],
  "modelOptions": [
    {
      "id": "qwen-cli",
      "name": "Qwen CLI",
      "description": "Install Qwen CLI.",
      "supportedPlatforms": ["darwin", "linux", "win32"],
      "scriptFile": "qwen_install"
    }
  ]
}
```

### 2. 新增安装脚本

把脚本放进：

```text
resources/scripts/
```

例如：

```text
qwen_install (按平台自动匹配 .bat / .sh)
```

然后在上面的 provider json 里通过 `scriptFile` 指向它。

## Windows 额外说明

Windows 现在使用原生 `.bat` 脚本，不再依赖 Git Bash。

核心脚本包括：

```text
resources/scripts/install.bat
resources/scripts/qwen_install.bat
resources/scripts/install-openai-cli.bat
```

## macOS / Linux 额外说明

macOS 和 Linux 也会检查 `bash` 环境。

但这两个系统一般本身就带有终端和 `bash`，通常不需要额外安装。

正常流程是：
- 先确认终端环境可用
- 再执行 `install.sh`
- 然后确认前置环境都齐全
- 最后再做大模型配置

## 如果你只想改界面

直接改：

```text
src/renderer/src/App.vue
```

常见修改包括：
- 按钮文字
- 下拉框
- 提示文案
- 面板布局

## 如果你只想改安装逻辑

优先改：

```text
src/main/services/app-config.ts
```

这里负责：
- 检测平台
- 打开终端
- 执行安装脚本
- 读取 provider 配置

## 如果你只想改模板内容

直接改：

- `resources/templates/auth.example.json`
- `resources/templates/config.example.toml`

## 后续维护建议

为了后面不把项目改乱，建议按这个规则维护：

- 加新模型：先加 `resources/providers/*.json`
- 加安装脚本：放到 `resources/scripts/`
- 改界面：改 `App.vue`
- 改桌面逻辑：改 `app-config.ts`
- 改默认配置：改 `resources/templates/`
- 改自动打包：改 `.github/workflows/release.yml`

## 一句话总结

这个项目不是“大模型本体”，而是一个：

“帮用户安装模型 CLI、管理配置文件、并能跨平台打包发布的桌面启动器。”
