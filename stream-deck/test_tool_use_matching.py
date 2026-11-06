import importlib.machinery
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
hook_path = str(Path.home() / "dotfiles" / "bin" / "claude-stream-deck")
module_loader = importlib.machinery.SourceFileLoader("claude_stream_deck_hook", hook_path)
module_specification = importlib.util.spec_from_loader("claude_stream_deck_hook", module_loader)
hook_module = importlib.util.module_from_spec(module_specification)
module_loader.exec_module(hook_module)


def assistant_tool_use(tool_use_id, tool_name, tool_input):
    return {"type": "assistant", "message": {"content": [{"type": "tool_use", "id": tool_use_id, "name": tool_name, "input": tool_input}]}}


def user_tool_result(tool_use_id):
    return {"type": "user", "message": {"content": [{"type": "tool_result", "tool_use_id": tool_use_id, "content": "ok"}]}}


def write_transcript(transcript_entries):
    transcript_file = tempfile.NamedTemporaryFile("w", suffix=".jsonl", delete=False, encoding="utf-8")
    for transcript_entry in transcript_entries:
        transcript_file.write(json.dumps(transcript_entry, separators=(",", ":")) + "\n")
    transcript_file.close()
    return transcript_file.name


def found_id(transcript_entries, tool_name, tool_input):
    transcript_path = write_transcript(transcript_entries)
    return hook_module.find_tool_use_id({"transcript_path": transcript_path, "tool_name": tool_name, "tool_input": tool_input})


failures = []


def expect(description, actual_value, expected_value):
    outcome = "ok" if actual_value == expected_value else "FAIL"
    if outcome == "FAIL":
        failures.append(description)
    print(f"{outcome}: {description} -> {actual_value!r}")


expect("exact input match", found_id([assistant_tool_use("toolu_a", "Bash", {"command": "git status"})], "Bash", {"command": "git status"}), "toolu_a")
expect("rewritten input falls back to name", found_id([assistant_tool_use("toolu_a", "Bash", {"command": "git status"})], "Bash", {"command": "rtk git status"}), "toolu_a")
expect(
    "resolved tool use is skipped",
    found_id([assistant_tool_use("toolu_a", "Bash", {"command": "ls"}), user_tool_result("toolu_a")], "Bash", {"command": "ls"}),
    None,
)
expect(
    "first unresolved of parallel calls",
    found_id(
        [assistant_tool_use("toolu_a", "Bash", {"command": "one"}), assistant_tool_use("toolu_b", "Bash", {"command": "two"})],
        "Bash",
        {"command": "rewritten"},
    ),
    "toolu_a",
)
expect(
    "exact match wins over earlier unresolved",
    found_id(
        [assistant_tool_use("toolu_a", "Bash", {"command": "one"}), assistant_tool_use("toolu_b", "Bash", {"command": "two"})],
        "Bash",
        {"command": "two"},
    ),
    "toolu_b",
)
expect("other tool names ignored", found_id([assistant_tool_use("toolu_a", "Read", {"file_path": "x"})], "Bash", {"command": "x"}), None)

watched_transcript_path = write_transcript([assistant_tool_use("toolu_w", "AskUserQuestion", {"questions": []})])
terminal_answer_watcher = hook_module.TerminalAnswerWatcher(watched_transcript_path, "toolu_w")
expect("watcher quiet before result", terminal_answer_watcher.terminal_already_answered(), False)
with open(watched_transcript_path, "a", encoding="utf-8") as transcript_file:
    transcript_file.write(json.dumps(user_tool_result("toolu_other"), separators=(",", ":")) + "\n")
expect("watcher ignores other results", terminal_answer_watcher.terminal_already_answered(), False)
partial_line = json.dumps(user_tool_result("toolu_w"), separators=(",", ":"))
with open(watched_transcript_path, "a", encoding="utf-8") as transcript_file:
    transcript_file.write(partial_line[:20])
expect("watcher waits for complete line", terminal_answer_watcher.terminal_already_answered(), False)
with open(watched_transcript_path, "a", encoding="utf-8") as transcript_file:
    transcript_file.write(partial_line[20:] + "\n")
expect("watcher sees result", terminal_answer_watcher.terminal_already_answered(), True)

sys.exit(1 if failures else 0)
