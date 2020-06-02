--
local mono = require('monolua').init(
        'mono-2.0-boehm.dll',
        'test',
        "C:/Program Files (x86)/Mono/lib",
        "C:/Program Files (x86)/Mono/etc")
local assembly = mono.Assembly(mono.lib.corlib_assembly)
local Console = assembly:getClass('System', 'Console')
Console:invokeStaticMethod(':WriteLine(string)', 'Hello world!')
mono.finish()
