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

    if( chatType == "local" ) then
        if(dist <= 300 or (listener:Visible( speaker ) and dist <= 500)) then
            return true
        end
        return false
    end
    if( chatType == "global" ) then
        return true
    end
    if chatType == "dm" then
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
    
    if target ~= "" then
        --dm
    else
        if chatType == "global" then
            net.Start("ReceiveChat")
                net.WriteString(sanitizedInput)
                net.WriteString(chatType)
                net.WriteString(ply:Name())
            net.Broadcast()
        elseif chatType == "local" then
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
        end
    end
end)
/*

*/

timer.Simple(10, function() 
    net.Start("ReceiveChat")
        net.WriteString("lmao")
        net.WriteString("global")
        net.WriteString("ply:Name()")
    net.Broadcast()
end)

timer.Create( "testTimer", 4, 20, function() 
    net.Start("ReceiveChat")
        net.WriteString("lmao")
        net.WriteString("global")
        net.WriteString("ply:Name()")
    net.Broadcast()
end)

timer.Start("testTimer")