using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace System.Diagnostics.CodeAnalysis

$IsVSCode = $ENV:TERM_PROGRAM -eq "vscode"

if ($_ -like '-NonI*') {
    $Global:InteractiveMode=$false
} else {
    $Global:InteractiveMode=$true
}

if (-not $InteractiveMode)
{
    # Non-interactive mode, do not load any interactive settings
    return
}

# ---------------------------------------------------------------------------
#region: Helper functions

function Test-ModuleExists {
    param (
        [string]$ModuleName
    )
    return [bool](Get-Module -ListAvailable -Name $ModuleName)
}

function Test-PwshExists {
    return [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
}

#endregion


oh-my-posh init pwsh --config ~/.config/ohmyposh/zen.toml | Invoke-Expression
Import-Module -Name Terminal-Icons

Invoke-Expression (& { (zoxide init powershell | Out-String) })

if (-not (Test-ModuleExists -ModuleName "PSReadLine")) {
    Import-Module PSReadLine
}

$PSReadlineVersion = (Get-Module PSReadLine).version

# Predictive Intellisense was introduced but not enabled by default for these versions
if ($PSReadlineVersion -ge '2.1.0' -and $PSReadlineVersion -lt '2.2.6') {
    Set-PSReadLineOption -PredictionSource History
}

# Stolen and modified from https://github.com/PowerShell/PSReadLine/blob/master/PSReadLine/SamplePSReadLineProfile.ps1
# F1 for help on the command line - naturally
Set-PSReadLineKeyHandler -Key F1 `
  -BriefDescription CommandHelp `
  -LongDescription 'Open the help window for the current command' `
  -ScriptBlock {
  param($key, $arg)

  $ast = $null
  $tokens = $null
  $errors = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

  $commandAst = $ast.FindAll( {
      $node = $args[0]
      $node -is [CommandAst] -and
      $node.Extent.StartOffset -le $cursor -and
      $node.Extent.EndOffset -ge $cursor
    }, $true) | Select-Object -Last 1

  if ($commandAst -ne $null) {
    $commandName = $commandAst.GetCommandName()
    if ($commandName -ne $null) {
      $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
      if ($command -is [Management.Automation.AliasInfo]) {
        $commandName = $command.ResolvedCommandName
      }

      if ($commandName -ne $null) {
        #First try online
        try {
          Get-Help $commandName -Online -ErrorAction Stop
        } catch [InvalidOperationException] {
          if ($PSItem -notmatch 'The online version of this Help topic cannot be displayed') { throw }
          Get-Help $CommandName -ShowWindow
        }
      }
    }
  }
}

# Insert text from the clipboard as a here string
Set-PSReadLineKeyHandler -Key Ctrl+Alt+V `
  -BriefDescription PasteAsHereString `
  -LongDescription 'Paste the clipboard text as a here string' `
  -ScriptBlock {
  param($key, $arg)

  Add-Type -Assembly PresentationCore
  if ([System.Windows.Clipboard]::ContainsText()) {
    # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
    $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
  } else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
  }
}

# Sometimes you want to get a property of invoke a member on what you've entered so far
# but you need parens to do that.  This binding will help by putting parens around the current selection,
# or if nothing is selected, the whole line.
Set-PSReadLineKeyHandler -Key 'Alt+(' `
  -BriefDescription ParenthesizeSelection `
  -LongDescription 'Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis' `
  -ScriptBlock {
  param($key, $arg)

  $selectionStart = $null
  $selectionLength = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

  $line = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
  if ($selectionStart -ne -1) {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.SubString($selectionStart, $selectionLength) + ')')
    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
  } else {
    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
    [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
  }
}

# Each time you press Alt+', this key handler will change the token
# under or before the cursor.  It will cycle through single quotes, double quotes, or
# no quotes each time it is invoked.
Set-PSReadLineKeyHandler -Key "Alt+'" `
  -BriefDescription ToggleQuoteArgument `
  -LongDescription 'Toggle quotes on the argument under the cursor' `
  -ScriptBlock {
  param($key, $arg)

  $ast = $null
  $tokens = $null
  $errors = $null
  $cursor = $null
  [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

  $tokenToChange = $null
  foreach ($token in $tokens) {
    $extent = $token.Extent
    if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
      $tokenToChange = $token

      # If the cursor is at the end (it's really 1 past the end) of the previous token,
      # we only want to change the previous token if there is no token under the cursor
      if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
        $nextToken = $foreach.Current
        if ($nextToken.Extent.StartOffset -eq $cursor) {
          $tokenToChange = $nextToken
        }
      }
      break
    }
  }

  if ($tokenToChange -ne $null) {
    $extent = $tokenToChange.Extent
    $tokenText = $extent.Text
    if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
      # Switch to no quotes
      $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
    } elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
      # Switch to double quotes
      $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
    } else {
      # Add single quotes
      $replacement = "'" + $tokenText + "'"
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
      $extent.StartOffset,
      $tokenText.Length,
      $replacement)
  }
}



Set-Alias Open Start
Set-Alias ll dir

# Set editor to VSCode or nano if present
if (Get-Command code -Type Application -ErrorAction SilentlyContinue) {
    $Env:EDITOR = 'code'
} elseif (Get-Command nano -Type Application -ErrorAction SilentlyContinue) {
    $Env:EDITOR = 'nano'
}

if (Test-PwshExists) {
    $Env:SHELL = "pwsh -NoLogo"
} else {
    $Env:SHELL = "powershell -NoLogo"
}
