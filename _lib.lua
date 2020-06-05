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

return M
