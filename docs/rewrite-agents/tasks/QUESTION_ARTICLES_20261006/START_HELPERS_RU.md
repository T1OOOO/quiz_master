# Запуск помощников

Открой Claude Code и Antigravity в C:/ap/quiz_master. После обновления MCP переподключи серверы. Вставь соответствующий английский промпт ниже. Это промпты для настоящих сеансов: Hub не может сам возобновить завершённый диалог в Antigravity.

## Claude

Запуск из PowerShell (интерактивный режим, без обхода подтверждений):

```powershell
Set-Location C:/ap/quiz_master
claude --model sonnet --effort medium "Read C:/ap/quiz_master/docs/rewrite-agents/tasks/QUESTION_ARTICLES_20261006/COLLABORATION_CONTEXT_EN.md and CLAUDE_EXECUTOR_EN.md completely. Follow their startup protocol, connect to host_hub, send READY to the live Quiz Master Feedback team lead, accept a scoped task and execute it now."
```

Флаг запуска не подтверждает фактическую модель: агент обязан сообщить её сам. Для Gemini используем Antigravity; прежний headless CLI завершился ошибкой авторизации.

```text
Read C:/ap/quiz_master/docs/rewrite-agents/tasks/QUESTION_ARTICLES_20261006/COLLABORATION_CONTEXT_EN.md and CLAUDE_EXECUTOR_EN.md completely. Follow their startup protocol, inventory actual tools/model, connect to host_hub, find the live Quiz Master Feedback team lead, send READY and accept one scoped assignment. Execute it with bounded real subagents if supported. Codex coordinates integration/review/deployment; you implement or review and submit evidence. Start now.
```

## Gemini в Antigravity

```text
Read C:/ap/quiz_master/docs/rewrite-agents/tasks/QUESTION_ARTICLES_20261006/COLLABORATION_CONTEXT_EN.md and GEMINI_EXECUTOR_EN.md completely. Follow their startup protocol in Antigravity, inventory actual tools/model, connect to host_hub, find the live Quiz Master Feedback team lead and send fresh READY/checkpoint. Resume your existing eight-article assignment if still assigned, otherwise accept one scoped offer. Use bounded real subagents if supported. Codex coordinates integration/review/deployment; submit concrete drafts and source evidence. Start now.
```

Полный контекст и правила распределения находятся в COLLABORATION_CONTEXT_EN.md; отдельные задания — в CLAUDE_EXECUTOR_EN.md и GEMINI_EXECUTOR_EN.md. Проверяй настоящий статус в Hub: отправленное сообщение, QUEUED-запуск и открытое окно не означают, что агент выполняет задачу.
