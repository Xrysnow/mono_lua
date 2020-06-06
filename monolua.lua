--
local M = {}

function M.init(bin_path, domain_name, lib_dir, etc_dir)
    require('_lib').load(bin_path, domain_name, lib_dir, etc_dir)
    M.lib = require('_lib')
    M.enum = require('enum')
    M.Assembly = require('MonoAssembly')
    M.Class = require('MonoClass')
    M.Object = require('MonoObject')
    M.Type = require('MonoType')
    M.Value = require('MonoValue')
    return M
end

local ffi = require('ffi')
M['.dtor_proxy'] = ffi.gc(
        ffi.new('int[0]'),
        function()
            require('_lib').finish()
        end
)

return M
