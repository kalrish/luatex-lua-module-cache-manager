# luatex-lua-module-cache-manager
Lua module cache manager for LuaTeX engines

## Overview ##
`luamcm` is a LuaTeX Lua initialization script that manages a cache for Lua modules which works similarly to LaTeX's aux file. It speeds up document generation by about half a second in my machine, which is nice for small documents that are generated often.

## Context ##
Lua modules are typically loaded from source. The Lua implementations bundled in LuaTeX and LuaJITTeX turn Lua source into bytecode prior to executing it, so it would be faster to load them in bytecode form directly.

## How to use it ##
Use the `--lua` option:

    $  lualatex --lua=luamcm.lua main.tex

Since the Lua initialization script is to be run every time the document is generated, and the sole purpose of the cache manager is to speed things up, it would make sense to compile the script itself:

* LuaTeX:

    ```
    $  texluac -s -o luamcm.texluabc luamcm.lua
    ```
* LuaJITTeX:

    ```
    $  texluajitc -b luamcm.lua luamcm.texluajitbc
    ```

Then:

    $  lualatex --lua=luamcm.texluabc main.tex

Lua initialization scripts have access to the arguments with which the LuaTeX engine was invoked. This script handles a few options:

option | description
------------ | ------------
**--lua-module-cache-mode**=**b**\|t | Cache format:<table><tr><td>**t**</td><td>ASCII Lua source</td></tr><tr><td>**b**</td><td>Lua bytecode</td></tr></table>
**--lua-module-cache-file**=_/path/to/the/cache/file.extension_ | Its default value depends on the cache format:<table><tr><td>ASCII Lua source</td><td>lua-module-cache.lua</td></tr><tr><td>Bytecode</td><td>lua-module-cache.texluabc</td></tr></table>
**--lua-module-cache-manager-verbose** | Whether merely informational logging messages should be outputted to the terminal (and not only to the log file).

Pass them as if they were regular LuaTeX options:

    $  lualatex --lua=luamcm.lua --lua-module-cache-file=main.lmc --lua-module-cache-mode=b --lua-module-cache-manager-verbose main.tex

## Requirements ##
 -  a recent LuaTeX engine
	
	Tested on:
	 -  LuaTeX 0.80, revision 5238 by TeX Live 2015 on Windows.
	 -  LuaJITTeX 0.80, revision 5238 by TeX Live 2015 on Windows.
	 -  LuaTeX 0.95 by TeX Live 2016 on Windows.
	 -  LuaJITTeX 0.95 by TeX Live 2016 on Windows.

 -  a recent installation of the LuaLaTeX infrastructure
	
	In particular, the LaTeX kernel should include LuaTeX support and the [`luatexbase`](http://www.ctan.org/pkg/luatexbase) package should reflect this change. This all panned out around October 2015. See [issue #1](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/1) for a description of the problem you would face in case you didn't meet this requirement and a workaround by [Henry So](https://github.com/henryso).