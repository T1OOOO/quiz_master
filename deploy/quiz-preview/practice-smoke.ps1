param([string]$BaseUrl = 'https://quiz.kotopedia.org')
$ErrorActionPreference = 'Stop'
# Disposable practice records. Never prints credentials or edits existing attempts.
$guest = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Practice release smoke"}'
$headers = @{Authorization = "Bearer $($guest.token)"}
$attempt = Invoke-RestMethod "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"gastronomy-traditions-and-etiquette","round":0,"mode":"practice"}'
$path = "$BaseUrl/v1/attempts/$($attempt.attempt_id)"
$q = $attempt.question_snapshots[0]
$feedbackPath = "$path/feedback/$($q.question_id)"
$early = Invoke-WebRequest $feedbackPath -Headers $headers -SkipHttpErrorCheck
if ($early.StatusCode -ne 404 -or $early.Headers['Cache-Control'] -notmatch 'no-store') { throw 'Unanswered feedback exposed or cached' }
$answer = [ordered]@{option_id = $q.option_order[0]}
$revision = [ordered]@{number = $q.question_revision.number; sha256 = $q.question_revision.sha256}
$payload = [ordered]@{answer = $answer; attempt_id = $attempt.attempt_id; participant_id = $attempt.participant_id; question_id = $q.question_id; question_revision = $revision} | ConvertTo-Json -Depth 5 -Compress
$digest = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($payload))).ToLowerInvariant()
$body = [ordered]@{question_id = $q.question_id; question_revision = $revision; answer = $answer; idempotency_key = [guid]::NewGuid().ToString(); payload_digest = $digest} | ConvertTo-Json -Depth 5 -Compress
$receipt = Invoke-RestMethod "$path/answers" -Method Post -ContentType application/json -Headers $headers -Body $body
$response = Invoke-WebRequest $feedbackPath -Headers $headers
$feedback = $response.Content | ConvertFrom-Json
if ($response.Headers['Cache-Control'] -notmatch 'no-store' -or $feedback.reveal.question_id -ne $q.question_id -or $feedback.reveal.question_revision.sha256 -ne $q.question_revision.sha256 -or [string]::IsNullOrWhiteSpace($feedback.reveal.explanation) -or $feedback.correct -ne ($answer.option_id -eq $feedback.reveal.correct_answer.option_id)) { throw 'Practice feedback mismatch' }
$future = Invoke-WebRequest "$path/feedback/$($attempt.question_snapshots[1].question_id)" -Headers $headers -SkipHttpErrorCheck
$other = Invoke-RestMethod "$BaseUrl/v1/guests" -Method Post -ContentType application/json -Body '{"display_name":"Practice foreign smoke"}'
$foreign = Invoke-WebRequest $feedbackPath -Headers @{Authorization = "Bearer $($other.token)"} -SkipHttpErrorCheck
if ($future.StatusCode -ne 404 -or $foreign.StatusCode -ne 404) { throw 'Practice answer boundary failed' }
$invalid = Invoke-WebRequest "$BaseUrl/v1/attempts" -Method Post -ContentType application/json -Headers $headers -Body '{"quiz_id":"home-alone-1-part-1","round":0,"mode":"unknown"}' -SkipHttpErrorCheck
if ($invalid.StatusCode -ne 400) { throw 'Unknown mode accepted' }
[pscustomobject]@{Practice='PASS'; AcceptedReceipt=[bool]$receipt.receipt_id; Explanation='present'; Correctness='server reveal matches selection'; Unanswered=$early.StatusCode; Future=$future.StatusCode; Foreign=$foreign.StatusCode; Cache='no-store'; InvalidMode=$invalid.StatusCode}
