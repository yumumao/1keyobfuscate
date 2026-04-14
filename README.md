# 1keyobfuscate

edgetunnel `_worker.js` 一键混淆打包工具 — 自动完成代码混淆并生成可直接部署到 Cloudflare Pages 的 `main.zip`。

---

## ✨ 功能

- **一键完成混淆+打包**：双击运行，自动混淆 `_worker.js` 并打包为 `main.zip`，可直接上传 Cloudflare Pages 部署
- **智能检测重复混淆**：自动识别 `_worker.js` 是否已经是混淆文件，避免重复混淆导致体积暴增或运行异常
- **随机种子混淆**：每次运行使用不同的随机种子，生成结果各不相同
- **多种打包方式兜底**：依次尝试 PowerShell Compress-Archive → .NET ZipFile → tar → jar，最大程度兼容不同 Windows 环境
- **交互式操作**：检测到已有混淆文件或压缩包时提供选择，防止误覆盖
- **无需管理员权限**：普通 CMD 即可执行

---

## 📋 前提条件

### 1. 安装 Node.js

前往 Node.js 官网下载并安装：

> **https://nodejs.org**
>
> 推荐选择 **LTS（长期支持）版本**（当前为 v24.14.1），安装过程保持默认选项即可。

安装完成后，打开终端验证：

```bash
node -v
npm -v
```

两条命令均能输出版本号即表示安装成功。

| 操作系统 | 打开终端的方式 |
|---------|--------------|
| Windows | PowerShell 或 CMD（按 `Win + R`，输入 `powershell` 或 `cmd`） |
| macOS   | 终端（Terminal）（`Command + Space` 搜索 "Terminal"） |

### 2. 安装混淆工具

在终端中执行以下命令，全局安装 `javascript-obfuscator`：

```bash
npm install -g javascript-obfuscator
```

等待安装完成，出现类似 `added xx packages` 的提示即表示安装成功。可通过以下命令确认：

```bash
javascript-obfuscator --version
```

---

## 🚀 使用方法

1. 将 `obfuscate.bat` 和你的 `_worker.js` 放在**同一文件夹**
2. **双击运行** `obfuscate.bat`
3. 根据提示进行操作（通常一路回车即可）
4. 完成后在同目录下得到 `main.zip`
5. 将 `main.zip` 上传到 **Cloudflare Pages** 部署

```
运行前目录结构：
├── obfuscate.bat       # 一键混淆脚本
└── _worker.js          # edgetunnel 原始文件

运行后目录结构：
├── obfuscate.bat
├── _worker.js          # 原始文件（未改动）
├── _worker_obf.js      # 混淆后的文件
└── main.zip            # 部署压缩包（内含混淆后的 _worker.js）
```

---

## 🔧 混淆参数说明

脚本使用以下 `javascript-obfuscator` 参数：

| 参数 | 值 | 说明 |
|------|-----|------|
| `--compact` | `true` | 压缩为单行，去除格式 |
| `--control-flow-flattening` | `true` | 控制流平坦化，增加逆向难度 |
| `--control-flow-flattening-threshold` | `0.3` | 平坦化比例（30%），平衡安全与性能 |
| `--dead-code-injection` | `true` | 注入死代码，干扰分析 |
| `--dead-code-injection-threshold` | `0.15` | 死代码比例（15%），控制体积增长 |
| `--string-array` | `true` | 字符串提取到数组中 |
| `--string-array-encoding` | `rc4` | 使用 RC4 加密字符串数组 |
| `--string-array-threshold` | `0.75` | 75% 的字符串会被转移 |
| `--rename-globals` | `false` | 不重命名全局变量（避免破坏 Worker 接口） |
| `--self-defending` | `false` | 关闭自我保护（避免格式化后代码失效） |
| `--seed` | 随机 | 每次运行自动生成随机种子 |

---

## 📖 交互流程说明

脚本运行过程中会根据当前文件状态智能提示：

**情况一：`_worker.js` 已是混淆文件**（检测到大量 `_0x` 特征）

脚本会警告并提供三个选择：直接打包为 `main.zip`（推荐）、强制重新混淆（不推荐）、退出。

**情况二：已存在上次生成的 `_worker_obf.js`**

可选择直接复用打包（节省时间），或删除后重新混淆（每次结果不同）。

**情况三：已存在 `main.zip`**

可选择重新混淆并覆盖，或保留现有文件退出。

---

## ⚠️ 注意事项

- `_worker.js` 为原始源文件，脚本**不会修改**它，请放心使用。
- 重复对已混淆的文件再次混淆会导致体积急剧膨胀，脚本已内置检测机制加以防范。
- 混淆过程根据文件大小可能需要 **30 秒 ~ 2 分钟**，请耐心等待。
- `main.zip` 内部的文件名固定为 `_worker.js`，可直接用于 Cloudflare Pages 部署。
- 如果 `npm install -g` 提示权限不足，请以管理员身份运行终端后重试。
- 脚本本身**无需管理员权限**，普通 CMD 窗口双击即可运行。

---

## 📄 License

MIT License