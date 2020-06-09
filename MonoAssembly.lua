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
    --
    self:_makeTypes()
    self:_makeIndex()
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

local insert = table.insert
local sfind = string.find
local function string_split(s, sep)
    local ret = {}
    if not sep or sep == '' then
        local len = #s
        for i = 1, len do
            insert(ret, s:sub(i, i))
        end
    else
        while true do
            local p = sfind(s, sep)
            if not p then
                insert(ret, s)
                break
            end
            local ss = s:sub(1, p - 1)
            insert(ret, ss)
            s = s:sub(p + 1, #s)
        end
    end
    return ret
end

function M:_makeTypes()
    local im = self._image
    local t = lib.mono_image_get_table_info(im, 2)
    local rows = lib.mono_table_info_get_rows(t)
    local types = {}
    for i = 1, rows do
        local col = ffi.new('uint32_t[?]', 6)
        lib.mono_metadata_decode_row(t, i - 1, col, 6)
        local name = col[1]
        local ns = col[2]
        name = ffi.string(lib.mono_metadata_string_heap(im, name))
        ns = ffi.string(lib.mono_metadata_string_heap(im, ns))
        if ns ~= '' then
            table.insert(types, { name, ns })
        end
    end
    self._types = types
end

function M:_makeIndex()
    local ns = {}
    for _, v in ipairs(self._types) do
        local name, namespace = v[1], v[2]
        local p = lib.mono_class_from_name(self._image, namespace, name)
        assert(not ffi.isnullptr(p))
        --print('class', namespace, name)
        local cls = require('MonoClass')(p)
        if not self._classes[namespace] then
            self._classes[namespace] = {}
        end
        self._classes[namespace][name] = cls
        self._classes[cls._hdl] = cls
        local s = string_split(namespace, '%.')
        if #s == 0 then
            error('invalid namespace')
        end
        local cur_ns = ns
        for i = 1, #s do
            local si = s[i]
            assert(si ~= '')
            if i < #s then
                if not cur_ns[si] then
                    cur_ns[si] = {}
                end
                cur_ns = cur_ns[si]
            else
                if cur_ns[si] then
                    cur_ns[si][name] = { cls }
                else
                    cur_ns[si] = { [name] = { cls } }
                end

                --[[
                local ss = string_split(si, '+')
                if #ss == 0 then
                    error('invalid namespace')
                else
                    -- nested class
                    for j = 1, #ss do
                        local ssj = ss[j]
                        if not cur_ns[ssj] then
                            cur_ns[ssj] = {}
                        end
                        if j < #ss then
                            cur_ns = cur_ns[ssj]
                        else
                            cur_ns[ssj][1] = v
                        end
                    end
                end
                ]]
            end
        end
    end
    self._index = ns
end
return M
