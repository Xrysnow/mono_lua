--
local M = {}
ffi = require("ffi")
mono = {}
require('base')
require("ffi_util")
require("mono.jit.jit")
require("mono.metadata.assembly")
require("mono.metadata.debug-helpers")

function M.load(bin_path, domain_name, assembly_dir, config_dir)
    M.lib = ffi.load(bin_path)
    if assembly_dir or config_dir then
        M.lib.mono_set_dirs(assembly_dir, config_dir)
    end
    local domain = M.lib.mono_jit_init(domain_name or "monolua")
    if ffi.isnullptr(domain) then
        error('failed to init domain')
    end
    M.domain = domain
    local corlib = M.lib.mono_get_corlib()
    M.corlib_image = corlib
    M.corlib_assembly = M.lib.mono_image_get_assembly(corlib)
    local filename_corlib = M.lib.mono_image_get_filename(corlib)
    if ffi.isnullptr(filename_corlib) then
        error('failed to get path of corlib')
    end
    M.core_path = ffi.string(filename_corlib):sub(1, -13)
end

function M.finish()
    if not M.domain then
        return
    end
    M.lib.mono_jit_cleanup(M.domain)
end

setmetatable(M, { __index = function(t, k)
    return M.lib[k]
end })

function M.setRootDir()
    M.lib.mono_set_rootdir()
end

function M.setDirs(assembly_dir, config_dir)
    M.lib.mono_set_dirs(assembly_dir, config_dir)
end

function M.setPath(path)
    M.lib.mono_set_assemblies_path(path)
end

local _asms = {}

function M.loadAssembly(path, ...)
    for _, v in ipairs({ path, ... }) do
        M.getAssembly(v)
    end
end

function M.unloadAssembly(path)
    if not _asms[path] then
        return
    end
    local asm = M.getAssembly(path)
    _asms[path] = nil
    _asms[asm:getPath()] = nil
    _asms[asm._hdl] = nil
    for i = 1, #_asms do
        if _asms[i] == asm then
            table.remove(_asms, i)
            break
        end
    end
    asm:close()
end

---@return MonoAssembly
function M.getAssembly(path_or_hdl)
    if _asms[path_or_hdl] then
        return _asms[path_or_hdl]
    end
    if type(path_or_hdl) == 'cdata' then
        if ffi.istype('MonoImage*', path_or_hdl) then
            path_or_hdl = M.lib.mono_image_get_assembly(path_or_hdl)
        end
        check_ptr(path_or_hdl, "invalid handle")
    end
    if type(path_or_hdl) == 'string' then
        local hdl = M.lib.mono_domain_assembly_open(M.domain, path_or_hdl)
        if ffi.isnullptr(hdl) then
            -- search internal
            path_or_hdl = M.core_path .. path_or_hdl
        else
            path_or_hdl = hdl
        end
    end
    local asm = require('MonoAssembly')(path_or_hdl)
    _asms[asm:getPath()] = asm
    _asms[path_or_hdl] = asm
    _asms[asm._hdl] = asm
    table.insert(_asms, asm)
    return asm
end

---@return MonoClass
function M.getClass(handle)
    assert(ffi.istype('MonoClass*', handle))
    check_ptr(handle, "invalid handle")
    return M.getAssembly(M.lib.mono_class_get_image(handle)):getClass(handle)
end

return M
