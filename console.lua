
local Main = CommsAddon

-------------------------------------------------------------------------------
function Main:SetupConsole()
	SLASH_CCM1 = "/ccm"
end

-------------------------------------------------------------------------------
function SlashCmdList.CCM( msg )
	
	local data, error
	local cmd = msg:match( "([^ ]+)" )
	
	if cmd then 
		cmd = cmd:lower() 
		data, error = loadstring( "return " .. msg:sub( 1+cmd:len() ) )
		if not data then
			print( error )
			return
		end
	end
	
	if cmd == "create" then
		-- create community 
		Main:CreateComm( data() )
	elseif cmd == "inv" then
		-- activate comm
		Main:CommInvite( data() )
	
	elseif cmd == "kick" then
		-- kick player
		Main:CommKick( data() )
	end
end


