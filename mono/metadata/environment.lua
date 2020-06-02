
require('mono.utils.mono-publib')
ffi.cdef [[

int32_t mono_environment_exitcode_get (void);
void mono_environment_exitcode_set (int32_t value);
]]