---@class MonoClass
local M = class('MonoClass')
local lib = require('_lib')
local ffi = require("ffi")
require('ffi_util')

function M:ctor(klass)
    check_ptr(klass, "invalid handle")
    self._hdl = klass
    self._ns = ffi.string(lib.mono_class_get_namespace(klass))
    self._name = ffi.string(lib.mono_class_get_name(klass))
    self._rank = tonumber(lib.mono_class_get_rank(klass))
    self._type = lib.mono_class_get_type(klass)
    --
    self:_parseAttr()
    self:_getFields()
    self:_getMethods()
    self:_getProperties()
    self:_getEvents()
    self:_getInterfaces()
    self:_getNestedTypes()
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

function M:_getMethods(name, need_public, need_static)
    local ret = {}
    for _, v in ipairs(self._methods) do
        local ok = v.name == name
        ok = ok and (v.is_public or not need_public)
        ok = ok and (v.is_static or not need_static)
        if ok then
            table.insert(ret, v)
        end
    end
    return ret
end

function M:_getOperators(name)
    local ret = {}
    for _, v in ipairs(self._operators) do
        if v.name == name then
            table.insert(ret, v)
        end
    end
    return ret
end

--

function M:getRank()
    return self._rank
end

function M:getName()
    return self._name
end

function M:getNamespace()
    return self._ns
end

function M:getAttr()
    return self._attr
end

function M:getType()
    return self._type
end

function M:getByrefType()
    return lib.mono_class_get_byref_type(self._hdl)
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

--

local band = bit.band
local isnullptr = ffi.isnullptr
local insert = table.insert
local tonumber = tonumber
local enum = require('enum')

local function check_flags(flags, value)
    return band(flags, value) > 0 or nil
end
local function check_ret(p)
    return not isnullptr(p) and p or nil
end

function M:_parseAttr()
    local flags = tonumber(lib.mono_class_get_flags(self._hdl))
    self._flags = flags
    local e = enum
    local attr = {}
    local vis = band(flags, e.MONO_TYPE_ATTR_VISIBILITY_MASK)
    attr.is_public = vis == e.MONO_TYPE_ATTR_PUBLIC
    attr.is_nested_public = vis == e.MONO_TYPE_ATTR_NESTED_PUBLIC
    attr.is_sequential_layout = check_flags(flags, e.MONO_TYPE_ATTR_SEQUENTIAL_LAYOUT)
    attr.is_explicit_layout = check_flags(flags, e.MONO_TYPE_ATTR_EXPLICIT_LAYOUT)
    attr.is_interface = check_flags(flags, e.MONO_TYPE_ATTR_INTERFACE)
    attr.is_abstract = check_flags(flags, e.MONO_TYPE_ATTR_ABSTRACT)
    attr.is_sealed = check_flags(flags, e.MONO_TYPE_ATTR_SEALED)
    attr.is_interface = check_flags(flags, e.MONO_TYPE_ATTR_INTERFACE)

    attr.is_special_name = check_flags(flags, e.MONO_TYPE_ATTR_SPECIAL_NAME)
    attr.is_import = check_flags(flags, e.MONO_TYPE_ATTR_IMPORT)
    attr.is_serializable = check_flags(flags, e.MONO_TYPE_ATTR_SERIALIZABLE)

    local fmt = band(flags, e.MONO_TYPE_ATTR_STRING_FORMAT_MASK)
    local fmt_t = {
        [e.MONO_TYPE_ATTR_ANSI_CLASS]    = 'ansi',
        [e.MONO_TYPE_ATTR_UNICODE_CLASS] = 'unicode',
        [e.MONO_TYPE_ATTR_AUTO_CLASS]    = 'auto',
        [e.MONO_TYPE_ATTR_CUSTOM_CLASS]  = 'custom',
    }
    attr.string_format = fmt_t[fmt]

    attr.is_before_field_init = check_flags(flags, e.MONO_TYPE_ATTR_BEFORE_FIELD_INIT)
    attr.is_forwarder = check_flags(flags, e.MONO_TYPE_ATTR_FORWARDER)
    self._attr = attr
end

function M:_getContents(f)
    local ret = {}
    local iter = ffi.new('void*[1]')
    local hdl = self._hdl
    while true do
        local p = f(hdl, iter)
        if isnullptr(p) then
            break
        end
        insert(ret, { hdl = p })
    end
    return ret
end

local function parseFieldAttr(flags, t)
    t = t or {}
    local e = enum
    local access = band(flags, e.MONO_FIELD_ATTR_FIELD_ACCESS_MASK)
    t.is_public = access == e.MONO_FIELD_ATTR_PUBLIC
    t.is_static = check_flags(flags, e.MONO_FIELD_ATTR_STATIC) or false
    t.is_init_only = check_flags(flags, e.MONO_FIELD_ATTR_INIT_ONLY)
    t.is_literal = check_flags(flags, e.MONO_FIELD_ATTR_LITERAL)
    t.is_not_serialized = check_flags(flags, e.MONO_FIELD_ATTR_NOT_SERIALIZED)
    t.is_special_name = check_flags(flags, e.MONO_FIELD_ATTR_SPECIAL_NAME)
    t.is_pinvoke_impl = check_flags(flags, e.MONO_FIELD_ATTR_PINVOKE_IMPL)
    return t
end

function M:_getFields()
    self._fields = self:_getContents(lib.mono_class_get_fields)
    self._fields_public = {}
    self._fields_public_static = {}
    for _, t in ipairs(self._fields) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_field_get_name(p))
        t.type = lib.mono_field_get_type(p)
        t.parent = check_ret(lib.mono_field_get_parent(p))
        t.flags = tonumber(lib.mono_field_get_flags(p))
        t.offset = tonumber(lib.mono_field_get_offset(p))
        t.data = check_ret(lib.mono_field_get_data(p))
        parseFieldAttr(t.flags, t)
        --
        if t.is_public then
            if t.is_static then
                self._fields_public_static[t.name] = t
            else
                self._fields_public[t.name] = t
            end
        end
    end
end

local function parseMethodAttr(flags, iflags, t)
    t = t or {}
    local e = enum
    local access = band(flags, e.MONO_METHOD_ATTR_ACCESS_MASK)
    t.is_public = access == e.MONO_METHOD_ATTR_PUBLIC
    t.is_static = check_flags(flags, e.MONO_METHOD_ATTR_STATIC) or false
    t.is_final = check_flags(flags, e.MONO_METHOD_ATTR_FINAL)
    t.is_virtual = check_flags(flags, e.MONO_METHOD_ATTR_VIRTUAL)
    t.is_hide_by_sig = check_flags(flags, e.MONO_METHOD_ATTR_HIDE_BY_SIG)
    t.is_new_slot = check_flags(flags, e.MONO_METHOD_ATTR_NEW_SLOT)
    t.is_strict = check_flags(flags, e.MONO_METHOD_ATTR_STRICT)
    t.is_abstract = check_flags(flags, e.MONO_METHOD_ATTR_ABSTRACT)
    t.is_special_name = check_flags(flags, e.MONO_METHOD_ATTR_SPECIAL_NAME)
    t.is_pinvoke_impl = check_flags(flags, e.MONO_METHOD_ATTR_PINVOKE_IMPL)
    t.is_unmanaged_export = check_flags(flags, e.MONO_METHOD_ATTR_UNMANAGED_EXPORT)
    return t
end
local function parseSignature(ptr, sig)
    local s = ptr
    sig.return_type = lib.mono_signature_get_return_type(s)
    local param_types = {}
    sig.param_types = param_types
    local iter = ffi.new('void*[1]')
    while true do
        local ty = lib.mono_signature_get_params(s, iter)
        if ffi.isnullptr(ty) then
            break
        end
        insert(param_types, ty)
    end
    sig.param_count = tonumber(lib.mono_signature_get_param_count(s))
    sig.call_conv = tonumber(lib.mono_signature_get_call_conv(s))
    sig.vararg_start = tonumber(lib.mono_signature_vararg_start(s))
    sig.is_instance = lib.mono_signature_is_instance(s) > 0
    sig.explicit_this = lib.mono_signature_explicit_this(s) > 0
    local is_out = {}
    sig.is_out = is_out
    for i = 1, sig.param_count do
        insert(is_out, lib.mono_signature_param_is_out(s, i - 1) > 0)
    end
end

local _op_names = {
    'op_Implicit',
    'op_Explicit',

    'op_BitwiseAnd',
    'op_BitwiseOr',
    'op_ExclusiveOr',
    'op_LeftShift',
    'op_RightShift',

    'op_OnesComplement',
    'op_UnaryNegation',
    'op_UnaryPlus',

    'op_Increment',
    'op_Decrement',

    'op_Addition',
    'op_Subtraction',
    'op_Multiply',
    'op_Division',
    'op_Modulus',

    'op_LessThan',
    'op_LessThanOrEqual',
    'op_GreaterThan',
    'op_GreaterThanOrEqual',
    'op_Equality',
    'op_Inequality',
}
for i = 1, #_op_names do
    _op_names[_op_names[i]] = true
end

function M:_getMethods()
    self._methods = self:_getContents(lib.mono_class_get_methods)
    self._methods_public = {}
    self._methods_public_static = {}
    self._operators = {}
    for _, t in ipairs(self._methods) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_method_get_name(p))
        t.signature = check_ret(lib.mono_method_signature(p))
        t.header = check_ret(lib.mono_method_get_header(p))
        t.class = check_ret(lib.mono_method_get_class(p))
        t.token = tonumber(lib.mono_method_get_token(p))
        t.index = tonumber(lib.mono_method_get_index(p))
        --
        local iflags = ffi.new('uint32_t[1]')
        t.flags = tonumber(lib.mono_method_get_flags(p, iflags))
        t.iflags = tonumber(iflags[0])
        parseMethodAttr(t.flags, t.iflags, t)
        --
        local sig = {}
        t.sig = sig
        parseSignature(t.signature, sig)
        --
        local names, tokens = {}, {}
        local out = ffi.new('const char*[?]', sig.param_count)
        lib.mono_method_get_param_names(p, out)
        for i = 1, sig.param_count do
            insert(names, ffi.string(check_ptr(out[i - 1])))
            insert(tokens, tonumber(lib.mono_method_get_param_token(p, i - 1)))
        end
        t.param_names = names
        t.param_tokens = tokens
        -- methods can have same name
        if t.is_public then
            if t.is_static then
                self._methods_public_static[t.name] = true
                if _op_names[t.name] and t.is_special_name then
                    -- operator
                    insert(self._operators, t)
                    self._operators[t.name] = true
                end
            else
                self._methods_public[t.name] = true
            end
        end
    end
end

function M:_getProperties()
    self._properties = self:_getContents(lib.mono_class_get_properties)
    self._properties_method = {}
    for _, t in ipairs(self._properties) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_property_get_name(p))
        t.setter = check_ret(lib.mono_property_get_set_method(p))
        t.getter = check_ret(lib.mono_property_get_get_method(p))
        t.parent = check_ret(lib.mono_property_get_parent(p))
        t.flags = tonumber(lib.mono_property_get_flags(p))
        --
        local e = enum
        t.is_special_name = check_flags(t.flags, e.MONO_PROPERTY_ATTR_SPECIAL_NAME)
        t.has_default = check_flags(t.flags, e.MONO_PROPERTY_ATTR_HAS_DEFAULT)
        --
        if t.getter then
            local hdl = t.getter
            local attr = { hdl = hdl }
            t.getter = attr
            local iflags = ffi.new('uint32_t[1]')
            attr.flags = tonumber(lib.mono_method_get_flags(hdl, iflags))
            parseMethodAttr(attr.flags, iflags[0], attr)
            attr.signature = check_ret(lib.mono_method_signature(hdl))
            attr.sig = {}
            parseSignature(attr.signature, attr.sig)
        end
        if t.setter then
            local hdl = t.setter
            local attr = { hdl = hdl }
            t.setter = attr
            local iflags = ffi.new('uint32_t[1]')
            attr.flags = tonumber(lib.mono_method_get_flags(hdl, iflags))
            parseMethodAttr(attr.flags, iflags[0], attr)
            attr.signature = check_ret(lib.mono_method_signature(hdl))
            attr.sig = {}
            parseSignature(attr.signature, attr.sig)
        end
        self._properties_method[t.name] = { t.getter, t.setter }
    end
end

function M:_getEvents()
    self._events = self:_getContents(lib.mono_class_get_events)
    for _, t in ipairs(self._events) do
        local p = t.hdl
        t.name = ffi.string(lib.mono_event_get_name(p))
        t.add = check_ret(lib.mono_event_get_add_method(p))
        t.remove = check_ret(lib.mono_event_get_remove_method(p))
        t.raise = check_ret(lib.mono_event_get_raise_method(p))
        t.parent = check_ret(lib.mono_event_get_parent(p))
        t.flags = tonumber(lib.mono_event_get_flags(p))
    end
end

function M:_getInterfaces()
    self._interfaces = self:_getContents(lib.mono_class_get_interfaces)
end

function M:_getNestedTypes()
    self._nested_types = self:_getContents(lib.mono_class_get_nested_types)
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
