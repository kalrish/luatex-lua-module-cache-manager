# The name of this file is `GNUmakefile' and not e.g. `Makefile' because it follows GNU Make and is not intended for other Make versions.


.DEFAULT_GOAL := show
.PHONY : show clean


# Configuration - touch these
#  a LuaTeX-like engine, e.g. luatex or luajittex
ENGINE := luatex
#  the format to use - do set one only if you want or need to override the default (see below)
#FORMAT := 
#  note: on LuaTeX <0.89, the recorder feature (`--recorder`) causes segfaults; see [issue #2](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/2), reported by Henry So
ENGINE_ARGUMENTS := --interaction=nonstopmode --halt-on-error --file-line-error --recorder# --jiton
#  may be 'b' (bytecode) or 't' (ASCII Lua source)
LUA_MODULE_CACHE_MODE := b
#  arguments meant for the Lua module cache manager
EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS := --lua-module-cache-manager-verbose
OUTPUT_FORMAT := pdf

# Internal - don't touch these
JOBNAME := main
LUA_MODULE_CACHE_FILE_EXTENSION_t := lua
LUA_MODULE_CACHE_FILE_EXTENSION_b := lmc
LUA_MODULE_CACHE_FILE_EXTENSION := $(LUA_MODULE_CACHE_FILE_EXTENSION_$(LUA_MODULE_CACHE_MODE))
ifeq ($(FORMAT),)
	ifeq ($(ENGINE),luatex)
		FORMAT := lualatex
	endif
	ifeq ($(ENGINE),luajittex)
		FORMAT := luajitlatex
	endif
endif
ifneq ($(FORMAT),)
	ENGINE_ARGUMENTS += --fmt=$(FORMAT)
endif


# It might be needed to adjust this rule if the engine is neither LuaTeX nor LuaJITTeX
luamcm.texluabc: luamcm.lua
ifeq ($(ENGINE),luatex)
	texluac -s -o $@ -- $^
endif
ifeq ($(ENGINE),luajittex)
	texluajitc -b $^ $@
endif

show: luamcm.texluabc main.tex
	$(ENGINE) $(ENGINE_ARGUMENTS) --lua=luamcm.texluabc --lua-module-cache-file=$(JOBNAME).$(LUA_MODULE_CACHE_FILE_EXTENSION) --lua-module-cache-mode=$(LUA_MODULE_CACHE_MODE) $(EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS) --jobname=$(JOBNAME) --output-format=$(OUTPUT_FORMAT) -- main.tex


clean:
	rm -f -- *.texluabc main.log main.fls main.aux main.lua main.lmc main.pdf