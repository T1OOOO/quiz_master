$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskReviewed = Get-Content "$taskRoot/docs/rewrite-agents/content20/paintings20.legacy.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$taskSourcePath = "$taskRoot/quizzes/Preparation/prep_wave20_paintings.json"
$taskSourceText = Get-Content $taskSourcePath -Raw -Encoding UTF8
$taskSource = $taskSourceText | ConvertFrom-Json
$taskCanonical = Get-Content "$taskRoot/next/content/prep-wave20-paintings/bundle.json" -Raw -Encoding UTF8 | ConvertFrom-Json
$taskManifest = Get-Content "$taskRoot/next/content/prep-wave20-paintings/manifest.json" -Raw -Encoding UTF8 | ConvertFrom-Json
if ($taskSource.questions.Count -ne 20 -or $taskCanonical.quiz.questions.Count -ne 20) { throw 'Question count differs' }
$taskNormalized = $taskSourceText.Replace("`r`n", "`n").Replace("`r", "`n")
$taskHash = [System.Security.Cryptography.SHA256]::Create()
try { $taskDigest = [BitConverter]::ToString($taskHash.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($taskNormalized))).Replace('-', '').ToLowerInvariant() }
finally { $taskHash.Dispose() }
if ($taskDigest -ne $taskManifest.source_sha256) { throw 'Normalized source hash differs' }
for ($taskIndex = 0; $taskIndex -lt 20; $taskIndex++) {
    $taskExpected = $taskReviewed.questions[$taskIndex]
    $taskActual = $taskSource.questions[$taskIndex]
    $taskPublic = $taskCanonical.quiz.questions[$taskIndex]
    if (($taskExpected | ConvertTo-Json -Depth 8 -Compress) -cne ($taskActual | ConvertTo-Json -Depth 8 -Compress)) { throw 'Reviewed source differs' }
    if ($taskPublic.question_id -cne $taskActual.id -or $taskPublic.stem -cne $taskActual.text) { throw 'Canonical stem or ID differs' }
    if ($taskPublic.PSObject.Properties.Name -contains 'grading' -or $taskPublic.PSObject.Properties.Name -contains 'explanation') { throw 'Private data in public question' }
    for ($taskOption = 0; $taskOption -lt 4; $taskOption++) {
        if ($taskPublic.options[$taskOption].text -cne $taskActual.options[$taskOption]) { throw 'Canonical option differs' }
    }
    $taskAnswerId = $taskPublic.options[$taskActual.correct_answer].option_id
    if ($taskCanonical.private_grading.($taskActual.id).correct_option_id -cne $taskAnswerId) { throw 'Canonical answer differs' }
    if ($taskManifest.questions[$taskIndex].source_explanation -cne $taskActual.explanation) { throw 'Explanation differs' }
}
$taskCatalog = Get-Content "$taskRoot/next/apps/quiz_app/assets/catalog.json" -Raw -Encoding UTF8 | ConvertFrom-Json
if ($taskCatalog.Count -ne 118 -or ($taskCatalog | Measure-Object questions_count -Sum).Sum -ne 3878) { throw 'Catalog inventory differs' }
foreach ($taskEntry in $taskCatalog) {
    if (($taskEntry.PSObject.Properties.Name | Where-Object { $_ -notin @('quiz_id','title','description','category','questions_count') }).Count) { throw 'Private or unexpected catalog field' }
}
'PASS: reviewed source, normalized hash, all 20 canonical answers/options/stems/explanations, public boundary, catalog 118/3878'
