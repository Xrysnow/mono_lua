
require('mono.utils.mono-publib')
ffi.cdef [[

void 
mono_trace_set_level_string (const char *value);

void 
mono_trace_set_mask_string (const char *value);

typedef void (*MonoPrintCallback) (const char *string, mono_bool is_stdout);
typedef void (*MonoLogCallback) (const char *log_domain, const char *log_level, const char *message, mono_bool fatal, void *user_data);

void
mono_trace_set_log_handler (MonoLogCallback callback, void *user_data);

void
mono_trace_set_print_handler (MonoPrintCallback callback);

void
mono_trace_set_printerr_handler (MonoPrintCallback callback);
]]