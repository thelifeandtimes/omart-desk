#!/bin/sh
# Local development only: no production piers or existing tend ships are touched.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
SESSION=omart-dev
STATE="$ROOT/.dev/fakenet"
case "${1:-status}" in
  start)
    mkdir -p "$STATE"
    for spec in nec:8091 bus:8092 tyr:8093; do
      ship=${spec%:*}
      port=${spec#*:}
      if tmux list-panes -t "$SESSION:$ship" >/dev/null 2>&1; then continue; fi
      if [ -d "$STATE/$ship/.urb" ]; then
        command="urbit $ship -b 127.0.0.1 --http-port $port --snap-time 60 --no-dock"
      else
        command="urbit -F $ship -c $ship -b 127.0.0.1 --http-port $port --snap-time 60 --no-dock"
      fi
      if tmux has-session -t "$SESSION" 2>/dev/null; then
        tmux new-window -d -t "$SESSION" -n "$ship" -c "$STATE" "$command"
      else
        tmux new-session -d -s "$SESSION" -n "$ship" -c "$STATE" "$command"
      fi
    done
    echo "Attach: tmux attach -t $SESSION"
    ;;
  status)
    tmux list-panes -s -t "$SESSION" -F '#{window_name}: #{pane_current_command} (#{pane_current_path})'
    ;;
  dojo)
    case "${2:-}" in nec|bus|tyr) ;; *) echo 'Choose nec, bus, or tyr' >&2; exit 1;; esac
    [ "$#" -eq 3 ] || { echo 'Usage: fakenet.sh dojo SHIP "COMMAND"' >&2; exit 1; }
    tmux send-keys -t "$SESSION:$2" -l "$3"
    tmux send-keys -t "$SESSION:$2" Enter
    ;;
  sync)
    sh "$ROOT/scripts/install-to-pier.sh" "$STATE/nec"
    "$0" dojo nec '|commit %omart'
    echo 'Commit queued on ~nec; check its dojo for completion. Subscribers update over Ames.'
    ;;
  *) echo 'Usage: fakenet.sh [start|status|dojo SHIP COMMAND|sync]' >&2; exit 1;;
esac
