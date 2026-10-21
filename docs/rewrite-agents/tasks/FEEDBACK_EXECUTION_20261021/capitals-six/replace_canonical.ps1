param(
    [string]$CanonicalDirectory = 'next/content/prep-capitals-1',
    [string]$CandidateDirectory = '.run/feedback_execute_20261021/capitals-six/candidate-v3',
    [string]$EvidenceDirectory = '.run/feedback_execute_20261021/capitals-six/original-canonical'
)

$ErrorActionPreference = 'Stop'
$expectedCandidateHashes = @{
    'draft.json' = '68f61b50d06f5ddeddc23f52c0386483c908fd7d9748a4a5c888884679832985'
    'bundle.json' = 'f6372d69a929dc8ddb8d623668a0cf0c6672a820179888e7bb3634b87e6af8ae'
    'manifest.json' = '755692aff8a11be862e53c8f074637124db6573675d6ccd7e6cfa67c4603ade1'
}
$files = @('draft.json', 'bundle.json', 'manifest.json')
$snapshot = Get-Content -LiteralPath (Join-Path $EvidenceDirectory 'snapshot.json') -Raw | ConvertFrom-Json

foreach ($file in $files) {
    $target = Join-Path $CanonicalDirectory $file
    $candidate = Join-Path $CandidateDirectory $file
    $expectedBefore = $snapshot.sha256.$file
    $actualBefore = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    $actualCandidate = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualBefore -ne $expectedBefore) { throw "Canonical changed after snapshot: $file" }
    if ($actualCandidate -ne $expectedCandidateHashes[$file]) { throw "Candidate hash changed: $file" }
}

foreach ($file in $files) {
    $target = Join-Path $CanonicalDirectory $file
    $candidate = Join-Path $CandidateDirectory $file
    $stage = "$target.capitals-six.tmp"
    $backup = Join-Path $EvidenceDirectory "replace-$file.bak"
    if (Test-Path -LiteralPath $stage) { throw "Staging path already exists: $stage" }
    if (Test-Path -LiteralPath $backup) { throw "Replacement backup already exists: $backup" }
    Copy-Item -LiteralPath $candidate -Destination $stage
    [System.IO.File]::Replace((Resolve-Path -LiteralPath $stage), (Resolve-Path -LiteralPath $target), $backup, $true)
}

foreach ($file in $files) {
    $target = Join-Path $CanonicalDirectory $file
    $actual = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expectedCandidateHashes[$file]) { throw "Post-replacement hash mismatch: $file" }
}

Write-Output 'canonical replacement: PASS (three preflighted file replacements)'
