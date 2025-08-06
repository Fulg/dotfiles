oh-my-posh init pwsh --config ~/.config/ohmyposh/zen.toml | Invoke-Expression
Import-Module -Name Terminal-Icons

Invoke-Expression (& { (zoxide init powershell | Out-String) })

function Test-ModuleExists {
    param (
        [string]$ModuleName
    )
    return [bool](Get-Module -ListAvailable -Name $ModuleName)
}

if (Test-ModuleExists -ModuleName "PSReadLine")
    Import-Module PSReadLine

Set-PSReadLineOption -PredictionSource History

Set-Alias Open Start
Set-Alias ll dir

function Test-PwshExists {
    return [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
}

$Env:EDITOR = "code"
if (Test-PwshExists)
    $Env:SHELL = "pwsh -NoLogo"
else
    $Env:SHELL = "powershell -NoLogo"
