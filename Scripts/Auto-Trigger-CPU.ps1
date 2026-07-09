# Auto-Trigger-CPU.ps1
# 用途：持续监控目标进程 CPU，超过阈值自动抓取快照
# ============================================
param(
    [int]$Threshold = 0,
    [int]$CheckInterval = 0,
    [int]$Cooldown = 0,
    [int]$CaptureDuration = 20,
    [int]$MaxCaptures = 0,
    [switch]$IncludeMemory
)

. "$PSScriptRoot\Core.ps1"

$threshold = if ($Threshold -gt 0) { $Threshold } else { $Global:DotTraceConfig.CpuThreshold }
$checkInterval = if ($CheckInterval -gt 0) { $CheckInterval } else { $Global:DotTraceConfig.CpuCheckInterval }
$cooldown = if ($Cooldown -gt 0) { $Cooldown } else { $Global:DotTraceConfig.CpuCooldown }
$maxCaptures = if ($MaxCaptures -gt 0) { $MaxCaptures } else { $Global:DotTraceConfig.MaxCaptures }

Write-PerfLog "========== CPU 自动触发监控 ==========" "OK"
Write-PerfLog "CPU 阈值: ${threshold}% | 检查间隔: ${checkInterval}s | 冷却: ${cooldown}s"

$lastTriggerTime = [DateTime]::MinValue
$captureCount = 0
$cpuHistory = [System.Collections.Generic.Queue[double]]::new()
$historySize = 5

while ($captureCount -lt $maxCaptures) {
    $proc = Get-TargetProcess
    if (-not $proc) {
        Start-Sleep -Seconds $checkInterval
        continue
    }

    $cpu = Get-CpuUsage
    if ($cpu -lt 0) {
        Start-Sleep -Seconds $checkInterval
        continue
    }

    # 滑动平均
    $cpuHistory.Enqueue($cpu)
    if ($cpuHistory.Count -gt $historySize) { $cpuHistory.Dequeue() | Out-Null }
    $avgCpu = [math]::Round(($cpuHistory | Measure-Object -Average).Average, 1)

    # 内存检查
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
    $memTrigger = $IncludeMemory -and ($mem -gt 2048)

    # 判断触发
    $shouldTrigger = ($avgCpu -gt $threshold) -or $memTrigger
    $timeSinceLastTrigger = ((Get-Date) - $lastTriggerTime).TotalSeconds
    $inCooldown = $timeSinceLastTrigger -lt $cooldown

    if ($shouldTrigger -and -not $inCooldown) {
        $reason = if ($memTrigger) { "HighMem_${mem}MB" } else { "HighCPU_${avgCpu}pct" }
        Write-PerfLog "触发! 原因: $reason" "WARN"

        $snapshot = Start-Snapshot -ProcessId $proc.Id `
            -Label "AutoTrigger_$reason" `
            -ProfilingType "Timeline" `
            -Duration $CaptureDuration

        if ($snapshot) {
            $captureCount++
            $lastTriggerTime = Get-Date

            # 保存上下文
            $detailPath = $snapshot -replace '\.dtp$', '_context.txt'
            @"
触发时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
触发原因: $reason
CPU (平均): ${avgCpu}%
CPU (瞬时): ${cpu}%
内存: ${mem}MB
线程数: $($proc.Threads.Count)
句柄数: $($proc.HandleCount)
运行时长: $([math]::Round(((Get-Date) - $proc.StartTime).TotalMinutes, 1)) 分钟
"@ | Out-File $detailPath -Encoding UTF8
        }

        Write-PerfLog "冷却 ${cooldown}s... (已采集 $captureCount/$maxCaptures)"
    }

    Start-Sleep -Seconds $checkInterval
}

Write-PerfLog "已达最大采集次数 ($maxCaptures)，监控停止" "WARN"
