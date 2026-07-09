$ErrorActionPreference = 'Stop'
try {
    $baseDir = "C:\Users\jiajun.wu\Desktop\dottrace"
    $scriptRoot = Join-Path $baseDir "Scripts"
    Write-Host "scriptRoot: $scriptRoot"
    Write-Host "Core exists: $(Test-Path (Join-Path $scriptRoot 'Core.ps1'))"
    
    . (Join-Path $scriptRoot "Config.ps1")
    Write-Host "Config loaded OK"
    Write-Host "ToolPath: $($Global:DotTraceConfig.ToolPath)"
    Write-Host "ToolExists: $(Test-Path $Global:DotTraceConfig.ToolPath)"
    
    . (Join-Path $scriptRoot "Core.ps1")
    Write-Host "Core loaded OK"
    
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms
    Write-Host "WPF assemblies loaded OK"
    
    Write-Host "ALL CHECKS PASSED"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
    Write-Host "At: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)"
    Write-Host "Stack: $($_.ScriptStackTrace)"
}
