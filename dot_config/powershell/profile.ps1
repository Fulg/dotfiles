oh-my-posh init pwsh --config ~/.config/ohmyposh/zen.toml | Invoke-Expression
Import-Module -Name Terminal-Icons

Invoke-Expression (& { (zoxide init powershell | Out-String) })

Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History

Set-Alias Open Start
Set-Alias ll dir

$Env:EDITOR = "code"
$Env:SHELL = "pwsh -NoLogo"