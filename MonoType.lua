--
local M = {}
local lib = require('_lib')
local ffi = require("ffi")

function M.isByref(t)
    return lib.mono_type_is_byref(check_ptr(t)) > 0
end

function M.getPtrType(t)
    return lib.mono_type_get_ptr_type(check_ptr(t))
end

function M.getArrayType(t)
    return lib.mono_type_get_array_type(check_ptr(t))
end

function M.getClass(t)
    --return lib.mono_type_get_class(check_ptr(t))
    return lib.mono_class_from_mono_type(check_ptr(t))
end

function M.isStruct(t)
    return lib.mono_type_is_struct(check_ptr(t)) > 0
end

function M.isVoid(t)
    return lib.mono_type_is_void(check_ptr(t)) > 0
end

function M.isPointer(t)
    return lib.mono_type_is_pointer(check_ptr(t)) > 0
end

function M.isReference(t)
    return lib.mono_type_is_reference(check_ptr(t)) > 0
end

function M.isGenericParameter(t)
    return lib.mono_type_is_generic_parameter(check_ptr(t)) > 0
end

--- MonoTypeEnum
function M.getILType(t)
    return tonumber(lib.mono_type_get_type(check_ptr(t)))
end

local enum = require('enum').MonoTypeEnum
local map = {
    --[enum.MONO_TYPE_END]     = "",
    --[enum.MONO_TYPE_VOID]    = "",
    [enum.MONO_TYPE_BOOLEAN] = "bool",
    [enum.MONO_TYPE_CHAR]    = "char",
    [enum.MONO_TYPE_I1]      = "int8_t",
    [enum.MONO_TYPE_U1]      = "uint8_t",
    [enum.MONO_TYPE_I2]      = "int16_t",
    [enum.MONO_TYPE_U2]      = "uint16_t",
    [enum.MONO_TYPE_I4]      = "int32_t",
    [enum.MONO_TYPE_U4]      = "uint32_t",
    [enum.MONO_TYPE_I8]      = "int64_t",
    [enum.MONO_TYPE_U8]      = "uint64_t",
    [enum.MONO_TYPE_R4]      = "float",
    [enum.MONO_TYPE_R8]      = "double",
    --[enum.MONO_TYPE_STRING]      = "",
    --[enum.MONO_TYPE_PTR]         = "",
    --[enum.MONO_TYPE_BYREF]       = "",
    --[enum.MONO_TYPE_VALUETYPE]   = "",
    --[enum.MONO_TYPE_CLASS]       = "",
    --[enum.MONO_TYPE_VAR]         = "",
    --[enum.MONO_TYPE_ARRAY]       = "",
    --[enum.MONO_TYPE_GENERICINST] = "",
    --[enum.MONO_TYPE_TYPEDBYREF]  = "",
    [enum.MONO_TYPE_I]       = "int",
    [enum.MONO_TYPE_U]       = "unsigned int",
    --[enum.MONO_TYPE_FNPTR]       = "",
    --[enum.MONO_TYPE_OBJECT]      = "",
    --[enum.MONO_TYPE_SZARRAY]     = "",
    --[enum.MONO_TYPE_MVAR]        = "",
    --[enum.MONO_TYPE_CMOD_REQD]   = "",
    --[enum.MONO_TYPE_CMOD_OPT]    = "",
    --[enum.MONO_TYPE_INTERNAL]    = "",
    --[enum.MONO_TYPE_MODIFIER]    = "",
    --[enum.MONO_TYPE_SENTINEL]    = "",
    --[enum.MONO_TYPE_PINNED]      = "",
}
M.ValueTypeMap = map

--

function M.getPtrClass(t)
    return lib.mono_ptr_class_get(check_ptr(t))
end

function M.getName(t)
    return ffi.string(lib.mono_type_get_name(check_ptr(t)))
end

function M.getUnderlyingType(t)
    return lib.mono_type_get_underlying_type(check_ptr(t))
end

--

local luamap = {
    ['bool[1]']     = 'mono_get_boolean_class',
    ['char[1]']     = 'mono_get_char_class',
    ['int8_t[1]']   = 'mono_get_sbyte_class',
    ['uint8_t[1]']  = 'mono_get_byte_class',
    ['int16_t[1]']  = 'mono_get_int16_class',
    ['uint16_t[1]'] = 'mono_get_uint16_class',
    ['int32_t[1]']  = 'mono_get_int32_class',
    ['uint32_t[1]'] = 'mono_get_uint32_class',
    ['int64_t[1]']  = 'mono_get_int64_class',
    ['uint64_t[1]'] = 'mono_get_uint64_class',
    ['float[1]']    = 'mono_get_single_class',
    ['double[1]']   = 'mono_get_double_class',
    --
    --['int[1]'] = '',
    --['unsigned int[1]'] = '',
}

function M.fromCdata(v)
    assert(type(v) == 'cdata')
    if ffi.istype('MonoObject*', v) then
        local klass = check_ptr(lib.mono_object_get_class(v))
        local t = check_ptr(lib.mono_class_get_type(klass))
        return t, klass
    elseif ffi.istype('MonoString*', v) then
        local klass = check_ptr(lib.mono_get_string_class())
        local t = check_ptr(lib.mono_class_get_type(klass))
        return t, klass
    else
        -- value
        for k, f in pairs(luamap) do
            if ffi.istype(k, v) then
                local klass = check_ptr(lib[f]())
                local t = check_ptr(lib.mono_class_get_type(klass))
                return t, klass
            end
        end
        -- not found
        error(("can't find mono type of '%s'"):format(tostring(v)))
    end
end

local _value_class_map = {
    mono_get_boolean_class = 'bool',
    mono_get_char_class    = 'char',
    mono_get_sbyte_class   = 'int8_t',
    mono_get_byte_class    = 'uint8_t',
    mono_get_int16_class   = 'int16_t',
    mono_get_uint16_class  = 'uint16_t',
    mono_get_int32_class   = 'int32_t',
    mono_get_uint32_class  = 'uint32_t',
    mono_get_int64_class   = 'int64_t',
    mono_get_uint64_class  = 'uint64_t',
    mono_get_single_class  = 'float',
    mono_get_double_class  = 'double',

    mono_get_string_class  = 'string',
    mono_get_void_class    = 'void',
}
local _number_key = {
    'char',
    'int8_t',
    'uint8_t',
    'int16_t',
    'uint16_t',
    'int32_t',
    'uint32_t',
    'int64_t',
    'uint64_t',
    'float',
    'double',
}
local value_class, value_type, number_type
local function make_value_info()
    if value_class then
        return
    end
    value_class, value_type, number_type = {}, {}, {}
    for k, v in pairs(_value_class_map) do
        local klass = check_ptr(lib[k]())
        local t = check_ptr(lib.mono_class_get_type(klass))
        value_class[tostring(klass)] = v
        value_class[v] = klass
        value_type[tostring(t)] = v
        value_type[v] = t
    end
    for _, v in ipairs(_number_key) do
        number_type[v] = value_type[v]
        number_type[tostring(value_type[v])] = v
    end
end

function M.fromLua(v)
    make_value_info()
    local ty = type(v)
    if ty == 'cdata' then
        return M.fromCdata(v)
    elseif ty == 'boolean' then
        return value_type.bool, value_class.bool
    elseif ty == 'string' then
        return value_type.string, value_class.string
    elseif ty == 'number' then
        local klass = check_ptr(lib.mono_get_double_class())
        local t = check_ptr(lib.mono_class_get_type(klass))
        return t, klass
    elseif ty == 'nil' then
        return value_type.void, value_class.void
    elseif ty == 'table' then
        assert(rawget(v, '.classname') == 'MonoObject')
        local cls = v:getClass()
        return cls:getType(), cls._hdl
    else
        --TODO: function
    end
    error(("can't find mono type of '%s'"):format(ty))
end

function M.isBool(t)
    make_value_info()
    return t == value_type.bool
end
function M.isChar(t)
    make_value_info()
    return t == value_type.char
end

function M.isNumberic(t)
    make_value_info()
    return number_type[tostring(t)] ~= nil
end
function M.isFloat(t)
    make_value_info()
    return t == value_type.float
end
function M.isDouble(t)
    make_value_info()
    return t == value_type.double
end

function M.convertNumber(t, v)
    assert(M.isNumberic(t))
    local ctype = number_type[tostring(t)] .. '[1]'
    local ret = ffi.new(ctype)
    ret[0] = v
    return ret
end

return M
