param(
    [string]$SourceDirectory = 'next/content/prep-capitals-1',
    [string]$EvidenceDirectory = '.run/feedback_execute_20261021/capitals-six/original-canonical'
)

$ErrorActionPreference = 'Stop'
$files = @('draft.json', 'bundle.json', 'manifest.json')

if (Test-Path -LiteralPath $EvidenceDirectory) {
    if ((Get-ChildItem -LiteralPath $EvidenceDirectory -Force | Measure-Object).Count -ne 0) {
        throw "Evidence directory already contains data: $EvidenceDirectory"
    }
} else {
    New-Item -ItemType Directory -Path $EvidenceDirectory | Out-Null
}

foreach ($file in $files) {
    $source = Join-Path $SourceDirectory $file
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Canonical input missing: $source"
    }
    $destination = Join-Path $EvidenceDirectory $file
    if (Test-Path -LiteralPath $destination) {
        throw "Evidence destination already exists: $destination"
    }
    Copy-Item -LiteralPath $source -Destination $destination
}

$hashes = @{}
foreach ($file in $files) {
    $sourceHash = (Get-FileHash (Join-Path $SourceDirectory $file) -Algorithm SHA256).Hash.ToLowerInvariant()
    $evidenceHash = (Get-FileHash (Join-Path $EvidenceDirectory $file) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHash -ne $evidenceHash) {
        throw "Snapshot hash mismatch: $file"
    }
    $hashes[$file] = $sourceHash
}

[ordered]@{
    captured_from = $SourceDirectory
    sha256 = $hashes
    purpose = 'Exact pre-replacement bytes for reviewed capitals-six canonical replacement.'
} | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $EvidenceDirectory 'snapshot.json') -Encoding utf8NoBOM

Write-Output 'original canonical snapshot: PASS'
