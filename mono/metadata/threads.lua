
require('mono.utils.mono-publib')
require('mono.metadata.object')
require('mono.metadata.appdomain')

ffi.cdef [[

/* This callback should return TRUE if the runtime must wait for the thread, FALSE otherwise */
typedef mono_bool (*MonoThreadManageCallback) (MonoThread* thread);

void mono_thread_init (MonoThreadStartCB start_cb,
			      MonoThreadAttachCB attach_cb);
void mono_thread_cleanup (void);

void mono_thread_manage(void);

MonoThread *mono_thread_current (void);

void        mono_thread_set_main (MonoThread *thread);
MonoThread *mono_thread_get_main (void);

void mono_thread_stop (MonoThread *thread);

void mono_thread_new_init (intptr_t tid, void* stack_start,
				  void* func);

void
mono_thread_create (MonoDomain *domain, void* func, void* arg);

MonoThread *mono_thread_attach (MonoDomain *domain);
void mono_thread_detach (MonoThread *thread);
void mono_thread_exit (void);

void
mono_threads_attach_tools_thread (void);

char   *mono_thread_get_name_utf8 (MonoThread *thread);
int32_t mono_thread_get_managed_id (MonoThread *thread);

void     mono_thread_set_manage_callback (MonoThread *thread, MonoThreadManageCallback func);

void mono_threads_set_default_stacksize (uint32_t stacksize);
uint32_t mono_threads_get_default_stacksize (void);

void mono_threads_request_thread_dump (void);

mono_bool mono_thread_is_foreign (MonoThread *thread);

mono_bool
mono_thread_detach_if_exiting (void);
]]