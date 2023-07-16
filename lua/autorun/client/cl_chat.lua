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
    helpChat = Color(255, 165, 80),
    tradeChat = Color(119, 246, 255),
    recruitmentChat = Color(255, 252, 80)
}

local gradient = Material("gui/center_gradient")
local gradient2 = Material("vgui/gradient_up")
local gradient3 = Material("vgui/gradient_down")

local hasOpenedPanel = false
local chatMode = false

local chatType = "Global"
local chatTypes = {"Global", "Local", "DM", "Admin", "Trade", "Recruitment"}

local chatLogPanel = {}

local lastChatType = ""

local lastMessage = {}

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

local function IsPlayerInPropMenu()
    return IsValid(g_SpawnMenu) and g_SpawnMenu:IsVisible()
end

local function ChatBoxPanel()
    local frame = vgui.Create( "DFrame" )
    frame:SetSize(ScrW() * 0.25, ScrH() * 0.4)
    frame:SetTitle("")
    frame:ShowCloseButton(false) //temp
    frame:SetVisible(true)
    frame:SetPos(ScrW() * 0.005, ScrH() * 0.5)
    frame.UseDown = true
    frame:SetDraggable(false)
    frame:SetAlpha(0)
    frame:AlphaTo(255, 0.1)
    frame:MakePopup()
    local DoClose = false 

    if not frame then return end

    function frame:Paint( w, h )
        if chatMode then
            surface.SetDrawColor( 20,20,20, 0)
            surface.DrawRect( 0, 0, w, h )
            surface.SetDrawColor( 219,219,219,178)       
            surface.DrawOutlinedRect( 0, 0, w, h )
        end
    end

    local chatBarPanel = vgui.Create("Panel", frame)
    chatBarPanel:SetSize(frame:GetWide(), 50)
    chatBarPanel:SetPos(0, frame:GetTall() - 50)
    function chatBarPanel:Paint( w, h )
        if chatMode then
            surface.SetDrawColor(20,20,20, 10)
            surface.DrawRect(0, 0, w, h )
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
        end
    end

    local chatTypePanel = vgui.Create("Panel", chatBarPanel)
    chatTypePanel:SetSize(chatBarPanel:GetWide(), 25)
    chatTypePanel:SetPos(0, 0)
    function chatTypePanel:Paint( w, h )
        if chatMode then
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
            elseif chatType == "Admin" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.adminChat, TEXT_ALIGN_LEFT)
            elseif chatType == "Recruitment" then
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.recruitmentChat, TEXT_ALIGN_LEFT)
            else
                draw.DrawText(chatType, "sChat_18", 4, 3, colours.globalChat, TEXT_ALIGN_LEFT)
            end
        end
    end

    local chatEntryPanel = vgui.Create("DTextEntry", chatBarPanel)
    chatEntryPanel:SetSize(chatBarPanel:GetWide(), 25)
    chatEntryPanel:SetPos(0, 25)
    chatEntryPanel:SetTextColor(Color(255, 255, 255))
    chatEntryPanel:SetFont("sChat_18")
    chatEntryPanel:SetHighlightColor( Color(52, 152, 219) )
    if chatMode then
        chatEntryPanel:RequestFocus()
    end

    function chatEntryPanel:Paint( w, h )
        if chatMode then
            surface.SetDrawColor(20,20,20, 126)
            surface.DrawRect(0, 0, w, h )
            --derma.SkinHook( "Paint", "TextEntry", self, w, h )
            surface.SetDrawColor( 219,219,219,105)       
            surface.DrawOutlinedRect( 0, 0, w, h )
            self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
        end
    end

    chatLogPanel = vgui.Create("Panel", frame)
    chatLogPanel:SetSize(frame:GetWide(), frame:GetTall() - chatBarPanel:GetTall())
    chatLogPanel:SetPos(0, 0)

    function chatLogPanel:Paint( w, h )
        if chatMode then
            surface.SetDrawColor(20,20,20, 0)
            surface.DrawRect(0, 0, w, h )
        end
    end    

    if chatMode then
        chatEntryPanel.OnTextChanged = function( self )
            if self and self.GetText then 
                gamemode.Call( "ChatTextChanged", self:GetText() or "" )
            end
            local currentText = self:GetText()
            local maxCharacterLimit = 200
            if #currentText > maxCharacterLimit then
                -- Truncate the text to the maximum character limit
                self:SetText(string.sub(currentText, 1, maxCharacterLimit))
                self:SetCaretPos(maxCharacterLimit) -- Set the caret position to the end
                if chatMode then
                    self:RequestFocus() -- Request focus to maintain cursor position
                end
            end
        end
    
        function chatEntryPanel.OnKeyCodeTyped(self, code)
            if code == KEY_TAB then
                
                typeSelector = (typeSelector and typeSelector + 1) or 2
                if typeSelector > 6 then typeSelector = 1 end
                if typeSelector < 1 then typeSelector = 6 end
                chatType = chatTypes[typeSelector]
                lastChatType = chatType
    
                timer.Simple(0.001, function() if chatMode then chatEntryPanel:RequestFocus() end end)
    
            elseif code == KEY_ENTER then
                
                local target = ""
    
                local sanitizedInput = string.gsub(self:GetText(), '[\\:%*%?%z%c"<>|]', '')
    
                -- Replicate the client pressing enter
                if string.Trim( sanitizedInput ) != "" then
                    if chatType == chatTypes[2] then
                        lastChatType = "Local"
                    elseif chatType == chatTypes[3] then
                        lastChatType = "DM"
                        target = "123"
                    elseif chatType == chatTypes[4] then
                        lastChatType = "Admin"
                    elseif chatType == chatTypes[5] then
                        lastChatType = "Trade"
                    elseif chatType == chatTypes[6] then
                        lastChatType = "Recruitment"
                    else
                        lastChatType = "Global"
                    end
    
                    if self:GetText() ~= nil then
                        sendToServer("SendChat", sanitizedInput, chatType, target)
                    end
                    frame:SetAlpha(255)
                    frame:AlphaTo(0, 0.1)
                    timer.Create("frameFaded", 0.1, 0, function()
                        frame:Close()
                        hasOpenedPanel = false
                        chatMode = false
                        timer.Remove("frameFaded")
                    end)
                end
            end
        end
    end

    function frame:Think()
        if IsPlayerInPropMenu() then return end
        if self.UseDown and not input.IsKeyDown(KEY_Y) then
            self.UseDown = false
            return
        elseif not self.UseDown and input.IsKeyDown(KEY_ESCAPE) then
            chatMode = false
            gui.HideGameUI()
            frame:SetAlpha(255)
            frame:AlphaTo(0, 0.1)
            timer.Create("frameFaded", 0.1, 0, function()
                self:Close()
                hasOpenedPanel = false
                timer.Remove("frameFaded")
            end)
        end
    end
end

function AddChatMessage(sender, text, chatType)

    if not chatLogPanel then
        ChatBoxPanel()
    end

    local typeColor = Color(0, 0, 0)
    
    if chatType == "Global" then
        typeColor = colours[1]
    elseif chatType == "Local" then
        typeColor = colours[2]
    elseif chatType == "DM" then
        typeColor = colours[3]
    elseif chatType == "Trade" then
        typeColor = colours[4]
    elseif chatType == "Help" then
        typeColor = colours[5]
    elseif chatType == "Recruitment" then
        typeColor = colours[6]
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

    local chatTxt = vgui.Create("RichText", chatParent)
    chatTxt:SetContentAlignment(7)
    chatTxt:Dock(TOP)
    chatTxt:SetVerticalScrollbarEnabled(false)
    chatTxt:InsertColorChange( typeColor.r, typeColor.g, typeColor.b, 255 )
    chatTxt:SetZPos(1)

    local splitSize = 58
    local splitStrings = {}

    for i = 1, #text, splitSize do
           local substring = string.sub(text, i, i + splitSize - 1)
        table.insert(splitStrings, substring)
    end

    for i, line in ipairs(splitStrings) do
        if i > 1 then
            local wLine, hLine = surface.GetTextSize(line)
            chatTxt:SetTall(chatTxt:GetTall() + hLine)
        end
        chatTxt:AppendText(line)
    end

    chatTxt.PerformLayout = function (self)

        self:SetFontInternal("sChat_18")
        --self:SetWrap(true)
        
    end
end

timer.Create("ChatBoxPanel", 0, 0, function()
    if IsPlayerInPropMenu() or LocalPlayer():IsTyping() then return end
    if input.IsKeyDown(KEY_Y) and not hasOpenedPanel then
        ChatBoxPanel()
        hasOpenedPanel = true
        chatMode = true
        DoClose = false
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
    local chatType = net.ReadString()
    local plyName = net.ReadString()

	lastMessage = CurTime()
    ChatBoxPanel()

    AddChatMessage(plyName, text, chatType)

end)