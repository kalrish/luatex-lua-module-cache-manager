# The name of this file is `GNUmakefile' and not e.g. `Makefile' because it follows GNU Make and is not intended for other Make versions.


##############################################################################
#  Configuration - play with these variables
##############################################################################

# Which engine to use
#  examples: luatex, luajittex
ENGINE := luatex

# Format to use instead of the default
#FORMAT := 

# Additional arguments to pass to the engine
#  e.g.: --jiton, --jithash=luajit20
EXTRA_ENGINE_ARGUMENTS := 

# Format of the Lua module cache
#  Either 'b' (bytecode) or 't' (ASCII Lua source)
LUA_MODULE_CACHE_FORMAT := b

# Additional arguments meant for the Lua module cache manager
#  e.g.: --lua-module-cache-manager-verbose
EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS := 

# Format of the final document
#  e.g.: dvi, pdf
OUTPUT_FORMAT := pdf

##############################################################################


# Tell Make to use Bash to execute recipes, as otherwise we would have very little guarantee on the syntax and features that are available and it's Bash I'm testing this against. Use another shell at your own.
SHELL := bash

ifeq ($(ENGINE),luatex)
	TEXLUA_BYTECODE_EXTENSION := texluabc
else ifeq ($(ENGINE),luajittex)
	TEXLUA_BYTECODE_EXTENSION := texluajitbc
endif

ifeq ($(LUA_MODULE_CACHE_FORMAT),b)
	LUA_MODULE_CACHE_FILE_EXTENSION := $(TEXLUA_BYTECODE_EXTENSION)
else
	LUA_MODULE_CACHE_FILE_EXTENSION := lua
endif

ifeq ($(FORMAT),)
	ifeq ($(ENGINE),luatex)
		FORMAT := lualatex
	endif
	ifeq ($(ENGINE),luajittex)
		FORMAT := luajitlatex
	endif
endif

JOBNAME := main

# Note: on LuaTeX <0.89, the recorder feature (`--recorder`) causes segfaults. See [issue #2](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/2), reported by Henry So.
ENGINE_ARGUMENTS := --interaction=nonstopmode --halt-on-error --recorder $(EXTRA_ENGINE_ARGUMENTS) --lua=luamcm.$(TEXLUA_BYTECODE_EXTENSION) --lua-module-cache-file=$(JOBNAME).$(LUA_MODULE_CACHE_FILE_EXTENSION) --lua-module-cache-format=$(LUA_MODULE_CACHE_FORMAT) $(EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS) --jobname=$(JOBNAME) --fmt=$(FORMAT) --output-format=$(OUTPUT_FORMAT)

%.texluabc : %.lua
	texluac -s -o $@ -- $<

%.texluajitbc : %.lua
	texluajitc -bt raw $< $@

show: luamcm.$(TEXLUA_BYTECODE_EXTENSION) main.tex
	$(ENGINE) $(ENGINE_ARGUMENTS) -- main.tex

clean:
	rm -f -- luamcm.$(TEXLUA_BYTECODE_EXTENSION) main.{log,fls,aux,$(LUA_MODULE_CACHE_FILE_EXTENSION),$(OUTPUT_FORMAT)}

.PHONY : show clean