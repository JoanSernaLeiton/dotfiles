import { spawn } from "node:child_process"

// RTK OpenCode plugin — rewrites shell commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// V2 plugins must default-export a definition with an id and setup(). `rtk rewrite`
// can exit non-zero even when it prints a rewrite, so stdout is the source of truth.

type ToolExecuteBefore = {
  tool?: unknown
  input?: unknown
}

function runRtk(args: string[]): Promise<{ found: boolean; stdout: string }> {
  return new Promise((resolve) => {
    const child = spawn("rtk", args, { stdio: ["ignore", "pipe", "ignore"] })
    const chunks: Buffer[] = []
    child.stdout?.on("data", (chunk: Buffer) => chunks.push(chunk))
    child.on("error", () => resolve({ found: false, stdout: "" }))
    child.on("close", () => {
      resolve({ found: true, stdout: Buffer.concat(chunks).toString("utf8") })
    })
  })
}

async function rewrite(command: string): Promise<string | undefined> {
  const result = await runRtk(["rewrite", command])
  if (!result.found) return
  const rewritten = result.stdout.trim()
  if (!rewritten || rewritten === command) return
  return rewritten
}

export default {
  id: "rtk",
  async setup(ctx: {
    tool: {
      hook(
        name: "execute.before",
        callback: (event: ToolExecuteBefore) => Promise<void> | void,
      ): Promise<unknown>
    }
  }) {
    const probe = await runRtk(["--version"])
    if (!probe.found) {
      console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
      return
    }

    await ctx.tool.hook("execute.before", async (event) => {
      const tool = String(event?.tool ?? "").toLowerCase()
      if (tool !== "bash" && tool !== "shell") return
      const input = event?.input
      if (!input || typeof input !== "object") return

      const args = input as Record<string, unknown>
      const command = args.command
      if (typeof command !== "string" || !command) return

      try {
        const rewritten = await rewrite(command)
        if (!rewritten) return
        event.input = { ...args, command: rewritten }
      } catch {
        // rtk rewrite failed — pass through unchanged
      }
    })
  },
}
