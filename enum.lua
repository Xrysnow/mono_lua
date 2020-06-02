--
local M = {}

local MonoTypeEnum = {}
M.MonoTypeEnum = MonoTypeEnum

MonoTypeEnum.MONO_TYPE_END = 0x00
MonoTypeEnum.MONO_TYPE_VOID = 0x01
MonoTypeEnum.MONO_TYPE_BOOLEAN = 0x02
MonoTypeEnum.MONO_TYPE_CHAR = 0x03
MonoTypeEnum.MONO_TYPE_I1 = 0x04
MonoTypeEnum.MONO_TYPE_U1 = 0x05
MonoTypeEnum.MONO_TYPE_I2 = 0x06
MonoTypeEnum.MONO_TYPE_U2 = 0x07
MonoTypeEnum.MONO_TYPE_I4 = 0x08
MonoTypeEnum.MONO_TYPE_U4 = 0x09
MonoTypeEnum.MONO_TYPE_I8 = 0x0a
MonoTypeEnum.MONO_TYPE_U8 = 0x0b
MonoTypeEnum.MONO_TYPE_R4 = 0x0c
MonoTypeEnum.MONO_TYPE_R8 = 0x0d
MonoTypeEnum.MONO_TYPE_STRING = 0x0e
MonoTypeEnum.MONO_TYPE_PTR = 0x0f
MonoTypeEnum.MONO_TYPE_BYREF = 0x10
MonoTypeEnum.MONO_TYPE_VALUETYPE = 0x11
MonoTypeEnum.MONO_TYPE_CLASS = 0x12
MonoTypeEnum.MONO_TYPE_VAR = 0x13
MonoTypeEnum.MONO_TYPE_ARRAY = 0x14
MonoTypeEnum.MONO_TYPE_GENERICINST = 0x15
MonoTypeEnum.MONO_TYPE_TYPEDBYREF = 0x16
MonoTypeEnum.MONO_TYPE_I = 0x18
MonoTypeEnum.MONO_TYPE_U = 0x19
MonoTypeEnum.MONO_TYPE_FNPTR = 0x1b
MonoTypeEnum.MONO_TYPE_OBJECT = 0x1c
MonoTypeEnum.MONO_TYPE_SZARRAY = 0x1d
MonoTypeEnum.MONO_TYPE_MVAR = 0x1e
MonoTypeEnum.MONO_TYPE_CMOD_REQD = 0x1f
MonoTypeEnum.MONO_TYPE_CMOD_OPT = 0x20
MonoTypeEnum.MONO_TYPE_INTERNAL = 0x21
MonoTypeEnum.MONO_TYPE_MODIFIER = 0x40
MonoTypeEnum.MONO_TYPE_SENTINEL = 0x41
MonoTypeEnum.MONO_TYPE_PINNED = 0x45
MonoTypeEnum.MONO_TYPE_ENUM = 0x55

return M
