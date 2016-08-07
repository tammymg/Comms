-- COMMS by Tammya-MoonGuard

CommsLocale = {}
local L = CommsLocale

-------------------------------------------------------------------------------
setmetatable( L, { 

	-- Normally, the key is the translation in english. 
	-- If a value isn't found, just return the key.
	__index = function( table, key ) 
		return key 
	end;
	
	-- When treating the L table like a function, it can accept arguments
	-- that will replace {1}, {2}, etc in the text.
	__call = function( table, key, ... )
		for i = 1, select( "#", ... ) do
			local text = select( i, ... )
			key = string.gsub( key, "{" .. i .. "}", text )
		end
		return key
	end;
})

-------------------------------------------------------------------------------
 