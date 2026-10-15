param([ValidateSet('capture','audit')][string]$Action)
$ErrorActionPreference='Stop'
$private='C:/ap/quiz_master/.run/reader303_release_20261015/published-browser/identities-private.json'
$public='C:/ap/quiz_master/docs/rewrite-agents/tasks/READER303_RELEASE_20261015/published-browser'
if($PSVersionTable.PSVersion.Major -lt 7){throw 'PowerShell7 required'}
if($Action -eq 'capture'){
 if(Test-Path -LiteralPath $private){throw 'Preserve prior identity capture'}
 $all=@(Get-CimInstance Win32_Process)
 $ownedPid=[int](Get-Content -LiteralPath 'C:/Users/Alexey_Matvienko/.agent-browser/namespaces/quiz-master/run/reader303-published.pid' -Raw).Trim()
 $roots=@($all|Where-Object{$_.ProcessId -eq $ownedPid -and $_.Name -eq 'agent-browser-win32-x64.exe'})
 if($roots.Count -ne 1){throw 'Expected exactly one named owned daemon'}
 $chrome=@($all|Where-Object{$_.ParentProcessId -eq $ownedPid -and $_.Name -eq 'chrome.exe'})
 if($chrome.Count -ne 1 -or $chrome[0].CommandLine -notlike '*agent-browser-chrome-*'){throw 'Expected one private owned Chrome root'}
 $ids=[Collections.Generic.HashSet[int]]::new();[void]$ids.Add([int]$roots[0].ProcessId)
 do{$changed=$false;foreach($p in $all){if($ids.Contains([int]$p.ParentProcessId) -and $ids.Add([int]$p.ProcessId)){$changed=$true}}}while($changed)
 $rows=@(foreach($p in $all|Where-Object{$ids.Contains([int]$_.ProcessId)}){
  $n=[Diagnostics.Process]::GetProcessById([int]$p.ProcessId);if($n.HasExited){throw 'Process exited during identity capture'}
  @{pid=[int]$p.ProcessId;name=$p.Name;command=[string]$p.CommandLine;cim_ticks=[string]$p.CreationDate.ToUniversalTime().Ticks;native_ticks=[string]$n.StartTime.ToUniversalTime().Ticks}
 })
 @{rows=$rows;session='reader303-published';namespace='quiz-master';native_and_cim_recorded_separately=$true}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $private -Encoding utf8
 @{captured=$rows.Count;actual_exit=0;native_and_cim_recorded_separately=$true}|ConvertTo-Json|Set-Content -LiteralPath "$public/identity-capture.json" -Encoding utf8
 Write-Output "Captured $($rows.Count) owned identities"
}else{
 $saved=Get-Content -LiteralPath $private -Raw|ConvertFrom-Json
 $rows=@(foreach($row in $saved.rows){
  $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($row.pid)"
  if(-not $p){@{pid=$row.pid;outcome='absent'};continue}
  try{$n=[Diagnostics.Process]::GetProcessById([int]$row.pid)}catch{if($_.Exception.InnerException -is [ArgumentException]){@{pid=$row.pid;outcome='native_absent_after_cim_read'};continue};throw}
  if($n.HasExited){@{pid=$row.pid;outcome='exited'};continue}
  if([string]$n.StartTime.ToUniversalTime().Ticks -ne $row.native_ticks -or [string]$p.CreationDate.ToUniversalTime().Ticks -ne $row.cim_ticks -or [string]$p.CommandLine -ne $row.command){throw 'Identity differs: do not kill or claim inactive'}
  throw "Captured owned process still alive: $($row.pid); diagnose exact identity before action"
 })
 @{actual_exit=0;session='reader303-published';namespace='quiz-master';inactive=$true;rows=$rows}|ConvertTo-Json -Depth 5|Set-Content -LiteralPath "$public/native-cleanup.json" -Encoding utf8
 Write-Output 'All captured native identities inactive'
}
