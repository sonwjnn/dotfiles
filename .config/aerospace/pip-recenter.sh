#!/bin/bash

osascript <<-'EOF'
  with timeout of 3 seconds
    tell application "System Events"
      repeat with proc in (application processes whose background only is false)
        try
          repeat with w in windows of proc
            try
              set windowTitle to name of w
              if windowTitle contains "Picture in Picture" or windowTitle contains "Picture-in-Picture" then
                set position of w to {100, 100}
                set size of w to {480, 270}
              end if
            end try
          end repeat
        end try
      end repeat
    end tell
  end timeout
EOF
