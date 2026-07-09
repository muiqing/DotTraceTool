# Core.ps1 - Core Functions
# ============================================
if (-not $Global:DotTraceConfig) {
    $cfgPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot "Config.ps1" } else { Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Config.ps1" }
    if (Test-Path $cfgPath) { . $cfgPath }
}

function Write-PerfLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"
    $logFile = Join-Path $Global:DotTraceConfig.LogDir "perf_$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logFile -Value $logLine -Encoding UTF8
    return $logLine
}

function Get-TargetProcess {
    param([string]$AppName = $Global:DotTraceConfig.AppName)
    $proc = Get-Process -Name $AppName -ErrorAction SilentlyContinue | Select-Object -First 1
    return $proc
}

function Get-CpuUsage {
    param([string]$AppName = $Global:DotTraceConfig.AppName)
    try {
        # 轻量级 CPU 计算：基于 Process.CPU 两次采样差值，不阻塞 UI
        $procs = Get-Process -Name $AppName -ErrorAction SilentlyContinue
        if (-not $procs) { return -1 }
        $totalCpu = ($procs | Measure-Object -Property CPU -Sum).Sum

        # 首次调用：记录基准值，返回 0
        if (-not $script:_lastCpuTime) {
            $script:_lastCpuTime = $totalCpu
            $script:_lastCheckTime = Get-Date
            $script:_lastCpuPercent = 0
            return 0
        }

        $now = Get-Date
        $elapsed = ($now - $script:_lastCheckTime).TotalSeconds
        if ($elapsed -lt 0.5) { return $script:_lastCpuPercent }

        $cpuDelta = $totalCpu - $script:_lastCpuTime
        $percent = [math]::Round(($cpuDelta / $elapsed) / [Environment]::ProcessorCount * 100, 1)

        $script:_lastCpuTime = $totalCpu
        $script:_lastCheckTime = $now
        $script:_lastCpuPercent = [math]::Max(0, $percent)

        return $script:_lastCpuPercent
    } catch {
        return -1
    }
}

function Get-ProcessMetrics {
    param([string]$AppName = $Global:DotTraceConfig.AppName)
    $proc = Get-Process -Name $AppName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { return $null }
    $cpu = Get-CpuUsage -AppName $AppName
    return @{
        PID        = $proc.Id
        CPU        = $cpu
        MemoryMB   = [math]::Round($proc.WorkingSet64 / 1MB, 0)
        Threads    = $proc.Threads.Count
        Handles    = $proc.HandleCount
        StartTime  = $proc.StartTime
        Uptime     = (Get-Date) - $proc.StartTime
    }
}

function Invoke-DotTrace {
    param(
        [Parameter(Mandatory)][string]$Command,
        [string]$Arguments = ""
    )
    $tool = $Global:DotTraceConfig.ToolPath
    if (-not (Test-Path $tool)) {
        return "ERROR: dotTrace 未找到: $tool"
    }
    $fullArgs = "$Command $Arguments"
    $result = & $tool $Command $Arguments.Split(' ') 2>&1
    return ($result | Out-String)
}

function Start-Snapshot {
    param(
        [int]$ProcessId,
        [string]$Label = "Manual",
        [string]$ProfilingType = $Global:DotTraceConfig.DefaultType,
        [int]$Duration = $Global:DotTraceConfig.DefaultTimeout
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "$($Global:DotTraceConfig.AppName)_${Label}_${ProfilingType}_${timestamp}.dtp"
    $snapshotPath = Join-Path $Global:DotTraceConfig.SnapshotDir $fileName

    $tool = $Global:DotTraceConfig.ToolPath
    $argList = @(
        "attach", $ProcessId,
        "--save-to=$snapshotPath",
        "--profiling-type=$ProfilingType",
        "--timeout=${Duration}s"
    )

    Write-PerfLog "开始采集: PID=$ProcessId, 类型=$ProfilingType, 时长=${Duration}s, 标签=$Label" "OK"

    try {
        $output = & $tool @argList 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) {
            Write-PerfLog "dotTrace 退出码: $exitCode, 输出: $($output | Out-String)" "ERROR"
            return $null
        }
    } catch {
        Write-PerfLog "采集异常: $_" "ERROR"
        return $null
    }

    if (Test-Path $snapshotPath) {
        $size = [math]::Round((Get-Item $snapshotPath).Length / 1MB, 2)
        Write-PerfLog "快照已保存: $fileName ($size MB)" "OK"
        return $snapshotPath
    } else {
        Write-PerfLog "快照保存失败" "ERROR"
        return $null
    }
}

function Clear-OldSnapshots {
    $maxAge = $Global:DotTraceConfig.MaxSnapshotAge
    $dir = $Global:DotTraceConfig.SnapshotDir
    $cutoff = (Get-Date).AddDays(-$maxAge)

    $removed = 0
    Get-ChildItem -Path $dir -Filter "*.dtp" -ErrorAction SilentlyContinue | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | ForEach-Object {
        Remove-Item $_.FullName -Force
        $removed++
    }
    if ($removed -gt 0) {
        Write-PerfLog "已清理 $removed 个过期快照" "WARN"
    }
    return $removed
}

function Get-SnapshotList {
    $dir = $Global:DotTraceConfig.SnapshotDir
    return Get-ChildItem -Path $dir -Filter "*.dtp" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime
}
