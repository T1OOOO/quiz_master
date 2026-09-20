$ErrorActionPreference='Stop'
$container='qm-p09-20260920-1742'
$volume='qm-p09-20260920-1742-data'
$identity=(& docker inspect $container --format '{{json .}}'|ConvertFrom-Json)
if($LASTEXITCODE -ne 0 -or $identity.Config.Labels.'qm.task' -ne 'P09' -or $identity.Name -ne '/qm-p09-20260920-1742'){throw 'Unexpected container identity'}
if(-not ($identity.Mounts|Where-Object {$_.Name -eq $volume -and $_.Destination -eq '/var/lib/postgresql/data'})){throw 'Unexpected volume identity'}
$watch=[System.Diagnostics.Stopwatch]::StartNew()
$removedContainer=(& docker rm -f $container | Out-String).Trim();$containerExit=$LASTEXITCODE
if($containerExit -ne 0){throw 'Container cleanup failed'}
$removedVolume=(& docker volume rm $volume | Out-String).Trim();$volumeExit=$LASTEXITCODE
if($volumeExit -ne 0){throw 'Volume cleanup failed'}
$remainingContainer=(& docker ps -a --filter "name=^/$container$" --format '{{.Names}}' | Out-String).Trim();$listContainerExit=$LASTEXITCODE
$remainingVolume=(& docker volume ls --filter "name=^$volume$" --format '{{.Name}}' | Out-String).Trim();$listVolumeExit=$LASTEXITCODE
if($remainingContainer -or $remainingVolume -or $listContainerExit -ne 0 -or $listVolumeExit -ne 0){throw 'Resource remains after cleanup'}
$watch.Stop()
$record=[ordered]@{container=$container;volume=$volume;validated_container_id=$identity.Id;validated_label='qm.task=P09';commands=@("docker rm -f $container","docker volume rm $volume","docker ps -a --filter name=^/$container$ --format {{.Names}}","docker volume ls --filter name=^$volume$ --format {{.Name}}");cwd=(Get-Location).Path;duration_seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);exits=@($containerExit,$volumeExit,$listContainerExit,$listVolumeExit);removed_container=$removedContainer;removed_volume=$removedVolume;remaining_container=$remainingContainer;remaining_volume=$remainingVolume}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'cleanup.json'),($record|ConvertTo-Json -Depth 6))
Write-Output "Removed validated P09 container and volume; exact-name inventory confirms neither remains."
