
local Main = CommsAddon
local L = Main.Locale
local SharedMedia = LibStub("LibSharedMedia-3.0")
 
local g_pcolor   = {-0.25,1,0}
local g_newcolor = {1,1,-0.5}
 

Main.windows = {}

-------------------------------------------------------------------------------
local function ChatBox_OnMouseWheel(self, delta)
		
	local reps = IsShiftKeyDown() and 5 or 1
	if delta > 0 then
		if IsAltKeyDown() then
			self:ScrollToTop()
		elseif IsControlKeyDown() then
			-- todo: increase font size
			Main:SetFontSize( Main.db.profile.font.size + 1 )
		else
			for i = 1,reps do self:ScrollUp() end
		end
	else
		if IsAltKeyDown() then
			self:ScrollToBottom()
		elseif IsControlKeyDown() then
			-- todo: decrease font size
			Main:SetFontSize( Main.db.profile.font.size - 1 )
		else
			for i = 1,reps do self:ScrollDown() end
		end
	end
end

local function ChatBox_OnMessageScrollChanged( self ) 
	-- show or hide the scroll marker if we are scrolled up
	if self:GetCurrentScroll() ~= 0 then
		self.parent.scrollmark:Show()
	else
		self.parent.scrollmark:Hide()
	end
end

local function ChatBox_OnHyperlinkClick(self, link, text, button)
	
	if ( strsub(link, 1, 6) == "player" ) then
		local namelink, isGMLink;
		if ( strsub(link, 7, 8) == "GM" ) then
			namelink = strsub(link, 10);
			isGMLink = true;
		else
			namelink = strsub(link, 8);
		end
		
	--	local name, lineid, chatType, chatTarget = strsplit(":", namelink);
	--	if IsShiftKeyDown() and button == "RightButton" then
	--		Main:RemovePlayer( name )
--			return
--		end
	end
	
	SetItemRef(link, text, button, self);

end

local function Bar_OnMouseDown( self, button )
	if button == "LeftButton" then
		self:GetParent():StartMoving() 
	end
end

local function Bar_OnMouseUp( self, button )
	if button == "LeftButton" then
		self:GetParent():StopMovingOrSizing()
	end
end

local function Resize_OnMouseDown( self, button ) 
	if button == "LeftButton" then
		self:GetParent():StartSizing()
	end
end
	
local function Resize_OnMouseUp( self, button ) 
	if button == "LeftButton" then
		self:GetParent():StopMovingOrSizing() 
	end
end

local function Window_Open( self )
	self.frame:Show()
	-- todo: reset stuff
end

local WindowMethods = {
	["Open"] = Window_Open;
}

-------------------------------------------------------------------------------
function Main:FindUnusedWindow()
	for _,v in pairs( self.windows ) do
		if not v.active then
			return v
		end
	end
end

-------------------------------------------------------------------------------
function Main:OpenWindow()

	local w = self:FindUnusedWindow()
	if w then
		w:Open()
		return w
	end
	
	local frame = CreateFrame( "Frame", nil, UIParent )
	
	frame:SetSize( 300, 200 )
	frame:SetPoint( "CENTER", 0, 0 )
	
	frame.scrollmark = CreateFrame( "Frame", nil, frame )
	frame.scrollmark:SetPoint( "TOPLEFT", frame, "BOTTOMLEFT", 0, 4 )
	frame.scrollmark:SetPoint( "BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0 )
	frame.scrollmark.tex = frame.scrollmark:CreateTexture()
	frame.scrollmark.tex:SetAllPoints()
	frame.scrollmark.tex:SetTexture( 1, 0.21, 0.04, 1 )
	frame.scrollmark:Hide()
	--[[
	frame.scrollmark:SetScript( "OnUpdate", function()
		if g_has_unread_entries then
			-- flash red if we have new entries
			local a = math.sin(GetTime() * 3) * 0.4 + 0.6
			self.scrollmark.tex:SetTexture( 1, 0.21, 0.04, a )
		else
			self.scrollmark.tex:SetTexture( 1, 1, 1, 0.25 )
		end
		
	end)]]
	
	frame.resize = CreateFrame( "Frame", nil, frame ) 
	frame.resize:SetPoint( "BOTTOMRIGHT", 0, 0 )
	frame.resize:SetSize( 16, 16 )
	
	frame.bar = CreateFrame( "Frame", nil, frame ) 
	frame.bar.tex = frame.bar:CreateTexture()
	frame.bar:SetPoint( "TOPLEFT", 0, 0 )
	frame.bar:SetPoint( "BOTTOMRIGHT", frame, "TOPRIGHT", 0, -7 ) 
	frame.bar.tex:SetTexture( 1,1,1,0.25 )
	frame.bar.tex:SetAllPoints()
	
	frame.bg = frame:CreateTexture( nil, "BACKGROUND" )
	frame.bg:SetAllPoints()
	frame.bg:SetTexture( 0,0,0,0.25 )
	
	frame.chat = CreateFrame( "ScrollingMessageFrame", nil, frame )
	frame.chat:SetPoint( "TOPLEFT", 2, -16 )
	frame.chat:SetPoint( "BOTTOMRIGHT", -2, 2 )
	frame.chat:SetMaxLines( 500 )
	frame.chat:SetTimeVisible( 300 )
	 
	frame.chat:SetFont( "Fonts\\ARIALN.TTF", 12, "OUTLINE" )
	frame.chat:SetJustifyH( "LEFT" )
	frame.chat:EnableMouseWheel( true )
	frame.chat.parent = frame
	
	frame.chat:SetScript("OnMouseWheel", Chatbox_OnMouseWheel )
	frame.chat:SetScript( "OnMessageScrollChanged", ChatBox_OnMessageScrollChanged )
	
	frame.chat:SetScript( "OnHyperlinkClick", ChatBox_OnHyperlinkClick )
	
	frame.bar:EnableMouse( true )
	frame:SetMovable( true )
	frame:SetResizable( true )
	frame:SetMinResize( 200, 100 )
	
	frame.bar:SetScript( "OnMouseDown", Bar_OnMouseDown ) 
	frame.bar:SetScript( "OnMouseUp", Bar_OnMouseUp )
	
	frame.resize:EnableMouse()
	frame.resize:SetScript( "OnMouseDown", Resize_OnMouseDown )
	frame.resize:SetScript( "OnMouseUp", Resize_OnMouseUp )
	
	frame:Show()
	
	local window = {
		frame = frame;
		active = true;
	}
	
	for k,v in pairs(WindowMethods) do window[k] = v end
	
	table.insert( self.windows, window )
	return window
end

-------------------------------------------------------------------------------
function Main:SetChatFont( font )
	self.db.profile.font.face = font
	self:LoadChatFont()
end

-------------------------------------------------------------------------------
function Main:SetFontSize( size )
	size = math.max( size, 6 )
	size = math.min( size, 24 )
	self.db.profile.font.size = size
	self:LoadChatFont()
end

-------------------------------------------------------------------------------
function Main:LoadChatFont()
	local font = SharedMedia:Fetch( "font", self.db.profile.font.face )
	
	for k, v in pairs( self.windows ) do 
		v.frame.chat:SetFont( font, self.db.profile.font.size, "OUTLINE" )
	end
end
