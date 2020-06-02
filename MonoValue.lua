--
local M = {}
local lib = require('_lib')
local ffi = require("ffi")

local function tostr(s)
    local p = lib.mono_string_new_len(lib.domain, s, #s)
    return check_ptr(p, 'failed to create mono string')
end

function M.string(s)
    local ty = type(s)
    if ty == 'table' then
        if iskindof(s, 'MonoInstance') then
            return tostr(s:tostring())
        end
    elseif ty == 'string' then
        return tostr(s)
    elseif ty == 'cdata' then
        if ffi.istype('MonoString*', s) then
            return s
        end
    elseif ty == 'nil' then
        return tostr('')
    end
    error("can't convert to string:", s)
    s = tostring(s)
    return lib.mono_string_new_len(lib.domain, s, #s)
end

function M.null()
    local klass = lib.mono_get_void_class()
    return lib.mono_object_new(lib.domain, klass)
end

local function cvalue(t, v)
    local ret = ffi.new(t)
    if v then
        ret[0] = v
    end
    return ret
end

function M.bool(v)
    return cvalue('bool[1]', v)
end

function M.char(v)
    return cvalue('char[1]', v)
end

function M.int(v)
    return cvalue('int[1]', v)
end

function M.uint(v)
    return cvalue('unsigned int[1]', v)
end

function M.float(v)
    return cvalue('float[1]', v)
end

function M.double(v)
    return cvalue('double[1]', v)
end

--

local enum = require('enum').MonoTypeEnum
local map = require('MonoType').ValueTypeMap

function M.fromType(t, value)
    local ret
    if type(t) ~= 'number' then
        t = require('MonoType').getILType(t)
    end
    if map[t] then
        local ctype = map[t] .. '[1]'
        ret = ffi.new(ctype)
    elseif t == enum.MONO_TYPE_STRING then
        return M.string(value)
    elseif t == enum.MONO_TYPE_VOID then
        return M.null()
    end
    if ret and value then
        ret[0] = value
    end
    return ret
end

return M
