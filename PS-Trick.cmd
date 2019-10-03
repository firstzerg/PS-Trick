<# :
    @echo off 
    set args=%*
if not defined args goto noargs
    set args=%args:"=`"""%
:noargs
    powershell /nologo /noprofile /command ^
    "&{[ScriptBlock]::Create( '$thisfilename="""%~f0"""' + [Char]10 + ((cat """%~f0""") -join [Char]10) ).Invoke("""%args%""")}"
  exit /b
#>

$arch = @{$true="x86";$false="x64"}[$env:Processor_Architecture -eq "x86"]
$thisfile=$thisfilename
$thisdir=split-path $thisfile
$datetime = Get-Date -format yyyy-MM-dd_HH-mm-ss
$caption = split-path $thisfile -leaf

function Elevate(){
	$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
	$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
	$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
	if ($myWindowsPrincipal.IsInRole($adminRole)){
		$Host.UI.RawUI.WindowTitle = $thisfile + " (Elevated)"
		clear-host
	}else{
		$newProcess = new-object System.Diagnostics.ProcessStartInfo "cmd.exe";
		$newProcess.Arguments = "/C `"$thisfilename`"";
		$newProcess.Verb = "runas";
		[System.Diagnostics.Process]::Start($newProcess);
		exit
	}
}
Elevate
