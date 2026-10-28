@RTK.md

# Voice rule (STRICT)

Anything written or published in Joan's name (blog posts, LinkedIn, X, site copy, READMEs, bios, emails, commit-free public text) MUST follow the voice guide below, in both Spanish and English. Apply it before drafting, not after. If a text would sound generic or corporate, rewrite it. Chat replies to Joan are not covered.

@VOICE.md

# Shared memory rule (STRICT)

The `memory` MCP server (http://127.0.0.1:8765/mcp) is shared with OpenCode. Use it on every task, not just when asked.

1. **Before** starting any code search, investigation/research, or implementation: call `memory_search` (MCP `memory`) with the topic, project, and key terms. Read the relevant hits and use them before searching code or the web.
2. **After** finishing a search, investigation, or implementation, and **any time you find something worth knowing** (root cause, decision, gotcha, file location, command that worked, config, user preference): save it with `memory_store`. One fact per memory, include the project name, concrete paths/commands, and the why.
3. Before storing, check the search results for an existing memory on the same topic; update it (`memory_update`) instead of creating a duplicate.
4. Never store secrets, tokens, or passwords.
5. Every error, confusion, or misunderstanding (mine, a subagent's, or a wrong assumption) gets recorded the moment it's detected with `mistake_note_add` (incorrect action + correct action). Before each task, also run `mistake_note_search` on the topic.
6. Before creating or asking Joan for any credential or infrastructure resource, check whether it already exists (local env files, tofu, the provider's console) and test it for real.

# GitHub polling rule (STRICT)

Joan's GitHub API quota is shared with his release workflows; bursts of queries get it blocked.

- What matters is concurrency, not spacing: at most **3–4 `gh` calls at the same time** across all agents. Never bursts of dozens of calls (e.g. 50 in a loop).
- Sequential calls are fine without waiting between them; for bulk work (many issues), run them one or a few at a time, never fan out dozens in parallel.
- When polling CI, checks, runs or releases, still sleep between checks in the background: `until ! gh pr checks N | grep -qE "pending|queued|in_progress"; do sleep 60; done`. Never a tight loop.
- On "API rate limit exceeded": check `gh api rate_limit` once and wait for the reset.

# Self-documenting code rule (STRICT)

Comments in code are completely forbidden. Code must be fully self-descriptive through very descriptive names.

- Never write comments of any kind: inline, block, docstrings, JSDoc, TODOs, section headers, or commented-out code.
- The code documents itself through its names. Every variable, function, method, parameter, type and constant gets a very descriptive name that says exactly what it holds or does (`remainingRetryAttempts`, `calculateMonthlyInvoiceTotal`).
- No abbreviations or cryptic names: no `i`, `e`, `err`, `res`, `req`, `ctx`, `cfg`, `tmp`, `val`, `obj`, `arr`, `str`, `btn`, `idx`, `cnt`, `usr`. Spell every word out (`error`, `response`, `configuration`, `userIndex`). Long names are fine; unclear names are not.
- Also: small single-purpose functions, named constants instead of magic values, and clear structure.
- If code seems to need a comment, rename or restructure it until it does not.
- Put explanations in chat replies, commit messages or docs, never in the code.
