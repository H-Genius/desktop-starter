#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo "   OpenAI Codex CLI 安装脚本"
echo "========================================"
echo

# 检查 Node.js 是否已安装
if ! command -v node >/dev/null 2>&1; then
    echo "[错误] 未找到 Node.js，请先安装 Node.js"
    echo "可运行 install.sh 进行自动安装"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
fi

# 检查 npm 是否已安装
if ! command -v npm >/dev/null 2>&1; then
    echo "[错误] 未找到 npm，请检查 Node.js 安装"
    echo
    read -r -p "按回车关闭窗口..."
    exit 1
fi

echo "[信息] Node.js 版本:"
node -v
echo
echo "[信息] npm 版本:"
npm -v
echo

echo "[信息] 正在安装 OpenAI Codex CLI..."

# 配置国内镜像源
npm config set registry https://registry.npmmirror.com || true

if command -v brew >/dev/null 2>&1; then
    echo "[信息] 使用 Homebrew 安装"
    brew install --cask codex || npm install -g @openai/codex
else
    echo "[信息] 使用 NPM 安装（国内镜像）"
    npm install -g @openai/codex
fi

echo
echo "[信息] 安装完成！正在验证..."
echo

if command -v codex >/dev/null 2>&1; then
    codex --version
    echo
    echo "[成功] OpenAI Codex CLI 已成功安装！"
else
    echo "[警告] codex 命令可能需要重新打开终端才能生效"
fi

echo
echo "========================================"
echo "   请关闭终端重新打开后验证安装"
echo "========================================"
echo
read -r -p "按回车关闭窗口..."