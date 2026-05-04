@echo off
chcp 65001 >nul
cls

echo ========================================
echo   OpenAI Codex CLI 安装脚本 (Windows)
echo ========================================
echo.

:: 检查 Node.js 是否已安装
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 Node.js，请先安装 Node.js
    echo 可运行 install.bat 进行自动安装
    echo.
    pause
    exit /b 1
)

:: 检查 npm 是否已安装
where npm >nul 2>nul
if %errorlevel% neq 0 (
    echo [错误] 未找到 npm，请检查 Node.js 安装
    echo.
    pause
    exit /b 1
)

echo [信息] Node.js 版本:
node -v
echo.
echo [信息] npm 版本:
npm -v
echo.

echo [信息] 正在安装 OpenAI Codex CLI...
npm install -g @openai/codex --registry=https://registry.npmmirror.com

if %errorlevel% neq 0 (
    echo.
    echo [错误] 安装失败，请检查网络连接或尝试使用官方源：
    echo npm install -g @openai/codex
    echo.
    pause
    exit /b 1
)

echo.
echo [信息] 安装完成！正在验证...
echo.
codex --version
echo.
echo ========================================
echo   OpenAI Codex CLI 已成功安装！
echo ========================================
echo.
pause
exit /b