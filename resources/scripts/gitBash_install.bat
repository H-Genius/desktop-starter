@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo        Git Bash 一键安装（Windows）
echo ========================================
echo.
echo 将通过 winget 安装 Git for Windows。
echo 安装完成后，请重新打开本应用再执行模型安装脚本。
echo.

where winget >nul 2>nul
if errorlevel 1 (
  echo 未找到 winget，无法自动安装 Git Bash。
  echo 请先安装 Git for Windows: https://git-scm.com/download/win
  echo.
  pause
  exit /b 1
)

winget install --id Git.Git -e --source winget
if errorlevel 1 (
  echo.
  echo Git Bash 安装失败，请稍后重试或手动安装。
  echo.
  pause
  exit /b 1
)

echo.
echo Git Bash 安装已完成。
echo 请重新打开本应用，再执行对应模型脚本。
echo.
pause
