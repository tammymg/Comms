
local Main = CommsAddon

local COMM_PREFIX      = "Ccm"
local PROTOCOL_VERSION = 1

Main.Protocol = {}

local Me = Main.Protocol

function Me:Init()
	RegisterAddonMessagePrefix( "Ccm" )
end

function Me:OnReceivedMessage( packed_message, dist, sender, channel )

	local result, msg, data = self:Deserialize( packed_message )
	if result == false then return end -- bad message
	
	sender = Ambiguate( sender, "all" )
	
	if data.pv ~= PROTOCOL_VERSION then
		-- incompatible protocols!
		if data.pv > PROTOCOL_VERSION then
			if not self.warned_protocol_outdated then
				self.warned_protocol_outdated = true
				--self:Print( L["Your version is outdated. Please update."] )
			end
		end
		return
	end
	
	local func = "OnComm_" .. msg
	if self.func then
		self.func( self, data, dist, sender )
	end 
end

-------------------------------------------------------------------------------
function Main:OnComm_hi( data, dist, sender )
	
	if data.r then
		
	end
end

function Main:OnComm_m( data, dist, sender )

end

function Main:OnComm_l( data, dist, sender )

end

function Main:OnComm_inv( data, dist, sender )

end

function Main:OnComm_kick( data, dist, sender )

end

function Main:OnComm_host( data, dist, sender )
end
 
-------------------------------------------------------------------------------
function Main:SendChannelMessage( channel, msg, data, prio )
	local chnum = GetChannelName( channel )
	if not chnum then return end -- not in channel
	prio = prio or "ALERT"
	
	data = data or {}
	data.pv = PROTOCOL_VERSION
	local packed = self:Serialize( msg, data )
	
	self:SendCommMessage( "Ccm", packed, "CHANNEL", tostring(chnum), prio )
end

-------------------------------------------------------------------------------
function Main:SendWhisperMessage( target, msg, data, prio )
  
	prio = prio or "ALERT"
	
	data = data or {}
	data.pv = PROTOCOL_VERSION
	local packed = self:Serialize( msg, data )
	
	self:SendCommMessage( "Ccm", packed, "WHISPER", target, prio )
end

-------------------------------------------------------------------------------
-- Line protocol
-------------------------------------------------------------------------------

function self:SendCcmMessage( 