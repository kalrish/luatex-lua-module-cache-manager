main_file = "main.tex"
--engine = "lualatex"
engine = "luajitlatex"
lua_module_cache_file="lua-module-cache.texluabc"
lua_module_cache_mode='b'
--lua_module_cache_mode='t'
--output_format='dvi'
output_format='pdf'
engine_arguments = {
	"--interaction=nonstopmode",
	"--halt-on-error",
	"--file-line-error",
	"--recorder",
--	"--jiton"
}