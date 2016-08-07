-- COMMS by Tammya-MoonGuard --

CommsAddon = LibStub("AceAddon-3.0"):NewAddon( "Comms", 
	             		  "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0",
						  "AceTimer-3.0" ) 
local Main = CommsAddon
local L    = CommsLocale
 
--local PUB_CHAT_CHANNEL = "xtensionxtooltip2"

-------------------------------------------------------------------------------
Main.db_template = {
	
	global = {
		comms = {
		-- indexed by chat
			--   chat     - chat channel 
			--   name     - name of community 
			--   rank     - rank in community 
			--   alias    - username
			--   channels - list of channels in community, indexed by name
			--     cipher   - channel cipher
			--   hosts    - list of host toons
			--   admins   - list of admin toons
			--   ishost   - is host of community
			--   isadmin  - is admin of community  
		};
		
	};
}

-- a note why simple channels should use pub channels:
--   we dont want non-admins sharing private community channels with people

-------------------------------------------------------------------------------		  
function Main:OnInitialize()
	
	self.db = LibStub( "AceDB-3.0" ):New( "CommsAddonSaved", self.db_template, true )
end

-------------------------------------------------------------------------------
function Main:OnEnable()
	self:InitProtocol()
	self:JoinChannels()
	self:ScheduleTimer( "SendHostMessages", 3 )
	
	self:SetupConsole()
	
--	self:OpenWindow()
end

-------------------------------------------------------------------------------
function Main:SendHostMessages()
	for k,v in pairs( self.db.global.comms ) do
		if v.ishost then
			self:SendChannelMessage( v.chat, "host", {
				chat = v.chat;
				hosts = v.hosts;
			})
		end
	end
end	

-------------------------------------------------------------------------------
function Main:MakeHostsList( alts )
	local hosts = { UnitName( "player" ) }
	alts = alts or {}
	for _,v in pairs( alts ) do
		local duplicate = false
		for _,v2 in pairs( hosts ) do
			if v == v2 then
				duplicate = true
				break
			end
		end
		
		if not duplicate then
			table.insert( hosts, v )
		end
	end
end

-------------------------------------------------------------------------------
function Main:GetCommInfo( chat )
	return self.db.global.comms[chat]
end

-------------------------------------------------------------------------------
local function BadString( s, pattern )
	if not s or type( s ) ~= "string" then return true end
	pattern = pattern or ".+"
	if not s:match( pattern ) then return true end
end

-------------------------------------------------------------------------------
-- Create a new comm.
--
-- Data:
--   name = name of comm
--   chat = chat channel to use
--   rank = rank name of host (default: Host)
--   channels = channel list e.g { 
--                                  General = { desc="general chat", admins={ "pootytang" } }, 
--                                  Officers = { desc="officer chat" } 
--                               }
--              ciphers will be generated if not specified
--   hosts = host list, e.g. { "Me", "Myself" } character names
--   admins = global admin list, e.g. { "Myfriend", "Otherfriend" }
--
function Main:CreateComm( data )
	
	local comm = {
		ishost  = true;
		isadmin = true;
		hosts   = self:MakeHostsList( data.hosts );
		admins  = data.admins or {};
	}
	
	if BadString( data.name ) then self:Print( "Bad comm name." ) return end
	if BadString( data.chat ) then self:Print( "Bad chat-channel." ) return end
	comm.chat = data.chat
	
	-- catch duplicates
	if self:GetCommInfo( comm.chat ) then
		self:Print( "Chat-channel already in use." )
		return
	end
	
	comm.name = data.name
	comm.rank = data.rank or "Host"
	if not data.channels then self:Print( "Missing channel list." ) return end
	comm.channels = data.channels
	
	
	for k,v in pairs( comm.channels ) do
		if not v.cipher or v.cipher == "" then
			v.cipher = CcmCipher:Generate()
		end
		
		if BadString( k ) then
			print( "Bad channel name." )
			return
		end
	end
	 
	self.db.global.comms[comm.chat] = comm
	self:JoinChatChannel( comm.chat )
	
	self:SendMessage( "COMM_CREATED", comm )
	
	self:Print( "Comm created: %s", comm.name )
end

-------------------------------------------------------------------------------
-- invite player to comm
--
-- player = name of player
-- options = {
--   chat     = chat channel (comm)
--   rank     = player title
--   channels = list of channel names for them to have access to
-- }
function Main:CommInvite( player, options )
	if not player then return end
	
	if not options.rank then options.rank = "Member" end
	if not options.channels then self:Print( "Missing channel list." ) return end
	if BadString( options.chat ) then self:Print( "Missing comm chat." ) return end
	
	local comm = self:GetCommInfo( options.chat )
	if not comm then self:Print( "Undefined comm." ) return end
	if not comm.ishost then self:Print( "You are not the host of that channel." ) return end
	 
	local channels = {}
	for k, v in pairs( options.channels ) do
		if not comm.channels[v] then
			self:Print( "Unknown channel: %s", v )
			return
		end
		channels[v] = comm.channels[v]
	end
	
	local msg = {
		name     = comm.name;
		chat     = comm.chat;
		rank     = options.rank;
		channels = channels;
		hosts    = comm.hosts;
		admins   = comm.admins;
	}
	
	self:SendWhisperMessage( player, "inv", msg )
end

-------------------------------------------------------------------------------
-- kick player from comm channel(s)
--
-- player = player name
-- options = {
--   chat = chat channel
--   channels = list of channels to remove from, nil to remove from all
-- }
function Main:CommKick( player, options )
	if BadString( options.chat ) then self:Print( "Missing comm chat." ) return end
	local comm = self:GetCommInfo( options.chat )
	if not comm then self:Print( "Undefined comm." ) return end
	if not comm.isadmin then self:Print( "You are not an admin of that channel." ) return end
	
	local msg = {
		chat = comm.chat;
		channels = options.channels;
	}
	
	self:SendWhisperMessage( player, "kick", msg )
end


-------------------------------------------------------------------------------
function Main:RegisterModule( name, tbl, options )
	Main.modules[name] = tbl
	
	options = options or {}
	options.name = options.name or name
	
	if options.db then
		self.db_template.profile[name] = options.db
		tbl.db = function() return self.db.profile[name] end
	end
	--[[ change these into functions
	if options.config_section then
		self.config_options.args[ name .. "_config" ] = {
			name = L[options.name];
			type = "group";
			args = options.config_section;
		}
		
	end
	
	if options.config_general then
		self.Config:AddGeneral( options.config_general )
		
	end]]
	 
end

-------------------------------------------------------------------------------
function Main:GetModuleConfigOption( mod, name )
	return self.Config.options.args[ mod .. "_config" ].args[name]
end

-------------------------------------------------------------------------------
function Main:GetModuleConfigSection( mod )
	return self.Config.options.args[ mod .. "_config" ].args
end

-------------------------------------------------------------------------------
function Main:ModCall( module, method, ... )
	return self.modules[module][method]( self.modules[module], ... )
end 

-------------------------------------------------------------------------------
function Main:ModMethod( module, method, ... )
	return self.modules[module][method]
end 

-------------------------------------------------------------------------------
function Main:ModStaticCall( module, method, ... )
	return self.modules[module][method]( ... )
end 

-------------------------------------------------------------------------------
function Main:SendMessage( msgname, ... )

	-- pass to modules
	for k,v in pairs( self.modules ) do
		if v["MSG_" .. msgname] then
			v["MSG_" .. msgname]( v, ... )
		end
	end
	
	-- pass to other addons
	AceEvent:SendMessage( msgname, ... )
end

-------------------------------------------------------------------------------
function Main:Print( msg, ... )
	if select( "#", ... ) > 0 then
		msg = string.format( msg, ... )
	end
	
	print( "|cffd9bfb1<Comms>|r " .. msg )
end
