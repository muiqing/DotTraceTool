# Scheduled-Patrol.ps1
# 用途：周期性采集短快照，建立性能基线，发现渐进式退化
# ============================================
param(
    [int]$IntervalSeconds = 0,
    [int]$Duration = 0,
    [int]$MaxRounds = 0
)

. "$PSScriptRoot\Core.ps1"

$interval = if ($IntervalSeconds -gt 0) { $IntervalSeconds } else { $Global:DotTraceConfig.PatrolInterval }
$captureDuration = if ($Duration -gt 0) { $Duration } else { $Global:DotTraceConfig.PatrolDuration }

Write-PerfLog "========== 定时性能巡检 ==========" "OK"
Write-PerfLog "巡检间隔: ${interval}s | 采集时长: ${captureDuration}s"

$round = 0
$baselineMetrics = $null

while ($true) {
    $round++
    if ($MaxRounds -gt 0 -and $round -gt $MaxRounds) { break }

    Write-PerfLog "--- 第 $round 轮巡检 ---"

    $proc = Get-TargetProcess
    if (-not $proc) {
        Write-PerfLog "目标进程未运行，跳过本轮" "WARN"
        Start-Sleep -Seconds $interval
        continue
    }

    $cpu = Get-CpuUsage
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
    $handles = $proc.HandleCount
    $threads = $proc.Threads.Count

    # 建立基线
    if (-not $baselineMetrics) {
        $baselineMetrics = @{ CPU = $cpu; MemoryMB = $mem; Handles = $handles }
        Write-PerfLog "基线已建立: CPU=${cpu}% | 内存=${mem}MB | 句柄=$handles"
    }

    # 检测异常
    $memGrowth = $mem - $baselineMetrics.MemoryMB
    $handleGrowth = $handles - $baselineMetrics.Handles
    $anomaly = ($memGrowth -gt 500) -or ($handleGrowth -gt 1000) -or ($cpu -gt 50)

    if ($anomaly) {
        Write-PerfLog "检测到异常: 内存增长=${memGrowth}MB, 句柄增长=$handleGrowth, CPU=${cpu}%" "WARN"
    }

    # 采集快照
    $label = "Patrol_R${round}_CPU${cpu}_Mem${mem}"
    if ($anomaly) { $label += "_ANOMALY" }

    Start-Snapshot -ProcessId $proc.Id `
        -Label $label `
        -ProfilingType "Sampling" `
        -Duration $captureDuration | Out-Null

    # 记录 CSV
    $csvPath = Join-Path $Global:DotTraceConfig.ReportDir "patrol_$(Get-Date -Format 'yyyyMMdd').csv"
    if (-not (Test-Path $csvPath)) {
        "Time,CPU%,MemoryMB,Handles,Threads,Anomaly" | Out-File $csvPath -Encoding UTF8
    }
    "$(Get-Date -Format 'HH:mm:ss'),$cpu,$mem,$handles,$threads,$anomaly" | Out-File $csvPath -Append -Encoding UTF8

    # 清理旧快照
    Clear-OldSnapshots

    if ($MaxRounds -eq 0 -or $round -lt $MaxRounds) {
        # 间隔期间每30秒记录指标
        $remainingWait = $interval
        while ($remainingWait -gt 0) {
            $waitStep = [math]::Min(30, $remainingWait)
            Start-Sleep -Seconds $waitStep
            $remainingWait -= $waitStep

            $proc = Get-TargetProcess
            if ($proc) {
                $cpu = Get-CpuUsage
                $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
                $handles = $proc.HandleCount
                $threads = $proc.Threads.Count
                "$(Get-Date -Format 'HH:mm:ss'),$cpu,$mem,$handles,$threads,False" | Out-File $csvPath -Append -Encoding UTF8
            }
        }
    }
}

Write-PerfLog "========== 巡检结束 =========="
