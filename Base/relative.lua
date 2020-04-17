require "Base.attribute"

--[[
    @desc 将当前lua文件增加相对路径引用使用的环境变量
          在文件顶部使用, 使用形式为relative(...)
          之后本文件内可以使用import(relative_path)
]]
relative = attribute(function(this, attrib, file)
    file = file or ""
    attrib.__file__ = file
    attrib.__relative__ = string.gsub(file, "[^./\\]+$", "")
end)

--[[
    @desc 相对路径require, 不支持向上查找".."
]]
import = attribute(function(this, attrib, name)
    local relative = attrib.__relative__ or ""
    attrib:__remove__()
    return require(relative .. name)
end)
