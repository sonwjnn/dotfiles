# macOS lock-screen binding research

## Conclusion

The current `shift-alt-l` binding in `aerospace.toml` uses Apple's documented **Control–Command–Q** lock-screen shortcut through System Events. I found no better documented direct lock API on this Mac. The most likely issue is a macOS privacy permission or a hidden AppleScript error—not the binding itself.

The manual command shown in the conversation was split across a newline immediately after AppleScript's `to`, which causes the reported `-2740` syntax error before any key event is sent. That does not test whether the configured one-line command works.

## Local checks

- `aerospace config --get mode.main.binding --keys` lists `shift-alt-l`.
- A temporary harmless canary, invoked with `aerospace trigger-binding --mode main -- shift-alt-l`, ran successfully. The original lock action was restored and AeroSpace reloaded afterward.
- The AppleScript compiles with `osacompile`; I did not execute it because success would lock the active session.
- A harmless query to System Events succeeds, but that does **not** prove permission to synthesize keyboard events.
- AeroSpace's `exec-and-forget` launches through `/bin/bash -c` and discards command output/status. A permission error can therefore appear as a no-op.
- On this macOS 26.1 host, the commonly cited `CGSession -suspend` path is absent. Local `man pmset` documents `displaysleepnow` as putting the display to sleep, not locking the session. `ScreenSaverEngine.app` exists, but launching a screen saver is not itself a guaranteed lock.
- The `shortcuts` CLI is installed, but no existing shortcut named `Lock Screen` was found. The CLI runs existing shortcuts; it is not itself a lock command.

## Options

| Method | What it does | Caveat |
|---|---|---|
| **System Events + Control–Command–Q (recommended)** | Requests the actual macOS Lock Screen using Apple's documented shortcut. | The invoking process may need approval under **Privacy & Security → Accessibility** and **Automation** (control System Events). Check which process macOS names in the prompt/settings; it may depend on whether AeroSpace or Terminal launches the script. |
| `open -a ScreenSaverEngine` | Starts the screen saver. | Password enforcement depends on **Lock Screen → Require password after screen saver begins or display is turned off**. It is not a guaranteed immediate lock by itself. |
| `pmset displaysleepnow` | Immediately sleeps the display. | Does not itself lock the session; password behavior depends on the same Lock Screen setting. |
| `shortcuts run <name>` | Runs a named, existing Shortcut. | Requires creating/confirming a suitable Lock Screen shortcut first; I did not verify an Apple-documented macOS Lock Screen action. |
| `CGSession -suspend` | Legacy command found in older online instructions. | The commonly cited binary is absent on this host; not a portable or documented option. |

## Recommended next step

Keep the binding as-is, then check **System Settings → Privacy & Security → Accessibility** and **Automation**. Allow the trusted process responsible for the invocation (the one named by macOS) to send keyboard events/control System Events. Press **Shift + Option + L** while AeroSpace is in `main` mode. Since `exec-and-forget` hides errors, temporary shell redirection to a log file would be useful if it still does nothing.

## Sources

1. Apple Support, [Lock the screen of your Mac](https://support.apple.com/en-us/102650) — identifies Control–Command–Q as “Lock your screen”.
2. Apple Support, [Change Lock Screen settings on Mac](https://support.apple.com/en-us/102316) — describes the password delay after screen saver starts or the display turns off.
3. Apple Mac User Guide, [Allow accessibility apps to access your Mac](https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac).
4. Apple Mac User Guide, [Allow apps to automate and control other apps](https://support.apple.com/guide/mac-help/allow-apps-to-automate-and-control-other-apps-mchl108e1718/mac).
5. AeroSpace docs, [`exec-and-forget`](https://nikitabobko.github.io/AeroSpace/commands#exec-and-forget) and [configuration guide](https://nikitabobko.github.io/AeroSpace/guide).
6. Apple Shortcuts User Guide, [Run shortcuts from the command line](https://support.apple.com/guide/shortcuts-mac/run-shortcuts-from-the-command-line-apd455c82f02/mac).
7. Local macOS `man pmset` and `/usr/bin/shortcuts help run` on the examined host.
