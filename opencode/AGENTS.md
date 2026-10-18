# Global rules

## Shared memory rule (STRICT)

The `memory` MCP server (http://127.0.0.1:8765/mcp) is shared with Claude Code. Use it on every task, not just when asked.

1. **Before** starting any code search, investigation/research, or implementation: call the memory MCP `memory_search` tool with the topic, project, and key terms. Read the relevant hits and use them before searching code or the web.
2. **After** finishing a search, investigation, or implementation, and **any time you find something worth knowing** (root cause, decision, gotcha, file location, command that worked, config, user preference): save it with the memory MCP `memory_store` tool. One fact per memory, include the project name, concrete paths/commands, and the why.
3. Before storing, check the search results for an existing memory on the same topic; update it (`memory_update`) instead of creating a duplicate.
4. Never store secrets, tokens, or passwords.

## Self-documenting code rule (STRICT)

Comments in code are completely forbidden. Code must be fully self-descriptive through very descriptive names.

- Never write comments of any kind: inline, block, docstrings, JSDoc, TODOs, section headers, or commented-out code.
- The code documents itself through its names. Every variable, function, method, parameter, type and constant gets a very descriptive name that says exactly what it holds or does (`remainingRetryAttempts`, `calculateMonthlyInvoiceTotal`).
- No abbreviations or cryptic names: no `i`, `e`, `err`, `res`, `req`, `ctx`, `cfg`, `tmp`, `val`, `obj`, `arr`, `str`, `btn`, `idx`, `cnt`, `usr`. Spell every word out (`error`, `response`, `configuration`, `userIndex`). Long names are fine; unclear names are not.
- Also: small single-purpose functions, named constants instead of magic values, and clear structure.
- If code seems to need a comment, rename or restructure it until it does not.
- Put explanations in chat replies, commit messages or docs, never in the code.