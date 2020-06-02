
ffi.cdef [[

typedef int32_t		mono_bool;
typedef uint8_t		mono_byte;
typedef mono_byte       MonoBoolean;
typedef uint16_t	mono_unichar2;
typedef uint32_t	mono_unichar4;

typedef void	(*MonoFunc)	(void* data, void* user_data);
typedef void	(*MonoHFunc)	(void* key, void* value, void* user_data);

void mono_free (void *);

typedef struct {
	int version;
	void *(*malloc)      (size_t size);
	void *(*realloc)     (void *mem, size_t count);
	void (*free)        (void *mem);
	void *(*calloc)      (size_t count, size_t size);
} MonoAllocatorVTable;

mono_bool
mono_set_allocator_vtable (MonoAllocatorVTable* vtable);
]]
