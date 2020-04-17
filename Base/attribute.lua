require "Base.global"

local attributes = function()
    local attribs = {}
    local attribsIndex = {}
    local obj
    local index = function(self, k)
        local attrib, v
        for i = attribsIndex[self]-1, 1, -1 do
            v = rawget(attribs[i], k)
            if v ~= nil then return v end
        end
        return obj[k]
    end
    local remove = function(attrib)
        local index = attribsIndex[attrib]
        if not index then return end
        attribsIndex[attrib] = nil
        table.remove(attribs, index)
        for i = index, #attribs do
            attribsIndex[attribs[i]] = i
        end
    end
    obj = {
        __new__ = function()
            local attrib = setmetatable({
                __remove__ = remove,
            }, {__index = index})
            table.insert(attribs, attrib)
            attribsIndex[attrib] = #attribs
            return attrib
        end,
        __last__ = function() return attribs[#attribs] end,
    }
    return obj
end

attribute = function(startFunc)
    local this
    this = setmetatable({}, {
        __index = nullFunc,
        __call = function(t, ...)
            local fenv = getfenv(2)
            local attribs = fenv.__attributes__

            if not attribs then
                attribs = attributes()
                local metaIndex = {}
                local metaIndexByAttrib = {}

                attribs.__fenv_meta_addIndex__ = function(attrib, index, newindex)
                    local origin = metaIndexByAttrib[attrib]
                    if origin then
                        local metaIndex = metaIndex[origin]
                        metaIndex.index = index
                        metaIndex.newindex = newindex
                        return
                    end
                    table.insert(metaIndex, {attrib = attrib, index = index, newindex = newindex})
                    metaIndexByAttrib[attrib] = #metaIndex
                end
                attribs.__fenv_meta_removeIndex__ = function(attrib)
                    local index = metaIndexByAttrib[attrib]
                    if not index then return end
                    metaIndexByAttrib[attrib] = nil
                    table.remove(metaIndex, index)
                    for i = index, #metaIndex do
                        metaIndexByAttrib[metaIndex[i].attrib] = i
                    end
                end
                local newfenv = {__attributes__ = attribs}
                local lock
                setmetatable(newfenv, {
                    __index = function(t, k)
                        local v, index
                        for i = #metaIndex, 1, -1 do
                            index = metaIndex[i].index
                            if istable(index) then
                                v = index[k]
                            elseif isfunction(index) then
                                v = index(t, k)
                            end
                            if v ~= nil then return v end
                        end
                        return findfenv(lock)[k]
                    end,
                    __newindex = function(t, k, v)
                        local newindex, hasSet
                        for i = #metaIndex, 1, -1 do
                            newindex = metaIndex[i].newindex
                            if istable(newindex) then
                                newindex[k] = v
                                hasSet = true
                                break
                            elseif isfunction(newindex) then
                                newindex(t, k, v)
                                hasSet = true
                                break
                            end
                        end
                        if not hasSet then
                            findfenv(lock)[k] = v
                        end
                    end
                })
                lock = lockfenv(2, newfenv)
            end
            
            local ret
            if startFunc then ret = startFunc(this, attribs:__new__(), ...) end
            return ret
        end
    })

    return this
end
