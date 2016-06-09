.DEFAULT_GOAL := show
.PHONY : show clean


# Configuration - touch these
ENGINE := lualatex
#ENGINE := luajitlatex
# The recorder feature (`--recorder`) seems to cause segfaults (they happen at `loadfile` time, when the cache file is loaded). See [issue #2](https://github.com/kalrish/luatex-lua-module-cache-manager/issues/2), reported by Henry So
ENGINE_ARGUMENTS := --interaction=nonstopmode --halt-on-error --file-line-error# --recorder# --jiton
LUA_MODULE_CACHE_MODE := b
# Arguments meant for the Lua module cache manager
EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS := --lua-module-cache-manager-verbose
OUTPUT_FORMAT := pdf

# Internal - don't touch these
JOBNAME := main
LUA_MODULE_CACHE_FILE_EXTENSION_t := lua
LUA_MODULE_CACHE_FILE_EXTENSION_b := lmc
LUA_MODULE_CACHE_FILE_EXTENSION := $(LUA_MODULE_CACHE_FILE_EXTENSION_$(LUA_MODULE_CACHE_MODE))


%.texluabc : %.lua
ifeq ($(ENGINE),lualatex)
	texluac -s -o $@ -- $^
else
	texluajitc -b $^ $@
endif


show: lua-module-cache-manager.texluabc main.tex
	$(ENGINE) $(ENGINE_ARGUMENTS) --lua=lua-module-cache-manager.texluabc --lua-module-cache-file=$(JOBNAME).$(LUA_MODULE_CACHE_FILE_EXTENSION) --lua-module-cache-mode=$(LUA_MODULE_CACHE_MODE) $(EXTRA_LUA_MODULE_CACHE_MANAGER_ARGUMENTS) --jobname=$(JOBNAME) --output-format=$(OUTPUT_FORMAT) -- main.tex


clean:
	rm -f -- *.texluabc main.log main.fls main.aux main.lua main.lmc main.pdf