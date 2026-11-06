#!/usr/bin/env bash
set -u
hook_command="$HOME/.local/bin/claude-stream-deck"
hidden_session_id="simulated-deck-hidden-0001"
enabled_session_id="simulated-deck-enabled-0001"
fake_working_directory="$HOME/dotfiles"
export CLAUDE_CODE_ENTRYPOINT=cli
unset TMUX_PANE
unset CLAUDE_STREAM_DECK

coordinator_health() {
  ssh -o LogLevel=ERROR rpi 'curl -s -m 3 http://127.0.0.1:8791/health' | python3 -c 'import json,sys; health=json.load(sys.stdin); print("health:", {key: health.get(key) for key in ("pending_requests","parked_requests","waiting_sessions","waiting_sessions_on_deck","known_sessions","sessions_on_deck","screen")})'
}

press_deck_key() {
  ssh -o LogLevel=ERROR rpi "curl -s -m 3 -X POST http://127.0.0.1:8791/deck/press/$1/$2" >/dev/null
  echo "pressed $1/$2"
}

open_deck_from_main_page() {
  ssh -o LogLevel=ERROR rpi "curl -s -m 3 -X POST http://127.0.0.1:8791/deck/open" >/dev/null
  echo "opened from main page"
}

send_hook_event() {
  printf '%s' "$1" | "$hook_command"
}

start_permission_request() {
  local session_id="$1"
  local output_file="$2"
  printf '{"hook_event_name":"PermissionRequest","session_id":"%s","cwd":"%s","tool_name":"Bash","tool_input":{"command":"echo prueba-stream-deck","description":"Prueba del Stream Deck"},"permission_suggestions":[]}' "$session_id" "$fake_working_directory" | "$hook_command" > "$output_file" &
}

answer_focused_permission_from_deck() {
  open_deck_from_main_page
  sleep 1
  press_deck_key 1 0
  sleep 1
  press_deck_key 2 4
}

echo "== Hidden session (no CLAUDE_STREAM_DECK)"
send_hook_event "$(printf '{"hook_event_name":"SessionStart","session_id":"%s","cwd":"%s","session_title":"prueba oculta"}' "$hidden_session_id" "$fake_working_directory")"
send_hook_event "$(printf '{"hook_event_name":"Stop","session_id":"%s","cwd":"%s","last_assistant_message":"Listo, terminé la prueba oculta"}' "$hidden_session_id" "$fake_working_directory")"
coordinator_health

echo "== PermissionRequest from the hidden session (expect parked)"
hidden_output_file="$(mktemp)"
start_permission_request "$hidden_session_id" "$hidden_output_file"
hidden_hook_process_id=$!
sleep 3
coordinator_health

echo "== Live toggle from the deck: machine key, then first session"
press_deck_key 0 0
sleep 1
coordinator_health
press_deck_key 1 0
sleep 1
coordinator_health
press_deck_key 0 0
answer_focused_permission_from_deck
wait "$hidden_hook_process_id"
echo "hook output: $(cat "$hidden_output_file")"
rm -f "$hidden_output_file"
send_hook_event "$(printf '{"hook_event_name":"SessionEnd","session_id":"%s","cwd":"%s"}' "$hidden_session_id" "$fake_working_directory")"
coordinator_health

echo "== Hidden session ended while its request is parked (expect withdrawn)"
send_hook_event "$(printf '{"hook_event_name":"SessionStart","session_id":"%s","cwd":"%s","session_title":"prueba oculta"}' "$hidden_session_id" "$fake_working_directory")"
parked_output_file="$(mktemp)"
start_permission_request "$hidden_session_id" "$parked_output_file"
parked_hook_process_id=$!
sleep 3
coordinator_health
send_hook_event "$(printf '{"hook_event_name":"SessionEnd","session_id":"%s","cwd":"%s"}' "$hidden_session_id" "$fake_working_directory")"
wait "$parked_hook_process_id"
echo "hook output (expect empty): $(cat "$parked_output_file")"
rm -f "$parked_output_file"
coordinator_health

echo "== Session launched with CLAUDE_STREAM_DECK=1 (expect queued right away)"
export CLAUDE_STREAM_DECK=1
send_hook_event "$(printf '{"hook_event_name":"SessionStart","session_id":"%s","cwd":"%s","session_title":"prueba visible"}' "$enabled_session_id" "$fake_working_directory")"
enabled_output_file="$(mktemp)"
start_permission_request "$enabled_session_id" "$enabled_output_file"
enabled_hook_process_id=$!
sleep 3
coordinator_health
answer_focused_permission_from_deck
wait "$enabled_hook_process_id"
echo "hook output: $(cat "$enabled_output_file")"
rm -f "$enabled_output_file"
send_hook_event "$(printf '{"hook_event_name":"SessionEnd","session_id":"%s","cwd":"%s"}' "$enabled_session_id" "$fake_working_directory")"
coordinator_health

test -f "$HOME/.cache/claude-stream-deck/errors.log" && tail -20 "$HOME/.cache/claude-stream-deck/errors.log" || echo "no hook errors logged"
