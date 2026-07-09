# Config.ps1 - 全局配置
# ============================================
# 使用前请根据实际环境修改以下配置

# 基于脚本目录解析项目根目录
$_configScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$_projectRoot = Split-Path -Parent $_configScriptRoot

$Global:DotTraceConfig = @{
    # dotTrace 工具路径（相对于项目根目录，自动解析，无需手动配置）
    ToolPath       = (Join-Path $_projectRoot "JetBrains.dotTrace\dottrace.exe")
    ReporterPath   = (Join-Path $_projectRoot "JetBrains.dotTrace\Reporter.exe")

    # 目标应用（修改为你的桌面软件名称，不含 .exe）
    AppName        = "PolarWorks"
    AppPath        = "D:\Apps\PolarWorks\bin\PolarWorks.exe"

    # 输出目录（相对于项目根目录）
    OutputRoot     = $_projectRoot
    SnapshotDir    = (Join-Path $_projectRoot "Snapshots")
    ReportDir      = (Join-Path $_projectRoot "Reports")
    LogDir         = (Join-Path $_projectRoot "Logs")

    # 分析参数
    DefaultType    = "Sampling"
    DefaultTimeout = 30

    # CPU 触发阈值
    CpuThreshold      = 70
    CpuCheckInterval  = 5
    CpuCooldown       = 300

    # 定时巡检
    PatrolInterval = 1800
    PatrolDuration = 15

    # 快照保留策略
    MaxSnapshotAge  = 7
    MaxSnapshotSize = 5GB
    MaxCaptures     = 10
}

# 确保目录存在
$dirsToCreate = @($Global:DotTraceConfig.SnapshotDir, $Global:DotTraceConfig.ReportDir, $Global:DotTraceConfig.LogDir)
foreach ($d in $dirsToCreate) {
    if ($d -and -not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
}