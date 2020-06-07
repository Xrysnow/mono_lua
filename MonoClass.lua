---@class MonoClass
local M = class('MonoClass')
local lib = require('_lib')
local ffi = require("ffi")

function M:ctor(klass)
    check_ptr(klass, "invalid handle")
    self._hdl = klass
    self._ns = ffi.string(lib.mono_class_get_namespace(klass))
    self._name = ffi.string(lib.mono_class_get_name(klass))
    self._rank = tonumber(lib.mono_class_get_rank(klass))
    self._type = lib.mono_class_get_type(klass)
    --
    self._fields = self:_getFields()
    self._methods = self:_getMethods()
    self._properties = self:_getProperties()
    self._events = self:_getEvents()
    self._interfaces = self:_getInterfaces()
    self._nested_types = self:_getNestedTypes()
    --TODO: nested types
end

function M:getMethodFromDesc(desc)
    assert(desc)
    local method_desc = lib.mono_method_desc_new(desc, false)
    check_ptr(method_desc, "failed to create method desc '%s'", desc)
    local method = lib.mono_method_desc_search_in_class(method_desc, self._hdl)
    lib.mono_method_desc_free(method_desc)
    check_ptr(method, "failed to get method '%s' of class '%s'", desc, self._name)
    return method
end

function M:getMethod(name, param_count)
    if name:sub(1, 1) == ':' then
        return self:getMethodFromDesc(name)
    end
    param_count = param_count or 0
    local method = lib.mono_class_get_method_from_name(self._hdl, name, param_count)
    check_ptr(method, "failed to get method '%s' of class '%s'", name, self._name)
    return method
end

function M:getFieldHandle(name)
    assert(name)
    local field = lib.mono_class_get_field_from_name(self._hdl, name)
    check_ptr(field, "failed to get field '%s' of class '%s'", name, self._name)
    return field
end

function M:getPropertyHandle(name)
    assert(name)
    local property = lib.mono_class_get_property_from_name(self._hdl, name)
    check_ptr(property, "failed to get property '%s' of class '%s'", name, self._name)
    return property
end

function M:invokeStaticMethod(name, ...)
    local obj = lib.mono_runtime_invoke(self:getMethod(name, select("#", ...)),
                                        nil, make_param(...), nil)
    if ffi.isnullptr(obj) then
        return nil
    end
    return require('MonoObject')(obj)
end

function M:createInstance(...)
    local ctor = self:getMethod('.ctor', select("#", ...))
    local obj = check_ptr(lib.mono_object_new(lib.domain, self._hdl))
    lib.mono_runtime_invoke(ctor, obj, make_param(...), nil)
    return require('MonoObject')(obj)
end

--

function M:getRank()
    return tonumber(lib.mono_class_get_rank(self._hdl))
end

function M:getFlags()
    return tonumber(lib.mono_class_get_flags(self._hdl))
end

function M:getName()
    return self._name
end

function M:getNamespace()
    return self._ns
end

function M:getType()
    return lib.mono_class_get_type(self._hdl)
end

function M:getByrefType()
    return lib.mono_class_get_byref_type(self._hdl)
end

--

function M:_getContents(f)
    local ret = {}
    local iter = ffi.new('void*[1]')
    while true do
        local p = f(self._hdl, iter)
        if ffi.isnullptr(p) then
            break
        end
        table.insert(ret, { hdl = p })
    end
    return ret
end

function M:_getFields()
    local ret = self:_getContents(lib.mono_class_get_fields)
    for i, t in ipairs(ret) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_field_get_name(p))
        t.type = lib.mono_field_get_type(p)
        t.parent = lib.mono_field_get_parent(p)
        t.flags = tonumber(lib.mono_field_get_flags(p))
        t.offset = tonumber(lib.mono_field_get_offset(p))
        t.data = lib.mono_field_get_data(p)
    end
    return ret
end

function M:_getMethods()
    local ret = self:_getContents(lib.mono_class_get_methods)
    for _, t in ipairs(ret) do
        local p = t.hdl
        t.signature = lib.mono_method_signature(p)
        t.header = lib.mono_method_get_header(p)
        t.name = ffi.string(lib.mono_method_get_name(p))
        t.class = lib.mono_method_get_class(p)
        t.token = tonumber(lib.mono_method_get_token(p))
        t.index = tonumber(lib.mono_method_get_index(p))
        --
        local s = t.signature
        local sig = {}
        t.sig = sig
        sig.return_type = lib.mono_signature_get_return_type(s)
        local param_types = {}
        sig.param_types = param_types
        local iter = ffi.new('void*[1]')
        while true do
            local ty = lib.mono_signature_get_params(s, iter)
            if ffi.isnullptr(ty) then
                break
            end
            table.insert(param_types, ty)
        end
        sig.param_count = tonumber(lib.mono_signature_get_param_count(s))
        sig.call_conv = tonumber(lib.mono_signature_get_call_conv(s))
        sig.vararg_start = tonumber(lib.mono_signature_vararg_start(s))
        sig.is_instance = lib.mono_signature_is_instance(s) > 0
        sig.explicit_this = lib.mono_signature_explicit_this(s) > 0
        local is_out = {}
        sig.is_out = is_out
        for i = 1, sig.param_count do
            table.insert(is_out, lib.mono_signature_param_is_out(s, i - 1) > 0)
        end
        --
        local names, tokens = {}, {}
        local out = ffi.new('const char*[?]', sig.param_count)
        lib.mono_method_get_param_names(p, out)
        for i = 1, sig.param_count do
            table.insert(names, ffi.string(check_ptr(out[i - 1])))
            table.insert(tokens, tonumber(lib.mono_method_get_param_token(p, i - 1)))
        end
        t.param_names = names
        t.param_tokens = tokens
    end
    return ret
end

function M:_getProperties()
    local ret = self:_getContents(lib.mono_class_get_properties)
    for i, t in ipairs(ret) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_property_get_name(p))
        t.setter = lib.mono_property_get_set_method(p)
        t.getter = lib.mono_property_get_get_method(p)
        t.parent = lib.mono_property_get_parent(p)
        t.flags = tonumber(lib.mono_property_get_flags(p))
    end
    return ret
end

function M:_getEvents()
    local ret = self:_getContents(lib.mono_class_get_events)
    for i, t in ipairs(ret) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_event_get_name(p))
        t.add = lib.mono_event_get_add_method(p)
        t.remove = lib.mono_event_get_remove_method(p)
        t.raise = lib.mono_event_get_raise_method(p)
        t.parent = lib.mono_event_get_parent(p)
        t.flags = tonumber(lib.mono_event_get_flags(p))
    end
    return ret
end

function M:_getInterfaces()
    return self:_getContents(lib.mono_class_get_interfaces)
end

function M:_getNestedTypes()
    return self:_getContents(lib.mono_class_get_nested_types)
end

--

function M:isValueType()
    return lib.mono_class_is_valuetype(self._hdl) > 0
end

function M:isEnum()
    return lib.mono_class_is_enum(self._hdl) > 0
end

function M:getEnumBaseType()
    if not self:isEnum() then
        return nil
    end
    return lib.mono_class_enum_basetype(self._hdl)
end

function M:getParent()
    local p = lib.mono_class_get_parent(self._hdl)
    return not ffi.isnullptr(p) and M(p) or nil
end

function M:getNestingType()
    local p = lib.mono_class_get_nesting_type(self._hdl)
    return not ffi.isnullptr(p) and M(p) or nil
end

--

local function get_hdl(cls)
    if type(cls) == 'table' then
        cls = cls._hdl
    end
    assert(type(cls) == 'cdata')
    return cls
end

function M:isSubclassOf(cls, check_interfaces)
    cls = get_hdl(cls)
    if check_interfaces then
        check_interfaces = 1
    else
        check_interfaces = 0
    end
    return lib.mono_class_is_subclass_of(self._hdl, cls, check_interfaces) > 0
end

function M:isAssignableFrom(cls)
    cls = get_hdl(cls)
    return lib.mono_class_is_assignable_from(self._hdl, cls) > 0
end

function M:getArrayClass(rank)
    rank = rank or 1
    return M(lib.mono_array_class_get(self._hdl, rank))
end

function M:box(value)
    local o = lib.mono_value_box(lib.domain, self._hdl, ffi.cast('void*', value))
    return not ffi.isnullptr(o) and require('MonoObject')(o) or nil
end

-- internal classes

function M.Object()
    return M(lib.mono_get_object_class())
end
function M.Byte()
    return M(lib.mono_get_byte_class())
end
function M.Void()
    return M(lib.mono_get_void_class())
end
function M.Boolean()
    return M(lib.mono_get_boolean_class())
end
function M.Sbyte()
    return M(lib.mono_get_sbyte_class())
end
function M.Int16()
    return M(lib.mono_get_int16_class())
end
function M.Uint16()
    return M(lib.mono_get_uint16_class())
end
function M.Int32()
    return M(lib.mono_get_int32_class())
end
function M.Uint32()
    return M(lib.mono_get_uint32_class())
end
function M.Intptr()
    return M(lib.mono_get_intptr_class())
end
function M.Uintptr()
    return M(lib.mono_get_uintptr_class())
end
function M.Int64()
    return M(lib.mono_get_int64_class())
end
function M.Uint64()
    return M(lib.mono_get_uint64_class())
end
function M.Float()
    return M(lib.mono_get_single_class())
end
function M.Double()
    return M(lib.mono_get_double_class())
end
function M.Char()
    return M(lib.mono_get_char_class())
end
function M.String()
    return M(lib.mono_get_string_class())
end
function M.Enum()
    return M(lib.mono_get_enum_class())
end
function M.Array()
    return M(lib.mono_get_array_class())
end
function M.Thread()
    return M(lib.mono_get_thread_class())
end
function M.Exception()
    return M(lib.mono_get_exception_class())
end

return M
