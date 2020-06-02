
require('mono.utils.mono-forward')
require('mono.metadata.metadata')
require('mono.metadata.image')
require('mono.utils.mono-error')
ffi.cdef [[

typedef mono_bool (*MonoStackWalk)     (MonoMethod *method, int32_t native_offset, int32_t il_offset, mono_bool managed, void* data);

MonoMethod *
mono_get_method             (MonoImage *image, uint32_t token, MonoClass *klass);

MonoMethod *
mono_get_method_full        (MonoImage *image, uint32_t token, MonoClass *klass,
			     MonoGenericContext *context);

MonoMethod *
mono_get_method_constrained (MonoImage *image, uint32_t token, MonoClass *constrained_class,
			     MonoGenericContext *context, MonoMethod **cil_method);

void               
mono_free_method           (MonoMethod *method);

MonoMethodSignature*
mono_method_get_signature_full (MonoMethod *method, MonoImage *image, uint32_t token,
				MonoGenericContext *context);

MonoMethodSignature*
mono_method_get_signature  (MonoMethod *method, MonoImage *image, uint32_t token);

MonoMethodSignature*
mono_method_signature      (MonoMethod *method);

MonoMethodHeader*
mono_method_get_header     (MonoMethod *method);

const char*
mono_method_get_name       (MonoMethod *method);

MonoClass*
mono_method_get_class      (MonoMethod *method);

uint32_t
mono_method_get_token      (MonoMethod *method);

uint32_t
mono_method_get_flags      (MonoMethod *method, uint32_t *iflags);

uint32_t
mono_method_get_index      (MonoMethod *method);

void
mono_add_internal_call     (const char *name, const void* method);

void
mono_dangerous_add_raw_internal_call (const char *name, const void* method);

void*
mono_lookup_internal_call (MonoMethod *method);

const char*
mono_lookup_icall_symbol (MonoMethod *m);

void
mono_dllmap_insert (MonoImage *assembly, const char *dll, const char *func, const char *tdll, const char *tfunc);

void*
mono_lookup_pinvoke_call (MonoMethod *method, const char **exc_class, const char **exc_arg);

void
mono_method_get_param_names (MonoMethod *method, const char **names);

uint32_t
mono_method_get_param_token (MonoMethod *method, int idx);

void
mono_method_get_marshal_info (MonoMethod *method, MonoMarshalSpec **mspecs);

mono_bool
mono_method_has_marshal_info (MonoMethod *method);

MonoMethod*
mono_method_get_last_managed  (void);

void
mono_stack_walk         (MonoStackWalk func, void* user_data);

/* Use this if the IL offset is not needed: it's faster */
void
mono_stack_walk_no_il   (MonoStackWalk func, void* user_data);

typedef mono_bool (*MonoStackWalkAsyncSafe)     (MonoMethod *method, MonoDomain *domain, void *base_address, int offset, void* data);
void
mono_stack_walk_async_safe   (MonoStackWalkAsyncSafe func, void *initial_sig_context, void* user_data);

MonoMethodHeader*
mono_method_get_header_checked (MonoMethod *method, MonoError *error);
]]