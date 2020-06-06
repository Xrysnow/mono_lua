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
end

function M:getImage()
    return self._image
end
function M:getPath()
    return self._path
end

function M:getClass(namespace, name)
    local klass = lib.mono_class_from_name(self:getImage(), namespace, name)
    check_ptr(klass, "failed to get class '%s.%s' from '%s'", namespace, name, self._path)
    lib.mono_class_init(klass)
    return require('MonoClass')(klass)
end

function M:close()
    lib.mono_assembly_close(self._hdl)
end

function M:setMain()
    lib.mono_assembly_set_main(self._hdl)
end

return M
