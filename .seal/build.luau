local env = require("@std/env")
local fs = require("@std/fs")
local colors = require("@std/io/colors")
local process = require("@std/process")
local str = require("@std/str")

local target_dir = fs.path.join(fs.path.home(), ".local", "bin", "lsl")

process.shell("seal compile -o lsl.luau"):unwrap()

local lines: { string } = { "#!/usr/bin/env seal" }
for index, line in fs.readlines("./lsl.luau") do
    if str.endswith(line, "===]") then -- fix stupid mistake in seal compile
        line ..= ","
    end
    table.insert(lines, line)
end

fs.writefile("./lsl.luau", table.concat(lines, "\n"))
fs.copy("./lsl.luau", "./lsl")

if env.os ~= "Windows" then
    process.shell("chmod +x ./lsl"):unwrap()
end

fs.move("./lsl", target_dir)

print(`Built, fixed, and moved lsl to {colors.red(target_dir)}`)