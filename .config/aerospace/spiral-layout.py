"""Keep the AeroSpace spiral ordered and preserve existing split proportions."""

from contextlib import contextmanager
import fcntl
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import tomllib

from spiral_geometry import read_layout, window_frames


AEROSPACE = "/opt/homebrew/bin/aerospace"
TILES = {"h_tiles", "v_tiles"}
ACCORDION = {"h_accordion", "v_accordion"}
CACHE = Path.home() / "Library/Caches/AeroSpaceSpiral"
CONFIG = Path(__file__).with_name("aerospace.toml")
FIELDS = (
    "%{window-id} %{workspace} %{window-layout} %{workspace-root-container-layout} "
    "%{window-is-fullscreen} %{workspace-is-visible} %{monitor-id}"
)


def aerospace(*args, check=True):
    return subprocess.run(
        [AEROSPACE, *args], capture_output=True, text=True, check=check, timeout=15
    )


def list_windows(*args):
    return json.loads(aerospace("list-windows", *args, "--format", FIELDS, "--json").stdout)


def grouped(snapshot):
    workspaces = {}
    for row in snapshot:
        workspaces.setdefault(row["workspace"], []).append(row)
    return workspaces


def tiled_ids(rows):
    return [row["window-id"] for row in rows if row["window-layout"] in TILES]


def can_arrange(rows):
    return all(
        row["window-layout"] not in ACCORDION
        and not row["window-is-fullscreen"]
        and row["workspace-root-container-layout"] in TILES
        for row in rows
    )


def capture(rows, frames, exclude=()):
    if not rows or not rows[0]["workspace-is-visible"] or not can_arrange(rows):
        return None
    axis = 0 if rows[0]["workspace-root-container-layout"] == "h_tiles" else 1
    layout = read_layout([wid for wid in tiled_ids(rows) if wid not in exclude], frames, axis)
    if layout:
        layout["monitor"] = rows[0]["monitor-id"]
    return layout


def tree_commands(workspace, order, root):
    commands = [f"flatten-workspace-tree --workspace {workspace}"]
    back, forward = ("left", "right") if root == "h_tiles" else ("up", "down")
    for wid in reversed(order):
        step = f"(move --window-id {wid} --boundaries-action fail {back} || true)"
        commands.extend([step] * (len(order) - 1))
    for index in range(len(order) - 2, 0, -1):
        wid = order[index]
        commands.append(f"join-with --window-id {wid} {forward}")
        if index % 2 == 0:
            commands.append(f"layout --window-id {wid} {root}")
    return commands


def restore_proportions(order, root, geometry):
    ratios = geometry.get("ratios", {})
    size = list(geometry.get("size", ()))
    if not ratios or len(size) != 2:
        return
    with CONFIG.open("rb") as handle:
        inner = tomllib.load(handle).get("gaps", {}).get("inner", {})
    gaps = [inner.get("horizontal", 0), inner.get("vertical", 0)]
    axis = 0 if root == "h_tiles" else 1
    for wid in order[:-1]:
        gap = gaps[axis]
        if not isinstance(gap, (int, float)):
            break
        ratio = ratios.get(str(wid))
        span = size[axis]
        if ratio is not None and 0 < ratio < 1 and span > gap:
            weight = max(1, min(round(span) - 1, round(span * ratio)))
            aerospace("resize", "--window-id", str(wid), "smart", str(weight))
        else:
            weight = span / 2
        size[axis] = span - weight - gap / 2
        axis = 1 - axis


def arrange(workspace, rows, state, incoming=(), frames=None, before_move=None):
    if not re.fullmatch(r"[0-9A-Za-z_-]+", workspace):
        return
    record = state.setdefault(workspace, {})
    ids = tiled_ids(rows)
    pending = list(dict.fromkeys([*record.get("pending", []), *incoming]))
    pending = [wid for wid in pending if wid in ids]
    record["pending"] = pending
    if not ids:
        state.pop(workspace, None)
        return
    if not can_arrange(rows):
        return
    root = rows[0]["workspace-root-container-layout"]
    geometry = before_move or record.get("geometry", {})
    old = [wid for wid in ids if wid not in pending]
    prior_order = geometry.get("order", record.get("order", []))
    if any(wid not in prior_order for wid in old) or not geometry:
        current = capture(rows, frames or {}, exclude=pending)
        if current:
            geometry = current
            prior_order = current["order"]
    if len(old) <= 1:
        prior_order = old
    if any(wid not in prior_order for wid in old):
        # Hidden workspaces park their windows at overlapping coordinates.
        # Wait until all existing windows can be read in their visual order.
        return
    if geometry and rows[0]["monitor-id"] != geometry.get("monitor"):
        current = capture(rows, frames or {}, exclude=pending)
        if current is None and len(old) > 1:
            return
        geometry = current or {}
    order = [wid for wid in prior_order if wid in old] + pending
    if len(order) >= 3 or record.get("managed"):
        aerospace("eval", " && ".join(tree_commands(workspace, order, root)))
        restore_proportions(order, root, geometry)
    record.update(order=order, pending=[], managed=True)
    # Keep the restored ratios for hidden workspaces until visible again.
    # The observer can refresh them from real frames on the next stable sample.
    if geometry:
        record["geometry"] = {
            **geometry,
            "order": order,
            "ratios": {key: ratio for key, ratio in geometry.get("ratios", {}).items()
                       if int(key) in order},
        }


@contextmanager
def locked_state():
    CACHE.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (CACHE / "lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state_file = CACHE / "layout-v2.json"
        initialize = False
        try:
            state = json.loads(state_file.read_text())
        except FileNotFoundError:
            initialize = True
            state = {}
            legacy_file = CACHE / "order.json"
            if legacy_file.exists():
                try:
                    legacy = json.loads(legacy_file.read_text())
                except json.JSONDecodeError:
                    legacy = {}
                current = grouped(list_windows("--all"))
                for workspace, order in legacy.items():
                    if order and set(order) == set(tiled_ids(current.get(workspace, []))):
                        state[workspace] = {"order": order, "managed": True}
        except json.JSONDecodeError:
            initialize = True
            state = {}
        previous = json.dumps(state)
        yield state
        updated = json.dumps(state)
        if initialize or updated != previous:
            temp = state_file.with_suffix(".tmp")
            temp.write_text(updated)
            temp.replace(state_file)


def observe():
    with locked_state() as state:
        spaces = grouped(list_windows("--all"))
        frames = window_frames()
        if not frames:
            return
        for workspace in state.keys() | spaces.keys():
            rows = spaces.get(workspace, [])
            record = state.get(workspace, {})
            ids = tiled_ids(rows)
            previous = record.get("order", [])
            present = {row["window-id"] for row in rows}
            missing = set(previous) - present
            # A closed app can keep its old WindowServer surface alive.
            # Require two AeroSpace snapshots before treating an ID as gone.
            closed = bool(missing.intersection(record.get("missing", [])))
            if missing:
                record["missing"] = sorted(missing)
            else:
                record.pop("missing", None)
            if record.get("pending") or (record.get("managed") and closed):
                arrange(workspace, rows, state, frames=frames)
                continue
            if not rows:
                if closed:
                    state.pop(workspace, None)
                continue
            # Let the new-window callback use the last stable pre-insert frame.
            if previous and (set(ids) - set(previous) or record.get("managed") and set(previous) != set(ids)):
                continue
            geometry = capture(rows, frames)
            if geometry:
                record = state.setdefault(workspace, {})
                record.update(geometry=geometry, order=geometry["order"])


def watch():
    while True:
        try:
            observe()
        except (OSError, subprocess.SubprocessError, ValueError) as error:
            print(error, file=sys.stderr, flush=True)
        time.sleep(0.85)


def move_or_insert(destination):
    window_id = os.environ.get("AEROSPACE_WINDOW_ID", "")
    if destination and not window_id:
        focused = aerospace("list-windows", "--focused", "--format", "%{window-id}", check=False)
        window_id = focused.stdout.strip()
    if not window_id.isdecimal():
        return
    window_id = int(window_id)

    with locked_state() as state:
        spaces = grouped(list_windows("--all"))
        source = next((ws for ws, rows in spaces.items()
                       if any(row["window-id"] == window_id for row in rows)), None)
        if source is None or source == destination:
            return
        rows = spaces[source]
        tiled = window_id in tiled_ids(rows)
        if destination:
            frames = window_frames() if tiled else {}
            source_geometry = capture(rows, frames)
            dest_geometry = capture(spaces.get(destination, []), frames)
            aerospace("move-node-to-workspace", "--window-id", str(window_id), "--", destination)
            if tiled:
                arrange(destination, list_windows("--workspace", destination), state,
                        [window_id], window_frames(), dest_geometry)
                if state.get(source, {}).get("managed"):
                    arrange(source, list_windows("--workspace", source), state,
                            before_move=source_geometry)
        elif tiled:
            record = state.get(source, {})
            if not record.get("managed") or window_id not in record.get("order", []):
                arrange(source, rows, state, [window_id], window_frames())


if __name__ == "__main__":
    try:
        argument = sys.argv[1] if len(sys.argv) > 1 else ""
        if argument == "--watch":
            watch()
        else:
            move_or_insert(argument)
    except (OSError, subprocess.SubprocessError, ValueError) as error:
        print(getattr(error, "stderr", None) or error, file=sys.stderr)
        sys.exit(1)
