require "Base.attribute"
require "Base.global"

instanceof = function(o, clazz)
    return extendsof(o.__class__, clazz)
end

extendsof = function(clazz, baseClazz)
    local clazz = clazz.__class__
    local baseClazz = baseClazz.__class__
    local ret = clazz == baseClazz
    while not ret do
        local ext = clazz.base
        if ext ~= nil then
            clazz = ext.__class__
        else
            break
        end
        ret = clazz == baseClazz
    end
    return ret
end

local function searchStatic(clazz, staticField, fenvClazz, key)
    -- search public
    local vt = staticField.public[key]
    -- if in subclass, search protected
    if vt == nil and fenvClazz ~= nil and extendsof(fenvClazz, clazz) then
        vt = staticField.protected[key]
    end
    -- if in same class, search private
    if vt == nil and fenvClazz == clazz then
        vt = staticField.private[key]
    end
    return vt
end

local function searchMember(super, clazz, memberField, fenvClazz, key)
    local vt
    while vt == nil do
        -- search public
        vt = memberField.public[key]
        if vt == nil and fenvClazz and extendsof(clazz, fenvClazz) then
            vt = memberField.protected[key]
        end
        if vt == nil and fenvClazz == clazz then
            vt = memberField.private[key]
        end
        if vt == nil then
            if super == nil then
                break
            else
                memberField = super.__member__
                clazz = clazz.__class__.base
                super = rawget(super, "__super__")
            end
        end
    end
    return vt, clazz, super
end

class = attribute(function(this, attrib, className)
    return setmetatable({}, {
        __index = function(t, k)
            return function(base, chunk)
                if not chunk then
                    chunk = base
                    base = nil
                end

                local clsStaticMember = {
                    public = {},
                    protected = {},
                    private = {},
                }
                local clsMember = {
                    static = clsStaticMember,
                    public = {},
                    protected = {},
                    private = {},
                }
                
                local static = {
                    public = {},
                    protected = {},
                    private = {},
                }

                local cls = {
                    base = base,
                    name = k,
                    static = static,
                    public = {},
                    protected = {},
                    private = {},
                }
                
                local clazz = {__class__ = cls}
                clazz.__instantiate__ = function()
                    local super
                    if base then super = base.__instantiate__() end

                    local oMember = {
                        public = {},
                        protected = {},
                        private = {},
                    }
                    
                    for k, v in pairs(clsMember) do
                        if k ~= "static" then
                            for kk, vv in pairs(v) do
                                oMember[k][kk] = {val = vv.val}
                            end
                        end
                    end

                    local o = setmetatable({__member__ = oMember, __super__ = super, __class__ = clazz}, {
                        __newindex = function(_, k, v)
                            local vt = searchMember(super, clazz, oMember, getfenv(2).cls, k)
                            -- not found value, set val into public
                            if vt == nil then
                                oMember.public[k] = {val = v}
                                return
                            end
                            -- found value, update
                            vt.val = v
                        end,
                        __index = function(_, k)
                            local vt, clazz, super = searchMember(super, clazz, oMember, getfenv(2).cls, k)
                            -- found value
                            if vt ~= nil then
                                local v = vt.val
                                if isfunction(v) and not findfenv(v) then
                                    local fenv = {cls = clazz, super = super}
                                    setmetatable(fenv, {
                                        __index = function(_, k) return findfenv(v)[k] end,
                                        __newindex = function(_, k, v) findfenv(v)[k] = v end,
                                    })
                                    lockfenv(v, fenv)
                                end
                                return v
                            end
                        end,
                    })
                    return o
                end

                for k, v in pairs(cls) do
                    if k == "static" then
                        for kk, vv in pairs(v) do
                            local current = clsStaticMember[kk]
                            setmetatable(vv, {
                                __index = function(_, k)
                                    local vt = current[k]
                                    if vt == nil then return end
                                    return vt
                                end,
                                __newindex = function(_, k, v)
                                    local vt = current[k]
                                    if not vt then
                                        current[k] = {val = v}
                                        return
                                    end
                                    vt.val = v
                                    vt.fenv = nil
                                end,
                            })
                        end
                    elseif k ~= "base" and k ~= "name" then
                        local current = clsMember[k]
                        setmetatable(v, {
                            __index = nullFunc,
                            __newindex = function(_, k, v)
                                if v == nil or isfunction(v) then
                                    local vt = current[k]
                                    if vt == nil then
                                        current[k] = {val = v}
                                        return
                                    end
                                    vt.val = v
                                    vt.fenv = nil
                                end
                            end,
                        })
                    end
                end

                local meta = {__newindex = cls.public}

                getfenv(2)[k] = setmetatable(clazz, {
                    __newindex = function(_, k, v)
                        local vt = searchStatic(clazz, static, getfenv(2).cls, k)
                        -- not found value, set val into public
                        if vt == nil then
                            static.public[k] = v
                            return
                        end
                        -- found value, update
                        vt.val = v
                    end,
                    __index = function(_, k)
                        local vt = searchStatic(clazz, static, getfenv(2).cls, k)
                        -- found value
                        if vt ~= nil then
                            local v = vt.val
                            if isfunction(v) and not findfenv(v) then
                                local fenv = {cls = clazz}
                                setmetatable(fenv, {
                                    __index = function(_, k) return findfenv(v)[k] end,
                                    __newindex = function(_, k, v) findfenv(v)[k] = v end,
                                })
                                lockfenv(v, fenv)
                            end
                            return v
                        end
                    end,
                    __call = function(_, ...)
                        local o = clazz.__instantiate__()
                        o[clazz.__class__.name](o, ...)
                        return o
                    end
                })

                attrib:__fenv_meta_addIndex__(nil, setmetatable({}, meta))
                attrib.__class__ = cls
                attrib.__class_meta__ = meta
                chunk()
                attrib:__fenv_meta_removeIndex__()
                attrib:__remove__()
            end
        end,
    })
end)

public = attribute(function(this, attrib)
    attrib.__class_meta__.__newindex = attrib.__class__.public
    attrib:__remove__()
end)
protected = attribute(function(this, attrib)
    attrib.__class_meta__.__newindex = attrib.__class__.protected
    attrib:__remove__()
end)
private = attribute(function(this, attrib)
    attrib.__class_meta__.__newindex = attrib.__class__.private
    attrib:__remove__()
end)
static = attribute(function(this, attrib)
    local meta = attrib.__class_meta__
    local nowIndex = meta.__newindex
    local cls = attrib.__class__
    local static = cls.static
    local newIndex = static.public
    if nowIndex == cls.protected then
        newIndex = static.protected
    elseif nowIndex == cls.private then
        newIndex = static.private
    end
    meta.__newindex = newIndex
    local staticMeta = getmetatable(newIndex)
    local staticNowIndex = staticMeta.__newindex
    staticMeta.__newindex = function(t, k, v)
        staticMeta.__newindex = staticNowIndex
        meta.__newindex = nowIndex
        staticNowIndex(t, k, v)
    end
    attrib:__remove__()
end)