"""Read window frames from WindowServer and recover their tiling order."""

import ctypes as ct
import plistlib


def _function(library, name, result, *arguments):
    function = getattr(library, name)
    function.argtypes = arguments
    function.restype = result
    return function


_cf = ct.CDLL("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
_cg = ct.CDLL("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics")
_ptr = ct.c_void_p
_copy_windows = _function(_cg, "CGWindowListCopyWindowInfo", _ptr, ct.c_uint32, ct.c_uint32)
_plist_data = _function(_cf, "CFPropertyListCreateData", _ptr, _ptr, _ptr, ct.c_long, ct.c_ulong, _ptr)
_length = _function(_cf, "CFDataGetLength", ct.c_long, _ptr)
_bytes = _function(_cf, "CFDataGetBytePtr", _ptr, _ptr)
_release = _function(_cf, "CFRelease", None, _ptr)


def window_frames():
    windows = _copy_windows(16, 0)  # Exclude desktop elements.
    if not windows:
        return {}
    try:
        data = _plist_data(None, windows, 200, 0, None)  # Binary plist.
        if not data:
            return {}
        try:
            rows = plistlib.loads(ct.string_at(_bytes(data), _length(data)))
        finally:
            _release(data)
    finally:
        _release(windows)
    return {
        row["kCGWindowNumber"]: (box["X"], box["Y"], box["Width"], box["Height"])
        for row in rows
        if (box := row.get("kCGWindowBounds")) and box["Width"] > 0 and box["Height"] > 0
    }


def read_layout(ids, frames, root_axis):
    if not ids or any(wid not in frames for wid in ids):
        return None
    # Frames can differ by a point due to WindowServer rounding.
    tolerance = 2
    ratios = {}

    def extent(group, axis):
        start = min(frames[wid][axis] for wid in group)
        end = max(frames[wid][axis] + frames[wid][axis + 2] for wid in group)
        return start, end

    def walk(group, preferred):
        if len(group) == 1:
            return group
        for axis in (preferred, 1 - preferred):
            ordered = sorted(group, key=lambda wid: frames[wid][axis])
            edge = float("-inf")
            for index, wid in enumerate(ordered[:-1], 1):
                edge = max(edge, frames[wid][axis] + frames[wid][axis + 2])
                next_edge = frames[ordered[index]][axis]
                if next_edge < edge - tolerance:
                    continue
                first, rest = ordered[:index], ordered[index:]
                left = walk(first, 1 - axis)
                right = walk(rest, 1 - axis)
                if left is None or right is None:
                    return None
                if len(first) == 1:
                    start, end = extent(group, axis)
                    ratios[str(wid)] = ((edge + next_edge) / 2 - start) / (end - start)
                return left + right
        return None

    order = walk(list(ids), root_axis)
    if order is None:
        return None
    return {
        "order": order,
        "ratios": ratios,
        "size": [end - start for start, end in (extent(order, 0), extent(order, 1))],
    }
