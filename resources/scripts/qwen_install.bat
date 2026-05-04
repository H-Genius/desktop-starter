@echo off
chcp 65001 >nul
cls

echo ========================================
echo   Qwen-CLI 一键安装（国内镜像版）
echo ========================================
echo.

:: 配置国内镜像源
echo [信息] 配置国内镜像源（npm）
npm config set registry https://registry.npmmirror.com

:: 检查可用的包管理器
where npm >nul 2>nul
if %errorlevel% equ 0 (
    echo [信息] 使用 NPM 安装（国内镜像）
    npm install -g @qwen-code/qwen-code@latest
    goto :success
)

where bun >nul 2>nul
if %errorlevel% equ 0 (
    echo [信息] 使用 Bun 安装（国内镜像）
    bun add -g @qwen-code/qwen-code@latest
    goto :success
)

echo [错误] 未找到包管理器，请先安装 Node.js 或 Bun
echo 可运行 install.bat 进行自动安装
echo.
pause
exit /b 1

:success
echo.
echo [成功] 安装完成！
echo 请关闭终端重新打开
echo 验证：qwen --version
echo 使用：qwen
echo.
pause