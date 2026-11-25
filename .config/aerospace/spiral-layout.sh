#!/bin/bash
# Window routing callbacks run before the new-window layout pass.
if [ "$#" -eq 0 ]; then
  sleep 0.15
fi
exec /opt/homebrew/bin/python3 -B /Users/sonwin/.config/aerospace/spiral-layout.py "$@"
