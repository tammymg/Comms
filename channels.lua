-- for managing physical chat channels

local Main = CommsAddon

function Main:JoinChannels()
	local joined = {}
	for k, v in pairs( self.db.global.comms ) do
		if not joined[v.chat] then
			joined[v.chat] = true
			JoinPermanentChannel( v.chat )
		end
	end
end

function Main:JoinChatChannel( name )
	JoinPermanentChannel( name )
end

function Main:LeaveChatChannel( name )
	
	LeaveChannelByName( name )
end