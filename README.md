# dotTrace Performance Profiler v1.0

## 功能使用说明文档

基于 JetBrains dotTrace CLI 的桌面应用性能分析工具，提供 WPF GUI 界面，支持手动/自动/定时采集性能快照、崩溃监控、自动化脚本批量执行、报告生成，帮助定位 .NET 应用的性能瓶颈。

---

## 目录

- [环境要求](#环境要求)
- [Python 环境配置](#python-环境配置)
- [快速开始](#快速开始)
- [部署到其他电脑](#部署到其他电脑)
- [目录结构](#目录结构)
- [配置说明](#配置说明)
- [功能模块](#功能模块)
  - [Dashboard（仪表盘）](#dashboard仪表盘)
  - [Load Test（负载测试）](#load-test负载测试)
  - [Patrol（定时巡检）](#patrol定时巡检)
  - [CPU Trigger（CPU 自动触发）](#cpu-triggercpu-自动触发)
  - [Automation（自动化）](#automation自动化)
  - [Report（报告生成）](#report报告生成)
  - [Settings（设置）](#settings设置)
- [分析模式说明](#分析模式说明)
- [输出文件说明](#输出文件说明)
- [常见问题](#常见问题)

---

## 环境要求

| 项目 | 要求 | 说明 |
|------|------|------|
| 操作系统 | Windows 10/11 | WPF GUI 依赖 |
| PowerShell | 5.1 或更高版本 | Windows 自带 |
| .NET Framework | 4.5+ | Windows 自带（WPF 依赖） |
| JetBrains dotTrace | 命令行版本 | 放在项目 `JetBrains.dotTrace\` 目录下 |
| Python | 3.8+（可选） | 仅 Automation 功能需要 |
| 目标应用 | .NET 桌面应用程序 | WPF、WinForms、.NET Console 等 |

> **注意：** dotTrace 只能附加到 .NET 进程。Electron、原生 C++ 应用不支持。

---

## Python 环境配置

Automation（自动化）功能使用 Python 脚本驱动 UI 操作，需要配置 Python 环境。**如果不使用 Automation 功能，可跳过此节。**

### 1. 安装 Python

从 [Python 官网](https://www.python.org/downloads/) 下载 Python 3.8 或更高版本。

安装时 **务必勾选**：
- ✅ `Add Python to PATH`（添加到系统环境变量）
- ✅ `Install pip`

验证安装：
```powershell
python --version
pip --version
```

### 2. 安装依赖库

自动化脚本依赖以下 Python 库：

```powershell
pip install pywinauto pyautogui pynput Pillow
```

| 库 | 用途 |
|----|------|
| `pywinauto` | Windows UI 自动化（UIA/Win32 后端） |
| `pyautogui` | 屏幕截图、鼠标键盘模拟 |
| `pynput` | 监听鼠标/键盘事件 |
| `Pillow` | 图像处理（截图标注） |

### 3. 验证环境

```powershell
python -c "import pywinauto; print('pywinauto OK')"
python -c "import pyautogui; print('pyautogui OK')"
```

### 4. 常见问题

**Q: `pip install pywinauto` 报错网络超时**

使用国内镜像源：
```powershell
pip install pywinauto pyautogui pynput Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple
```

**Q: 运行脚本报 `ModuleNotFoundError`**

确认 Python 路径正确：
```powershell
where python
```
确保输出的路径是你安装的 Python，而非 Windows Store 版本。如果显示 `WindowsApps` 路径，需要在系统环境变量中将 Python 安装目录移到最前面。

**Q: pywinauto 无法识别控件**

- 确保目标应用以普通权限运行，或以管理员身份运行 Python 脚本
- 对于 WPF 应用，使用 `backend="uia"`；对于传统 Win32 应用，使用 `backend="win32"`

---

## 快速开始

### 1. 放置 dotTrace 工具

将 JetBrains dotTrace 命令行工具放入项目目录：

```
dottrace\
└── JetBrains.dotTrace\
    ├── dottrace.exe
    ├── Reporter.exe
    └── ... (其他 dotTrace 文件)
```

> 工具路径会自动解析为 `{项目根目录}\JetBrains.dotTrace\dottrace.exe`，无需手动配置。

### 2. 修改目标应用配置

编辑 `Scripts\Config.ps1`，仅需修改目标应用信息：

```powershell
AppName = "YourApp"                          # 目标进程名（不含 .exe）
AppPath = "D:\Path\To\YourApp.exe"           # 目标应用完整路径
```

### 3. 启动工具

```powershell
powershell -ExecutionPolicy Bypass -File DotTraceUI.ps1
```

或者右键 `DotTraceUI.ps1` → "使用 PowerShell 运行"。

### 4. 确认状态

启动后查看顶部状态栏：
- **Target**: 显示目标进程名
- **PID**: 显示进程 ID（`-` 表示未运行）
- **状态指示灯**: 🟢 绿色 = 进程运行中，🔴 红色 = 未检测到
- **dotTrace**: 显示 `Installed` 或 `Not Found`

---

## 部署到其他电脑

本工具所有路径（快照、日志、报告、dotTrace 工具）均基于项目根目录自动解析，**支持整体复制部署**。

### 部署步骤

1. **复制整个 `dottrace` 文件夹**到目标电脑任意位置
2. 确保 `dottrace\JetBrains.dotTrace\` 下有 `dottrace.exe` 和 `Reporter.exe`
3. 编辑 `Scripts\Config.ps1`，修改 `AppName` 和 `AppPath` 为目标电脑上的应用
4. 右键 `DotTraceUI.ps1` → "使用 PowerShell 运行"

### 需要的环境

| 环境 | 是否必须 | 说明 |
|------|----------|------|
| Windows 10/11 | ✅ 必须 | 系统自带 PowerShell 和 .NET Framework |
| JetBrains dotTrace CLI | ✅ 必须 | 放在项目 `JetBrains.dotTrace\` 目录 |
| Python 3.8+ | ⚠️ 可选 | 仅 Automation 功能需要 |

> **无需额外安装 PowerShell 或 .NET Framework**，Windows 10/11 已自带。

---

## 目录结构

```
dottrace/
├── DotTraceUI.ps1              # 主程序（GUI 入口）
├── README.md                   # 本说明文档
├── Scripts/
│   ├── Config.ps1              # 全局配置文件
│   ├── Core.ps1                # 核心函数库
│   ├── Auto-Trigger-CPU.ps1    # CPU 自动触发脚本
│   ├── Compare-AB.ps1          # A/B 版本对比脚本（命令行）
│   ├── Profile-UnderLoad.ps1   # 负载测试采集脚本
│   └── Scheduled-Patrol.ps1    # 定时巡检脚本
├── Automation/
│   └── UI/                     # Python 自动化脚本目录
│       └── Demo.py             # 示例脚本
├── JetBrains.dotTrace/         # dotTrace CLI 工具目录
│   ├── dottrace.exe
│   └── Reporter.exe
├── Snapshots/                  # 快照输出目录（.dtp 文件）
├── Reports/                    # 报告输出目录
│   └── pattern/                # 报告 Pattern 模板
│       ├── pattern.xml
│       ├── pattern_phase1.xml
│       └── pattern_phase2.xml
└── Logs/                       # 日志目录
```

---

## 配置说明

配置文件位于 `Scripts\Config.ps1`，所有路径基于项目根目录自动解析。

### 基础配置

| 参数 | 说明 | 备注 |
|------|------|------|
| `ToolPath` | dotTrace CLI 路径 | 自动解析，无需修改 |
| `ReporterPath` | Reporter.exe 路径 | 自动解析，无需修改 |
| `AppName` | 目标进程名称（不含 .exe） | **需要修改** |
| `AppPath` | 目标应用完整路径 | **需要修改** |

### 输出目录（自动解析，无需修改）

| 参数 | 实际路径 |
|------|----------|
| `OutputRoot` | `{项目根目录}` |
| `SnapshotDir` | `{项目根目录}\Snapshots` |
| `ReportDir` | `{项目根目录}\Reports` |
| `LogDir` | `{项目根目录}\Logs` |

### 分析参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `DefaultType` | 默认分析模式 | `"Sampling"` |
| `DefaultTimeout` | 默认采集时长（秒） | `30` |

### CPU 触发阈值

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `CpuThreshold` | CPU 使用率触发阈值（%） | `70` |
| `CpuCheckInterval` | 检查间隔（秒） | `5` |
| `CpuCooldown` | 触发后冷却时间（秒） | `300` |

### 定时巡检

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `PatrolInterval` | 巡检间隔（秒） | `1800`（30 分钟） |
| `PatrolDuration` | 每次采集时长（秒） | `15` |

### 快照保留策略

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `MaxSnapshotAge` | 快照保留天数 | `7` |
| `MaxSnapshotSize` | 最大总占用空间 | `5GB` |
| `MaxCaptures` | CPU 触发最大采集次数 | `10` |

---

## 功能模块

### Dashboard（仪表盘）

主界面，提供实时监控和快速操作。

#### 实时指标卡片

| 指标 | 说明 |
|------|------|
| CPU Usage | 目标进程当前 CPU 使用率 |
| Memory | 目标进程工作集内存（MB） |
| Threads | 线程数 |
| Handles | 句柄数 |

> 指标每 5 秒自动刷新。

#### 操作按钮

| 按钮 | 功能 |
|------|------|
| **Manual Snapshot** | 立即对目标进程采集一次快照 |
| **Refresh List** | 刷新快照列表 |
| **Open Folder** | 打开快照保存目录 |
| **Clean Old** | 清理超过保留天数的旧快照 |
| **⚠ Crash Monitor** | 开启/关闭崩溃监控 |

#### Manual Snapshot 使用流程

1. 确保目标进程正在运行（状态灯为绿色）
2. 点击 **Manual Snapshot**
3. 等待采集完成（默认 30 秒）
4. 快照文件出现在列表中

快照命名格式：`{AppName}_Manual_{ProfilingType}_{yyyyMMdd_HHmmss}.dtp`

#### Crash Monitor（崩溃监控）

开启后，工具会持续对目标进程进行低开销 Sampling 采集。当检测到进程意外退出（崩溃）时：

1. 自动保存崩溃前的性能快照
2. 从 Windows 事件日志中提取崩溃信息
3. 快照文件名以 `CrashMonitor_` 前缀标识

**使用流程：**
1. 点击 **⚠ Crash Monitor** 按钮开启（按钮变红，显示 ON）
2. 工具自动开始后台 Profiling 会话
3. 如果进程崩溃，自动保存快照并记录事件日志
4. 进程重启后自动恢复监控
5. 再次点击按钮关闭监控

**适用场景：**
- 捕获随机崩溃的性能上下文
- 分析崩溃前的调用栈和资源使用情况

---

### Load Test（负载测试）

在负载测试期间多次采集快照，形成完整的性能画像。适用于模拟用户高并发场景下的性能分析。

#### 配置参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| Test Name | 测试名称（用于文件命名） | `LoadTest` |
| Duration(s) | 测试总时长（秒） | `300` |
| Sample Count | 采样次数 | `5` |
| Each Sample(s) | 每次采样时长（秒） | `20` |
| Profiling Type | 分析模式 | `Timeline` |

#### 使用流程

1. 确保目标进程正在运行
2. 填写测试参数
3. 点击 **Start Load Test**
4. 脚本在新窗口中执行，按等间隔自动采集多次快照
5. 完成后在 Snapshots 目录查看结果

#### 输出

- 多个 `.dtp` 快照文件（每个采集点一个）
- `{TestName}_{timestamp}_meta.json` 元数据文件，记录每次采集时的 CPU、内存、线程等指标

#### 适用场景

- 压力测试期间观察性能变化趋势
- 发现内存泄漏或资源累积问题
- 对比测试开始和结束时的性能差异

---

### Patrol（定时巡检）

周期性采集短快照，建立性能基线，自动检测渐进式性能退化。

#### 配置参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| Interval(s) | 巡检间隔（秒） | `1800`（30 分钟） |
| Capture(s) | 每次采集时长（秒） | `15` |
| Max Rounds(0=inf) | 最大巡检轮数（0=无限） | `0` |

#### 使用流程

1. 设置巡检参数
2. 点击 **Start Patrol**
3. 脚本在新窗口中持续运行
4. 点击 **Stop Patrol** 停止巡检
5. 点击 **View CSV Trend** 查看当日趋势数据

#### 异常检测逻辑

巡检会自动建立基线，并在以下情况标记异常：
- 内存增长超过基线 **500MB**
- 句柄增长超过基线 **1000** 个
- CPU 使用率超过 **50%**

异常快照文件名中会包含 `_ANOMALY` 标记。

#### 输出

- 每轮一个 `.dtp` 快照文件
- `Reports/patrol_{yyyyMMdd}.csv` 趋势数据（含时间、CPU、内存、句柄、线程、是否异常）
- 自动清理超过保留天数的旧快照

#### 适用场景

- 长时间运行的服务/应用监控
- 检测内存泄漏（内存持续增长）
- 检测句柄泄漏
- 建立性能基线用于版本对比

---

### CPU Trigger（CPU 自动触发）

持续监控目标进程 CPU 使用率，超过阈值时自动抓取快照。

#### 配置参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| CPU Threshold(%) | CPU 触发阈值 | `70` |
| Check Interval(s) | 检查间隔 | `5` |
| Cooldown(s) | 触发后冷却时间 | `300` |
| Max Captures | 最大采集次数 | `10` |
| Also monitor memory | 同时监控内存（超 2GB 触发） | 未勾选 |

#### 使用流程

1. 设置触发参数
2. 点击 **Start CPU Monitor**
3. 监控在新窗口中持续运行
4. 当 CPU 超过阈值时自动采集快照
5. 点击 **Stop Monitor** 停止监控

#### 触发逻辑

- 使用 **5 次采样的滑动平均值** 判断是否超过阈值（避免瞬间毛刺误触发）
- 触发后进入冷却期（默认 300 秒），冷却期内不会重复触发
- 达到最大采集次数后自动停止
- 如果勾选了内存监控，当内存超过 2GB 时也会触发

#### 输出

- `.dtp` 快照文件（文件名包含触发原因，如 `AutoTrigger_HighCPU_85pct`）
- `_context.txt` 上下文文件（记录触发时的详细指标）

#### 适用场景

- 捕获间歇性 CPU 飙高问题
- 无人值守的性能监控
- 生产环境异常自动采集

---

### Automation（自动化）

批量执行 Python UI 自动化脚本，可选在执行期间同步采集性能快照。适用于自动化回归测试场景下的性能分析。

> **前置条件：** 需要配置 Python 环境，详见 [Python 环境配置](#python-环境配置)。

#### 功能概述

- 扫描 `Automation\UI\` 目录下的 `.py` 脚本
- 支持选择性执行、批量执行
- 可为每个脚本单独开启/关闭快照采集
- 执行期间自动启动 dotTrace Profiling，脚本结束后保存快照

#### 界面说明

| 列 | 说明 |
|----|------|
| Sel | 是否选中执行（✓ = 选中） |
| Script Name | 脚本文件名 |
| Snap | 是否启用快照（✓ = 开启） |
| Status | 执行状态（Ready / Running / Done / Failed / Timeout） |

#### 操作按钮

| 按钮 | 功能 |
|------|------|
| **✓ Select All** | 全选所有脚本 |
| **✗ Deselect All** | 取消全选 |
| **Toggle Select** | 切换选中行的选中状态 |
| **Toggle Snapshot** | 切换选中行的快照开关 |
| **↻ Refresh** | 重新扫描脚本目录 |
| **Open Folder** | 打开 `Automation\UI\` 目录 |
| **▶ Run Selected** | 执行所有选中的脚本（按各自 Snap 设置决定是否采集） |
| **▶ Run All + Snapshot** | 执行所有脚本并强制开启快照 |
| **Stop** | 终止当前正在执行的脚本 |

#### 执行控制

| 参数 | 说明 | 默认值 |
|------|------|--------|
| Profiling Type | 快照分析模式 | `Sampling` |
| Timeout(s) | 单个脚本超时时间 | `300` |

#### 使用流程

1. 将 Python 自动化脚本放入 `Automation\UI\` 目录
2. 点击 **↻ Refresh** 扫描脚本
3. 选择要执行的脚本，设置是否开启快照
4. 选择 Profiling Type 和 Timeout
5. 点击 **▶ Run Selected** 或 **▶ Run All + Snapshot**
6. 查看执行日志和快照结果

#### 快照命名格式

```
Auto_{脚本名}_{ProfilingType}_{yyyyMMdd_HHmmss}.dtp
```

#### 编写自动化脚本

脚本放在 `Automation\UI\` 目录下，使用 Python 编写。示例：

```python
from pywinauto import Application
import time

APP_PATH = r"D:\Apps\Polar\PolarControl\PolarControl.exe"

def main():
    app = Application(backend="uia").start(APP_PATH)
    time.sleep(2)
    dlg = app.top_window()
    dlg.set_focus()

    # 执行 UI 操作...
    # dlg.child_window(title="按钮名", control_type="Button").click_input()

    time.sleep(1)
    try:
        dlg.close()
    except Exception:
        app.kill()

if __name__ == "__main__":
    main()
```

#### 适用场景

- 自动化回归测试 + 性能采集
- 批量 UI 操作场景的性能分析
- 重复性测试流程自动化

---

### Report（报告生成）

使用 JetBrains dotTrace Reporter 工具，基于 Pattern 模板从快照中提取热点函数报告。

#### 界面说明

| 字段 | 说明 |
|------|------|
| Reporter.exe | Reporter 工具路径（自动填充） |
| Snapshot (.dtp) | 要分析的快照文件 |
| Pattern (.xml) | 分析模板（定义要匹配的函数模式） |
| Output (.xml) | 报告输出路径 |

#### 操作按钮

| 按钮 | 功能 |
|------|------|
| **Browse** | 浏览选择文件 |
| **Generate Report** | 生成报告 |
| **Open Output** | 打开生成的报告文件 |
| **Open Folder** | 打开报告所在目录 |

#### 使用流程

1. 选择要分析的 `.dtp` 快照文件
2. 选择 Pattern 模板（项目自带 `Reports/pattern/` 下的模板）
3. 指定输出路径
4. 点击 **Generate Report**
5. 查看生成的 XML 报告

#### Pattern 模板说明

项目自带三个 Pattern 模板：

| 模板 | 用途 |
|------|------|
| `pattern.xml` | 通用热点函数匹配（UI 操作、GC、Native 调用等） |
| `pattern_phase1.xml` | 按命名空间过滤（PolarControl、Quartz、DevExpress 等） |
| `pattern_phase2.xml` | 精确匹配特定方法（含调用栈输出） |

#### 报告输出格式

生成的 XML 报告包含匹配函数的：
- 函数全限定名（FQN）
- 总耗时（TotalTime）
- 自身耗时（OwnTime）
- 采样次数（Samples）
- 调用栈路径（CallStack）

#### 适用场景

- 从快照中快速提取关注的热点方法
- 批量分析多个快照的特定性能指标
- 生成可对比的结构化性能数据

---

### Settings（设置）

运行时修改配置参数。

#### 可修改项

| 设置项 | 说明 |
|--------|------|
| dotTrace Path | dotTrace 可执行文件路径 |
| Process Name | 目标进程名称 |
| App Path | 目标应用路径 |
| Keep Days | 快照保留天数 |
| Default Type | 默认分析模式 |

#### 注意事项

- 点击 **Save Settings** 后仅保存到当前会话内存
- 重启工具后会重新从 `Config.ps1` 加载
- 如需永久修改，请直接编辑 `Scripts\Config.ps1`

---

## 分析模式说明

| 模式 | 开销 | 适用场景 | 说明 |
|------|------|----------|------|
| **Sampling** | ~2% | 生产环境 | 定期采样调用栈，开销极低，适合长时间运行 |
| **Timeline** | ~5% | 测试环境 | 记录线程时间线，可分析并发、等待、阻塞问题 |
| **Tracing** | ~20%+ | 开发环境 | 精确记录每次方法调用，数据量大，严重影响性能 |

### 选择建议

- **日常监控/巡检/崩溃监控** → Sampling
- **排查卡顿/死锁** → Timeline
- **精确定位热点方法** → Tracing（仅在开发环境使用）

---

## 输出文件说明

### 快照文件（.dtp）

| 命名格式 | 来源 |
|----------|------|
| `{App}_Manual_{Type}_{时间}.dtp` | 手动采集 |
| `{App}_LoadTest_Phase{N}of{M}_CPU{X}_{时间}.dtp` | 负载测试 |
| `{App}_Patrol_R{N}_CPU{X}_Mem{Y}_{时间}.dtp` | 定时巡检 |
| `{App}_AutoTrigger_HighCPU_{X}pct_{时间}.dtp` | CPU 触发 |
| `Auto_{脚本名}_{Type}_{时间}.dtp` | 自动化执行 |
| `CrashMonitor_{时间}.dtp` | 崩溃监控 |

用 JetBrains dotTrace Viewer 打开 `.dtp` 文件即可查看详细的调用树、热点方法、线程时间线等。

### 报告文件

| 文件 | 说明 |
|------|------|
| `patrol_{日期}.csv` | 巡检趋势数据 |
| `report_{时间}.xml` | Reporter 生成的热点报告 |
| `{TestName}_{时间}_meta.json` | 负载测试元数据 |

### 日志文件

位于 `Logs/perf_{yyyyMMdd}.log`，记录所有操作的时间戳和详细信息。

---

## 常见问题

### Q: 启动后状态显示 "Not Running"

**A:** 目标进程未运行。请先启动目标应用，或检查 `Config.ps1` 中的 `AppName` 是否与实际进程名一致（不含 `.exe`）。

验证方法：
```powershell
Get-Process -Name "YourAppName"
```

### Q: dotTrace 显示 "Not Found"

**A:** 确保 `JetBrains.dotTrace\dottrace.exe` 存在于项目根目录下。检查目录结构：
```
dottrace\
└── JetBrains.dotTrace\
    └── dottrace.exe  ← 必须存在
```

### Q: 快照采集失败

**A:** 可能原因：
1. 目标进程不是 .NET 应用（dotTrace 仅支持 .NET）
2. 权限不足（尝试以管理员身份运行）
3. dotTrace 版本与目标 .NET 版本不兼容

查看 `Logs/` 目录下的日志文件获取详细错误信息。

### Q: Config.ps1 加载报错（乱码）

**A:** 文件编码问题。确保 `Config.ps1` 为 **UTF-8 with BOM** 编码。可用以下命令重新保存：
```powershell
$content = Get-Content "Scripts\Config.ps1" -Raw
[System.IO.File]::WriteAllText("Scripts\Config.ps1", $content, [System.Text.UTF8Encoding]::new($true))
```

### Q: CPU Trigger 一直不触发

**A:** 检查以下几点：
1. 目标进程是否在运行
2. 阈值设置是否过高（可先降低到 30% 测试）
3. 查看监控窗口中的实时 CPU 数值

### Q: 巡检 CSV 文件在哪里？

**A:** 位于 `Reports/patrol_{当天日期}.csv`。点击 **View CSV Trend** 按钮可直接打开。

### Q: Automation 脚本执行报错

**A:** 检查以下几点：
1. Python 是否已安装并加入 PATH（运行 `python --version` 验证）
2. 依赖库是否已安装（`pip install pywinauto pyautogui pynput Pillow`）
3. 脚本是否有语法错误（先在命令行手动运行测试）
4. 目标应用是否已启动（如果脚本需要附加到已有进程）

### Q: 如何用 dotTrace Viewer 分析快照？

**A:**
1. 打开 JetBrains dotTrace（GUI 版本）
2. 菜单 → File → Open Snapshot
3. 选择 `Snapshots/` 目录下的 `.dtp` 文件
4. 查看 Hot Spots（热点方法）、Call Tree（调用树）、Timeline（线程时间线）

### Q: 部署到其他电脑后报错找不到 Scripts

**A:** 确保复制了完整的目录结构，特别是 `Scripts\` 文件夹。DotTraceUI.ps1 启动时会检查 Scripts 目录是否存在。

---

## 技术架构

```
┌─────────────────────────────────────────────┐
│           DotTraceUI.ps1 (WPF GUI)           │
├─────────────────────────────────────────────┤
│  Config.ps1        │    Core.ps1             │
│  (全局配置/相对路径) │    (核心函数库)          │
├─────────────────────────────────────────────┤
│  子脚本（独立 PowerShell 窗口运行）            │
│  ├── Profile-UnderLoad.ps1                   │
│  ├── Scheduled-Patrol.ps1                    │
│  └── Auto-Trigger-CPU.ps1                    │
├─────────────────────────────────────────────┤
│  Automation/UI/*.py (Python 自动化脚本)       │
├─────────────────────────────────────────────┤
│  JetBrains dotTrace CLI                      │
│  ├── dottrace.exe (采集快照)                  │
│  └── Reporter.exe (生成报告)                  │
└─────────────────────────────────────────────┘
```

- **主 GUI** 负责配置管理、状态显示、操作入口、崩溃监控
- **子脚本** 在独立 PowerShell 窗口中运行，避免阻塞 GUI
- **Core.ps1** 提供进程检测、CPU 采集、快照管理等公共函数
- **Python 脚本** 驱动 UI 自动化操作
- **dotTrace CLI** 负责实际的性能数据采集
- **Reporter** 负责从快照生成结构化报告

---

*文档版本: v1.1 | 最后更新: 2026-06-17*
