-- Syrup Chatbox-2
-- Author : Maple_Guy
--Made to look like the new world (the mmorpg) chatbox with a twist
--Started on : 2023-06-27
--This chatbox is heavily inspired (and even copy pasted a bit) by Exho's chatbox on GitHub (at least the client side part is)
--I added a bit of networking to allow me to make the chatbox more custom

if SERVER then
    return
end

sChat = {}
sChat.channels = {"global", "local", "dm", "admin", "trade"}

sChat.chatMessages = {}

sChat.inChatMode = false

sChat.Color = {
	globalChat = Color(91, 233, 115),
	localChat = Color(214, 164, 56),
	dmChat = Color(186, 238, 238),
	helpChat = Color(255, 165, 80),
	tradeChat = Color(119, 246, 255),
	recruitmentChat = Color(255, 252, 80)
}

sChat.config = {
	timeStamps = false,
	position = 1,	
	fadeTime = 12,
}

sChat.lastMessage = nil

sChat.temp = {
	lastChatType = "global"
}

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