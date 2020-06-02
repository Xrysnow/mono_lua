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
    return lib.mono_type_get_class(check_ptr(t))
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

return M
