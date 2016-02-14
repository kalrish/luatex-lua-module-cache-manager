local log_outfile = io.stderr

local function log_output( id , ... )
	log_outfile:write( id , ": " )
	
	log_outfile:write( ... )
	
	log_outfile:write( "\n" )
	
	log_outfile:flush()
end

local function log_info(...)
	log_output( "info" , ... )
end

local function log_error(...)
	log_output( "error" , ... )
end


local errors = false

local tex_engine_parameters = {}
assert( loadfile( 'tex-engine-parameters.lua53bc' , 'b' , tex_engine_parameters ) )()

local logfile_path = "main.log"


local log = ""
local string_find = string.find
local function log_find_string( s )
	return string_find( log , s , 1 , true ) ~= nil
end
local os_time = os.time

local function reload_log()
	local fd, error_string = io.open( logfile_path , 'rb' )
	if fd then
		log = fd:read( 'a' )
		
		fd:close()
	else
		assert( fd == nil )
		
		log_error( "couldn't open log file: " , error_string )
		
		os.exit( false )
	end
end

local error_strings = {
	"ultiply defined",
	"same identifier",
	"error:",
	"issing character",
	"LaTeX Font Warning: Font shape"
}
local error_strings_n = #error_strings

local function there_were_errors()
	for i = 1, error_strings_n do
		if log_find_string( error_strings[i] ) then
			return true
		end
	end
	
	return false
end

local function there_were_erfulls()
	return log_find_string( "erfull" )
end


local command_string = tex_engine_parameters.engine .. " " .. table.concat(tex_engine_parameters.engine_arguments," ") .. " --lua=lua-module-cache-manager.texluabc --lua-module-cache-file=" .. tex_engine_parameters.lua_module_cache_file .. " --lua-module-cache-mode=" .. tex_engine_parameters.lua_module_cache_mode .. " --output-format=" .. tex_engine_parameters.output_format .. " -- " .. tex_engine_parameters.main_file
log_info( "starting run: " , command_string )
local time_run_start = os_time()
local terminated_successfully, exit_way, code = os.execute( command_string )
local time_run_end = os_time()
if terminated_successfully == true then
	if exit_way == "exit" then
		reload_log()
		
		if there_were_errors() then
			log_error( "there were errors" )
			errors = true
		end
		
		if code ~= 0 then
			log_error( "the TeX engine failed (exit code = " , code , ")" )
			errors = true
		end
		
		if not errors then
			local time_run_delta = os.difftime(time_run_end,time_run_start)
			
			log_info( "run completed in " , time_run_delta , "s" )
		else
			os.exit( false )
		end
	else
		assert( exit_way == "signal" )
		
		log_error( "the TeX engine was terminated by a signal (signal = " , code , ")" )
		
		os.exit( false )
	end
else
	log_error( "the TeX engine didn't terminate successfully (exit code = " , code , ")" )
	
	os.exit( false )
end

if there_were_erfulls() then
	log_error( "there were erfulls" )
	errors = true
end

os.exit( not errors )