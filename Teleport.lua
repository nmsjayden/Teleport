--⚙️ SETTINGS
local configFile = "ServerHopSettings.txt"
local LocalPlayer = game:GetService("Players").LocalPlayer
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

--📁 Load config or create default
local config = {targetVersion = "", maxHops = 20, hops = 0}
if isfile(configFile) then
    local ok, saved = pcall(function()
        return HttpService:JSONDecode(readfile(configFile))
    end)
    if ok and typeof(saved) == "table" then config = saved end
end

--📦 Persist on teleport
local reexecuteCode = [[
loadstring(game:HttpGet("https://raw.githubusercontent.com/nmsjayden/Teleport/refs/heads/main/Teleport.lua"))()
]]
queue_on_teleport(reexecuteCode)

--🖼️ GUI Setup
if not game.CoreGui:FindFirstChild("HopGui") then
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "HopGui"
    gui.ResetOnSpawn = false

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 200, 0, 150)
    frame.Position = UDim2.new(0.5, -100, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

    local versionBox = Instance.new("TextBox", frame)
    versionBox.PlaceholderText = "Target Version (e.g. 1669)"
    versionBox.Size = UDim2.new(1, -20, 0, 30)
    versionBox.Position = UDim2.new(0, 10, 0, 10)
    versionBox.Text = tostring(config.targetVersion)

    local hopsBox = Instance.new("TextBox", frame)
    hopsBox.PlaceholderText = "Max Hops (e.g. 50)"
    hopsBox.Size = UDim2.new(1, -20, 0, 30)
    hopsBox.Position = UDim2.new(0, 10, 0, 50)
    hopsBox.Text = tostring(config.maxHops)

    local startBtn = Instance.new("TextButton", frame)
    startBtn.Text = "Start Hopping"
    startBtn.Size = UDim2.new(1, -20, 0, 30)
    startBtn.Position = UDim2.new(0, 10, 0, 90)

    startBtn.MouseButton1Click:Connect(function()
        config.targetVersion = versionBox.Text
        config.maxHops = tonumber(hopsBox.Text) or 50
        config.hops = 0
        writefile(configFile, HttpService:JSONEncode(config))
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

--🔍 Version check
local function getCurrentVersion()
    local success, result = pcall(function()
        local raw = LocalPlayer.PlayerGui:WaitForChild("Version_UI", 5):FindFirstChild("Version")
        if raw and raw:IsA("TextLabel") then
            return raw.Text:match("v(%d+)")
        end
        return nil
    end)
    return success and result or nil
end

--🚪 Simple teleport
local function hop()
    local servers = {}
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100"
    local data = HttpService:JSONDecode(game:HttpGet(url))
    for _, v in ipairs(data.data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        warn("No servers found.")
    end
end

--📡 Start hopping if configured
task.delay(2, function()
    if config.targetVersion and tonumber(config.targetVersion) then
        local version = getCurrentVersion()
        if version == config.targetVersion then
            print("✅ Correct version found:", version)
            config.hops = 0
            writefile(configFile, HttpService:JSONEncode(config))
            return
        end

        config.hops += 1
        if config.hops > config.maxHops then
            warn("❌ Max hops reached.")
            return
        end

        writefile(configFile, HttpService:JSONEncode(config))
        print("🔁 Hop #" .. config.hops .. " | Current: " .. tostring(version))
        hop()
    end
end)
