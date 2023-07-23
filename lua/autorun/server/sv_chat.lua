util.AddNetworkString("SendChat")
util.AddNetworkString("ReceiveChat")

if not GAMEMODE then
	hook.Remove("Initialize", "schat_init")
	hook.Add("Initialize", "schat_init", function()
		include("autorun/server/sv_chat.lua")
	end)
	return
end

function PlayerCanSeeChat(chatType, listener, speaker)
    local dist = listener:GetPos() : Distance( speaker:GetPos() )

    if( chatType == "Local" ) then
        if(dist <= 300 or (listener:Visible( speaker ) and dist <= 500)) then
            return true
        end
        return false
    end
    if( chatType == "Global" ) then
        return true
    end
    if chatType == "DM" then
        if listener:Name() == target:Name() then
            return true
        end
        return false
    end
end    

function GAMEMODE:PlayerCanHearPlayersVoice( listener, speaker)
    local dist = listener:GetPos() : Distance( speaker:GetPos() )
    return( dist <= 300 or (listener:Visible( speaker ) and  dist <= 600))
end

net.Receive("SendChat", function(len, ply)
    local text = net.ReadString()
    local chatType = net.ReadString()
    local target = net.ReadString()

    local sanitizedInput = string.gsub(text, '[\\:%*%?%z%c"<>|]', '')

    if chatType == "Global" then
        net.Start("ReceiveChat")
        net.WriteString(sanitizedInput)
        net.WriteString(chatType)
        net.WriteString(ply:Name())
        net.Broadcast()
    elseif chatType == "Local" then
        local players = player.GetAll()
        for _, plyl in ipairs(players) do
            if PlayerCanSeeChat(chatType, plyl, ply) then
                net.Start("ReceiveChat")
                net.WriteString(sanitizedInput)
                net.WriteString(chatType)
                net.WriteString(ply:Name())
                net.Send(plyl)
            end
        end
    elseif chatType == "Admin" then
        if ply:IsAdmin() then
            local players = player.GetAll()
            for _, plyl in ipairs(players) do
                if plyl:IsAdmin() then
                    net.Start("ReceiveChat")
                    net.WriteString(sanitizedInput)
                    net.WriteString(chatType)
                    net.WriteString(ply:Name())
                    net.Send(plyl)
                end
            end
        end
    elseif chatType == "Recruitment" then
        net.Start("ReceiveChat")
        net.WriteString(sanitizedInput)
        net.WriteString(chatType)
        net.WriteString(ply:Name())
        net.Broadcast()
    elseif chatType == "Trade" then
        net.Start("ReceiveChat")
            net.WriteString(sanitizedInput)
            net.WriteString(chatType)
            net.WriteString(ply:Name())
        net.Broadcast()
    elseif chatType == "DM" then
        local players = player.GetAll()
        local plyFound = false
        for _, plyl in ipairs(players) do
            if plyl:Name() == target then
                plyFound = true
                net.Start("ReceiveChat")
                    net.WriteString(sanitizedInput)
                    net.WriteString(chatType)
                    net.WriteString(ply:Name())
                    net.WriteString(target)
                net.Send(plyl)
            end
        end
        if plyFound then
            net.Start("ReceiveChat")
                net.WriteString(sanitizedInput)
                net.WriteString(chatType)
                net.WriteString(ply:Name())
                net.WriteString(target)
            net.Send(ply)
        else
            net.Start("ReceiveChat")
                net.WriteString("Target not found")
                net.WriteString(chatType)
                net.WriteString(ply:Name())
                net.WriteString("unknown")
            net.Send(ply)
        end
    end
end)
/*
timer.Create( "testTimer", 15, 20, function() 
    net.Start("ReceiveChat")
        net.WriteString("lmao")
        net.WriteString("Global")
        net.WriteString("Benjamin")
    net.Broadcast()
end)

timer.Start("testTimer")
*/




