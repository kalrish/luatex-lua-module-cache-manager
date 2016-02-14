# luatex-lua-module-cache-manager
Lua module cache manager for LuaTeX and cousins

## What is this? ##
`lua-module-cache-manager.lua` is a Lua initialization script for LuaTeX and cousins that manages a cache for Lua modules. Modules are loaded with `require`, a standard Lua function that offers a sophisticated system and is used widely in the LuaTeX landscape. They are typically loaded directly from Lua source files, which implies parsing them (and other steps). This incurs some cost. Lua implementations –including the ones bundled in LuaTeX and LuaJITTeX– typically turn Lua source code into a (binary) string of bytes called 'bytecode'. Loading bytecode is faster than loading Lua source code. This system approaches the problem by caching all Lua modules loaded from source as bytecode in a single file.

## How to use it? ##
LuaTeX engines understand the `--lua` option. Pass the script path as its argument:
> $  lualatex _--interaction=nonstopmode_ **--lua=lua-module-cache-manager.lua** _-- main.tex_

Keep in mind, though, that the Lua initialization script is run *every time*. You should consider byte-compiling it itself; the command depends on the engine in use:
> $  For LuaTeX:<br>
> $  texluac -s -o lua-module-cache-manager.texluabc -- lua-module-cache-manager.lua<br>
> $  For LuaJITTeX:<br>
> $  texluajitc -b lua-module-cache-manager.lua lua-module-cache-manager.texluabc

Lua initialization scripts have access to the arguments with which the LuaTeX engine was invoked. This script handles a few options:

option | type | description
------------ | ------------- | ------------
**--lua-module-cache-mode**=**b**\|t | optional | Cache format:<table><tr><td>**t**</td><td>ASCII Lua source</td></tr><tr><td>**b**</td><td>Lua bytecode. Should be a bit faster</td></tr></table>
**--lua-module-cache-file**=_/path/to/the/cache/file.extension_ | optional | Its default value depends on the cache format:<table><tr><td>**t**</td><td>_lua-module-cache.lua_</td></tr><tr><td>**b**</td><td>_lua-module-cache.texluabc_</td></tr></table>

## Where has it been tested? ##
I have tested it on LuaTeX and LuaJITTeX, both version 0.80, revision 5238, as packaged by TeX Live, on Windows.

## Does it really help? ##
A bit, ja, although I haven't properly benchmarked it. It can be more than half a second in my machine.
