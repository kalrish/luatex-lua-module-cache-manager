--[[
	Lua initialization script for LuaTeX and cousins that manages a cache for Lua modules.
]]


local next = next
local load = load
local type = type
local string_match = string.match
local string_dump = string.dump
local string_format = string.format
local texio_write = texio.write
local texio_write_nl = texio.write_nl
--[[
	Up to Lua 5.1, it was package.loaders. From Lua 5.2 onward, package.searchers.
	
	As of this writing, LuaTeX implements Lua 5.2 and thus understands package.searchers. LuaJITTeX, on the other hand, is stuck at 5.1, so we need to take care of the naming mismatch.
]]
local package_searchers = package.searchers or package.loaders


-- Prepended to every logging message
local logging_identification = "lua-module-cache-manager"

--[[
	Base logging function.
]]
local function log_base( target , log_type_id , ... )
	--[[
		Make sure that we start at the beginning of a new line. From the LuaTeX manual, section 7.16.1.2 (_`texio.write_nl`_):
		
			This function behaves like `texio.write`, but make sure that the given strings will appear at the beginning of a new line. You can pass a single empty string if you only want to move to the next line.
		
		FIXME: it adds an additional (unwanted) line break in some cases.
	]]
	texio_write_nl( target , "" )
	
	texio_write( target , logging_identification , ": " , log_type_id , ": " )
	texio_write( target , ... )
	
	texio_write_nl( target , "" )
end

-- See the description at section 7.16.1.1 (_`texio.write`_) of the LuaTeX manual
local log_target_log = 'log'
local log_target_term_and_log = 'term and log'

local function log_info( ... )
	log_base( log_target_log , "info" , ... )
end

local function log_error( ... )
	log_base( log_target_term_and_log , "error" , ... )
end


--[[
	Now comes option parsing. Section 2.1.3 (_Other commandline processing_) of the LuaTeX manual:
	
		From within the [Lua initialization] script, the entire commandline is available in the Lua table `arg`, beginning with `arg[0]`, containing the name of the executable.
	
	We use a couple Lua patterns for a very rudimentary parsing. See [section 6.4.1 of the Lua Reference Manual (_Patterns_)](http://www.lua.org/manual/5.2/manual.html#6.4.1) for more on them.
]]
local argument_processing_error = false
local i = 1

--[[
	The format of the cache file:
		'b'	Lua bytecode
		't'	Lua source (ASCII)
]]
local cache_mode
while arg[i] ~= nil and cache_mode == nil do
	-- In the pattern, I have used ".+" instead of "." because, if I had gone for the single-byte option, an argument with more than one byte (like "--lua-module-cache-mode=bt") would have been silently skipped
	cache_mode = string_match( arg[i] , "^%-%-lua%-module%-cache%-mode=(.+)$" )
	
	i = i + 1
end
if not cache_mode then
	-- No cache mode was specified; default to bytecode, as it should be faster
	cache_mode = 'b'
else
	if cache_mode ~= 'b' and cache_mode ~= 't' then
		-- We were told to use a cache format that we don't know
		log_error( "the specified Lua module cache mode ('" , cache_mode , "') isn't valid; use either 'b' (bytecode; default) or 't' (text)" )
		
		argument_processing_error = true
	end
end

-- Reset the counter
i = 1

--[[
	The path to the cache file.
]]
local cache_file_path
while arg[i] ~= nil and cache_file_path == nil do
	cache_file_path = string_match( arg[i] , "^%-%-lua%-module%-cache%-file=(.+)$" )
	
	i = i + 1
end
if not cache_file_path then
	--[[
		Defaults are evil, IMO, but I'll concede this one for the sake of making this script easier to use.
		
		It could be improved by using the jobname: `cache_file_path=$(jobname).lmc` (where 'lmc' is a random extension that stands for "Lua Module Cache"). However, the jobname is not available yet (we are at the Lua initialization script stage; see section 2.1.3 of the LuaTeX manual (_Other commandline processing_)). We could be 'smart' and peek at the arguments in the `arg` table to try to guess it, but the rules for computing the jobname are complex and we would not achieve it.
		
		Therefore, be warned that you must explicitly set the Lua module cache file path if:
		 ·  you have several jobs in the same directory; and either:
			 ·  they are being run with different versions of LuaTeX/LuaJITTeX; or
			 ·  more than one of them may be run in parallel.
		Otherwise there will be a conflict and those jobs will overwrite the cache everytime they are run. And the world will explode.
	]]
	
--	log_error( "the path of the Lua module cache file hasn't been specified (--lua-module-cache-file=path/to/file.ext)" )
	
--	argument_processing_error = true
	
	-- Be as smart as we can
	if cache_mode == 'b' then
		-- 'texluabc' stands for "TeXLua ByteCode"
		cache_file_path = "lua-module-cache.texluabc"
	else
--		assert( cache_mode == 't' )
		
		cache_file_path = "lua-module-cache.lua"
	end
end

-- Exit inmediatly if there were any problems encountered during option parsing
if argument_processing_error then
	os.exit( false )
end


--[[
	Internally, the cache is a table that maps a module's name (string) to its loader's bytecode (string).
]]
local cache
--[[
	Imagine that a module is loaded and we discover that it's not in the cache. This may happen if the document is changed (if, for instance, the package `microtype` is loaded when it wasn't before). We cache the new module, and we must also take note that we need to update the cache file, so that, in the next run, we'll find it in the cache.
]]
local cache_file_needs_to_be_updated = false


--[[
	An auxiliary function that hooks into (read: appends code to) a searcher function so as to add the module loader that it returns to the cache.
]]
local function hook_into_loader( searcher_index )
	-- Save the searcher previously stored
	local default_searcher = package_searchers[ searcher_index ]
	
	--[[
		We are going to emplace a new function in place of the old searcher. Their behavior must be identical. This includes its signature. From the [Lua 5.2 Reference Manual](http://www.lua.org/manual/5.2/manual.html#pdf-package.searchers):
		
			Each entry in this table [in Lua 5.2, `package.searchers`; `package.loaders` in Lua 5.1] is a _searcher function_. When looking for a module, `require` calls each of these searchers in ascending order, with the module name (the argument given to `require`) as its sole parameter.
		
		Therefore, the new function that takes the place of the old searcher must accept a string as its sole parameter, `module_name`. I would have used `...` (a vararg function in Lua speech) so as to keep ourselves independent from this interface, but it didn't work. Still don't know why.
	]]
	package_searchers[ searcher_index ] = function( module_name )
		--[[
			Again, from the [Lua 5.2 Reference Manual](http://www.lua.org/manual/5.2/manual.html#pdf-package.searchers):
			
				The [searcher] function can return another function (the module _loader_) plus an extra value that will be passed to that loader, or a string explaining why it did not find that module (or `nil` if it has nothing to say).
			
			Therefore:
			
				- The searcher we're hooking into successfully finds a module  ->  `retval1` is a function, `retval2` is either `nil` or "something"
				- The searcher we're hooking into doesn't have success  -------->  `retval1` is either `nil` or a string
		]]
		local retval1, retval2 = default_searcher( module_name )
		
		if type(retval1) == 'function' then
			--[[
				FIXME
				
				If `retval2` is not `nil`, it is an extra value that shall be passed to the module loader (`retval1`). The current code doesn't handle this case. To properly handle it, `retval2` would have to be _properly_ serialized. The Lua Reference Manual gives no clue about the type of this value, so we can't assume anything; it could be whatever. That's why I have preferred not to handle this case. Otherwise, it's ok; I haven't come across any use of this "extra value".
			]]
			assert( retval2 == nil,
				"can't handle extra value to be passed to the loader function" )
			
			-- We unconditionally add the module loader to the cache because we assume that there is a searcher function with higher priority that would have loaded the module from the cache, had it been cached, before `require` turned to this searcher function we have hooked into.
			
			-- Signal that we'll have to update the cache file
			cache_file_needs_to_be_updated = true
			
			--[[
				Remember that our cache associated each module's name with its loader's bytecode; we dump the bytecode now
				
				We pass `true` as the second argument to `string.dump` to tell it to strip the symbols from the dumped bytecode. From the LuaTeX manual, section 2.2 (_LUA behaviour_):
				
					There is also a two-argument form of `string.dump()`. The second argument is a boolean which,
if true, strips the symbols from the dumped data. This matches an extension made in `luajit`.
			]]
			cache[module_name] = string_dump(retval1,true)
			
			log_info( "module '" , module_name , "' now cached" )
		end
		
		return retval1, retval2
	end
end

--[[
	From the LuaTeX manual, section 2.2 (_LUA behaviour_):
	
		LuaTEX is able to use the kpathsea library to find `require()`d modules. For this purpose, `package.searchers[2]` is replaced by a different loader function, that decides at runtime whether to use kpathsea or the built-in core Lua function. It uses kpathsea when that is already initialized at that point in time, otherwise it reverts to using the normal `package.path` loader.
	
	Whether the second searcher uses kpathsea or not, it looks for Lua source files, meaning that we have to hook into this searcher function.
	
	Should we also hook into the third searcher, or is it cheap to load C libraries?
]]
hook_into_loader( 2 )


--[[
	A searcher function that tries to load the required module from the cache.
]]
local function try_to_load_module_from_cache( module_name )
	-- Query the cache with the require module's name
	local cache_entry = cache[module_name]
	if cache_entry then
		-- The module had been cached; try to load its loader's bytecode
		local retval1, retval2 = load(cache_entry,module_name,'b')
		if retval1 then
			log_info( "module '" , module_name , "' loaded from cache" )
			
			return retval1
		else
			-- `load` failed
			log_info( "couldn't load module '" , module_name , "' from cache: " , retval2 )
			
			return retval2
		end
	else
		-- The module is not cached. We'll cache it in the second default searcher's hook
		log_info( "module '" , module_name , "' wasn't cached" )
		
		return nil
	end
end

--[[
	From the [Lua 5.2 Reference Manual](http://www.lua.org/manual/5.2/manual.html#pdf-package.searchers):
	
		Each entry in this table [in Lua 5.2, `package.searchers`; `package.loaders` in Lua 5.1] is a _searcher function_. When looking for a module, `require` calls each of these searchers in ascending order, (…).
		
		1. The first searcher simply looks for a loader in the `package.preload` table.
		
		2. The second searcher looks for a loader as a Lua library, (…).
		
		3. The third searcher looks for a loader as a C library, (…).
		
		4. The fourth searcher tries an all-in-one loader.
	
	(1) is there to offer preloaded packages, which are not our business; we shall not change it. (2) is the one that loads Lua source files (whether guided or not by kpathsea), and, therefore, we must come before it so as to load the required Lua modules from the cache. `table.insert` does the job for us and avoids us having to fiddle with the table.
]]
table.insert( package_searchers , 2 , try_to_load_module_from_cache )


-- `fd_chunk_or_id` is either a file descriptor, a chunk or an id. Just trying to save some variables.
local fd_chunk_or_id
-- `err_msg` is the error message that some functions (e.g. `loadfile`, `io.open`,…) return. Again, just trying to save some variables.
local err_msg


--[[
	Serializes the internal Lua module cache as ASCII Lua source code that may be compiled or loaded.
]]
local function luaserialize_cache()
	-- Tables are more efficient than string concatenation
	
	local t = { "return{" }
	-- We reuse `i` from option parsing
	i = 1
	
	local module_name, module_loader_bytecode = next(cache)
	while module_name do
		i = i + 1
		t[i] = "["
		
		i = i + 1
		--[[
			From the [Lua 5.2 Reference Manual](http://www.lua.org/manual/5.2/manual.html#pdf-string.format):
			
				The `q` option formats a string between double quotes, using escape sequences when necessary to ensure that it can safely be read back by the Lua interpreter.
			
			I've seen module names that contain "dangerous" characters. Better safe than sorry.
		]]
		t[i] = string_format("%q",module_name)
		
		i = i + 1
		t[i] = "]="
		
		i = i + 1
		-- See above for the %q. Here it's not just being safe; it's necessary.
		t[i] = string_format("%q",module_loader_bytecode)
		
		i = i + 1
		t[i] = ","
		
		module_name, module_loader_bytecode = next(cache,module_name)
	end
	
	i = i + 1
	t[i] = "}"
	
	return t
end

--[[
	Updates the "on-disk" cache file.
]]
local function update_cache_file()
	fd_chunk_or_id, err_msg = io.open( cache_file_path , 'wb' )
	if fd_chunk_or_id then
		log_info( "Lua module cache file (path: `" , cache_file_path , "') opened successfully for writing" )
		
		-- Grab an ASCII-serialized version of the cache
		local cache_serialized_lua = luaserialize_cache()
		
		--[[
			`fd:write`'s first return value:
				`fd` on success
				`nil` on failure
			
			`stub` is there to let us know whether `io.write` failed. Just trying to be smart…
		]]
		local stub
		
		if cache_mode == 'b' then
			-- Instead of concatenating the strings of the table (either manually or with `table.concat`), we let `load` do that for us by using an index (`i`, you remember it from option parsing? We reuse it) and a small closure. This shall buy us some efficiency (those strings are really big)
			-- Using `stub` here to save `load`'s first return value, which is the compiled chunk as a function on success or `nil` on error
			i = 0
			stub, err_msg = load( function() i = i + 1 ; return cache_serialized_lua[i] end , "string" , 't' )
			if stub then
				-- `stub` is the compiled chunk as a function. Now it's a matter of dumping it
				
				--[[
					Note: You may wonder why we have first serialized the cache in text and then loaded it again. Keep in mind that updating the cache doesn't happen very often, while, once it is there [the cache], it is loaded **every** run. So having it in bytecode format should buy us a little improvement.
				]]
				
				stub, err_msg = fd_chunk_or_id:write( string_dump( stub , true ) )
			else
				log_error( "couldn't load Lua-serialized cache: ", err_msg )
				
				-- `stub` is `nil` now. If we let it this way, the code later would think that there was an error in `io.write`
				stub = false
			end
		else
--			assert( cache_mode == 't' )
			
			stub, err_msg = fd_chunk_or_id:write( table.unpack(cache_serialized_lua) )
		end
		
		if stub then
			log_info( "Lua module cache file (path: `" , cache_file_path , "', mode='" , cache_mode , "') written successfully" )
		elseif stub == false then
			log_error( "nothing was written to the cache file due to errors in the process" )
		else
			log_error( "couldn't write to cache file: ", err_msg )
		end
		
		fd_chunk_or_id:close()
	else
		log_error( "couldn't open cache file (path: `" , cache_file_path , "') for writing: " , err_msg )
	end
end


fd_chunk_or_id, err_msg = loadfile( cache_file_path , cache_mode )
if fd_chunk_or_id then
	log_info( "Lua module cache (path: `" , cache_file_path , "', mode='" , cache_mode , "') loaded successfully" )
	
	cache = fd_chunk_or_id()
else
	log_info( "couldn't load Lua module cache (path: `" , cache_file_path , "', mode='" , cache_mode , "'): " , err_msg )
	
	-- Initialize the cache to an empty state
	cache = {}
end


--[[
	Callback to be run at the end of the LuaTeX run. Checks whether we need to update the "on-disk" cache file.
]]
local function to_be_run_at_end_of_run()
	if not cache_file_needs_to_be_updated then
		log_info( "the cache file doesn't need to be updated" )
	else
		log_info( "the cache file needs to be updated" )
		
		update_cache_file()
	end
end

-- Caveat about using this callback and other options: see [this TeX.StackExchange question](http://tex.stackexchange.com/questions/292559/callback-to-be-run-at-the-end-of-the-job)
fd_chunk_or_id, err_msg = callback.register( "finish_pdffile" , to_be_run_at_end_of_run )
if fd_chunk_or_id then
	log_info( "callback successfully registered" )
else
	log_error( "couldn't register callback: " , err_msg )
	
	-- We are in a hurry if we couldn't register the callback. The user is in a hurry as well: I have no idea why `callback.register` would fail here, I guess something would have to be seriously broken…
	os.exit( false )
end