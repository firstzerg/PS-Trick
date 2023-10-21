<# :
  @echo off
  setlocal
  set "fn=%~f0"
  set "fn=%fn:'=''%"
  echo %* | powershell /nologo /noprofile /command "$arguments=$($input | out-string).trim(); &{[ScriptBlock]::Create( (get-content -literalpath '%fn%') -join [Char]10).Invoke('%fn%',$arguments)}"
  endlocal
  exit /b
#>
param($thisfilename,$arguments="")

$arch = @{$true="x86";$false="x64"}[$env:Processor_Architecture -eq "x86"]
$thisfile = if ($thisfilename) { $thisfilename } else { $MyInvocation.MyCommand.Definition }
$thisbase = (Get-Item $thisfile).BaseName
$thisdir = Split-Path $thisfile
$datetime = Get-Date -format yyyy-MM-dd_HH-mm-ss
$caption = split-path $thisfile -leaf

$params = @{}
if ($arguments) {
  $arguments | Select-String -Pattern '\s*(?<main>.*?)[\s]*(?<=\s|^)\/(?<key>\w+)(?:\s+|$)(?<value>.*?)?(?:\s+|$)?(?=\s*$|(?<=\s|^)\/\w)' -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object {
    if ($_.Groups["main"].Value) { $params.main = $params.main + ($_.Groups["main"].Value -replace '^(["]?)(.*?)\1*$','$2') }
    $params.($_.Groups["key"].Value) = if ($_.Groups["value"].Value) { ($_.Groups["value"].Value -replace '\\/','/') -replace '^(["]?)(.*?)\1*$','$2' } else { $true }
  }
}
if ($params.Count -eq 0) {
  $params.main = ($arguments -replace '^(["]?)(.*?)\1*$','$2')
}

function Elevate{
	$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	if ($myWindowsPrincipal.IsInRole($adminRole)){
		$Host.UI.RawUI.WindowTitle = $thisfile + " (Elevated)"
	}else{
		$cdir=(Get-Location).Path
		$newProcess = new-object System.Diagnostics.ProcessStartInfo "cmd.exe";
		$newProcess.Arguments = "/C `"cd /D `"$cdir`" && `"$thisfilename`" $arguments`"";
		$newProcess.Verb = "runas";
		[System.Diagnostics.Process]::Start($newProcess);
		exit
	}
}
Elevate
