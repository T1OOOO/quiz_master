$ErrorActionPreference='Stop'
$container='qm-p09-20260920-1742'
$watch=[System.Diagnostics.Stopwatch]::StartNew()
$identity=(& docker inspect $container --format '{{json .}}'|ConvertFrom-Json)
if($identity.Config.Labels.'qm.task' -ne 'P09' -or $identity.Name -ne '/qm-p09-20260920-1742'){throw 'Unexpected container identity'}
$sql=@'
SELECT json_build_object(
 'server_version',current_setting('server_version'),
 'database',current_database(),
 'migrations',(SELECT json_agg(json_build_object('version',version,'checksum',checksum) ORDER BY version) FROM schema_migrations),
 'row_counts',json_build_object('bundles',(SELECT count(*) FROM attempt_bundles),'attempts',(SELECT count(*) FROM attempts),'snapshots',(SELECT count(*) FROM attempt_questions),'receipts',(SELECT count(*) FROM attempt_answers),'finished',(SELECT count(*) FROM attempts WHERE status='finished')),
 'public_row_private_marker_count',(SELECT count(*) FROM (SELECT row_to_json(a)::text AS data FROM attempts a UNION ALL SELECT row_to_json(q)::text FROM attempt_questions q UNION ALL SELECT row_to_json(r)::text FROM attempt_answers r) x WHERE data ~ '"(private_grading|correct_option_ids?|accepted_variants|correct_answer|explanation|grading|token|token_digest|password)"'),
 'session_digest_format_failures',(SELECT count(*) FROM sessions WHERE token_digest !~ '^[0-9a-f]{64}$'),
 'schema_objects',(SELECT json_agg(json_build_object('table',tablename,'indexes',indexes) ORDER BY tablename) FROM (SELECT t.tablename,(SELECT count(*) FROM pg_indexes i WHERE i.tablename=t.tablename AND i.schemaname='public') AS indexes FROM pg_tables t WHERE schemaname='public' AND tablename LIKE 'attempt%') x),
 'constraints',(SELECT json_agg(json_build_object('table',conrelid::regclass::text,'name',conname,'type',contype) ORDER BY conrelid::regclass::text,conname) FROM pg_constraint WHERE conrelid IN ('attempt_bundles'::regclass,'attempts'::regclass,'attempt_questions'::regclass,'attempt_answers'::regclass)),
 'immutability_triggers',(SELECT json_agg(tgname ORDER BY tgname) FROM pg_trigger WHERE NOT tgisinternal AND tgname LIKE 'immutable_attempt%')
);
'@
$result=(& docker exec $container psql -U postgres -d p09 -At -c $sql | Out-String)
if($LASTEXITCODE -ne 0){throw 'Database inspection failed'}
$data=$result|ConvertFrom-Json
if($data.public_row_private_marker_count -ne 0 -or $data.session_digest_format_failures -ne 0 -or $data.row_counts.receipts -le 0){throw 'Database evidence invalid'}
$watch.Stop()
$record=[ordered]@{container_name=$container;container_id=$identity.Id;image=$identity.Config.Image;healthy=$identity.State.Health.Status;loopback_port=$identity.NetworkSettings.Ports.'5432/tcp';volume='qm-p09-20260920-1742-data';inspection_command='docker exec qm-p09-20260920-1742 psql -U postgres -d p09 -At -c <SQL in inspect-database.ps1>';cwd=(Get-Location).Path;duration_seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);exit=0;database=$data;raw_token_check='TestRealBundleBearerEndToEnd independently queried attempt/snapshot/receipt rows with both real raw bearer token values as SQL parameters; no matches. Values are never recorded.'}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot 'database.json'),($record|ConvertTo-Json -Depth 15))
Write-Output ($record.database.row_counts|ConvertTo-Json -Compress)
Write-Output "public_row_private_marker_count=$($data.public_row_private_marker_count); session_digest_format_failures=$($data.session_digest_format_failures)"
