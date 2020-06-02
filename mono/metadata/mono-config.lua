
require('mono.utils.mono-publib')
require('mono.metadata.image')
ffi.cdef [[

const char *mono_config_get_os (void);
const char *mono_config_get_cpu (void);
const char *mono_config_get_wordsize (void);

const char* mono_get_config_dir (void);
void        mono_set_config_dir (const char *dir);

const char* mono_get_machine_config (void);

void mono_config_cleanup      (void);
void mono_config_parse        (const char *filename);
void mono_config_for_assembly (MonoImage *assembly);
void mono_config_parse_memory (const char *buffer);

const char* mono_config_string_for_assembly_file (const char *filename);

void mono_config_set_server_mode (mono_bool server_mode);
mono_bool mono_config_is_server_mode (void);
]]
