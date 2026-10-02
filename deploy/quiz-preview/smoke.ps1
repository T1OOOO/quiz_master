param([string]$BaseUrl = 'https://quiz.kotopedia.org')
$ErrorActionPreference = 'Stop'
# Creates disposable guests and a completed attempt; never prints bearer tokens.
$version = Invoke-RestMethod "$BaseUrl/version.json"
if ($version.build_id -ne 'quiz-2026.10.02-1759-585c4e2') { throw 'Unexpected build' }
$ready = Invoke-WebRequest "$BaseUrl/health/ready"
if ($ready.StatusCode -ne 200) { throw 'Not ready' }
$catalog = Invoke-RestMethod "$BaseUrl/v1/catalog"
if ($catalog.quiz.questions.Count -ne 25) { throw 'Unexpected preview catalog' }
$guest = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Deployment smoke"}'
$headers = @{Authorization = "Bearer $($guest.token)"}
$attempt = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{}'
$path = "$BaseUrl/v1/attempts/$($attempt.attempt_id)"
$early = Invoke-WebRequest "$path/reveals" -Headers $headers -SkipHttpErrorCheck
if ($early.StatusCode -ne 404) { throw 'SQLite early reveal not blocked' }
$count = 0
foreach ($snapshot in $attempt.question_snapshots) {
    $answer = [ordered]@{option_id = $snapshot.option_order[0]}
    $revision = [ordered]@{number = $snapshot.question_revision.number; sha256 = $snapshot.question_revision.sha256}
    # Canonical keys sorted independently of the server's digest helper.
    $payload = [ordered]@{answer = $answer; attempt_id = $attempt.attempt_id; participant_id = $attempt.participant_id; question_id = $snapshot.question_id; question_revision = $revision} | ConvertTo-Json -Depth 5 -Compress
    $digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($payload))).ToLowerInvariant()
    $body = [ordered]@{question_id = $snapshot.question_id; question_revision = $revision; answer = $answer; idempotency_key = [guid]::NewGuid().ToString(); payload_digest = $digest} | ConvertTo-Json -Depth 5 -Compress
    $receipt = Invoke-RestMethod "$path/answers" -Method Post -ContentType application/json -Headers $headers -Body $body
    if ($count -eq 0) {
        $replay = Invoke-RestMethod "$path/answers" -Method Post -ContentType application/json -Headers $headers -Body $body
        if ($replay.receipt_id -ne $receipt.receipt_id) { throw 'Replay receipt changed' }
    }
    $count++
}
$finished = Invoke-RestMethod "$path/finish" -Method Post -ContentType application/json -Headers $headers -Body '{}'
$history = Invoke-RestMethod "$BaseUrl/v1/history/$($attempt.attempt_id)" -Headers $headers
$reveals = Invoke-RestMethod "$path/reveals" -Headers $headers
if ($count -ne 25 -or $finished.status -ne 'finished' -or $history.history.Count -ne 25 -or $reveals.Count -ne 25) { throw 'Attempt/history/reveals mismatch' }
$other = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Deployment ownership smoke"}'
$denied = Invoke-WebRequest "$BaseUrl/v1/history/$($attempt.attempt_id)" -Headers @{Authorization = "Bearer $($other.token)"} -SkipHttpErrorCheck
if ($denied.StatusCode -ne 404) { throw 'Cross-owner history exposed' }
[pscustomobject]@{Build = $version.build_id; Answers = $count; Status = $finished.status; History = $history.history.Count; Reveals = $reveals.Count; Replay = 'PASS'; CrossOwner = $denied.StatusCode}
