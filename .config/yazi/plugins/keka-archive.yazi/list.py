"""Stream only as many archive rows as Yazi needs for the preview."""

from collections import deque
import os
import signal
import subprocess
import sys
import tempfile
import threading
import unicodedata

KEKA = "/Applications/Keka.app/Contents/MacOS/Keka"
TIMEOUT = 5
COMPRESSED_TAR = (".tar.gz", ".tgz", ".tar.bz2", ".tbz", ".tbz2", ".tar.xz", ".txz", ".tar.zst", ".tzst")


def safe_text(value):
    return "".join(c if unicodedata.category(c) not in ("Cc", "Cf") else "?" for c in value)


def members(lines, compressed_tar):
    if compressed_tar:
        for line in lines:
            path = line.rstrip("\r\n")
            if path:
                yield path, path.endswith("/"), 0
        return

    info = {}
    for line in lines:
        line = line.rstrip("\r\n")
        key, _, value = line.partition(" = ")
        if key == "Path" or not line:
            if "Path" in info:
                yield slt_member(info)
            info = {}
        if key in {"Path", "Folder", "Attributes", "Size"}:
            info[key] = value
    if "Path" in info:
        yield slt_member(info)


def slt_member(info):
    size = info.get("Size", "")
    return (info["Path"], info.get("Folder") == "+" or info.get("Attributes", "").startswith("D"),
            int(size) if size.isascii() and size.isdecimal() and len(size) < 20 else 0)


def tree_rows(entries):
    active = []
    seen_dirs = set()
    for path, is_dir, size in entries:
        parts = tuple(part for part in path.split("/") if part not in ("", "."))
        if not parts or "__MACOSX" in parts:
            continue
        common = 0
        while common < min(len(active), len(parts) - 1) and active[common] == parts[common]:
            common += 1
        for depth in range(common, len(parts) - (not is_dir)):
            directory = parts[: depth + 1]
            if directory not in seen_dirs:
                seen_dirs.add(directory)
                yield depth, "d", 0, safe_text(parts[depth])
        if not is_dir:
            yield len(parts) - 1, "f", size, safe_text(parts[-1])
        active = parts if is_dir else parts[:-1]


def preview(path, skip, limit):
    path = os.path.abspath(path)
    compressed_tar = path.lower().endswith(COMPRESSED_TAR)
    if compressed_tar:
        args = [KEKA, "--cli", "tar", "-tf", path]
    else:
        password = os.getenv("YAZI_KEKA_PASSWORD") or "-"
        args = [KEKA, "--cli", "7zz", "l", "-ba", "-slt", "-sccUTF-8", "-p" + password, "--", path]

    page = deque(maxlen=limit)
    count = 0
    page_ready = False
    timed_out = threading.Event()
    try:
        with tempfile.TemporaryFile() as errors, subprocess.Popen(
            args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=errors,
            text=True, encoding="utf-8", errors="replace", start_new_session=True,
        ) as proc:
            def stop():
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass

            def expire():
                timed_out.set()
                stop()

            timer = threading.Timer(TIMEOUT, expire)
            timer.start()
            try:
                first_lines = []
                def output_lines():
                    for line in proc.stdout:
                        if len(first_lines) < 8:
                            first_lines.append(line[:1000])
                        yield line

                for row in tree_rows(members(output_lines(), compressed_tar)):
                    count += 1
                    page.append(row)
                    if count >= skip + limit:
                        page_ready = True
                        stop()
                        break
                status = proc.wait()
            finally:
                timer.cancel()
                timer.join()
                if proc.poll() is None:
                    stop()
            errors.seek(0)
            error = (errors.read(8192).decode(errors="replace") + "".join(first_lines)).lower()
    except OSError:
        print("Could not start Keka CLI. Check /Applications/Keka.app.")
        return

    if timed_out.is_set():
        print(f"Keka preview timed out ({TIMEOUT}s). Open with Keka instead.")
    elif status != 0 and not page_ready:
        if "wrong password" in error or "encrypted archive" in error:
            print("Password required or incorrect. Open with Keka to enter it.")
        elif "no file access" in error:
            print("Keka has no access to this folder. Check Keka's file access settings.")
        else:
            print("Keka could not list this archive. Open it with Keka to check.")
    elif not page:
        print("Archive is empty.")
    else:
        print(f"OK\t{max(0, count - limit)}")
        for depth, kind, size, name in page:
            print(f"{depth}\t{kind}\t{size}\t{name}")


if __name__ == "__main__":
    preview(sys.argv[1], int(sys.argv[2]), max(1, int(sys.argv[3])))
