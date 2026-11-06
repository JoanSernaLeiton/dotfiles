#!/usr/bin/env bash
set -u
hook_command="$HOME/.local/bin/claude-stream-deck"
fake_session_id="simulated-deck-test-0001"
fake_working_directory="$HOME/dotfiles"
export CLAUDE_CODE_ENTRYPOINT=cli
unset TMUX_PANE

coordinator_health() {
  ssh -o LogLevel=ERROR rpi 'curl -s -m 3 http://127.0.0.1:8791/health' | python3 -c 'import json,sys; health=json.load(sys.stdin); print("health:", {key: health[key] for key in ("pending_requests","waiting_sessions","screen")})'
}

press_deck_key() {
  ssh -o LogLevel=ERROR rpi "curl -s -m 3 -X POST http://127.0.0.1:8791/deck/press/$1/$2" >/dev/null
  echo "pressed $1/$2"
}

echo "== SessionStart with title"
printf '{"hook_event_name":"SessionStart","session_id":"%s","cwd":"%s","session_title":"prueba deck"}' "$fake_session_id" "$fake_working_directory" | "$hook_command"
echo "== Stop (session waiting)"
printf '{"hook_event_name":"Stop","session_id":"%s","cwd":"%s","last_assistant_message":"Listo, terminé la prueba del Stream Deck. ¿Seguimos con el Mac del trabajo?"}' "$fake_session_id" "$fake_working_directory" | "$hook_command"
coordinator_health

echo "== PermissionRequest (blocking until the deck answers)"
permission_output_file="$(mktemp)"
printf '{"hook_event_name":"PermissionRequest","session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"echo prueba-stream-deck","description":"Prueba del Stream Deck"},"permission_suggestions":[]}' "$fake_session_id" "$fake_working_directory" | "$hook_command" > "$permission_output_file" &
hook_process_id=$!
sleep 3
coordinator_health
press_deck_key 1 0
sleep 1
coordinator_health
press_deck_key 2 4
wait "$hook_process_id"
echo "hook output: $(cat "$permission_output_file")"
rm -f "$permission_output_file"
coordinator_health

echo "== SessionEnd"
printf '{"hook_event_name":"SessionEnd","session_id":"%s","cwd":"%s"}' "$fake_session_id" "$fake_working_directory" | "$hook_command"
coordinator_health
ls "$HOME/.cache/claude-stream-deck/session-titles" 2>/dev/null | grep -c "$fake_session_id" || true
test -f "$HOME/.cache/claude-stream-deck/errors.log" && tail -20 "$HOME/.cache/claude-stream-deck/errors.log" || echo "no hook errors logged"
