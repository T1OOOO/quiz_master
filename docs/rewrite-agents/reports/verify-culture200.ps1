$ErrorActionPreference = 'Stop'
# Run from the repository root. Compare the actual published inputs with reviewed drafts.
$banks = @(
    @('prep_books_classic', 'preparation-books-classic', 'preparation-books/legacy-classic.json', 30),
    @('prep_books_modern', 'preparation-books-modern', 'preparation-books/legacy-modern.json', 30),
    @('prep_ballet', 'prep-ballet', 'preparation-music/legacy-ballet.json', 20),
    @('prep_musicals', 'prep-musicals', 'preparation-music/legacy-musicals.json', 20),
    @('prep_opera', 'prep-opera', 'preparation-music/legacy-opera.json', 20),
    @('prep_history_events', 'prep-history-events', 'preparation-history/legacy.json', 20),
    @('prep_greek_mythology', 'prep-greek-mythology', 'preparation-mythology/legacy.json', 20),
    @('prep_norse_mythology', 'prep-norse-mythology', 'preparation-mythology/norse-legacy.json', 20),
    @('prep_compositions', 'prep-compositions', 'preparation-music/compositions20-legacy.json', 20)
)
$total = 0
foreach ($bank in $banks) {
    $source = Get-Content "quizzes/Preparation/$($bank[0]).json" -Raw | ConvertFrom-Json
    $reviewed = Get-Content "docs/rewrite-agents/$($bank[2])" -Raw | ConvertFrom-Json
    $draft = Get-Content "next/content/$($bank[1])/draft.json" -Raw | ConvertFrom-Json
    $manifest = Get-Content "next/content/$($bank[1])/manifest.json" -Raw | ConvertFrom-Json
    $bundle = Get-Content "next/content/$($bank[1])/bundle.json" -Raw | ConvertFrom-Json
    if ($source.questions.Count -ne $bank[3] -or $draft.questions.Count -ne $bank[3] -or $bundle.quiz.questions.Count -ne $bank[3]) { throw "Count: $($bank[1])" }
    if ($source.description -match 'Черновик') { throw "Draft metadata: $($bank[1])" }
    for ($i = 0; $i -lt $bank[3]; $i++) {
        $q = $source.questions[$i]
        if ($bank[1] -eq 'prep-compositions') {
            $r = $reviewed[$i]
            $stem = $r.question
            $options = @($r.options.A, $r.options.B, $r.options.C, $r.options.D)
            $answer = 'ABCD'.IndexOf([string]$r.answer)
        } else {
            $r = $reviewed.questions[$i]
            $stem = $r.text
            $options = $r.options
            $answer = $r.correct_answer
        }
        if ($q.id -cne $r.id -or $q.text -cne $stem -or $q.explanation -cne $r.explanation -or $q.correct_answer -ne $answer -or (ConvertTo-Json -Compress -InputObject $q.options) -cne (ConvertTo-Json -Compress -InputObject $options)) { throw "Reviewed content drift: $($q.id)" }
        $m = $manifest.questions[$i]
        $d = $draft.questions[$i]
        $public = $bundle.quiz.questions[$i]
        $grading = $bundle.private_grading.PSObject.Properties[$m.canonical_id].Value
        if ($m.source_id -cne $q.id -or $m.source_explanation -cne $q.explanation -or $d.question_id -cne $m.canonical_id -or $public.question_id -cne $m.canonical_id -or $grading.correct_option_id -cne $m.options[$answer].canonical_id) { throw "Canonical integrity: $($q.id)" }
        if ($public.PSObject.Properties.Name -contains 'grading') { throw "Public answer leak: $($q.id)" }
    }
    $total += $bank[3]
}
if ($total -ne 200) { throw 'Expected 200 reviewed questions' }
$catalog = Get-Content next/apps/quiz_app/assets/catalog.json -Raw | ConvertFrom-Json
if ($catalog.Count -ne 115 -or ($catalog | Measure-Object questions_count -Sum).Sum -ne 3798) { throw 'Catalog inventory' }
foreach ($pack in $catalog) {
    if (($pack.PSObject.Properties.Name | Sort-Object) -join ',' -cne 'category,description,questions_count,quiz_id,title') { throw 'Catalog is not metadata-only' }
}
Write-Output 'PASS 200 reviewed questions: stems/options/answers/explanations preserved, canonical/private grading aligned, public metadata-only catalog 115/3798'
