---@class MonoObject
local M = class('MonoObject')
local lib = require('_lib')
local ffi = require("ffi")

function M:ctor(object, gc_handle)
    check_ptr(object, "invalid handle")
    self._hdl = object
    if not gc_handle then
        gc_handle = lib.mono_gchandle_new(object, false)
    end
    self._gc = gc_handle
    local klass = lib.mono_object_get_class(object)
    check_ptr(klass, "failed to get class of object")
    self._klass = klass
    self._cls = lib.getClass(klass)
end

function M:dtor()
    lib.mono_gchandle_free(self._gc)
end

function M:getPropertyValue(name, ...)
    local property = self._cls:getProperty(name)
    local value = lib.mono_property_get_value(property, self._hdl, make_param(...), nil)
    check_ptr(value, "failed to get property '%s' of object '%s'", name, self._cls:getName())
    return require('MonoObject')(value)
end

function M:setPropertyValue(name, ...)
    local property = self._cls:getProperty(name)
    lib.mono_property_set_value(property, self._hdl, make_param(...), nil)
end

function M:getFieldValue(name)
    local field = self._cls:getField(name)
    local value = lib.mono_field_get_value_object(lib.domain, field, self._hdl)
    check_ptr(value, "failed to get field '%s' of object '%s'", name, self._cls:getName())
    return require('MonoObject')(value)
end

function M:setFieldValue(name, value)
    local field = self._cls:getField(name)
    lib.mono_field_set_value(self._hdl, field, value)
end

function M:invoke(name, ...)
    local ret = lib.mono_runtime_invoke(self._cls:getMethod(name, select('#', ...)),
                                        self._hdl, make_param(...), nil)
    if ffi.isnullptr(ret) then
        return nil
    end
    return M(ret)
end

---@param cls MonoClass
function M:cast(cls)
    if type(cls) == 'cdata' then
        assert(ffi.istype('MonoClass*', cls))
        cls = lib.getClass(cls)
    end
    if not cls:isAssignableFrom(self:getClass()) then
        error(("can't cast from '%s' to '%s'"):format(self:getClassName(), cls:getName()))
    end
    return M(lib.mono_object_castclass_mbyref(self._hdl, cls._hdl))
end

--

function M:hash()
    return tonumber(lib.mono_object_hash(self._hdl))
end

function M:unbox()
    if self:getClass()._hdl == lib.mono_get_string_class() then
        -- string type
        return self:tostring()
    end
    local enum = require('enum').MonoTypeEnum
    local map = require('MonoType').ValueTypeMap
    local t = self:getClass():getType()
    t = require('MonoType').getILType(t)
    if map[t] then
        -- value type
        local ctype = map[t] .. '*'
        local p = lib.mono_object_unbox(self._hdl)
        if ffi.isnullptr(p) then
            return nil
        end
        return ffi.cast(ctype, p)[0]
    elseif t == enum.MONO_TYPE_STRING then
        return self:tostring()
    end
    return nil
end

function M:clone()
    return M(lib.mono_object_clone(self._hdl))
end

function M:isInstance(cls)
    if type(cls) == 'table' then
        cls = cls._hdl
    end
    if cls == self._klass then
        return true
    end
    local p = lib.mono_object_isinst(self._hdl, cls)
    return not ffi.isnullptr(p)
end

function M:getSize()
    return tonumber(lib.mono_object_get_size(self._hdl))
end

function M:tostring()
    local s = lib.mono_object_to_string(self._hdl, nil)
    check_ptr(s, "failed to stringify object '%s", self._cls:getName())
    return ffi.string(lib.mono_string_to_utf8(s))
end

--

function M:getClass()
    return self._cls
end

function M:getClassName()
    return self._cls:getName()
end

return M
