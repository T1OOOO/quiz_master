param([string]$BaseUrl = 'https://quiz.kotopedia.org')
$ErrorActionPreference = 'Stop'
# Creates disposable guests and a completed attempt; never prints bearer tokens.
$version = Invoke-RestMethod "$BaseUrl/version.json"
if ($version.build_id -ne 'quiz-2026.10.03-0245-6b5e2e6') { throw 'Unexpected build' }
$ready = Invoke-WebRequest "$BaseUrl/health/ready"
if ($ready.StatusCode -ne 200) { throw 'Not ready' }
$collection = Invoke-RestMethod "$BaseUrl/assets/assets/catalog.json"
if ($collection.Count -ne 101) { throw 'Unexpected collection' }
$guest = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Deployment smoke"}'
$headers = @{Authorization = "Bearer $($guest.token)"}
$total = 0
foreach ($pack in $collection) {
    $selected = Invoke-RestMethod "$BaseUrl/v1/catalog?quiz_id=$($pack.quiz_id)"
    $request = @{quiz_id = $pack.quiz_id; round = 0} | ConvertTo-Json -Compress
    $started = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body $request
    if ($selected.quiz.quiz_id -ne $pack.quiz_id -or $selected.quiz.questions.Count -ne $pack.questions_count -or $started.bundle_sha256 -ne $selected.bundle_sha256 -or $started.question_snapshots.Count -ne [Math]::Min(20,$pack.questions_count)) { throw "Wrong selected round: $($pack.quiz_id)" }
    $total += $pack.questions_count
    Start-Sleep -Milliseconds 150
}
if ($total -ne 3128) { throw 'Collection question count mismatch' }
$catalog = Invoke-RestMethod "$BaseUrl/v1/catalog?quiz_id=gastronomy-cheeses-and-dairy"
$expected = $catalog.quiz.questions.Count
$attempt = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"gastronomy-cheeses-and-dairy","round":0}'
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
if ($count -ne $expected -or $finished.status -ne 'finished' -or $history.history.Count -ne $expected -or $reveals.Count -ne $expected) { throw 'Attempt/history/reveals mismatch' }
$list = @(Invoke-RestMethod "$BaseUrl/v1/history" -Headers $headers)
if ($list.Count -ne 1 -or $list[0].attempt_id -ne $attempt.attempt_id) { throw 'History list mismatch' }
$other = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Deployment ownership smoke"}'
$denied = Invoke-WebRequest "$BaseUrl/v1/history/$($attempt.attempt_id)" -Headers @{Authorization = "Bearer $($other.token)"} -SkipHttpErrorCheck
if ($denied.StatusCode -ne 404) { throw 'Cross-owner history exposed' }
$first = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"home-alone-1-part-1","round":0}'
$last = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"home-alone-1-part-1","round":1}'
$ids = @($first.question_snapshots.question_id) + @($last.question_snapshots.question_id)
if ($first.question_snapshots.Count -ne 20 -or $last.question_snapshots.Count -ne 5 -or @($ids | Select-Object -Unique).Count -ne 25) { throw 'Round partition mismatch' }
$invalid = Invoke-WebRequest "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"home-alone-1-part-1","round":-1}' -SkipHttpErrorCheck
if ($invalid.StatusCode -ne 400) {throw 'Invalid round accepted'}
[pscustomobject]@{Build = $version.build_id; Packs = $collection.Count; Questions = $total; RoundLimit = 20; Partition = '20+5, unique'; Answers = $count; Status = $finished.status; History = $history.history.Count; Reveals = $reveals.Count; Replay = 'PASS'; CrossOwner = $denied.StatusCode}
