require "Base.attribute"

local getNextNamespace = function(attrib, currentNamespace, name, baseNamespace)
    baseNamespace = baseNamespace or _G
    -- search if in any namespace
    local inNamespace = currentNamespace or attrib.__namespace__ or baseNamespace
    currentNamespace = inNamespace[name] -- search if defined
    if not currentNamespace then -- if not defined then create
        currentNamespace = {}
        inNamespace[name] = currentNamespace
    end
    return currentNamespace
end

namespace = attribute(function(this, attrib, baseNamespace)
    local currentNamespace
    return setmetatable({}, {
        __index = function(t, k)
            currentNamespace = getNextNamespace(attrib, currentNamespace, k, baseNamespace)
            return t
        end,
        __call = function(_, chunk) -- set current namespace
            attrib.__namespace__ = currentNamespace
            attrib:__fenv_meta_addIndex__(currentNamespace, currentNamespace)
            chunk()
            attrib:__fenv_meta_removeIndex__()
            attrib:__remove__()
        end,
    })
end)

usingNamespace = attribute(function(this, attrib, baseNamespace)
    local currentNamespace
    return setmetatable({}, {
        __index = function(t, k)
            currentNamespace = getNextNamespace(attrib, currentNamespace, k, baseNamespace)
            return t
        end,
        __call = function()
            attrib.__namespace__ = currentNamespace
            attrib:__fenv_meta_addIndex__(currentNamespace)
        end,
    })
end)