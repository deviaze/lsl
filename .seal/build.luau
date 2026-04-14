local env = require("@std/env")
local fs = require("@std/fs")
local colors = require("@std/io/colors")
local prompt = require("@std/io/prompt")
local process = require("@std/process")

local binname = if env.os == "Windows" then "lsl.exe" else "lsl"

local dedicated_lsl_location = env.vars.get("DIRECTORY_LISTER_LSL_BIN_LOCATION") or fs.dir.home():join(".local", "bin", binname)

-- compile it into binary
local res = process.shell("seal compile -o lsl") -- seal automatically adds .exe on windows
if not res.ok then
    error(`unable to compile lsl due to seal compile error: {res.err}`)
end
-- should already be chmoded on linux

local lsl_exists = fs.path.exists(dedicated_lsl_location)

if prompt.confirm(`{if lsl_exists then "Overwrite" else "Save"} {colors.blue("lsl")} binary to {colors.bold.blue(dedicated_lsl_location)}`, true) then
    if lsl_exists then
        fs.removefile(dedicated_lsl_location)
    end
    fs.move(`./{binname}`, dedicated_lsl_location)
end
