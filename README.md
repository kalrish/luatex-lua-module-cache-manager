# luatex-lua-module-cache-manager
Lua module cache manager for LuaTeX and cousins

## What is this? ##
`lua-module-cache-manager.lua` is a Lua initialization script for LuaTeX and cousins that manages a cache for Lua modules. Modules are loaded with `require`, a standard Lua function that offers a sophisticated system and is used widely in the LuaTeX landscape. They are typically loaded directly from Lua source files, which implies parsing them (and other steps). This incurs some cost. Lua implementations –including the ones bundled in LuaTeX and LuaJITTeX– typically turn Lua source code into a (binary) string of bytes called 'bytecode'. Loading bytecode is faster than loading Lua source code. This system approaches the problem by caching all Lua modules loaded from source as bytecode in a single file.

## Does it really help? ##
A bit, ja, although I haven't properly benchmarked it. It can be more than half a second in my machine, which is nice for small documents that are compiled often.

## How to use it? ##
LuaTeX engines understand the `--lua` option. Pass the script path as its argument:

    $  lualatex --interaction=nonstopmode --lua=lua-module-cache-manager.lua -- main.tex

Keep in mind, though, that the Lua initialization script is run *every time*. You should consider byte-compiling it itself; the command depends on the engine in use:

* For LuaTeX:

    ```
    $  texluac -s -o lua-module-cache-manager.texluabc -- lua-module-cache-manager.lua
    ```
* For LuaJITTeX:

    ```
    $  texluajitc -b lua-module-cache-manager.lua lua-module-cache-manager.texluabc
    ```

Then:

    $  lualatex --interaction=nonstopmode --lua=lua-module-cache-manager.texluabc -- main.tex

Lua initialization scripts have access to the arguments with which the LuaTeX engine was invoked. This script handles a few options:

option | type | description
------------ | ------------- | ------------
**--lua-module-cache-mode**=**b**\|t | optional | Cache format:<table><tr><td>**t**</td><td>ASCII Lua source</td></tr><tr><td>**b**</td><td>Lua bytecode. Should be a bit faster</td></tr></table>
**--lua-module-cache-file**=_/path/to/the/cache/file.extension_ | optional | Its default value depends on the cache format:<table><tr><td>**t**</td><td>_lua-module-cache.lua_</td></tr><tr><td>**b**</td><td>_lua-module-cache.texluabc_</td></tr></table>

Pass them to the script as if they were normal LuaTeX options:

    $  lualatex --interaction=nonstopmode --lua=lua-module-cache-manager.lua --lua-module-cache-file=main.lmc --lua-module-cache-mode=b -- main.tex

## Requirements ##
* A "new enough" version of LuaTeX/LuaJITTeX.

 I have tested it on both, version 0.80, revision 5238, as packaged by TeX Live on Windows.
* A recent enough installation of the LuaLaTeX infrastructure.

 In particular, the LaTeX kernel should include LuaTeX support and the [`luatexbase`](http://www.ctan.org/pkg/luatexbase) package should reflect this change. This all panned out around October 2015. See [issue #1](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/1) for a description of the problem you would face in case you didn't meet this requirement and a workaround by [Henry So](https://github.com/henryso).
