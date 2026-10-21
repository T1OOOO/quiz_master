param(
    [string]$Baseline = 'next/content/prep-capitals-1/draft.json',
    [string]$CandidateDirectory = '.run/feedback_execute_20261021/capitals-six/candidate'
)

$ErrorActionPreference = 'Stop'

function Assert-That([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

$expectedStems = @{
    'capitals-oct3-009' = 'Какой город является политической столицей Бурунди?'
    'capitals-oct3-015' = 'В каком городе находятся центральные учреждения исполнительной и законодательной власти Боливии?'
    'capitals-oct3-018' = 'В каком городе Шри-Ланки расположен и заседает парламент?'
}
$expectedExplanations = @{
    'capitals-oct3-009' = 'Гитега — политическая столица Бурунди с 2019 года; Бужумбура выполняет экономическую роль.'
    'capitals-oct3-015' = 'Центральные органы исполнительной и законодательной власти работают в Ла-Пасе, тогда как конституционная столица Боливии — Сукре.'
    'capitals-oct3-018' = 'Шри-Джаяварденепура-Котте объявлен столицей и в его границах расположен парламентский комплекс; Коломбо остаётся коммерческим центром.'
}
$expectedNewOptions = @{
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

$baselineDraft = Get-Content -LiteralPath $Baseline -Raw | ConvertFrom-Json
$candidateDraft = Get-Content -LiteralPath (Join-Path $CandidateDirectory 'draft.json') -Raw | ConvertFrom-Json
$bundle = Get-Content -LiteralPath (Join-Path $CandidateDirectory 'bundle.json') -Raw | ConvertFrom-Json
$manifest = Get-Content -LiteralPath (Join-Path $CandidateDirectory 'manifest.json') -Raw | ConvertFrom-Json

Assert-That ($baselineDraft.questions.Count -eq 20) 'baseline must contain 20 questions'
Assert-That ($candidateDraft.questions.Count -eq 20) 'candidate must contain 20 questions'
Assert-That ($bundle.quiz.questions.Count -eq 20) 'public bundle must contain 20 questions'
Assert-That ($manifest.questions.Count -eq 20) 'manifest must contain 20 mappings'
Assert-That (-not ($bundle.quiz.PSObject.Properties.Name -contains 'grading')) 'public quiz must not expose grading'

foreach ($oldQuestion in $baselineDraft.questions) {
    $questionId = $oldQuestion.question_id
    $newQuestion = @($candidateDraft.questions | Where-Object question_id -eq $questionId)
    Assert-That ($newQuestion.Count -eq 1) "$questionId must appear once in the candidate"
    $newQuestion = $newQuestion[0]
    Assert-That ($newQuestion.options.Count -eq 6) "$questionId must have exactly six options"
    Assert-That ((@($newQuestion.options.option_id | Select-Object -Unique).Count) -eq 6) "$questionId option IDs must be unique"
    Assert-That ((@($newQuestion.options.text | Select-Object -Unique).Count) -eq 6) "$questionId option texts must be unique"
    Assert-That ($newQuestion.revision.number -eq 2) "$questionId must have revision number 2"
    Assert-That ($newQuestion.grading.correct_option_id -eq $oldQuestion.grading.correct_option_id) "$questionId must preserve the correct option ID"
    for ($index = 0; $index -lt 4; $index++) {
        Assert-That ($newQuestion.options[$index].option_id -eq $oldQuestion.options[$index].option_id) "$questionId old option $index ID changed"
        Assert-That ($newQuestion.options[$index].text -eq $oldQuestion.options[$index].text) "$questionId old option $index text changed"
    }
    Assert-That ($expectedNewOptions.ContainsKey($questionId)) "$questionId must have reviewed new-option evidence"
    for ($index = 0; $index -lt 2; $index++) {
        Assert-That ($newQuestion.options[$index + 4].option_id -eq "$questionId-opt-$($index + 5)") "$questionId new option $index ID changed"
        Assert-That ($newQuestion.options[$index + 4].text -eq $expectedNewOptions[$questionId][$index]) "$questionId new option $index differs from the accepted draft"
    }
    $privateGrading = $bundle.private_grading.$questionId
    Assert-That ($null -ne $privateGrading) "$questionId must have private grading"
    Assert-That ($privateGrading.correct_option_id -eq $newQuestion.grading.correct_option_id) "$questionId private grading differs from draft"
    $publicQuestion = @($bundle.quiz.questions | Where-Object question_id -eq $questionId)
    Assert-That ($publicQuestion.Count -eq 1) "$questionId must appear once in public quiz"
    Assert-That (-not ($publicQuestion[0].PSObject.Properties.Name -contains 'grading')) "$questionId public question exposes grading"
    Assert-That ($publicQuestion[0].options.Count -eq 6) "$questionId public question must have six options"
    for ($index = 0; $index -lt 6; $index++) {
        Assert-That ($publicQuestion[0].options[$index].option_id -eq $newQuestion.options[$index].option_id) "$questionId public option $index ID differs from draft"
        Assert-That ($publicQuestion[0].options[$index].text -eq $newQuestion.options[$index].text) "$questionId public option $index text differs from draft"
    }
    $mapping = @($manifest.questions | Where-Object canonical_id -eq $questionId)
    Assert-That ($mapping.Count -eq 1) "$questionId must have one manifest mapping"
    Assert-That ($mapping[0].options.Count -eq 6) "$questionId manifest mapping must have six options"
}

foreach ($questionId in $expectedStems.Keys) {
    $question = @($candidateDraft.questions | Where-Object question_id -eq $questionId)[0]
    $mapping = @($manifest.questions | Where-Object canonical_id -eq $questionId)[0]
    Assert-That ($question.stem -eq $expectedStems[$questionId]) "$questionId stem is not the accepted clarification"
    Assert-That ($mapping.source_explanation -eq $expectedExplanations[$questionId]) "$questionId explanation is not the accepted reviewed text"
}

foreach ($question in $candidateDraft.questions) {
    if (-not $expectedStems.ContainsKey($question.question_id)) {
        $old = @($baselineDraft.questions | Where-Object question_id -eq $question.question_id)[0]
        $oldMapping = @((Get-Content -LiteralPath (Join-Path (Split-Path $Baseline -Parent) 'manifest.json') -Raw | ConvertFrom-Json).questions | Where-Object canonical_id -eq $question.question_id)[0]
        $newMapping = @($manifest.questions | Where-Object canonical_id -eq $question.question_id)[0]
        Assert-That ($question.stem -eq $old.stem) "$($question.question_id) stem changed outside the three accepted clarifications"
        Assert-That ($newMapping.source_explanation -eq $oldMapping.source_explanation) "$($question.question_id) explanation changed outside the three accepted replacements"
    }
}

Write-Output 'candidate integrity: PASS (20 questions, six unique options, stable correct IDs and first four options, private grading, three exact accepted stems and explanations)'
