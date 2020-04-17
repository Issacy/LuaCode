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

local function dumping(object, prefix, label, indent, nest, maxNesting, lookupTable, dumpPrint)
    nest = isnumber(nest) and nest or 1
    maxNesting = isnumber(maxNesting) and maxNesting or 99
    lookupTable = lookupTable or {}

    if not istable(object) then
        dumpPrint(string.format("%s%s = %s",
            indent, tostring(label), tostring(object)))
    else
        local ref = lookupTable[object]
        if ref ~= nil then
            dumpPrint(string.format("%s%s = *REF(%s)*",
                indent, tostring(label), tostring(ref)))
        else
            local path = prefix == nil and label or string.format("%s.%s",
                tostring(prefix), tostring(label))
            lookupTable[object] = path
            if nest > maxNesting then
                dumpPrint(string.format("%s%s = *MAX NESTING*",indent, label))
            else
                dumpPrint(string.format("%s%s = {", indent, tostring(label)))
                for k, v in pairs(object) do
                    dumping(v, path, k, indent .. "    ", nest+1, maxNesting, lookupTable, dumpPrint)
                end
                dumpPrint(string.format("%s}", indent))
            end
        end
    end
end

dump2String = function(object, label, maxNesting)
    local arr = {}
    dumping(object, nil, label or "var", " - ", nil, maxNesting, nil, function(s)
        table.insert(arr, s)
    end)
    return table.concat(arr, "\n")
end

dump = function(object, label, maxNesting, dumpPrint)
    (dumpPrint or print)(dump2String(object, label, maxNesting))
end

cond = function(case, ret1, ret2) if case then return ret1 else return ret2 end end

switch = setmetatable({Break = 1, Fall = 2,}, {
    __index = nullFunc,
    __newIndex = nullFunc,
    __call = function(t, dealVal)
        local switchCase = {}
        switchCase.cases = {}
        switchCase.defaultCall = nil
        function switchCase:case(...)
            local vals = {}
            local len = select("#", ...)
            assert(len >= 2,"case error, params need at least one case and call")
            local call = select(len, ...)
            assert(isfunction(call), "case error, the last param must be function")
            for i = 1, len-1 do
                vals[select(i, ...)] = true
            end
            table.insert(self.cases, {vals = vals, call = call})
            return self
        end
        function switchCase:default(call)
            assert(isfunction(call), "default error, param must be function")
            self.defaultCall = call
            return self
        end
        function switchCase:deal(val)
            if val ~= nil then dealVal = val end
            local ret = nil
            local fall = false
            for _,v in ipairs(self.cases) do
                if fall or v.vals[dealVal] then
                    fall = false
                    ret = v.call() or t.Break
                    if ret == t.Break then
                        break
                    else
                        fall = true
                    end
                end
            end
            if ret == nil or fall then
                local call = self.defaultCall
                if isfunction(call) then
                    call()
                end
            end
            return self
        end
        return switchCase
    end,
})

enum = function()
    local enums = {}
    local lastVal = -1
    local curKey = nil
    local sw = switch()
    :case("string", function()
        lastVal = enums[lastVal]
    end)
    :case("function", function()
        lastVal = lastVal(enums)
    end)
    :case("nil", function()
        lastVal = lastVal+1
    end)
    :case("number", nullFunc)
    :default(function()
        assert(false, "enum error, value type error")
    end)
    local define = function(val)
        lastVal = val or lastVal
        sw:deal(type(val))
        enums[curKey] = lastVal
        return enums
    end
    return setmetatable(enums, {
        __index = function(self, key)
            curKey = key
            return define
        end,
        __call = function(self, arg, loopIdx) return next(enums, loopIdx) end,
    })
end
