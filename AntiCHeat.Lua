-- Anti-Cheat Script for Roblox Studio
-- This script will detect and ban players using exploits or executing unauthorized scripts.
-- Thank you for using my script! To help support me share this to other roblox devs.

local bannedPlayers = {} -- Table to store banned player IDs
local logService = game:GetService("LogService")
local playersService = game:GetService("Players")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- Helper function to ban players
local function banPlayer(player, reason)
    -- Log the ban action
    print("Banned player: " .. player.Name .. " (" .. player.UserId .. ") | Reason: " .. reason)

    -- Add player to banned list
    table.insert(bannedPlayers, player.UserId)

    -- Optional: Show a message to all players about the ban
    game.ReplicatedStorage:BroadcastMessage(player.Name .. " was banned for exploiting!")

    -- Ban player (forcefully kick from game with a message)
    player:Kick("You have been banned for exploiting or executing unauthorized scripts.")
end

-- Check for unusual script execution
local function detectSuspiciousScripts()
    local scriptList = {}
    -- Check for scripts in places they shouldn't be
    for _, object in pairs(game:GetDescendants()) do
        if object:IsA("Script") or object:IsA("LocalScript") then
            table.insert(scriptList, object)
        end
    end

    -- Log or handle any found scripts that shouldn't be there
    for _, script in ipairs(scriptList) do
        -- Detect if the script is not supposed to be there
        if not script.Parent:IsA("Player") then
            -- This script is suspicious, banning player
            local player = playersService:GetPlayerFromCharacter(script.Parent)
            if player then
                banPlayer(player, "Executed unauthorized script")
            end
        end
    end
end

-- Detecting unusual remote events (e.g., external modules or exploit triggers)
local function detectSuspiciousRemoteEvents()
    for _, remote in pairs(replicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            remote.OnServerEvent:Connect(function(player, ...)
                -- Check if remote events are used inappropriately
                if player and player.UserId ~= game.CreatorId then
                    -- Log the suspicious event
                    print("Suspicious RemoteEvent usage by player: " .. player.Name)

                    -- Ban the player for trying to use remote events inappropriately
                    banPlayer(player, "Suspicious RemoteEvent usage")
                end
            end)
        end
    end
end

-- Detect unusual behavior from players (e.g., high speed, movement anomalies)
local function detectUnusualBehavior(player)
    local function monitorPlayerMovement()
        -- Simple movement anomaly check (adjust as needed)
        local previousPosition = player.Character and player.Character.HumanoidRootPart.Position
        wait(1)
        while player and player.Character do
            local currentPosition = player.Character.HumanoidRootPart.Position
            if previousPosition and (currentPosition - previousPosition).magnitude > 100 then
                -- If the player moved too fast (unlikely in normal circumstances)
                banPlayer(player, "Unusual movement detected")
                break
            end
            previousPosition = currentPosition
            wait(1)
        end
    end

    -- Start monitoring the player's movement
    spawn(monitorPlayerMovement)
end

-- Hook into new player joins
playersService.PlayerAdded:Connect(function(player)
    -- Check for suspicious scripts and remote events as soon as the player joins
    detectSuspiciousScripts()
    detectSuspiciousRemoteEvents()

    -- Monitor player behavior for anomalies
    spawn(function()
        detectUnusualBehavior(player)
    end)
end)

-- Hook into player leaving
playersService.PlayerRemoving:Connect(function(player)
    -- Optional: Clean up any active checks or logs
    print("Player leaving: " .. player.Name)
end)

-- To ensure banned players stay banned between sessions
game.Players.PlayerAdded:Connect(function(player)
    if table.find(bannedPlayers, player.UserId) then
        player:Kick("You are permanently banned from this game.")
    end
end)

