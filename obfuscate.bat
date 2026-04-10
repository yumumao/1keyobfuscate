@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
:: ============================================
:: edgetunnel _worker.js 一键混淆打包工具
:: 使用方法：与 _worker.js 放同一文件夹，双击运行
:: 无需管理员权限，普通 CMD 即可执行
:: ============================================

echo.
echo ==========================================
echo   edgetunnel _worker.js 一键混淆打包工具
echo ==========================================
echo.

cd /d "%~dp0"
echo [INFO] 工作目录：%cd%
echo.

:: ========== 检查工具 ==========
where javascript-obfuscator >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 未检测到 javascript-obfuscator
    echo         请先运行：npm install -g javascript-obfuscator
    goto :EXIT
)
echo [OK] javascript-obfuscator 已安装

:: ========== 检查 _worker.js ==========
if not exist "_worker.js" (
    echo [ERROR] 未找到 _worker.js
    goto :EXIT
)
for %%F in (_worker.js) do set "ORIG_SIZE=%%~zF"
echo [OK] 已找到 _worker.js（!ORIG_SIZE! 字节）

:: ========== 检测 _worker.js 是否已被混淆 ==========
set "OBF_COUNT=0"
for /f %%A in ('findstr /o /c:"_0x" "_worker.js" 2^>nul ^| find /c ":"') do set "OBF_COUNT=%%A"
if !OBF_COUNT! LEQ 10 goto :CHECK_OBF_FILE

echo.
echo ==========================================
echo   [WARN] _worker.js 已是混淆文件！
echo   （检测到 !OBF_COUNT! 处混淆特征）
echo   重复混淆会导致体积暴增或运行异常
echo ==========================================
echo.
echo   [1] 直接打包为 main.zip（推荐）
echo   [2] 强制重新混淆（不推荐）
echo   [3] 退出
echo.
set /p "C1=请输入选择 (1/2/3): "
if "!C1!"=="3" goto :EXIT
if "!C1!"=="2" goto :DO_OBFUSCATE
:: 默认或选1：直接打包 _worker.js
set "ZIP_SOURCE=_worker.js"
goto :DO_ZIP

:: ========== 检测已有 _worker_obf.js ==========
:CHECK_OBF_FILE
if not exist "_worker_obf.js" goto :CHECK_ZIP
for %%F in (_worker_obf.js) do set "EXIST_OBF_SIZE=%%~zF"
echo.
echo ==========================================
echo   [WARN] 发现上次混淆的 _worker_obf.js
echo   （!EXIST_OBF_SIZE! 字节）
echo ==========================================
echo.
echo   [1] 直接用它打包，跳过混淆（省时间）
echo   [2] 删除并重新混淆（每次结果不同）
echo   [3] 退出
echo.
set /p "C2=请输入选择 (1/2/3): "
if "!C2!"=="3" goto :EXIT
if "!C2!"=="1" goto :USE_EXISTING_OBF
:: 默认或选2：删除旧文件，重新混淆
del /f "_worker_obf.js"
echo [OK] 已删除旧的 _worker_obf.js
goto :CHECK_ZIP

:USE_EXISTING_OBF
set "ZIP_SOURCE=_worker_obf.js"
goto :DO_ZIP

:: ========== 检测已有 main.zip ==========
:CHECK_ZIP
if not exist "main.zip" goto :DO_OBFUSCATE
for %%F in (main.zip) do set "EXIST_ZIP_SIZE=%%~zF"
echo.
echo [WARN] main.zip 已存在（!EXIST_ZIP_SIZE! 字节）
echo   [1] 重新混淆并覆盖（推荐）
echo   [2] 保留现有文件，退出
echo.
set /p "C3=请输入选择 (1/2): "
if "!C3!"=="2" goto :SHOW_RESULT
:: 默认或选1：继续混淆

:: ========== 执行混淆 ==========
:DO_OBFUSCATE
if exist "_worker_obf.js" del /f "_worker_obf.js"

set /a SEED=%RANDOM%%RANDOM%
echo.
echo [INFO] 随机种子：!SEED!
echo [OBFUSCATE] 正在混淆，请稍候（约 30秒 ~ 2分钟）...
echo.

javascript-obfuscator _worker.js --output _worker_obf.js --compact true --control-flow-flattening true --control-flow-flattening-threshold 0.3 --dead-code-injection true --dead-code-injection-threshold 0.15 --string-array true --string-array-encoding rc4 --string-array-threshold 0.75 --rename-globals false --self-defending false --seed !SEED!

echo.

if not exist "_worker_obf.js" (
    echo [ERROR] 混淆失败，未生成 _worker_obf.js
    goto :EXIT
)
for %%F in (_worker_obf.js) do set "NEW_OBF_SIZE=%%~zF"
echo [OK] 混淆完成
echo     原始：!ORIG_SIZE! 字节
echo     混淆：!NEW_OBF_SIZE! 字节

set "ZIP_SOURCE=_worker_obf.js"

:: ========== 打包 ZIP ==========
:DO_ZIP

echo.

:: 检查是否需要覆盖已有 zip
if not exist "main.zip" goto :START_ZIP
for %%F in (main.zip) do set "OLD_ZIP=%%~zF"
echo [WARN] main.zip 已存在（!OLD_ZIP! 字节）
set /p "YN=是否覆盖重新打包？ Y/N: "
if /i "!YN!"=="N" goto :SHOW_RESULT
del /f "main.zip"

:START_ZIP
echo [ZIP] 正在将 !ZIP_SOURCE! 打包为 main.zip ...
echo      zip 内文件名自动改为 _worker.js

:: 创建临时文件夹，确保 zip 内是 _worker.js
if exist "_zip_temp" rd /s /q "_zip_temp"
mkdir "_zip_temp"
copy /y "!ZIP_SOURCE!" "_zip_temp\_worker.js" >nul

if not exist "_zip_temp\_worker.js" (
    echo [ERROR] 复制到临时目录失败
    rd /s /q "_zip_temp" 2>nul
    goto :EXIT
)

:: ------ 方法1：PowerShell Compress-Archive ------
:: 切回系统默认代码页，避免 chcp 65001 导致 PowerShell 异常
echo [INFO] 尝试 PowerShell Compress-Archive 打包...
chcp 437 >nul 2>&1

set "PS_SRC=%cd%\_zip_temp\_worker.js"
set "PS_DST=%cd%\main.zip"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Compress-Archive -LiteralPath '!PS_SRC!' -DestinationPath '!PS_DST!' -Force -ErrorAction Stop; exit 0 } catch { Write-Host '[PS ERROR]' $_.Exception.Message; exit 1 }"

chcp 65001 >nul 2>&1

if exist "main.zip" (
    echo [OK] PowerShell Compress-Archive 成功
    goto :ZIP_DONE
)

:: ------ 方法2：PowerShell .NET ZipFile（兜底旧版PS） ------
echo [INFO] Compress-Archive 失败，尝试 .NET ZipFile ...
chcp 437 >nul 2>&1

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Add-Type -AssemblyName System.IO.Compression.FileSystem; if (Test-Path '!PS_DST!') { Remove-Item '!PS_DST!' -Force }; [System.IO.Compression.ZipFile]::CreateFromDirectory('!cd!\_zip_temp', '!PS_DST!'); exit 0 } catch { Write-Host '[PS ERROR]' $_.Exception.Message; exit 1 }"

chcp 65001 >nul 2>&1

if exist "main.zip" (
    echo [OK] .NET ZipFile 成功
    goto :ZIP_DONE
)

:: ------ 方法3：tar（Win10 1803+ 自带） ------
echo [INFO] PowerShell 均失败，尝试 tar ...
pushd "_zip_temp"
tar -acf "..\main.zip" _worker.js 2>&1
popd

if exist "main.zip" (
    echo [OK] tar 打包成功
    goto :ZIP_DONE
)

:: ------ 方法4：jar（如果有 Java） ------
where jar >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] tar 失败，尝试 jar ...
    pushd "_zip_temp"
    jar -cMf "..\main.zip" _worker.js 2>&1
    popd
    if exist "main.zip" (
        echo [OK] jar 打包成功
        goto :ZIP_DONE
    )
)

:: ------ 全部失败 ------
rd /s /q "_zip_temp" 2>nul
echo.
echo [ERROR] 所有自动打包方式均失败
echo.
echo   请手动操作：
echo   1. 把 !ZIP_SOURCE! 复制一份改名为 _worker.js
echo   2. 右键该文件 - 发送到 - 压缩文件夹
echo   3. 重命名为 main.zip
echo.
echo   或者安装 7-Zip 后手动压缩
goto :SHOW_RESULT

:ZIP_DONE
rd /s /q "_zip_temp" 2>nul

if exist "main.zip" (
    for %%F in (main.zip) do set "ZIP_SIZE=%%~zF"
    echo.
    echo [OK] main.zip 打包成功（!ZIP_SIZE! 字节）
)

:: ========== 显示结果 ==========
:SHOW_RESULT

echo.
echo ==========================================
echo   文件清单
echo ------------------------------------------
if exist "_worker.js" (
    for %%F in (_worker.js) do echo   _worker.js           %%~zF 字节  [原始文件]
)
if exist "_worker_obf.js" (
    for %%F in (_worker_obf.js) do echo   _worker_obf.js       %%~zF 字节  [混淆文件]
)
if exist "main.zip" (
    for %%F in (main.zip) do echo   main.zip             %%~zF 字节  [部署压缩包]
)
echo ==========================================
echo.
if exist "main.zip" (
    echo   下一步：拿 main.zip 去 CF Pages 上传部署
)
echo.
echo   说明：
echo     _worker.js     = 原始文件（未改动）
echo     _worker_obf.js = 混淆后的文件
echo     main.zip       = 内含混淆后的 _worker.js
echo ==========================================

:EXIT
echo.
pause
endlocal