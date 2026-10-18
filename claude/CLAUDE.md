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

# GitHub polling rule (STRICT)

Joan's GitHub API quota is shared with his release workflows; too many queries get it blocked.

- At most **one GitHub query every 60 seconds** while waiting on CI, checks, runs or releases.
- One `gh` call per check, then `sleep 60`. Run it in the background: `until ! gh pr checks N | grep -qE "pending|queued|in_progress"; do sleep 60; done`.
- Never a tight loop, never several `gh` calls per iteration, and no ad-hoc `gh` checks while a poll is running.
- On "API rate limit exceeded": check `gh api rate_limit` once and wait for the reset.

# No code comments rule (STRICT)

Comments in code are completely forbidden. Code must be fully self-descriptive.

- Never write comments of any kind: inline, block, docstrings, JSDoc, TODOs, section headers, or commented-out code.
- Explain intent through code instead: precise names for variables, functions and types, small single-purpose functions, named constants instead of magic values, and clear structure.
- If code seems to need a comment, rename or restructure it until it does not.
- Put explanations in chat replies, commit messages or docs, never in the code.
