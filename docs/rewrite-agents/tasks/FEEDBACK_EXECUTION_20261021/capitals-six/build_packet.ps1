$ErrorActionPreference = 'Stop'

# Creates the controlled legacy input that quizctl imports for the accepted
# six-choice expansion.  The original four choices and answers come from the
# source quiz; the three accepted wording clarifications also replace their
# explanations with the reviewed private-draft text below.
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..\..\..')).Path
$input = Join-Path $root 'quizzes\Preparation\prep_capitals_1.json'
$output = Join-Path $PSScriptRoot 'source.legacy.json'
$provenanceOutput = Join-Path $PSScriptRoot 'provenance.json'
$acceptedDraftPath = Join-Path $PSScriptRoot 'accepted-draft-v3.json'
$finalReviewPath = Join-Path $PSScriptRoot 'final-review-v3.json'
$sourceEvidencePath = Join-Path $PSScriptRoot 'source-evidence.md'
$acceptedDraftSHA256 = 'ec6aa50dbb8bbddce2642e871bdc89046a26a747f608c5c9430ede89c443e58f'
$finalReviewSHA256 = 'aa094cbada1938ea5e184005ab2e4735bd27baa4909e388f7b68a3a53e9ad619'
$sourceEvidenceSHA256 = '57def723fbc1f67c9eb2b4a13b91fbe2e73046799413e823df846ab6dbbf5fb7'

foreach ($path in @($acceptedDraftPath, $finalReviewPath, $sourceEvidencePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required accepted packet evidence is missing: $path" }
}
$acceptedDraftHash = (Get-FileHash -Algorithm SHA256 $acceptedDraftPath).Hash.ToLowerInvariant()
$finalReviewHash = (Get-FileHash -Algorithm SHA256 $finalReviewPath).Hash.ToLowerInvariant()
$sourceEvidenceHash = (Get-FileHash -Algorithm SHA256 $sourceEvidencePath).Hash.ToLowerInvariant()
if ($acceptedDraftHash -ne $acceptedDraftSHA256) { throw 'Accepted draft hash does not match the v3 review binding.' }
if ($finalReviewHash -ne $finalReviewSHA256) { throw 'Final review hash does not match the accepted v3 evidence.' }
if ($sourceEvidenceHash -ne $sourceEvidenceSHA256) { throw 'Source-evidence hash does not match the prior full review binding.' }
$acceptedDraft = Get-Content -Raw $acceptedDraftPath | ConvertFrom-Json
$finalReview = Get-Content -Raw $finalReviewPath | ConvertFrom-Json
if ($acceptedDraft.draft_revision -ne 3 -or $acceptedDraft.questions.Count -ne 20) { throw 'Accepted v3 draft must contain its reviewed twenty questions.' }
if ($finalReview.result -ne 'The v3 private draft preserves the 20 original keys and 80 original option texts, retains all 40 additions accepted in the initial independent review, and resolves the three targeted stem/explanation issues. The v3 revision note accurately describes the sole content change and removal of the stale 015 flag.') { throw 'Final review verdict differs from the accepted v3 evidence.' }
if ($finalReview.artifact_binding.draft_sha256 -ne $acceptedDraftHash) { throw 'Final review is not bound to the accepted draft bytes.' }

$additions = @{
  'capitals-oct3-001' = @('Чикаго', 'Лос-Анджелес')
  'capitals-oct3-002' = @('Нагоя', 'Саппоро')
  'capitals-oct3-003' = @('Ла-Плата', 'Мар-дель-Плата')
  'capitals-oct3-004' = @('Порт-Харкорт', 'Бенин-Сити')
  'capitals-oct3-005' = @('Актобе', 'Тараз')
  'capitals-oct3-006' = @('Кветта', 'Фейсалабад')
  'capitals-oct3-007' = @('Аджман', 'Фуджейра')
  'capitals-oct3-008' = @('Коросаль', 'Дангрига')
  'capitals-oct3-009' = @('Муйинга', 'Руйиги')
  'capitals-oct3-010' = @('Касунгу', 'Мангочи')
  'capitals-oct3-011' = @('Дурбан', 'Гкеберха')
  'capitals-oct3-012' = @('Йоханнесбург', 'Гкеберха')
  'capitals-oct3-013' = @('Дурбан', 'Йоханнесбург')
  'capitals-oct3-014' = @('Тариха', 'Оруро')
  'capitals-oct3-015' = @('Кочабамба', 'Санта-Крус-де-ла-Сьерра')
  'capitals-oct3-016' = @('Эйндховен', 'Гронинген')
  'capitals-oct3-017' = @('Роттердам', 'Утрехт')
  'capitals-oct3-018' = @('Галле', 'Негомбо')
  'capitals-oct3-019' = @('Корого', 'Далоа')
  'capitals-oct3-020' = @('Мбея', 'Морогоро')
}
$stems = @{
  'capitals-oct3-009' = 'Какой город является политической столицей Бурунди?'
  'capitals-oct3-015' = 'В каком городе находятся центральные учреждения исполнительной и законодательной власти Боливии?'
  'capitals-oct3-018' = 'В каком городе Шри-Ланки расположен и заседает парламент?'
}
$explanations = @{
  'capitals-oct3-009' = 'Гитега — политическая столица Бурунди с 2019 года; Бужумбура выполняет экономическую роль.'
  'capitals-oct3-015' = 'Центральные органы исполнительной и законодательной власти работают в Ла-Пасе, тогда как конституционная столица Боливии — Сукре.'
  'capitals-oct3-018' = 'Шри-Джаяварденепура-Котте объявлен столицей и в его границах расположен парламентский комплекс; Коломбо остаётся коммерческим центром.'
}

$legacy = Get-Content -Raw $input | ConvertFrom-Json
if ($legacy.questions.Count -ne 20 -or $additions.Count -ne 20) {
  throw 'Expected exactly twenty source questions and twenty reviewed additions.'
}
foreach ($question in $legacy.questions) {
  $extra = $additions[$question.id]
  if ($null -eq $extra -or $extra.Count -ne 2) { throw "Missing reviewed additions for $($question.id)." }
  $question.options = @($question.options) + @($extra)
  $optionIds = @(1..6 | ForEach-Object { "$($question.id)-opt-$_" })
  $question | Add-Member -Force -NotePropertyName option_ids -NotePropertyValue $optionIds
  $question | Add-Member -Force -NotePropertyName revision_number -NotePropertyValue 2
  if ($stems.ContainsKey($question.id)) { $question.text = $stems[$question.id] }
  if ($explanations.ContainsKey($question.id)) { $question.explanation = $explanations[$question.id] }
}

$utf8 = [System.Text.UTF8Encoding]::new($false)
$sourceJson = $legacy | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($output, $sourceJson + [Environment]::NewLine, $utf8)
$sourceHash = (Get-FileHash -Algorithm SHA256 $output).Hash.ToLowerInvariant()
$provenance = [ordered]@{
  packet = 'yp19/prep-capitals-1-six-choice'
  status = 'canonical-input-generated; publication-not-performed'
  source_quiz = 'quizzes/Preparation/prep_capitals_1.json'
  source_quiz_sha256 = (Get-FileHash -Algorithm SHA256 $input).Hash.ToLowerInvariant()
  controlled_input = 'docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/source.legacy.json'
  controlled_input_sha256 = $sourceHash
  accepted_private_draft = 'docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/accepted-draft-v3.json'
  accepted_private_draft_sha256 = $acceptedDraftHash
  accepted_fact_review = 'docs/rewrite-agents/tasks/FEEDBACK_EXECUTION_20261021/capitals-six/final-review-v3.json'
  accepted_fact_review_sha256 = $finalReviewHash
  prior_full_fact_review_sources_sha256 = $sourceEvidenceHash
  reviewed_canonical_source = 'next/content/prep-capitals-1/draft.json'
  reviewed_canonical_source_raw_sha256 = '2c08402c53021e198fce9fde9ae954c327cfd5c812e824cd3a2ba090f080b41b'
  private_draft_declared_source_sha256 = '3c914f5db5dd22540319ea7d0b57305c9aa0c063bfc2a2f4345e49c12089c318'
  private_draft_declared_source_binding = 'Retained as an unverified private-draft declaration; final review v3 binds the actual canonical raw-byte hash above.'
  reviewed_stem_clarifications = @('capitals-oct3-009', 'capitals-oct3-015', 'capitals-oct3-018')
  reviewed_explanation_replacements = @('capitals-oct3-009', 'capitals-oct3-015', 'capitals-oct3-018')
  preserved_correct_option_ids = $legacy.questions | ForEach-Object { [ordered]@{ question_id = $_.id; correct_option_id = $_.option_ids[$_.correct_answer] } }
  expected_question_revision_number = 2
  difficulty_provenance = [ordered]@{
    legacy_numeric_difficulty_values = @{
      '2' = 4
      '3' = 2
      '4' = 3
      '5' = 4
      '6' = 4
      '7' = 3
    }
    legacy_difficulty_level = 'absent for all 20 source questions'
    canonicalization_observation = 'quizctl derives labels and emits difficulty_level from the legacy numeric value; this is a mechanical representation change, not a calibration claim.'
    known_label_delta = @('capitals-oct3-014: medium to hard, level 7', 'capitals-oct3-015: medium to hard, level 7', 'capitals-oct3-018: medium to hard, level 7')
  }
  build = [ordered]@{ version = '2026.10.21.yp19-capitals-six'; published_at = '2026-10-21T09:35:54Z' }
  boundary = 'This evidence authorizes only local canonicalization. It does not import to a server, publish a bundle, deploy, or resolve feedback.'
}
[System.IO.File]::WriteAllText($provenanceOutput, ($provenance | ConvertTo-Json -Depth 20) + [Environment]::NewLine, $utf8)
