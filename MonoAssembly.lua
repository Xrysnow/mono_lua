---@class MonoAssembly
local M = class('MonoAssembly')
local lib = require('_lib')
local ffi = require("ffi")

function M:ctor(path_or_hdl)
    local assembly, path, image
    if type(path_or_hdl) == 'string' then
        assembly = lib.mono_domain_assembly_open(lib.domain, path_or_hdl)
        path = path_or_hdl
    else
        assembly = path_or_hdl
    end
    self._hdl = check_ptr(assembly, "failed to load assembly from '%s'", path_or_hdl)
    image = lib.mono_assembly_get_image(self._hdl)
    self._image = check_ptr(image, "failed to get image from assembly '%s'", path)
    if not path then
        path = ffi.string(lib.mono_image_get_filename(image))
    end
    self._path = path
    self._name = ffi.string(lib.mono_stringify_assembly_name(lib.mono_assembly_get_name(self._hdl)))
    self._classes = {}
end

function M:getImage()
    return self._image
end
function M:getPath()
    return self._path
end

---@return MonoClass
function M:getClass(ns_or_hdl, name)
    local classes = self._classes
    local klass
    if type(ns_or_hdl) == 'string' then
        assert(type(name) == 'string')
        if classes[ns_or_hdl] and classes[ns_or_hdl][name] then
            return classes[ns_or_hdl][name]
        end
        klass = lib.mono_class_from_name(self:getImage(), ns_or_hdl, name)
    elseif type(ns_or_hdl) == 'cdata' then
        if classes[ns_or_hdl] then
            return classes[ns_or_hdl]
        end
        klass = ns_or_hdl
    else
        error('invalid param type')
    end
    check_ptr(klass, "failed to get class '%s.%s' from '%s'", ns_or_hdl, name, self._path)
    lib.mono_class_init(klass)
    local cls = require('MonoClass')(klass)
    local ns = cls:getNamespace()
    name = cls:getName()
    if not classes[ns] then
        classes[ns] = {}
    end
    classes[ns][name] = cls
    classes[klass] = cls
    return cls
end

function M:hasNamespace(namespace)
    return self._classes[namespace] ~= nil
end

function M:close()
    lib.mono_assembly_close(self._hdl)
end

function M:setMain()
    lib.mono_assembly_set_main(self._hdl)
end

return M
