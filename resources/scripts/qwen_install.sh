#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "       Qwen-CLI 一键安装（国内镜像版）"
echo "========================================"

# ======================
# 自动切换 国内镜像源
# ======================
echo "🔧 配置国内镜像源（npm / bun）"
npm config set registry https://registry.npmmirror.com || true
bun config set registry https://registry.npmmirror.com || true

# ======================
# 安装 Qwen-CLI
# ======================
if command -v brew &> /dev/null; then
    echo "🍺 使用 Homebrew 安装"
    brew install qwen-code

elif command -v npm &> /dev/null; then
    echo "📦 使用 NPM 安装（国内镜像）"
    npm install -g @qwen-code/qwen-code@latest

elif command -v bun &> /dev/null; then
    echo "⚡ 使用 Bun 安装（国内镜像）"
    bun add -g @qwen-code/qwen-code@latest

else
    echo "❌ 未找到包管理器，请先安装 nodejs / brew"
    exit 1
fi

echo -e "\n✅ 安装完成！"
echo "请关闭终端重新打开"
echo "验证：qwen --version"
echo "使用：qwen"
echo
read -r -p "按回车关闭窗口..."
