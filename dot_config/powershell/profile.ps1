$IsVSCode = $ENV:TERM_PROGRAM -eq "vscode"

function Test-ModuleExists {
    param (
        [string]$ModuleName
    )
    return [bool](Get-Module -ListAvailable -Name $ModuleName)
}

function Test-PwshExists {
    return [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
}

if ($_ -like '-NonI*') {
    $Global:InteractiveMode=$false
} else {
    $Global:InteractiveMode=$true
}

if ($InteractiveMode)
{
    oh-my-posh init pwsh --config ~/.config/ohmyposh/zen.toml | Invoke-Expression
    Import-Module -Name Terminal-Icons

    Invoke-Expression (& { (zoxide init powershell | Out-String) })

    if (-not (Test-ModuleExists -ModuleName "PSReadLine")) {
        Import-Module PSReadLine
    }

    Set-PSReadLineOption -PredictionSource History

    Set-Alias Open Start
    Set-Alias ll dir

    $Env:EDITOR = "code"
    if (Test-PwshExists) {
        $Env:SHELL = "pwsh -NoLogo"
    } else {
        $Env:SHELL = "powershell -NoLogo"
    }
}
