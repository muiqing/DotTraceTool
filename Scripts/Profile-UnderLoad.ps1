# Profile-UnderLoad.ps1
# 用途：在负载测试期间多次采集快照，形成完整性能画像
# ============================================
param(
    [int]$TestDuration = 300,
    [int]$SampleCount = 5,
    [string]$ProfilingType = "Timeline",
    [int]$SampleDuration = 20,
    [string]$TestName = "LoadTest"
)

. "$PSScriptRoot\Core.ps1"

Write-PerfLog "========== 负载测试性能画像 ==========" "OK"
Write-PerfLog "测试名称: $TestName | 总时长: ${TestDuration}s | 采样次数: $SampleCount"

$proc = Get-TargetProcess
if (-not $proc) {
    Write-PerfLog "目标进程未运行，请先启动应用" "ERROR"
    exit 1
}

$interval = [math]::Floor($TestDuration / $SampleCount)
$snapshots = @()
$testStart = Get-Date

for ($i = 1; $i -le $SampleCount; $i++) {
    $elapsed = ((Get-Date) - $testStart).TotalSeconds
    $targetTime = ($i - 1) * $interval
    $waitTime = [math]::Max(0, $targetTime - $elapsed)

    if ($waitTime -gt 0) {
        Write-PerfLog "等待 ${waitTime}s 到达第 $i 个采集点..."
        Start-Sleep -Seconds $waitTime
    }

    $proc = Get-TargetProcess
    if (-not $proc) {
        Write-PerfLog "目标进程已退出，提前结束" "ERROR"
        break
    }

    $cpu = Get-CpuUsage
    $mem = [math]::Round($proc.WorkingSet64 / 1MB, 0)
    $threads = $proc.Threads.Count

    Write-PerfLog "第 $i/$SampleCount 次采集 | CPU: ${cpu}% | 内存: ${mem}MB | 线程: $threads"

    $label = "${TestName}_Phase${i}of${SampleCount}_CPU${cpu}"
    $snapshot = Start-Snapshot -ProcessId $proc.Id `
        -Label $label `
        -ProfilingType $ProfilingType `
        -Duration $SampleDuration

    if ($snapshot) {
        $snapshots += @{
            Path    = $snapshot
            Phase   = $i
            CPU     = $cpu
            Memory  = $mem
            Threads = $threads
            Time    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

# 保存元数据
$metaPath = Join-Path $Global:DotTraceConfig.SnapshotDir "${TestName}_$(Get-Date -Format 'yyyyMMdd_HHmmss')_meta.json"
$snapshots | ConvertTo-Json -Depth 3 | Out-File $metaPath -Encoding UTF8
Write-PerfLog "元数据已保存: $metaPath"
Write-PerfLog "========== 负载测试完成，共 $($snapshots.Count) 个快照 =========="
