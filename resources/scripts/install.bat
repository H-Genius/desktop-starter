@echo off
chcp 65001 >nul
color 0F
cls

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ==============================================
    echo    [错误] 请以管理员身份运行此脚本！
    echo    右键点击脚本，选择"以管理员身份运行"
    echo ==============================================
    echo.
    pause
    exit /b 1
)

echo ==============================================
echo    Node.js 自动安装 + Miniconda 手动安装
echo ==============================================
echo.

:: ==================== 1. 自动安装 Node.js ====================
echo 第一步：将自动安装 Node.js...
if exist "C:\NodeJs" (
    echo Node.js 已存在，跳过安装
) else (
    echo 正在下载...
    powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://nodejs.org/dist/v22.14.0/node-v22.14.0-win-x64.zip' -OutFile 'node.zip'"
    echo 正在解压...
    powershell -Command "Expand-Archive 'node.zip' 'C:\' -Force"
    move "C:\node-v22.14.0-win-x64" "C:\NodeJs"
    echo 正在设置环境变量...
    setx PATH "C:\NodeJs;%PATH%" /m >nul
    del node.zip
    echo Node.js 安装完成！
)
echo.
pause
echo.

:: ==================== 2. 下载并启动 Miniconda 安装程序 ====================
echo 第二步：将下载并启动 Miniconda 安装程序...
powershell -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe' -OutFile 'miniconda.exe'"

echo.
echo ==============================================
echo  下载完成！
echo  即将打开安装程序，请注意：
echo  请务必在 "Advanced Installation Options" 页面
echo  勾选  "Add Miniconda3 to my PATH environment variable"
echo  否则安装完后无法直接用 conda 命令！
echo ==============================================
echo.
pause

echo 正在打开安装程序...
start "" miniconda.exe
echo.
echo 请手动完成安装，安装完成后按任意键继续...
pause >nul

:: 可选：安装后删除安装包
del miniconda.exe
echo.

:: ==================== 3. 结束语 ====================
echo ==============================================
echo  全流程已完成！
echo  请关闭当前窗口，重新打开一个新的 CMD
echo  然后依次运行以下命令验证：
echo    node -v
echo    python --version
echo    conda --version
echo ==============================================
echo.
pause