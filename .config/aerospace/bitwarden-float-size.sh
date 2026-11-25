#!/bin/bash

sleep 0.2

osascript <<'APPLESCRIPT'
tell application "Finder"
  set desktop_bounds to bounds of window of desktop
end tell

set target_width to 900
set target_height to 720
set desktop_left to item 1 of desktop_bounds
set desktop_top to item 2 of desktop_bounds
set desktop_right to item 3 of desktop_bounds
set desktop_bottom to item 4 of desktop_bounds
set target_left to desktop_left + ((desktop_right - desktop_left - target_width) / 2)
set target_top to desktop_top + ((desktop_bottom - desktop_top - target_height) / 2)

tell application "System Events"
  if exists process "Bitwarden" then
    tell process "Bitwarden"
      repeat with bitwarden_window in windows
        try
          set size of bitwarden_window to {target_width, target_height}
          set position of bitwarden_window to {target_left, target_top}
        end try
      end repeat
    end tell
  end if
end tell
APPLESCRIPT
