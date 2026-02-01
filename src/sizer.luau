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
