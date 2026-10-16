# Global rules

## Shared memory rule (STRICT)

The `memory` MCP server (http://127.0.0.1:8765/mcp) is shared with Claude Code. Use it on every task, not just when asked.

1. **Before** starting any code search, investigation/research, or implementation: call the memory MCP `memory_search` tool with the topic, project, and key terms. Read the relevant hits and use them before searching code or the web.
2. **After** finishing a search, investigation, or implementation, and **any time you find something worth knowing** (root cause, decision, gotcha, file location, command that worked, config, user preference): save it with the memory MCP `memory_store` tool. One fact per memory, include the project name, concrete paths/commands, and the why.
3. Before storing, check the search results for an existing memory on the same topic; update it (`memory_update`) instead of creating a duplicate.
4. Never store secrets, tokens, or passwords.
