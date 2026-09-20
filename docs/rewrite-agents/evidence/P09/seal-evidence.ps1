$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path
$files=@(Get-Item (Join-Path $root 'docs/rewrite-agents/reports/P09.md'))
$files+=@(Get-ChildItem -LiteralPath $PSScriptRoot -File|Where-Object {$_.Name -ne 'artifact-hashes.json'})
$hashes=[ordered]@{}
foreach($file in ($files|Sort-Object FullName)){$relative=$file.FullName.Substring($root.Length+1).Replace('\','/');$hashes[$relative]=(Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToLowerInvariant()}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'artifact-hashes.json'),($hashes|ConvertTo-Json -Depth 4))
Write-Output "Sealed $($files.Count) report/evidence files; artifact-hashes.json excludes itself."
