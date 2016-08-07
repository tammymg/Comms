 
-- enigma type shit

CcmCipher = {}

-------------------------------------------------------------------------------
function CcmCipher:Generate()
	local cipher = ""
	
	-- create a list of characters
	local chars = {}
	for i = 9,255 do
		table.insert( chars, string.char(i) )
	end
	
	-- shuffle them (fisher—yates)
	for i = #chars, 2, -1 do
		local j = math.random( 1, i )
		
		local a = chars[i]
		chars[i] = chars[j]
		chars[j] = a
	end
	
	chars = table.concat( chars ):sub( 1, 64 )
	
	return chars
end

-------------------------------------------------------------------------------
function CcmCipher:Checksum( text, clip )
	local sum = 0
	for i = 1, text:len() do
		sum = sum + text:byte(i)
	end
	
	if clip then
		return tostring(sum):sub( -clip )
	else
		return sum
	end
end

-------------------------------------------------------------------------------
function CcmCipher:Encode( msg, cipher )
	local encoded = ""
	local cipher_pos = 1 + (math.floor(msg:len() ^ 2.5) % cipher:len())
	for i = 1, msg:len() do
		local c = cipher:byte( cipher_pos )
		cipher_pos = (cipher_pos % cipher:len()) + 1
		local a = msg:byte(i)
		encoded = encoded .. string.char( ((a+c-1) % 255) + 1 )
	end
	
	return self:Checksum( cipher, 3 ) .. ":" .. encoded
end

-------------------------------------------------------------------------------
function CcmCipher:Decode( msg, cipher )
	local checksum = msg:match( "^(%d+):" ) 
	if not checksum then return end
	if checksum ~= CcmCipher:Checksum( cipher, 3 ) then return end 
	msg = msg:sub( 2+checksum:len() )
	local decoded = ""
	local cipher_pos = 1 + (math.floor(msg:len() ^ 2.5) % cipher:len())
	for i = 1, msg:len() do
		local c = cipher:byte( cipher_pos )
		cipher_pos = (cipher_pos % cipher:len()) + 1
		local a = msg:byte(i)
		decoded = decoded .. string.char( ((a-c-1) % 255) + 1 )
	end
	
	return decoded
end

-------------------------------------------------------------------------------
function CcmCipher:Test()
	
	for i = 1, 10 do
		local msg = CcmCipher:Generate()
		local cipher = CcmCipher:Generate()
		local original = msg
		print( "- TEST -" )
		print( msg, cipher )
		msg = self:Encode( msg, cipher )
		msg = self:Encode( msg, cipher )
		msg = self:Encode( msg, cipher )
		print( msg )
		msg = self:Decode( msg, cipher )
		if not msg then return false end
		msg = self:Decode( msg, cipher )
		if not msg then return false end
		msg = self:Decode( msg, cipher )
		if not msg then return false end
		print( msg )
		
		if msg ~= original then return false end
	end
	
	return true
end