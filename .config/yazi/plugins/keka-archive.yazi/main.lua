local M = {}

function M:peek(job)
	local helper = "/Users/sonwin/.config/yazi/plugins/keka-archive.yazi/list.py"
	local output = Command("/opt/homebrew/bin/python3")
		:arg({ helper, tostring(job.file.path), tostring(job.skip), tostring(job.area.h) })
		:stdin(Command.NULL):stdout(Command.PIPED):stderr(Command.NULL):output()
	local header, rows = (output and output.stdout or ""):match("^([^\n]+)\n(.*)$")
	local bound = header and tonumber(header:match("^OK\t(%d+)$"))
	if not bound then
		local message = header or "Could not start Keka preview."
		return ya.preview_widget(job, ui.Text(message):area(job.area))
	elseif job.skip > bound then
		return ya.emit("peek", { bound, only_if = job.file.url, upper_bound = true })
	end

	-- Match Yazi's built-in archive preview: themed icon, indentation, file size.
	local left, right = {}, {}
	for row in rows:gmatch("[^\n]+") do
		local depth, kind, size, name = row:match("^(%d+)\t([df])\t(%d+)\t(.+)$")
		if depth then
			local icon = th.icon:match(File {
				url = Url(Path.os(name)),
				cha = Cha { mode = tonumber(kind == "d" and "40700" or "100644", 8) },
			})
			local span = icon and ui.Span(" " .. icon.text .. " "):style(icon.style) or ui.Span(" ")
			local bytes = tonumber(size)
			local size_label = bytes > 0 and " " .. ya.readable_size(bytes) .. " " or " "
			local width = math.max(0, job.area.w - ui.width(span) - ui.width(size_label))
			local indent = string.rep(" │", math.min(tonumber(depth), math.max(0, (width - 8) // 2)))
			left[#left + 1] = ui.Line { indent, span, ui.truncate(name, { max = width - ui.width(indent) }) }
			right[#right + 1] = size_label
		end
	end
	ya.preview_widget(job, {
		ui.Text(left):area(job.area),
		ui.Text(right):area(job.area):align(ui.Align.RIGHT),
	})
end

function M:seek(job) require("code"):seek(job) end

return M
