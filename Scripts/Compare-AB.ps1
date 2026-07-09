# Compare-AB.ps1
# 用途：对比两个版本的性能差异，生成对比报告
# ============================================
param(
    [Parameter(Mandatory)][string]$VersionA,
    [Parameter(Mandatory)][string]$VersionB,
    [string]$AppPathA = "",
    [string]$AppPathB = "",
    [int]$WarmupSeconds = 10,
    [int]$CaptureDuration = 30,
    [int]$Iterations = 3,
    [string]$ProfilingType = "Sampling"
)

. "$PSScriptRoot\Core.ps1"

Write-PerfLog "========== A/B 版本性能对比 ==========" "OK"
Write-PerfLog "版本 A: $VersionA | 版本 B: $VersionB | 迭代: $Iterations"

function Test-SingleVersion {
    param([string]$Version, [string]$AppPath, [int]$Iteration)

    Write-PerfLog "--- [$Version] 第 $Iteration 次测试 ---"

    $appProcess = $null
    if ($AppPath -and (Test-Path $AppPath)) {
        $appProcess = Start-Process -FilePath $AppPath -PassThru
        Start-Sleep -Seconds 5
    }

    $proc = Get-TargetProcess
    if (-not $proc) {
        Write-PerfLog "目标进程未找到" "ERROR"
        return $null
    }

    Write-PerfLog "预热 ${WarmupSeconds}s..."
    Start-Sleep -Seconds $WarmupSeconds

    $label = "AB_${Version}_Iter${Iteration}"
    $snapshot = Start-Snapshot -ProcessId $proc.Id `
        -Label $label `
        -ProfilingType $ProfilingType `
        -Duration $CaptureDuration

    $cpu = Get-CpuUsage
    $metrics = @{
        Version   = $Version
        Iteration = $Iteration
        Snapshot  = $snapshot
        CPU       = $cpu
        MemoryMB  = [math]::Round($proc.WorkingSet64 / 1MB, 0)
        Threads   = $proc.Threads.Count
        Handles   = $proc.HandleCount
    }

    if ($appProcess) {
        Stop-Process -Id $appProcess.Id -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
    }

    return $metrics
}

$resultsA = @()
$resultsB = @()

for ($i = 1; $i -le $Iterations; $i++) {
    Write-PerfLog "====== 第 $i / $Iterations 轮 ======"

    Stop-Process -Name $Global:DotTraceConfig.AppName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $resultA = Test-SingleVersion -Version $VersionA -AppPath $AppPathA -Iteration $i
    if ($resultA) { $resultsA += $resultA }

    Start-Sleep -Seconds 5

    Stop-Process -Name $Global:DotTraceConfig.AppName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    $resultB = Test-SingleVersion -Version $VersionB -AppPath $AppPathB -Iteration $i
    if ($resultB) { $resultsB += $resultB }

    Start-Sleep -Seconds 5
}

# 生成对比
function Get-Avg { param($Results, $Field) [math]::Round(($Results.$Field | Measure-Object -Average).Average, 1) }

$report = @{
    TestTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    VersionA = @{
        Name    = $VersionA
        AvgCPU  = Get-Avg $resultsA "CPU"
        AvgMem  = Get-Avg $resultsA "MemoryMB"
        Results = $resultsA
    }
    VersionB = @{
        Name    = $VersionB
        AvgCPU  = Get-Avg $resultsB "CPU"
        AvgMem  = Get-Avg $resultsB "MemoryMB"
        Results = $resultsB
    }
}

$reportPath = Join-Path $Global:DotTraceConfig.ReportDir "AB_${VersionA}_vs_${VersionB}_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$report | ConvertTo-Json -Depth 5 | Out-File $reportPath -Encoding UTF8
Write-PerfLog "对比报告: $reportPath" "OK"
Write-PerfLog "========== A/B 对比完成 =========="
