# Config.ps1 - 全局配置
# ============================================
# 使用前请根据实际环境修改以下配置

$Global:DotTraceConfig = @{
    # dotTrace 独立安装路径（请根据实际安装版本修改）
    ToolPath       = "D:\Apps\JetBrains.dotTrace\dottrace.exe"

    # 目标应用（修改为你的桌面软件名称，不含 .exe）
    AppName        = "PolarControl"
    AppPath        = "D:\Apps\Polar\PolarControl\PolarControl.exe"

    # 输出目录
    OutputRoot     = "C:\Users\jiajun.wu\Desktop\dottrace"
    SnapshotDir    = "C:\Users\jiajun.wu\Desktop\dottrace\Snapshots"
    ReportDir      = "C:\Users\jiajun.wu\Desktop\dottrace\Reports"
    LogDir         = "C:\Users\jiajun.wu\Desktop\dottrace\Logs"

    # 分析参数
    DefaultType    = "Sampling"       # Sampling | Timeline | Tracing
    DefaultTimeout = 30               # 默认采集时长（秒）

    # CPU 触发阈值
    CpuThreshold      = 70            # CPU 使用率百分比
    CpuCheckInterval  = 5             # 检查间隔（秒）
    CpuCooldown       = 300           # 触发后冷却时间（秒）

    # 定时巡检
    PatrolInterval = 1800             # 巡检间隔（秒），默认 30 分钟
    PatrolDuration = 15               # 每次采集时长（秒）

    # 快照保留策略
    MaxSnapshotAge  = 7               # 保留天数
    MaxSnapshotSize = 5GB             # 最大总占用
    MaxCaptures     = 10              # CPU 触发最大采集次数
}

# 确保目录存在
$dirsToCreate = @($Global:DotTraceConfig.SnapshotDir, $Global:DotTraceConfig.ReportDir, $Global:DotTraceConfig.LogDir)
foreach ($d in $dirsToCreate) {
    if ($d -and -not (Test-Path $d)) {
        New-Item -ItemType Directory -Force -Path $d | Out-Null
    }
}
