import { execFile, spawn } from "node:child_process"
import { appendFileSync, realpathSync } from "node:fs"
import { homedir } from "node:os"

// OpenCode ⇄ tmux glue: the OpenCode side of bin/claude-tmux.
//
// Turns OpenCode events into the hook events Claude Code sends and pipes them to
// `claude-tmux hook`, so OpenCode panes get the same @claude pane options: the
// working / waiting / done icon, `prefix a`, the dashboard, desktop notifications.
//
// Plugins run in OpenCode's server, which is usually the shared background
// service and not a child of the pane, so TMUX_PANE can't be trusted. The pane is
// the one whose own process tree holds this server (`opencode --standalone`), or
// else the only pane running opencode in the session's directory.

const HOOK = process.env.CLAUDE_TMUX_BIN ?? `${homedir()}/.local/bin/claude-tmux`
const LOG = process.env.OPENCODE_TMUX_LOG
const ENV = { ...process.env, PATH: `${process.env.PATH ?? ""}:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin` }

type Target = { pane: string; tmux: string }

const log = (...a: unknown[]) => {
  if (LOG) appendFileSync(LOG, a.map((x) => (typeof x === "string" ? x : JSON.stringify(x))).join(" ") + "\n")
}

const run = (cmd: string, args: string[], env = ENV) =>
  new Promise<string>((resolve) =>
    execFile(cmd, args, { env, timeout: 3000 }, (err, stdout) => resolve(err ? "" : stdout.trim())),
  )

const real = (p: string) => {
  try {
    return realpathSync(p)
  } catch {
    return p
  }
}

// The tmux server to talk to: the one in $TMUX, else the default socket
const tmuxEnv = () => {
  const env = { ...ENV }
  if (!env.TMUX) delete env.TMUX
  return env
}
const tmux = (...args: string[]) => run("tmux", args, tmuxEnv())

async function ancestors(pid: number) {
  const out = await run("ps", ["-A", "-o", "pid=,ppid="])
  const parent = new Map(out.split("\n").map((l) => l.trim().split(/\s+/).map(Number) as [number, number]))
  const seen = new Set<number>()
  for (let p = pid; p > 1 && !seen.has(p); p = parent.get(p) ?? 0) seen.add(p)
  return seen
}

// $TMUX value for the hook, so it reaches the right server even from the background service
const socketFor = (pane: string) => tmux("display", "-p", "-t", pane, "#{socket_path},#{pid},0")

// Private server (`opencode --standalone`, `opencode run`): the pane we were started in
async function ownPane(): Promise<Target | undefined> {
  const pane = process.env.TMUX_PANE
  if (!pane || !process.env.TMUX) return
  const panePid = Number(await tmux("display", "-p", "-t", pane, "#{pane_pid}"))
  if (!panePid || !(await ancestors(process.pid)).has(panePid)) return
  return { pane, tmux: process.env.TMUX }
}

// Shared service: the single pane running opencode in that directory
async function paneFor(directory: string): Promise<Target | undefined> {
  const out = await tmux("list-panes", "-a", "-F", "#{pane_id}\t#{pane_current_command}\t#{pane_current_path}")
  const dir = real(directory)
  const hits = out
    .split("\n")
    .map((l) => l.split("\t"))
    .filter(([id, cmd, path]) => id && /^opencode/.test(cmd ?? "") && real(path ?? "") === dir)
  if (hits.length !== 1) {
    log("no single pane for", directory, hits)
    return
  }
  const pane = hits[0][0]
  return { pane, tmux: await socketFor(pane) }
}

function hook(target: Target, payload: Record<string, unknown>) {
  log("hook", target.pane, payload)
  const child = spawn(HOOK, ["hook"], {
    env: { ...ENV, TMUX: target.tmux, TMUX_PANE: target.pane },
    stdio: ["pipe", "ignore", "ignore"],
  })
  child.on("error", (err) => log("hook failed", String(err)))
  child.stdin?.end(JSON.stringify(payload))
}

// OpenCode tool calls → the shape claude-tmux summarises ("Run: git push", "Edit: install.sh")
const TOOLS: Record<string, string> = { bash: "Bash", shell: "Bash", edit: "Edit", write: "Write", read: "Read", patch: "Edit" }
function toolInput(input: Record<string, unknown> = {}) {
  const file = input.filePath ?? input.file_path ?? input.path
  return {
    command: input.command ?? input.code,
    file_path: typeof file === "string" && !file.startsWith("/") ? `/${file}` : file,
    url: input.url,
    pattern: input.pattern,
    query: input.query,
    description: input.description,
  }
}

const errorText = (e: unknown) =>
  typeof e === "string" ? e : ((e as { message?: string; data?: { message?: string } })?.data?.message ?? (e as { message?: string })?.message ?? "")

export default {
  id: "tmux",
  async setup(ctx: { event: { subscribe(): AsyncIterable<any> } }) {
    const own = await ownPane()
    const dirs = new Map<string, string>() // sessionID → directory
    const targets = new Map<string, Target>() // sessionID → pane
    const lastText = new Map<string, string>()
    const toolNames = new Map<string, string>() // tool call id → tool name (only input.started carries it)
    log("setup pid", process.pid, "own pane", own?.pane ?? "none")

    async function target(sid: string, directory?: string) {
      if (own) return own
      const known = targets.get(sid)
      if (known) return known
      const dir = directory ?? dirs.get(sid)
      if (!dir) return
      const found = await paneFor(dir)
      if (found) targets.set(sid, found)
      return found
    }

    async function send(sid: string, event: string, extra: Record<string, unknown> = {}, directory?: string) {
      const t = await target(sid, directory)
      if (t) hook(t, { hook_event_name: event, cwd: directory ?? dirs.get(sid) ?? "", ...extra })
    }

    async function handle(e: any) {
      const d = e.data ?? {}
      const sid: string = d.sessionID ?? d.form?.sessionID ?? ""
      const directory: string | undefined = e.location?.directory
      if (!sid) return
      if (directory) dirs.set(sid, directory)

      switch (e.type) {
        case "session.execution.started":
          lastText.delete(sid)
          return send(sid, "UserPromptSubmit", {}, directory)
        case "session.tool.input.started":
          toolNames.set(d.id, d.name)
          return
        case "session.tool.called": {
          const name = toolNames.get(d.id) ?? "Tool"
          toolNames.delete(d.id)
          return send(sid, "PreToolUse", { tool_name: TOOLS[name] ?? name, tool_input: toolInput(d.input) }, directory)
        }
        case "session.tool.success":
        case "session.tool.failed":
        case "permission.replied":
        case "form.replied":
        case "form.cancelled":
          return send(sid, "PostToolUse", {}, directory)
        case "permission.asked":
          return send(sid, "Notification", { notification_type: "permission_prompt", message: d.message ?? d.action }, directory)
        case "form.created":
          return send(sid, "Notification", { notification_type: "elicitation_dialog", message: d.form?.title }, directory)
        case "session.text.ended":
          if (d.text?.trim()) lastText.set(sid, d.text)
          return
        case "session.execution.succeeded":
          return send(sid, "Stop", { last_assistant_message: lastText.get(sid) ?? "" }, directory)
        case "session.execution.failed":
          return send(sid, "Stop", { last_assistant_message: `Failed: ${errorText(d.error)}` }, directory)
        case "session.execution.interrupted":
          if (d.reason === "shutdown") return send(sid, "SessionEnd", {}, directory)
          return send(sid, "Stop", { last_assistant_message: `Interrupted (${d.reason})` }, directory)
        case "session.usage.updated": {
          const t = await target(sid)
          if (t && typeof d.cost === "number")
            await run("tmux", ["set", "-p", "-t", t.pane, "@claude_ctx", `$${d.cost.toFixed(2)}`], { ...ENV, TMUX: t.tmux })
          return
        }
      }
    }

    ;(async () => {
      for await (const e of ctx.event.subscribe()) await handle(e).catch((err) => log("handle failed", e?.type, String(err)))
    })().catch((err) => log("subscribe failed", String(err)))
  },
}
