#!/usr/bin/env seal
--!optimize 2
--!nolint LocalShadow

local PARALLEL = true

local fs = require("@std/fs")
local args = require("@std/args")
local colors = require("@std/io/colors")
local str = require("@std/str")
local thread = require("@std/thread")
local datetime = require("@std/time/datetime")

local parsed = args.parse("lsl", "list files/directories with recentness and size, sorted by date modified or size", {
    description = "Recentness is determined by date modified, and directory size is computed recursively in parallel."
}):simple(
    args.named("--match", "optional pattern to filter by"):aliases("-m"),
    args.named("--path", "search for an explicit path instead of cwd"):aliases("-p"),
    args.named("--limit", "max number of results to display after sorting by modified"):aliases("-l"),
    args.flag("--size", "sort by size instead of modified"):aliases("-s"),
    args.flag("--norec", "omit recursive directory size checks"):aliases("-nr"),
    args.flag("--date", "show date last modified instead of duration since last modified"):aliases("-d")
)

local t0 = os.clock()

local pattern = parsed:get("--match") :: string?
local chosen_path = (parsed:get("--path") :: string?) or fs.path.cwd()
local limit_str = parsed:get("--limit") :: string?
local limit: number?
if limit_str then
    limit = tonumber(limit_str)
end
local sort_by_size = parsed.flags["--size"] or false
local omit_recursive = parsed.flags["--norec"] or false

local all_entries = fs.entries(chosen_path)

local function get_modified_at(entry: fs.Entry): DateTime
    local metadata = if entry.type == "Directory" then entry:metadata() else entry:metadata()
    local modified = metadata.modified_at
    assert(modified ~= nil, `no modified_at for {entry.path}?`)
    return modified
end

local function stringify_size(bytes: number): string
    if bytes < 1024 then
        return colors.style.dim(string.format("%d B", bytes))
    elseif bytes < 1024 * 1024 then
        return string.format("%.2f KB", bytes / 1024)
    elseif bytes < 1024 * 1024 * 1024 then
        local mb = bytes / (1024^2)
        if mb > 500 then
            return colors.yellow(string.format("%.2f MB", mb))
        else
            return string.format("%.2f MB", mb)
        end
    else
        return colors.bold.yellow(string.format("%.2f GB", bytes / (1024 * 1024 * 1024)))
    end
end

local function get_size_of_directory(dir: string): number
    local paths = fs.listdir(dir, true)
    local size = 0
    for _, path in paths do
        local entry = fs.file(path)
        if not entry then
            continue -- might be weird one like a symlink or fifo
        end
        size += entry:size()
    end
    return size
end

type EntryWithMetadata = {
    type: "File" | "Directory",
    basename: string,
    path: string,
    modified: DateTime,
    ago: string,
    size: number?
}

local entries: { EntryWithMetadata } = {}
local threads: { { path: string, handle: thread.ThreadHandle } } = {}

local function push_thread(path: string)
    local handle = thread.spawn {
        src = [====[
if channel then
    local fs = require("@std/fs")

    local function get_size_of_directory(dir: string): number
        local paths = fs.listdir(dir, true)
        local size = 0
        for _, path in paths do
            local entry = fs.file(path)
            if not entry then
                continue -- might be weird one like a symlink or fifo
            end
            size += entry:size()
        end
        return size
    end

    local path = channel.data.path :: string
    local size = get_size_of_directory(path)
    channel:send(tostring(size))
end
]====],
        data = {
            path = path,
        }
    }
    table.insert(threads, {
        path = path,
        handle = handle,
    })
end

local now = datetime.now()

for path, entry in all_entries do
    local basename = fs.path.child(path)
    assert(basename ~= nil, `no basename for {path}?`)
    local is_matching =
        if pattern == nil then
            true
        elseif string.match(basename, pattern) then
            true
        else
            false
    if is_matching then
        local modified = get_modified_at(entry)
        local size: number? = nil do
            if entry.type == "File" then
                size = entry:size()
            else
                if not omit_recursive then
                    if PARALLEL then
                        push_thread(path)
                    else
                        size = get_size_of_directory(path)
                    end
                end
            end
        end
        local ago = modified:to(now):duration():display() .. " ago"
        table.insert(entries, {
            type = entry.type,
            basename = basename,
            modified = modified,
            path = path,
            ago = ago,
            size = size,
        })
    end
end

while #threads > 0 do
    local sleep = true
    for index, info in threads do
        local size = info.handle:read()
        if size then
            for _, entry in entries do
                if entry.path == info.path then
                    entry.size = tonumber(size)
                end
            end
            info.handle:join()
            table.remove(threads, index)
            sleep = false -- we dont want to wait before iterating again if we found smth
            break -- prevent from removing > 1 index during iteration
        end
    end
    if sleep then
        thread.sleep(5)
    end
end

table.sort(entries, function(a: EntryWithMetadata, b: EntryWithMetadata)
    if sort_by_size and a.size and b.size then
        return a.size > b.size
    else
        return a.modified > b.modified
    end
end)

local max_name_len = 0
local ago_len = 0
for _, entry in entries do
    local utf8_len = str.width(entry.basename)
    if utf8_len > max_name_len then
        max_name_len = utf8_len
    end
    if #entry.ago > ago_len then
        ago_len = #entry.ago
    end
end

local total_size = 0
local lines: { string } = {}
local PIPE = colors.style.dim("│") -- box drawing thin vertical line
local DIR = colors.blue("D")

for index, entry in entries do
    local basename = entry.basename
    local needed_spaces = max_name_len - str.width(basename)
    if needed_spaces > 0 then
        basename ..= string.rep(" ", needed_spaces)
    end

    local ago = entry.ago
    local ago_needed_spaces = ago_len - #ago
    if ago_needed_spaces > 0 then
        ago ..= string.rep(" ", ago_needed_spaces)
    end

    local stringified_size = if entry.size then stringify_size(entry.size) else ""
    if entry.size then
        total_size += entry.size
    end

    table.insert(lines, `{if entry.type == "Directory" then DIR else "F"} {PIPE} {basename} {PIPE} {
        if parsed.flags["--date"] then
            entry.modified:format("MM/DD/YYYY HH:MM (AM/PM)")
        else ago
    } {PIPE} {stringified_size}`)
    if limit and index >= limit then
        break
    end
end

print(`{chosen_path}: {stringify_size(total_size)}`)
print(table.concat(lines, "\n"))

local dt = os.clock() - t0
if dt > 0.25 then
    print(colors.style.dim(`\n{if PARALLEL then "parallel" else "serial"}: {string.format("%.4f", os.clock() - t0)} seconds`))
end
