-- Syrup Chatbox-2
-- Author : Maple_Guy
--Made to look like the new world (the mmorpg) chatbox with a twist
--Started on : 2023-07-15

if SERVER then
    return
end

local colours = {
    globalChat = Color(0,255,160),
    localChat = Color(214, 164, 56),
    dmChat = Color(186, 238, 238),
    tradeChat = Color(119, 246, 255),
    recruitmentChat = Color(255, 252, 80),
    adminChat = Color(255, 165, 80)
}

local gradient = Material("gui/center_gradient")
local gradient2 = Material("vgui/gradient_up")
local gradient3 = Material("vgui/gradient_down")

local hasOpenedPanel = false
local chatMode = false
local chatType = "Global"
local chatTypes = {"Global", "Local", "DM", "Trade", "Recruitment", "Admin"}

local chatLogPanel = {}
local frame = {}
local chatEntryPanel = {}
local chatTypePanel = {}
local chatBarPanel = {}
local vbarPaint = {}
local chatMessages = {}
local doneOnce = false
local curretnText = ""

local lastChatType = ""
local chatFadeout = 12

local lastMessage = 0

surface.CreateFont( "sChat_18", {
    font = "Roboto Lt",
    size = 18,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
} )

surface.CreateFont( "sChat_16", {
    font = "Roboto Lt",
    size = 14,
    weight = 500,
    antialias = true,
    shadow = true,
    extended = true,
} )

function sendToServer(msgType, text, channel, target)
    local sanitizedInput = string.gsub(text, '[\\:%*%?%z%c"<>|]', '')

    net.Start(msgType)
        net.WriteString(sanitizedInput)
        net.WriteString(channel)
        net.WriteString(target)
    net.SendToServer()
end

if not GAMEMODE then
    hook.Remove("Initialize", "sChat_init")
    hook.Add("Initialize", "sChat_init", function()
        include("autorun/client/cl_chat.lua")
    end)
    return
end

local function SetFocusOnTextPanel(panel)
    if not IsValid(panel) then return end

    if panel == chatEntryPanel then
        chatEntryPanel:KillFocus()
    elseif panel == chatDMTargetPanel then
        chatDMTargetPanel:KillFocus()
    end
    panel:RequestFocus()
end

local function IsPlayerInPropMenu()
    return IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible()
end

local function ChatBoxPanel(first)

    if first then
        frame = vgui.Create( "DFrame" )
        frame:SetSize(ScrW() * 0.21, ScrH() * 0.4)
        frame:SetTitle("")
        frame:ShowCloseButton(false) //temp
        frame:SetPos(ScrW() * 0.005, ScrH() * 0.5)
        
        frame:SetDraggable(false)
        frame:SetVisible(true)
    end
    frame.UseDown = true
    if hasOpenedPanel then
        frame:MakePopup()
    end
    local DoClose = false

    function frame:Paint( w, h )
        surface.SetDrawColor( 20,20,20, 0)
        surface.DrawRect( 0, 0, w, h )
        if hasOpenedPanel then
            surface.SetDrawColor( 219,219,219,178)       
            surface.DrawOutlinedRect( 0, 0, w, h )
        end
    end
    if first then
        chatBarPanel = vgui.Create("Panel", frame)
        chatBarPanel:SetSize(frame:GetWide(), 50)
        chatBarPanel:SetPos(0, frame:GetTall() - 50)
    end    

    function chatBarPanel:Paint( w, h )
        if hasOpenedPanel then
            surface.SetDrawColor(20,20,20, 10)
            surface.DrawRect(0, 0, w, h ) 
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
        end
    end
    if first then
        chatTypePanel = vgui.Create("Panel", chatBarPanel)
        chatTypePanel:SetSize(chatBarPanel:GetWide(), 25)
        chatTypePanel:SetPos(0, 0)
    end

    function chatTypePanel:Paint( w, h )
        if hasOpenedPanel then
            surface.SetDrawColor(20,20,20, 0)
            surface.DrawRect(0, 0, w, h )

            if chatType == "Global" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.globalChat, TEXT_ALIGN_LEFT)
            elseif chatType == "Local" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.localChat, TEXT_ALIGN_LEFT)
            elseif chatType == "DM" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.dmChat, TEXT_ALIGN_LEFT)
            elseif chatType == "Trade" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.tradeChat, TEXT_ALIGN_LEFT)
            elseif chatType == "Recruitment" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.recruitmentChat, TEXT_ALIGN_LEFT)
            elseif chatType == "Admin" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.adminChat, TEXT_ALIGN_LEFT)
            else
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.globalChat, TEXT_ALIGN_LEFT)
            end
        end
    end
    if first then
        chatEntryPanel = vgui.Create("DTextEntry", chatBarPanel)
        chatEntryPanel:SetSize(chatBarPanel:GetWide(), 25)
        chatEntryPanel:SetPos(0, 25)
        chatEntryPanel:SetTextColor(Color(255, 255, 255))
        chatEntryPanel:SetFont("sChat_18")
        chatEntryPanel:SetHighlightColor( Color(52, 152, 219) )
        chatEntryPanel:SetHistoryEnabled(true)

    end
    if hasOpenedPanel then
        chatEntryPanel:RequestFocus()
    end

    function chatEntryPanel:Paint( w, h )
        if hasOpenedPanel then
            surface.SetDrawColor(20,20,20, 126)
            surface.DrawRect(0, 0, w, h )
            --derma.SkinHook( "Paint", "TextEntry", self, w, h )
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
            self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        end
    end

    if first then
        chatDMTargetPanel = vgui.Create("DTextEntry", chatBarPanel)
        chatDMTargetPanel:SetSize(chatBarPanel:GetWide() * 0.3, 25)
        chatDMTargetPanel:SetPos(chatBarPanel:GetWide() * 0.7, 0)
        chatDMTargetPanel:SetTextColor(Color(255, 255, 255))
        chatDMTargetPanel:SetFont("sChat_18")
        chatDMTargetPanel:SetHighlightColor( Color(52, 152, 219) )
    end

    function chatDMTargetPanel:Paint( w, h )
        if hasOpenedPanel && lastChatType == "DM" then
            surface.SetDrawColor(20,20,20, 126)
            surface.DrawRect(0, 0, w, h )
            --derma.SkinHook( "Paint", "TextEntry", self, w, h )
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
            self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        end
    end

    if first then
        chatLogPanel = vgui.Create("DScrollPanel", frame)
        chatLogPanel:SetSize(frame:GetWide() + 5, frame:GetTall() - chatBarPanel:GetTall())
        chatLogPanel:SetPos(0, 0)
    end

    function chatLogPanel:Paint( w, h )
        surface.SetDrawColor(20,20,20, 0)
        surface.DrawRect(0, 0, w, h )
    end

    local vbar = chatLogPanel.VBar
    vbar:SetHideButtons( true )

    function vbar.btnUp:Paint( w, h ) end
    function vbar:Paint (w, h )
        if hasOpenedPanel then
            surface.SetDrawColor(20,20,20, 51)
            surface.DrawRect(0, 0, w - 5, h )
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
        end
    end
    function vbar.btnGrip:Paint( w, h )
        if hasOpenedPanel then
            surface.SetDrawColor(255,182,24)
            surface.DrawRect(0, 0, w - 5, h )
        end
    end

    chatLogPanel.Think = function( self )
		if lastMessage then
			if CurTime() - lastMessage > chatFadeout then
				self:SetVisible( false )
			else
				self:SetVisible( true )
			end
		end
    end

    if hasOpenedPanel then

        function sendChat()
            local target = ""
    
            local sanitizedInput = string.gsub(chatEntryPanel:GetText(), '[\\:%*%?%z%c"<>|]', '')

            if string.Trim( sanitizedInput ) ~= "" then
                if chatType == chatTypes[2] then
                    lastChatType = "Local"
                elseif chatType == chatTypes[3] then
                    lastChatType = "DM"
                    target = chatDMTargetPanel:GetText()
                elseif chatType == chatTypes[4] then
                    lastChatType = "Trade"
                elseif chatType == chatTypes[5] then
                    lastChatType = "Recruitment"
                elseif chatType == chatTypes[6] then
                    lastChatType = "Admin"
                else
                    lastChatType = "Global"
                end

                hasOpenedPanel = false

                net.Start("SendChat")
                    net.WriteString(sanitizedInput)
                    net.WriteString(lastChatType)
                    net.WriteString(target)
                net.SendToServer()

                chatEntryPanel:SetText("")
                chatDMTargetPanel:SetText("")

                timer.Create("frameFaded", 0.1, 0, function()
                    hasOpenedPanel = false

                    frame:SetMouseInputEnabled( false )
                    frame:SetKeyboardInputEnabled( false )
                    gui.EnableScreenClicker( false )

                    timer.Remove("frameFaded")
                end)
            end
        end

        chatEntryPanel.OnTextChanged = function( self )
            if self and self.GetText then 
                gamemode.Call( "ChatTextChanged", self:GetText() or "" )
            end

            local checkCommand = string.sub(self:GetText(), 1, 3)
            if checkCommand == "/g " then
                lastChatType = "Global"
                chatType = "Global"
                self:SetText(string.sub(self:GetText(), 4))
            elseif checkCommand == "/l " then
                lastChatType = "Local"
                chatType = "Local"
                self:SetText(string.sub(self:GetText(), 4))
            elseif checkCommand == "/a " and LocalPlayer():IsAdmin() then
                lastChatType = "Admin"
                chatType = "Admin"
                self:SetText(string.sub(self:GetText(), 4))
            elseif checkCommand == "/t " then
                lastChatType = "Trade"
                chatType = "Trade"
                self:SetText(string.sub(self:GetText(), 4))
            elseif checkCommand == "/r " then
                lastChatType = "Recruitment"
                chatType = "Recruitment"
                self:SetText(string.sub(self:GetText(), 4))
            elseif checkCommand == "/d " then
                lastChatType = "DM"
                chatType = "DM"
                self:SetText(string.sub(self:GetText(), 4))
            end
            local currentText = self:GetText()
            local maxCharacterLimit = 200
        
            if #currentText > maxCharacterLimit then
                self:SetText(string.sub(currentText, 1, maxCharacterLimit))
                self:SetCaretPos(maxCharacterLimit)
            end
        end

        chatDMTargetPanel.OnTextChanged = function( self )
            if self and self.GetText then 
                gamemode.Call( "ChatTextChanged", self:GetText() or "" )
            end
            local currentText = self:GetText()
            local maxCharacterLimit = 200
            if #currentText > maxCharacterLimit then
                self:SetText(string.sub(currentText, 1, maxCharacterLimit))
                self:SetCaretPos(maxCharacterLimit)
            end
        end

        chatEntryPanel.OnMousePressed = function()
            SetFocusOnTextPanel(chatEntryPanel)
        end
        
        chatDMTargetPanel.OnMousePressed = function()
            SetFocusOnTextPanel(chatDMTargetPanel)
        end
    
        function chatEntryPanel.OnKeyCodeTyped(self, code)
            local currentText = self:GetText()
            if code == KEY_TAB then

                if LocalPlayer():IsAdmin() then
                    typeSelector = (typeSelector and typeSelector + 1) or 2
                    if typeSelector > 6 then typeSelector = 1 end
                    if typeSelector < 1 then typeSelector = 6 end
                    chatType = chatTypes[typeSelector]
                    lastChatType = chatType
                    chatEntryPanel:RequestFocus()
                    chatDMTargetPanel:SetText("")
                    doneOnce = false
                else
                    typeSelector = (typeSelector and typeSelector + 1) or 2
                    if typeSelector > 5 then typeSelector = 1 end
                    if typeSelector < 1 then typeSelector = 5 end
                    chatType = chatTypes[typeSelector]
                    lastChatType = chatType
                    chatEntryPanel:RequestFocus()
                    chatDMTargetPanel:SetText("")
                    doneOnce = false
                end
                

            elseif code == KEY_ENTER then
                sendChat()
            end
        end

        function chatDMTargetPanel.OnKeyCodeTyped(self, code)
            if code == KEY_TAB then
                
                typeSelector = (typeSelector and typeSelector + 1)
                chatType = chatTypes[typeSelector]
                lastChatType = chatType
                chatEntryPanel:RequestFocus()
                chatDMTargetPanel:SetText("")
                doneOnce = false
            elseif code == KEY_ENTER then
                sendChat()
            end
        end

        function frame:Think()
            if IsPlayerInPropMenu() then return end
        
            if hasOpenedPanel then
                if lastChatType == "DM" then
                    if !doneOnce then
                        chatEntryPanel:RequestFocus()
                        doneOnce = true
                    end    
                else
                    chatEntryPanel:RequestFocus()
                end
            end
        
            if self.UseDown and not input.IsKeyDown(KEY_Y) then
                self.UseDown = false
                return
            elseif input.IsKeyDown(KEY_ESCAPE) then
                doneOnce = false
                if hasOpenedPanel then
                    gui.HideGameUI()
                end
                lastMessage = CurTime()
                chatEntryPanel:SetText("")
                chatDMTargetPanel:SetText("")
                hasOpenedPanel = false
                frame:SetMouseInputEnabled(false)
                frame:SetKeyboardInputEnabled(false)
                gui.EnableScreenClicker(false)
            end
        end
    end
end

local function AfterPanelPaint(panel)

	if not hasOpenedPanel then
		local scroll = chatLogPanel:GetVBar()
		local current = scroll:GetScroll()
		scroll:SetScroll(current + 10000000000000000)
	end

end

local function charWrap(text, remainingWidth, maxWidth)
    local totalWidth = 0

    text = text:gsub(".", function(char)
        totalWidth = totalWidth + surface.GetTextSize(char)

        if totalWidth >= remainingWidth then
            totalWidth = surface.GetTextSize(char)
            remainingWidth = maxWidth
            return "\n" .. char
        end

        return char
    end)

    return text, totalWidth
end

function textWrap(text, font, maxWidth)
    local totalWidth = 0

    surface.SetFont(font)

    local spaceWidth = surface.GetTextSize(' ')
    text = text:gsub("(%s?[%S]+)", function(word)
            local char = string.sub(word, 1, 1)
            if char == "\n" or char == "\t" then
                totalWidth = 0
            end

            local wordlen = surface.GetTextSize(word)
            totalWidth = totalWidth + wordlen

            if wordlen >= maxWidth then
                local splitWord, splitPoint = charWrap(word, maxWidth - (totalWidth - wordlen), maxWidth)
                totalWidth = splitPoint
                return splitWord
            elseif totalWidth < maxWidth then
                return word
            end

            if char == ' ' then
                totalWidth = wordlen - spaceWidth
                return '\n' .. string.sub(word, 2)
            end

            totalWidth = wordlen
            return '\n' .. word
        end)

        local count = text:gsub("[^\n]", ""):len()+1

    return text, count
end

function AddChatMessage(sender, text, chatTypeS, target)

	local typeColor = Color(0, 0, 0)
	local typePretty = "idk"
	
	if chatTypeS == "Global" then
		typeColor = colours.globalChat
		typePretty = "GLOBAL"
	elseif chatTypeS == "Local" then
		typeColor = colours.localChat
		typePretty = "LOCAL"
	elseif chatTypeS == "DM" then
		typeColor = colours.dmChat
		typePretty = "DM"
    elseif chatTypeS == "Admin" then
		typeColor = colours.adminChat
		typePretty = "ADMIN"
	elseif chatTypeS == "Trade" then
		typeColor = colours.tradeChat
		typePretty = "TRADE"
	elseif chatTypeS == "Recruitment" then
		typeColor = colours.recruitmentChat
		typePretty = "RECRUITMENT"
	end

    local chatParent = vgui.Create("Panel", chatLogPanel)
    chatParent:SetSize(chatLogPanel:GetWide(), chatLogPanel:GetTall() * 0.09)
    chatParent:Dock(TOP)

    chatParent.Paint = function(self, w, h)

        if sender == LocalPlayer():Nick() then
            draw.RoundedBox( 0, 0, 0, w, h, Color( 247, 241, 241, 58) )
        else
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 44) )
        end

    end

    local chatTxt = vgui.Create("Panel", chatParent)
    chatTxt:SetContentAlignment(7)
    chatTxt:Dock(TOP)
    chatTxt:InsertColorChange()
    chatTxt:SetWide(chatLogPanel:GetWide())
    chatTxt:SizeToContents()
    local message, count = textWrap(text, "sChat_18", chatLogPanel:GetWide() - 10)
    print(count)
    local _, lineHeight = surface.GetTextSize("sChat_18")
    local totalHeight = count * lineHeight

    chatTxt:SetTall(totalHeight)

    chatTxt.PerformLayout = function (self)
        self:SetFontInternal("sChat_18")
    end
    --abcdefghijklmnopqrstuvwxyz
    function chatTxt:Paint( w, h )
        draw.DrawText( message, "sChat_18", 4, 0, Color( typeColor.r, typeColor.g, typeColor.b, 255 ), TEXT_ALIGN_LEFT )
    end    

    local chatInfo = vgui.Create("RichText", chatParent)
    chatInfo:SetContentAlignment(7)
    chatInfo:SetVerticalScrollbarEnabled(false)
	chatInfo:Dock(BOTTOM)
    chatInfo:InsertColorChange(255, 255, 255, 255)
    if chatTypeS == "DM" then
        chatInfo:AppendText(sender .. " to " .. target .. " * ")
    else
        chatInfo:AppendText(sender .. " * ")
    end
    
    chatInfo:InsertColorChange(typeColor.r, typeColor.g, typeColor.b, 255)
    chatInfo:AppendText(typePretty)
    chatInfo:SetSize(chatParent:GetWide(), chatParent:GetTall() * 0.5 + 5)
	chatInfo:SetZPos(1)
	
	chatInfo.PerformLayout = function(self)
		self:SetFontInternal("sChat_16")
	end

	local coverPanel = vgui.Create("DPanel", chatParent)
	coverPanel:SetSize(chatParent:GetWide(), chatParent:GetTall() + 20)
	coverPanel:Dock(NODOCK)
	coverPanel:SetZPos(10)

	coverPanel.Paint = function(self, w, h)

		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0) )

	end	

	chatParent:SetTall(chatTxt:GetTall() + chatInfo:GetTall())

	local spacerPanel = vgui.Create("Panel", chatLogPanel)
	spacerPanel:SetSize(chatLogPanel:GetWide(), 10)
	spacerPanel:Dock(TOP)

	spacerPanel.Paint = function(self, w, h)

		draw.RoundedBox( 0, 0, 0, w, h, Color( 255, 255, 255, 0) )

	end	

	chatParent.Paint = function(self, w, h)

		if sender == LocalPlayer():Nick() then
			draw.RoundedBox( 0, 0, 0, w, h, Color( 247, 241, 241, 58) )
		else
			draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 44) )
		end

	end

    local function PanelPainted()
		AfterPanelPaint(msgParent)
	end
	
	hook.Add("Think", "PanelPaint", PanelPainted)

end

timer.Create("ChatBoxPanel", 0, 0, function()
    if IsPlayerInPropMenu() then return end
    if input.IsKeyDown(KEY_Y) and not hasOpenedPanel then
        hasOpenedPanel = true
        DoClose = true
        lastMessage = nil
        chatLogPanel:SetVisible( true )
        ChatBoxPanel(false)
    end
end)

hook.Remove( "ChatText", "joinleave")
hook.Add( "ChatText", "joinleave", function( index, name, text, type )
	if type != "chat" then
		AddChatMessage("Console", text, "Global", "")
		lastMessage = CurTime()
		return true
	end
end)

-- Hide the default chat too in case that pops up
hook.Remove("HUDShouldDraw", "sChat_hidedefault")
hook.Add("HUDShouldDraw", "sChat_hidedefault", function( name )
    if name == "CHudChat" or name == "CHudHealth" then
        return false
    end
end)

hook.Add("PlayerBindPress", "overrideChatbind", function( ply, bind, pressed )
    local bTeam = false
    if bind == "messagemode" then
    elseif bind == "messagemode2" then
    else
        return
    end
    return true
end )

net.Receive("ReceiveChat", function(len)
    local text = net.ReadString()
    local chatTypeS = net.ReadString()
    local plyName = net.ReadString()
    local plyTarget = net.ReadString()

	lastMessage = CurTime()
    if hasOpenedPanel then
        AddChatMessage(plyName, text, chatType, plyTarget)
    else
        ChatBoxPanel(false)

        AddChatMessage(plyName, text, chatTypeS, plyTarget)
    end
end)

ChatBoxPanel(true)