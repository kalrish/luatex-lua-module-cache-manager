# luatex-lua-module-cache-manager
Lua module cache manager for LuaTeX engines

## What is this? ##
`luamcm` is a Lua initialization script for LuaTeX engines that manages a cache for Lua modules. Lua modules are typically loaded from source. This implies parsing them and other steps, which incurs some cost. Lua implementations –including the ones bundled in LuaTeX and LuaJITTeX– internally turn the source code into something called 'bytecode'. Loading bytecode would thus be faster than loading source code, as it would skip a few steps. This system approaches the problem by caching all Lua modules loaded from source as bytecode in a single file that works similarly to LaTeX's aux file.

## Does it really help? ##
A bit, ja, although I haven't properly benchmarked it. It can be more than half a second in my machine, which is nice for small documents that are compiled often.

## How to use it? ##
LuaTeX engines understand the `--lua` option. Pass the script path as its argument:

    $  lualatex --lua=luamcm.lua main.tex

Keep in mind, though, that the Lua initialization script is run *every time*. You should consider byte-compiling it itself; the command depends on the engine in use:

* LuaTeX:

    ```
    $  texluac -s -o luamcm.texluabc luamcm.lua
    ```
* LuaJITTeX:

    ```
    $  texluajitc -b luamcm.lua luamcm.texluabc
    ```

Then:

    $  lualatex --lua=luamcm.texluabc main.tex

Lua initialization scripts have access to the arguments with which the LuaTeX engine was invoked. This script handles a few options:

option | type | description
------------ | ------------- | ------------
**--lua-module-cache-mode**=**b**\|t | optional | Cache format:<table><tr><td>**t**</td><td>ASCII Lua source</td></tr><tr><td>**b**</td><td>Lua bytecode. Should be a bit faster</td></tr></table>
**--lua-module-cache-file**=_/path/to/the/cache/file.extension_ | optional | Its default value depends on the cache format:<table><tr><td>**t**</td><td>_lua-module-cache.lua_</td></tr><tr><td>**b**</td><td>_lua-module-cache.texluabc_</td></tr></table>
**--lua-module-cache-manager-verbose** | optional | Whether merely informational logging messages should be outputted to the terminal (and not only to the log file).

Pass them to the script as if they were normal LuaTeX options:

    $  lualatex --lua=luamcm.lua --lua-module-cache-file=main.lmc --lua-module-cache-mode=b --lua-module-cache-manager-verbose main.tex

## Requirements ##
* A "new enough" version of LuaTeX/LuaJITTeX.

 It has been tested on:
    -  LuaTeX 0.80, revision 5238 by TeX Live 2015 on Windows.
    -  LuaJITTeX 0.80, revision 5238 by TeX Live 2015 on Windows.
    -  LuaTeX 0.95 by TeX Live 2016 on Windows.
    -  LuaJITTeX 0.95 by TeX Live 2016 on Windows.
* A recent enough installation of the LuaLaTeX infrastructure.

 In particular, the LaTeX kernel should include LuaTeX support and the [`luatexbase`](http://www.ctan.org/pkg/luatexbase) package should reflect this change. This all panned out around October 2015. See [issue #1](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/1) for a description of the problem you would face in case you didn't meet this requirement and a workaround by [Henry So](https://github.com/henryso).