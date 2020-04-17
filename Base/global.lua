nullFunc = function() end

isfunction = function(o) return type(o) == "function" end
isnumber = function(o) return type(o) == "number" end
istable = function(o) return type(o) == "table" end
isstring = function(o) return type(o) == "string" end
isboolean = function(o) return type(o) == "boolean" end

local fenvs = {}
local orgSetFenv = setfenv
lockfenv = function(target, fenv)
    local func = debug.getinfo(isfunction(target) and target or target+1).func
    fenvs[func] = getfenv(func)
    orgSetFenv(func, setmetatable({
        unlockfenv = function()
            local fenv = fenvs[func]
            fenvs[func] = nil
            orgSetFenv(func, fenv)
        end
    }, {__index = fenv, __newindex = fenv}))
    return func
end
findfenv = function(func) return fenvs[func] end
setfenv = function(target, fenv)
    local func = debug.getinfo(isfunction(target) and target or target+1).func
    if fenvs[func] then
        fenvs[func] = fenv
    else
        orgSetFenv(func, fenv)
    end
end
