require "Base.attribute"

--[[
    add file's full path and dir into env,
    better use in top of the file,
    then can use import(relpath)
]]
relative = attribute(function(this, attrib, file)
    file = file or ""
    attrib.__file__ = file
    attrib.__dir__ = string.gsub(file, "[^./\\]+$", "")
end)

--[[
    require file in relative path,
    dont support back search '..'
]]
import = attribute(function(this, attrib, relpath)
    local dir = attrib.__dir__ or ""
    attrib:__remove__()
    return require(dir .. relpath)
end)
