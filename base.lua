--

local setmetatableindex_
setmetatableindex_ = function(t, index)
    if type(t) == "userdata" then
        error('not supported')
    else
        local mt = getmetatable(t)
        if not mt then
            mt = {}
        end
        if not mt.__index then
            mt.__index = index
            setmetatable(t, mt)
        elseif mt.__index ~= index then
            setmetatableindex_(mt, index)
        end
    end
end
local setmetatableindex = setmetatableindex_

local ffi = require('ffi')
local function dtor_proxy(ins, dtor)
    if dtor then
        ins['.dtor_proxy'] = ffi.gc(
                ffi.new('int32_t[0]'),
                function()
                    dtor(ins)
                end
        )
    end
end

function class(classname, ...)
    local cls = { __cname = classname }

    local supers = { ... }
    for _, super in ipairs(supers) do
        local superType = type(super)
        assert(superType == "nil" or superType == "table" or superType == "function",
               string.format("class() - create class \"%s\" with invalid super class type \"%s\"",
                             classname, superType))

        if superType == "function" then
            assert(cls.__create == nil,
                   string.format("class() - create class \"%s\" with more than one creating function",
                                 classname));
            -- if super is function, set it to __create
            cls.__create = super
        elseif superType == "table" then
            if super[".isclass"] then
                -- super is native class
                error('not supported')
            else
                -- super is pure lua class
                cls.__supers = cls.__supers or {}
                cls.__supers[#cls.__supers + 1] = super
                if not cls.super then
                    -- set first super pure lua class as class.super
                    cls.super = super
                end
            end
        else
            error(string.format("class() - create class \"%s\" with invalid super type",
                                classname), 0)
        end
    end

    cls.__index = cls
    local __call = function(_, ...)
        return cls.new(...)
    end
    if not cls.__supers or #cls.__supers == 1 then
        setmetatable(cls, { __index = cls.super, __call = __call })
    else
        setmetatable(cls, {
            __index = function(_, key)
                local supers = cls.__supers
                for i = 1, #supers do
                    local super = supers[i]
                    if super[key] then
                        return super[key]
                    end
                end
            end,
            __call  = __call })
    end

    if not cls.ctor then
        -- add default constructor
        cls.ctor = function()
        end
    end
    local meta_method
    cls.new = function(...)
        local instance
        if cls.__create then
            instance = cls.__create(...)
        else
            instance = {}
        end
        setmetatableindex(instance, cls)
        instance.class = cls
        instance['.class'] = cls
        instance['.classname'] = classname

        local mt = getmetatable(instance)
        -- set once
        if not meta_method then
            meta_method = {}
            for _, v in ipairs(
                    { '__add', '__sub', '__mul', '__div', '__mod', '__pow', '__unm',
                      '__concat', '__len', '__eq', '__lt', '__le',
                      '__index', '__newindex', '__call', '__tostring', '__tonumber' }) do
                meta_method[v] = instance[v]
            end
        end
        for k, v in pairs(meta_method) do
            rawset(mt, k, v)
        end
        mt.__supers = cls.__supers
        mt.__cname = cls.__cname
        dtor_proxy(instance, cls.dtor)

        instance:ctor(...)
        return instance
    end
    cls.create = function(_, ...)
        return cls.new(...)
    end

    return cls
end

function getclassname(obj)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then
        return
    end
    local ret
    ret = ret or obj['.classname']
    ret = ret or obj.__cname
    local mt
    if t == "userdata" then
        error('not supported')
    else
        mt = getmetatable(obj)
    end
    if not mt then
        return ret
    end
    ret = ret or rawget(mt, '.classname')
    ret = ret or rawget(mt, '__cname')
    local index = rawget(mt, '__index')
    if index then
        ret = ret or rawget(index, '.classname')
        ret = ret or rawget(index, '__cname')
    end
    return ret
end

local iskindof_
iskindof_ = function(cls, name)
    local __index = rawget(cls, "__index")
    if type(__index) == "table" and rawget(__index, "__cname") == name then
        return true
    end

    if rawget(cls, "__cname") == name then
        return true
    end
    local __supers = rawget(__index, "__supers")
    if not __supers then
        return false
    end
    for _, super in ipairs(__supers) do
        if iskindof_(super, name) then
            return true
        end
    end
    return false
end

function iskindof(obj, classname)
    local t = type(obj)
    if t ~= "table" and t ~= "userdata" then
        return false
    end

    local mt
    if t == "userdata" then
        error('not supported')
    else
        mt = getmetatable(obj)
    end
    if mt then
        return iskindof_(mt, classname)
    end
    return false
end

require('ffi_util')

function check_ptr(p, msg, ...)
    if ffi.isnullptr(p) then
        if msg then
            error(msg:format(...))
        else
            error(('invalid pointer %s'):format(tostring(p)))
        end
    end
    return p
end

function make_param(...)
    local n = select("#", ...)
    if n == 0 then
        return nil
    end
    local args = { ... }
    local param = ffi.new("void*[?]", n)
    for i = 1, n do
        local arg = args[i]
        local ty = type(arg)
        if ty == 'table' then
            arg = arg._hdl
        elseif ty == 'string' then
            arg = require('MonoValue').string(arg)
        end
        param[i - 1] = ffi.cast("void*", arg)
    end
    return param
end
