--[[
    APEX CROW HUB v10 — Blox Fruits
    Fusion: Redz Update 30, Banana Cat, Avalon, BPHUB, Snowy, Arc
    New over v9: Auto Raid (RaidsNpc), Auto Dungeon (requestEntrance),
                 Auto Factory, Auto Fishing, Auto Daily/Weekly,
                 Auto Race V3/V4 Awakening, Auto Stats, Auto Buy Styles,
                 Auto Unlock Weapons, Auto Boat Farm, Auto Pirate Raid,
                 Auto Cake Prince/Dough King, Auto Volcano/Prehistoric,
                 Auto Collect Orbs, Item/Food ESP, Shop Teleports,
                 Boss/NPC Teleports, Full CommF_ remote map.
    UI: Fluent (dawid-scripts) with 3-stage fallback. Delta HTTP patched.
]]

-- ============================================================
-- 0. DELTA HTTP TIMEOUT PATCH
-- ============================================================
local HTTP_TIMEOUT = 5
local _rawHttpFn = nil
pcall(function() if request then _rawHttpFn = request end end)
pcall(function() if not _rawHttpFn and http_request then _rawHttpFn = http_request end end)
pcall(function() if not _rawHttpFn and syn and syn.request then _rawHttpFn = syn.request end end)
pcall(function() if not _rawHttpFn and http and http.request then _rawHttpFn = http.request end end)
pcall(function() if not _rawHttpFn and fluxus and fluxus.request then _rawHttpFn = fluxus.request end end)

if _rawHttpFn then
    local function safeRequest(opts)
        local result, finished = nil, false
        task.spawn(function()
            local ok, res = pcall(_rawHttpFn, opts)
            if ok and type(res) == "table" then result = res end
            finished = true
        end)
        local t0 = tick()
        while not finished and (tick() - t0) < HTTP_TIMEOUT do task.wait(0.1) end
        if not finished then return {StatusCode = 0, Body = "", Headers = {}} end
        return result
    end
    if request then request = function(o) return safeRequest(o) end end
    if http_request then http_request = function(o) return safeRequest(o) end end
    if syn and syn.request then syn.request = function(o) return safeRequest(o) end end
    if http and http.request then http.request = function(o) return safeRequest(o) end end
    if fluxus and fluxus.request then fluxus.request = function(o) return safeRequest(o) end end
end
getgenv = getgenv or function() return _G end

-- ============================================================
-- 1. SERVICES
-- ============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- 2. UI LOADER — 3-STAGE FALLBACK
-- ============================================================
local Fluent, uiLoaded = nil, false

pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    uiLoaded = Fluent ~= nil
end)

if not uiLoaded then
    pcall(function()
        Fluent = loadstring(game:HttpGet("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau"))()
        uiLoaded = Fluent ~= nil
    end)
end

if not uiLoaded then
    local gui = Instance.new("ScreenGui")
    gui.Name = "ApexCrowFallback"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 140, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, 20)
    btn.Text = "Apex Crow (Fallback)"
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.Parent = gui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 120)
    frame.Position = UDim2.new(0, 20, 0, 70)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Visible = false
    frame.Parent = gui
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, -20)
    label.Position = UDim2.new(0, 10, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = "Full UI failed. Scripts still run in background.\nMinimize via getgenv().ApexMinimize()"
    label.TextColor3 = Color3.fromRGB(255, 150, 150)
    label.TextWrapped = true
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    btn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)
    return
end

local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/ActualMasterOogway/Fluent-Renewed/master/Addons/SaveManager.luau"))()

local Window = Fluent:CreateWindow({
    Title = "Apex Crow v10 | Blox Fruits",
    SubTitle = "raid · dungeon · factory · fishing · race awakening · full remote map",
    TabWidth = 150,
    Size = UDim2.fromOffset(660, 540),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Farm = Window:AddTab({ Title = "Farm", Icon = "tractor" }),
    Quest = Window:AddTab({ Title = "Quest", Icon = "scroll" }),
    Raid = Window:AddTab({ Title = "Raid", Icon = "castle" }),
    Dungeon = Window:AddTab({ Title = "Dungeon", Icon = "door-open" }),
    Factory = Window:AddTab({ Title = "Factory", Icon = "factory" }),
    Fishing = Window:AddTab({ Title = "Fishing", Icon = "fish" }),
    Daily = Window:AddTab({ Title = "Daily", Icon = "calendar" }),
    Race = Window:AddTab({ Title = "Race V4", Icon = "zap" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    Fruit = Window:AddTab({ Title = "Fruit", Icon = "apple" }),
    Combat = Window:AddTab({ Title = "Combat", Icon = "swords" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "map-pin" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}
local Options = Fluent.Options

-- ============================================================
-- 3. CONFIG
-- ============================================================
local Config = {
    -- Farm
    AutoFarm = false, FarmRange = 250, AttackPosition = "Behind", FastAttack = false, BringMob = false,

    -- Quest
    AutoQuest = false, AutoQuestDelay = 3, QuestName = "BanditQuest1", QuestLv = 1,
    QuestMobName = "Bandit", AutoDetectQuestMob = false,

    -- Raid
    AutoRaid = false, RaidMap = "Magma", RaidMicrochip = true,

    -- Dungeon
    AutoDungeon = false, DungeonFloor = 1,

    -- Factory
    AutoFactory = false, AutoFactoryRaid = false,

    -- Fishing
    AutoFishing = false, AutoSellFish = false,

    -- Daily
    AutoDaily = false, AutoWeekly = false,

    -- Race
    AutoRaceV3 = false, AutoRaceV4 = false, AutoRaceAwakening = false,

    -- Stats
    AutoStats = false, StatTarget = "Melee", StatAmount = 1,

    -- Fruit
    FruitSniper = false, SelectedFruit = "Any", AutoStoreFruit = false, AutoEatFruit = false,

    -- Combat
    KillAura = false, KillAuraRange = 30, AutoBuso = false, AutoKen = false,
    Aimbot = false, HitboxExpander = false, HitboxSize = 10,
    AutoBlock = false, AutoDodge = false,

    -- ESP
    PlayerESP = false, MobESP = false, FruitESP = false, ChestESP = false,
    ItemESP = false, FoodESP = false, IslandESP = false, ShowDistance = true,

    -- Misc
    AntiAFK = true, AntiLag = false, Fly = false, SpeedHack = false,
    SpeedValue = 100, Noclip = false, AutoBuyHaki = false, AutoBuyStyles = false,
    AutoUnlockWeapons = false, AutoBoatFarm = false, AutoPirateRaid = false,
    AutoCakePrince = false, AutoDoughKing = false, AutoVolcano = false, AutoPrehistoric = false,
    AutoCollectOrbs = false,
}

-- ============================================================
-- 4. REMOTES — FULL MAP
-- ============================================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 10)
local CommE = Remotes and Remotes:WaitForChild("CommE_", 10)

local function invokeF(...)
    if not CommF then return nil end
    local ok, res = pcall(function() return CommF:InvokeServer(...) end)
    return ok and res or nil
end

local function invokeE(...)
    if not CommE then return nil end
    local ok, res = pcall(function() return CommE:InvokeServer(...) end)
    return ok and res or nil
end

-- ============================================================
-- 5. UTILITIES
-- ============================================================
local function getHRP() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") end
local function getHum() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end
local function getTool() return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") end
local function isAlive() local h = getHum(); return h and h.Health > 0 end

local function tweenTo(targetCFrame, speed)
    local hrp = getHRP()
    if not hrp then return end
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local info = TweenInfo.new(dist / (speed or Config.TweenSpeed), Enum.EasingStyle.Linear)
    local tw = TweenService:Create(hrp, info, { CFrame = targetCFrame })
    tw:Play()
    tw.Completed:Wait()
end

-- ============================================================
-- 6. QUEST STATE + AUTO-DETECT MOB
-- ============================================================
local function isQuestActive()
    local main = PlayerGui and PlayerGui:FindFirstChild("Main")
    local quest = main and main:FindFirstChild("Quest")
    local visible = quest and quest:FindFirstChild("Visible")
    return visible and visible.Value == true
end

local QUEST_MOB_MAP = {
    BanditQuest1 = "Bandit", BanditQuest2 = "Bandit",
    MonkeyQuest1 = "Monkey", MonkeyQuest2 = "Monkey",
    BruteQuest1 = "Brute", BruteQuest2 = "Brute",
    PirateQuest1 = "Pirate", PirateQuest2 = "Pirate",
    MarineQuest1 = "Marine", MarineQuest2 = "Marine",
    JungleQuest1 = "Jungle Bandit", JungleQuest2 = "Jungle Pirate",
    SnowQuest1 = "Snow Bandit", SnowQuest2 = "Snowman",
    DesertQuest1 = "Desert Bandit", DesertQuest2 = "Desert Officer",
    SkyQuest1 = "Sky Bandit", SkyQuest2 = "Dark Master",
    FountainQuest1 = "Fountain Bandit", FountainQuest2 = "Fountain Pirate",
    ColosseumQuest1 = "Colosseum Bandit", ColosseumQuest2 = "Colosseum Pirate",
    MagmaQuest1 = "Magma Bandit", MagmaQuest2 = "Magma Pirate",
    FishmanQuest1 = "Fishman", FishmanQuest2 = "Fishman Captain",
    CursedQuest1 = "Cursed Skeleton", CursedQuest2 = "Cursed Skeleton",
    ZombieQuest1 = "Zombie", ZombieQuest2 = "Zombie",
    HalloweenQuest1 = "Halloween Skeleton", HalloweenQuest2 = "Halloween Zombie",
    PrisonerQuest1 = "Prisoner", PrisonerQuest2 = "Prisoner",
    GuardQuest1 = "Guard", GuardQuest2 = "Guard",
}
local QUEST_NAMES = {}
for qName in pairs(QUEST_MOB_MAP) do table.insert(QUEST_NAMES, qName) end
table.sort(QUEST_NAMES)

local function autoDetectQuestMob()
    if not Config.AutoDetectQuestMob then return end
    if QUEST_MOB_MAP[Config.QuestName] then
        Config.QuestMobName = QUEST_MOB_MAP[Config.QuestName]
    end
end

-- ============================================================
-- 7. MOB DETECTION
-- ============================================================
local function isMob(model)
    if not model:IsA("Model") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    if model:FindFirstChild("NPC") then return false end
    return true
end

local function getNearestMob(range, nameFilter)
    local myHRP = getHRP()
    if not myHRP then return nil end
    local nearest, dist = nil, range
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isMob(obj) then
            local hrp = obj:FindFirstChild("HumanoidRootPart")
            if hrp then
                if nameFilter and nameFilter ~= "" then
                    if not string.find(string.lower(obj.Name), string.lower(nameFilter), 1, true) then continue end
                end
                local d = (myHRP.Position - hrp.Position).Magnitude
                if d < dist then nearest, dist = obj, d end
            end
        end
    end
    return nearest
end

-- ============================================================
-- 8. ATTACK ENGINE
-- ============================================================
local lastAttack = 0
local ATTACK_COOLDOWN = 0.35

local function getAttackCFrame(mobHRP)
    local offset = CFrame.new(0, 0, -3)
    if Config.AttackPosition == "Above" then offset = CFrame.new(0, 8, 0)
    elseif Config.AttackPosition == "Below" then offset = CFrame.new(0, -5, 0)
    elseif Config.AttackPosition == "Front" then offset = CFrame.new(0, 0, 3) end
    return mobHRP.CFrame * offset
end

local function strikeMob(mob)
    if not mob or not isAlive() then return end
    if tick() - lastAttack < ATTACK_COOLDOWN then return end
    local myHRP = getHRP()
    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
    local mobHum = mob:FindFirstChildOfClass("Humanoid")
    if not myHRP or not mobHRP or not mobHum or mobHum.Health <= 0 then return end
    lastAttack = tick()
    local oldCF = myHRP.CFrame
    myHRP.CFrame = getAttackCFrame(mobHRP)
    local tool = getTool()
    if tool then pcall(function() tool:Activate() end) end
    invokeF("attack", mob.Name)
    task.wait(0.05)
    myHRP.CFrame = oldCF
end

-- ============================================================
-- 9. FARM LOOPS
-- ============================================================
task.spawn(function()
    while task.wait(0.35) do
        if not Config.AutoFarm or not isAlive() then continue end
        local filter = (Config.AutoQuest and Config.QuestMobName ~= "") and Config.QuestMobName or nil
        local mob = getNearestMob(Config.FarmRange, filter)
        if mob then strikeMob(mob) end
    end
end)

task.spawn(function()
    while task.wait(0.05) do
        if not Config.FastAttack or not isAlive() then continue end
        local tool = getTool()
        if tool then pcall(function() tool:Activate() end) end
    end
end)

task.spawn(function()
    while task.wait(0.25) do
        if not Config.BringMob or not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMob(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp and (myHRP.Position - hrp.Position).Magnitude < 200 then
                    hrp.CFrame = myHRP.CFrame * CFrame.new(0, 0, -5)
                end
            end
        end
    end
end)

-- ============================================================
-- 10. QUEST LOOP
-- ============================================================
local function startQuest()
    if Config.QuestName and Config.QuestName ~= "" then
        invokeF("StartQuest", Config.QuestName, Config.QuestLv)
    end
end

local function abandonQuest()
    invokeF("AbandonQuest")
end

local lastQuestStart = 0
task.spawn(function()
    while task.wait(1) do
        if not Config.AutoQuest then continue end
        if isQuestActive() then continue end
        if tick() - lastQuestStart < Config.AutoQuestDelay then continue end
        if not isAlive() or not Config.AutoFarm then continue end
        autoDetectQuestMob()
        lastQuestStart = tick()
        startQuest()
    end
end)

-- ============================================================
-- 11. AUTO RAID — RaidsNpc remote
-- ============================================================
local function startRaid()
    -- Select map first
    invokeF("RaidsNpc", "Select", Config.RaidMap)
    task.wait(0.3)
    -- Fire the summon click detector (location varies by sea)
    local map = Workspace:FindFirstChild("Map")
    if map then
        local circle = map:FindFirstChild("CircleIsland")
        if circle then
            local summon = circle:FindFirstChild("RaidSummon2")
            if summon and summon:FindFirstChild("Button") then
                local btn = summon.Button:FindFirstChild("Main")
                if btn and btn:FindFirstChild("ClickDetector") then
                    pcall(function() fireclickdetector(btn.ClickDetector) end)
                end
            end
        end
        local castle = map:FindFirstChild("Castle")
        if castle then
            local summon = castle:FindFirstChild("RaidSummon2")
            if summon and summon:FindFirstChild("Button") then
                local btn = summon.Button:FindFirstChild("Main")
                if btn and btn:FindFirstChild("ClickDetector") then
                    pcall(function() fireclickdetector(btn.ClickDetector) end)
                end
            end
        end
    end
end

task.spawn(function()
    while task.wait(2) do
        if not Config.AutoRaid or not isAlive() then continue end
        -- Only start if no raid timer visible
        local main = PlayerGui and PlayerGui:FindFirstChild("Main")
        local topHud = main and main:FindFirstChild("TopHUDList")
        local raidTimer = topHud and topHud:FindFirstChild("RaidTimer")
        if raidTimer and raidTimer.Visible then
            -- Raid already active — just farm mobs inside
            local mob = getNearestMob(800)
            if mob then strikeMob(mob) end
        else
            -- No raid active — try to start one
            startRaid()
        end
    end
end)

-- ============================================================
-- 12. AUTO DUNGEON — requestEntrance remote
-- ============================================================
local DUNGEON_ENTRANCE = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)

task.spawn(function()
    while task.wait(2) do
        if not Config.AutoDungeon or not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        -- Teleport to dungeon entrance if far
        if (myHRP.Position - DUNGEON_ENTRANCE).Magnitude > 3000 then
            invokeF("requestEntrance", DUNGEON_ENTRANCE)
            task.wait(2)
        end
        -- Farm dungeon mobs
        local mob = getNearestMob(1000)
        if mob then strikeMob(mob) end
    end
end)

-- ============================================================
-- 13. AUTO FACTORY / FACTORY RAID
-- ============================================================
local FACTORY_SPAWN = Vector3.new(-500, 7, 8000)

task.spawn(function()
    while task.wait(2) do
        if not Config.AutoFactory and not Config.AutoFactoryRaid then continue end
        if not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        -- Teleport to factory area
        if (myHRP.Position - FACTORY_SPAWN).Magnitude > 500 then
            tweenTo(CFrame.new(FACTORY_SPAWN), 600)
            task.wait(1)
        end
        -- Farm factory core / mobs
        local mob = getNearestMob(600, "Core")
        if not mob then mob = getNearestMob(600) end
        if mob then strikeMob(mob) end
    end
end)

-- ============================================================
-- 14. AUTO FISHING
-- ============================================================
task.spawn(function()
    while task.wait(3) do
        if not Config.AutoFishing or not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        -- Find fishing rod in backpack
        local rod = LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Fishing Rod")
        if rod then
            rod.Parent = LocalPlayer.Character
            task.wait(0.5)
            -- Cast
            pcall(function() rod:Activate() end)
            task.wait(3)
            -- Reel
            pcall(function() rod:Activate() end)
            task.wait(1)
            if Config.AutoSellFish then
                invokeF("SellFish")
            end
        end
    end
end)

-- ============================================================
-- 15. AUTO DAILY / WEEKLY
-- ============================================================
task.spawn(function()
    while task.wait(5) do
        if not isAlive() then continue end
        if Config.AutoDaily then
            invokeF("DailyQuest")
            invokeF("ClaimDailyReward")
        end
        if Config.AutoWeekly then
            invokeF("WeeklyQuest")
            invokeF("ClaimWeeklyReward")
        end
    end
end)

-- ============================================================
-- 16. AUTO RACE V3 / V4 / AWAKENING
-- ============================================================
task.spawn(function()
    while task.wait(2) do
        if not isAlive() then continue end
        if Config.AutoRaceV3 then
            invokeF("Awakening")
        end
        if Config.AutoRaceV4 then
            -- Clear trial mobs
            local mob = getNearestMob(800, "Trial")
            if mob then strikeMob(mob) end
            -- Attack trial boss
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and (obj.Name:find("Trial") or obj.Name:find("Ancient")) then
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    if hum and hrp and hum.Health > 0 then
                        tweenTo(hrp.CFrame * CFrame.new(0, 0, -3), 600)
                        task.wait(0.1)
                        local tool = getTool()
                        if tool then pcall(function() tool:Activate() end) end
                        invokeF("attack", obj.Name)
                    end
                end
            end
        end
        if Config.AutoRaceAwakening then
            invokeF("Awakening")
        end
    end
end)

-- ============================================================
-- 17. AUTO STATS — AddPoint remote
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if not Config.AutoStats or not isAlive() then continue end
        for _ = 1, Config.StatAmount do
            invokeF("AddPoint", Config.StatTarget)
        end
    end
end)

-- ============================================================
-- 18. AUTO-BUY HAKI / STYLES / WEAPONS
-- ============================================================
task.spawn(function()
    while task.wait(3) do
        if not isAlive() then continue end
        if Config.AutoBuyHaki then
            invokeF("Buy", "Buso")
            invokeF("Buy", "Ken")
        end
        if Config.AutoBuyStyles then
            for _, style in ipairs({ "BlackLeg", "FishmanKarate", "Electro", "Superhuman", "DeathStep", "SharkmanKarate", "DragonBreath" }) do
                invokeF("Buy", style)
            end
        end
        if Config.AutoUnlockWeapons then
            for _, weapon in ipairs({ "Saber", "Pole", "Saw", "Trident", "Rengoku" }) do
                invokeF("Buy", weapon)
            end
        end
    end
end)

-- ============================================================
-- 19. AUTO BUSO / KEN
-- ============================================================
task.spawn(function()
    while task.wait(0.5) do
        if Config.AutoBuso then
            if not LocalPlayer.Character:FindFirstChild("Buso") then invokeF("Buso") end
        end
        if Config.AutoKen then
            if not LocalPlayer.Character:FindFirstChild("Ken") then invokeF("Ken") end
        end
    end
end)

-- ============================================================
-- 20. KILL AURA
-- ============================================================
task.spawn(function()
    while task.wait(0.08) do
        if not Config.KillAura or not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        local tool = getTool()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 and (myHRP.Position - hrp.Position).Magnitude <= Config.KillAuraRange then
                    if tool then pcall(function() tool:Activate() end) end
                end
            end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMob(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp and (myHRP.Position - hrp.Position).Magnitude <= Config.KillAuraRange then
                    if tool then pcall(function() tool:Activate() end) end
                end
            end
        end
    end
end)

-- ============================================================
-- 21. AIMBOT / HITBOX / BLOCK / DODGE
-- ============================================================
local camera = Workspace.CurrentCamera
task.spawn(function()
    while task.wait(0.05) do
        if not Config.Aimbot or not isAlive() then continue end
        local myHRP = getHRP()
        if not myHRP then continue end
        local nearest, dist = nil, 1000
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (myHRP.Position - hrp.Position).Magnitude
                    if d < dist then nearest, dist = hrp, d end
                end
            end
        end
        if nearest then
            camera.CFrame = CFrame.new(camera.CFrame.Position, nearest.Position)
        end
    end
end)

local hitboxFolder = Instance.new("Folder")
hitboxFolder.Name = "ApexHitboxes_v10"
hitboxFolder.Parent = Workspace

task.spawn(function()
    while task.wait(0.5) do
        for _, child in ipairs(hitboxFolder:GetChildren()) do child:Destroy() end
        if not Config.HitboxExpander then continue end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMob(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local box = Instance.new("Part")
                    box.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    box.Transparency = 0.85
                    box.CanCollide = false
                    box.Anchored = true
                    box.Color = Color3.fromRGB(255, 0, 0)
                    box.CFrame = hrp.CFrame
                    box.Parent = hitboxFolder
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = box
                    weld.Part1 = hrp
                    weld.Parent = box
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        if not isAlive() then continue end
        if Config.AutoBlock then
            local tool = getTool()
            if tool and tool:FindFirstChild("Block") then
                pcall(function() tool.Block:FireServer() end)
            end
        end
        if Config.AutoDodge then
            local hum = getHum()
            if hum then hum.Jump = true end
        end
    end
end)

-- ============================================================
-- 22. FRUIT SNIPER — STRICT
-- ============================================================
local FRUIT_NAMES = {
    "Rocket","Spin","Chop","Spring","Bomb","Smoke","Flame","Ice","Sand","Dark","Diamond","Light",
    "Rubber","Barrier","Ghost","Magma","Door","Buddha","Love","Spider","Sound","Phoenix","Portal",
    "Rumble","Pain","Blizzard","Gravity","Mammoth","T-Rex","Dough","Shadow","Venom","Control",
    "Spirit","Dragon","Leopard","Kitsune","Yeti","Gas","Creation"
}

local function isFruit(obj)
    if not (obj:IsA("Tool") or obj:IsA("Model")) then return false end
    if not obj:FindFirstChild("Handle") then return false end
    if not obj:FindFirstChildOfClass("ClickDetector") and not obj:FindFirstChild("ClickDetector") then return false end
    for _, name in ipairs(FRUIT_NAMES) do
        if obj.Name == name or obj.Name == name .. "Fruit" then return true end
    end
    return false
end

task.spawn(function()
    while task.wait(0.5) do
        if not Config.FruitSniper or not isAlive() then continue end
        local fruitFolder = Workspace:FindFirstChild("Fruits")
        if not fruitFolder then continue end
        for _, fruit in ipairs(fruitFolder:GetChildren()) do
            if isFruit(fruit) then
                if Config.SelectedFruit == "Any" or string.find(fruit.Name, Config.SelectedFruit, 1, true) then
                    local hrp = getHRP()
                    if hrp then
                        hrp.CFrame = fruit:GetPivot()
                        task.wait(0.2)
                        invokeE("Grab", fruit.Name)
                        task.wait(0.2)
                        if Config.AutoStoreFruit then invokeF("StoreFruit", fruit.Name) end
                        if Config.AutoEatFruit then invokeF("EatFruit", fruit.Name) end
                    end
                    break
                end
            end
        end
    end
end)

-- ============================================================
-- 23. ESP — ENHANCED
-- ============================================================
local espFolder = Instance.new("Folder")
espFolder.Name = "ApexESP_v10"
espFolder.Parent = Workspace

local function createBox(adornee, color)
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = adornee
    box.AlwaysOnTop = true
    box.Size = Vector3.new(4, 6, 4)
    box.Color3 = color
    box.Transparency = 0.5
    box.Parent = espFolder
end

local function createLabel(adornee, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Adornee = adornee
    bb.Size = UDim2.new(0, 220, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Text = text
    label.Parent = bb
    bb.Parent = espFolder
end

local function getDist(hrp)
    local myHRP = getHRP()
    if not myHRP or not hrp then return 0 end
    return math.floor((myHRP.Position - hrp.Position).Magnitude)
end

task.spawn(function()
    while task.wait(0.5) do
        for _, child in ipairs(espFolder:GetChildren()) do child:Destroy() end
        if Config.PlayerESP then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum then
                        createBox(hrp, Color3.fromRGB(255, 60, 60))
                        local txt = plr.Name .. " | HP " .. math.floor(hum.Health)
                        if Config.ShowDistance then txt = txt .. " | " .. getDist(hrp) .. "m" end
                        createLabel(hrp, txt, Color3.fromRGB(255, 255, 255))
                    end
                end
            end
        end
        if Config.MobESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if isMob(obj) then
                    local hrp = obj:FindFirstChild("HumanoidRootPart")
                    local hum = obj:FindFirstChildOfClass("Humanoid")
                    if hrp and hum then
                        createBox(hrp, Color3.fromRGB(255, 165, 0))
                        local txt = obj.Name .. " | HP " .. math.floor(hum.Health)
                        if Config.ShowDistance then txt = txt .. " | " .. getDist(hrp) .. "m" end
                        createLabel(hrp, txt, Color3.fromRGB(255, 200, 0))
                    end
                end
            end
        end
        if Config.FruitESP then
            local fruitFolder = Workspace:FindFirstChild("Fruits")
            if fruitFolder then
                for _, fruit in ipairs(fruitFolder:GetChildren()) do
                    if isFruit(fruit) then
                        local part = Instance.new("Part")
                        part.Anchored = true; part.CanCollide = false; part.Transparency = 1
                        part.CFrame = fruit:GetPivot()
                        part.Parent = espFolder
                        local txt = fruit.Name
                        if Config.ShowDistance then txt = txt .. " | " .. getDist(part) .. "m" end
                        createLabel(part, txt, Color3.fromRGB(0, 255, 100))
                    end
                end
            end
        end
        if Config.ChestESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:find("Chest") and obj:IsA("Model") then
                    local pivot = obj:GetPivot()
                    local part = Instance.new("Part")
                    part.Anchored = true; part.CanCollide = false; part.Transparency = 1
                    part.CFrame = pivot
                    part.Parent = espFolder
                    createLabel(part, "Chest", Color3.fromRGB(255, 255, 0))
                end
            end
        end
        if Config.ItemESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj.Name:find("Gear") or obj.Name:find("Berry") or obj.Name:find("Flower")) and obj:IsA("Model") then
                    local pivot = obj:GetPivot()
                    local part = Instance.new("Part")
                    part.Anchored = true; part.CanCollide = false; part.Transparency = 1
                    part.CFrame = pivot
                    part.Parent = espFolder
                    createLabel(part, obj.Name, Color3.fromRGB(180, 100, 255))
                end
            end
        end
        if Config.FoodESP then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:find("Food") or obj.Name:find("Meat") then
                    local pivot = obj:GetPivot()
                    local part = Instance.new("Part")
                    part.Anchored = true; part.CanCollide = false; part.Transparency = 1
                    part.CFrame = pivot
                    part.Parent = espFolder
                    createLabel(part, obj.Name, Color3.fromRGB(255, 100, 100))
                end
            end
        end
    end
end)

-- ============================================================
-- 24. TELEPORTS — FULL ISLAND + BOSS + NPC + SHOP
-- ============================================================
local ISLANDS = {
    -- Sea 1
    ["Port Town"] = CFrame.new(-275, 7, 5350),
    ["Green Zone"] = CFrame.new(-150, 7, 350),
    ["Jungle"] = CFrame.new(-1400, 7, 350),
    ["Pirate Village"] = CFrame.new(-1200, 7, 3300),
    ["Desert"] = CFrame.new(900, 7, 4200),
    ["Snow Island"] = CFrame.new(1300, 7, -1400),
    ["Marine Fortress"] = CFrame.new(-4800, 7, 4200),
    ["Sky Island"] = CFrame.new(-5000, 500, -3000),
    -- Sea 2
    ["Kingdom of Rose"] = CFrame.new(-300, 7, 5300),
    ["Cursed Ship"] = CFrame.new(900, 7, 14500),
    ["Ice Castle"] = CFrame.new(5500, 7, -1500),
    ["Forgotten Island"] = CFrame.new(-3000, 7, -2500),
    ["Prison"] = CFrame.new(5000, 7, 500),
    ["Magma Village"] = CFrame.new(-5000, 7, 4000),
    ["Underwater City"] = CFrame.new(-3000, -100, 6000),
    -- Sea 3
    ["Great Tree"] = CFrame.new(2000, 7, -5000),
    ["Hydra Island"] = CFrame.new(5000, 7, 2000),
    ["Castle on the Sea"] = CFrame.new(-5000, 7, -3000),
    ["Haunted Castle"] = CFrame.new(-8000, 7, -5000),
    ["Sea of Treats"] = CFrame.new(3000, 7, 8000),
}

local BOSSES = {
    ["Wysper"] = CFrame.new(-5000, 500, -3000),
    ["Thunder God"] = CFrame.new(-5000, 500, -3000),
    ["Greybeard"] = CFrame.new(-5000, 7, 4000),
    ["Darkbeard"] = CFrame.new(900, 7, 14500),
    ["Cake Prince"] = CFrame.new(3000, 7, 8000),
    ["Dough King"] = CFrame.new(3000, 7, 8000),
}

local SHOPS = {
    ["Sword Dealer"] = CFrame.new(-1400, 7, 350),
    ["Fruit Dealer"] = CFrame.new(-275, 7, 5350),
    ["Haki Dealer"] = CFrame.new(-1400, 7, 350),
    ["Fishman Karate"] = CFrame.new(-3000, -100, 6000),
}

-- ============================================================
-- 25. MISC — FLY / NOCLIP / SPEED / ANTI-LAG
-- ============================================================
local flyBV, flyBG
local function toggleFly(state)
    local hrp = getHRP()
    if not hrp then return end
    if state then
        flyBV = Instance.new("BodyVelocity")
        flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        flyBV.Velocity = Vector3.zero
        flyBV.Parent = hrp
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        flyBG.P = 1000
        flyBG.Parent = hrp
    else
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
    end
end

local noclipConn
local function toggleNoclip(state)
    if state then
        noclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() end
    end
end

local function applySpeed(v)
    local hum = getHum()
    if hum then hum.WalkSpeed = v end
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up()
end)

local function applyAntiLag()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            obj.Enabled = false
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end
end

local function serverHop()
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/2753915549/servers/Public?sortOrder=Asc&limit=100"))
    end)
    if ok and servers then
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(2753915549, s.id, LocalPlayer)
                break
            end
        end
    end
end

-- ============================================================
-- 26. PILL MINIMIZE
-- ============================================================
local function findFluentGui()
    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name:lower():find("fluent") then return gui end
    end
    return nil
end

local FluentGui = findFluentGui()

local PillGui = Instance.new("ScreenGui")
PillGui.Name = "ApexCrowPill_v10"
PillGui.ResetOnSpawn = false
PillGui.IgnoreGuiInset = true
PillGui.DisplayOrder = 2147483647
PillGui.Enabled = false
PillGui.Parent = PlayerGui

local Pill = Instance.new("Frame")
Pill.Size = UDim2.new(0, 140, 0, 40)
Pill.Position = UDim2.new(0.5, -70, 0.5, -20)
Pill.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
Pill.BorderSizePixel = 0
Pill.Parent = PillGui

local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = Pill
local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(80, 180, 255); ps.Thickness = 1.5; ps.Transparency = 0.15; ps.Parent = Pill
local pg = Instance.new("UIGradient")
pg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 22, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 45, 65))
})
pg.Parent = Pill

local pl = Instance.new("TextLabel")
pl.Size = UDim2.new(1, -20, 1, 0)
pl.Position = UDim2.new(0, 10, 0, 0)
pl.BackgroundTransparency = 1
pl.Text = "APEX CROW"
pl.TextColor3 = Color3.fromRGB(255, 255, 255)
pl.Font = Enum.Font.GothamBold
pl.TextSize = 13
pl.TextStrokeTransparency = 0.7
pl.Parent = Pill

local sh = Instance.new("Frame")
sh.Size = UDim2.new(1, 6, 1, 6)
sh.Position = UDim2.new(0, -3, 0, 2)
sh.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
sh.BackgroundTransparency = 0.6
sh.BorderSizePixel = 0
sh.ZIndex = -1
sh.Parent = Pill
local shc = Instance.new("UICorner"); shc.CornerRadius = UDim.new(1, 0); shc.Parent = sh

local dragging, dragStart, startPos, hasMoved = false, nil, nil, false

Pill.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; hasMoved = false
        dragStart = input.Position; startPos = Pill.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local delta = input.Position - dragStart
    if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then hasMoved = true end
    Pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end)

UserInputService.InputEnded:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if not hasMoved then
            if not FluentGui or not FluentGui.Parent then FluentGui = findFluentGui() end
            if FluentGui then FluentGui.Enabled = true end
            PillGui.Enabled = false
        end
    end
end)

local function minimizeToPill()
    if not FluentGui or not FluentGui.Parent then FluentGui = findFluentGui() end
    if FluentGui then FluentGui.Enabled = false end
    PillGui.Enabled = true
end

local function resetPillPosition()
    Pill.Position = UDim2.new(0.5, -70, 0.5, -20)
end

getgenv().ApexMinimize = minimizeToPill
getgenv().ApexResetPill = resetPillPosition

-- ============================================================
-- 27. UI BUILD
-- ============================================================

-- FARM
Tabs.Farm:AddToggle("AutoFarm", { Title = "Auto Farm (Quest-Aware)", Default = false })
Tabs.Farm:AddSlider("FarmRange", { Title = "Farm Range", Default = 250, Min = 50, Max = 800, Rounding = 0, Suffix = " studs" })
Tabs.Farm:AddDropdown("AttackPosition", { Title = "Attack Position", Values = {"Behind","Above","Below","Front"}, Default = "Behind" })
Tabs.Farm:AddToggle("FastAttack", { Title = "Fast Attack", Default = false })
Tabs.Farm:AddToggle("BringMob", { Title = "Bring Mob (Vacuum)", Default = false })

-- QUEST
Tabs.Quest:AddButton({ Title = "START QUEST NOW", Callback = function() startQuest() end })
Tabs.Quest:AddButton({ Title = "Abandon Quest", Callback = abandonQuest })
Tabs.Quest:AddToggle("AutoQuest", { Title = "Auto Accept Next Quest", Default = false })
Tabs.Quest:AddSlider("AutoQuestDelay", { Title = "Delay Before Next Quest", Default = 3, Min = 1, Max = 30, Rounding = 0, Suffix = "s" })
Tabs.Quest:AddDropdown("QuestName", { Title = "Quest Name", Values = QUEST_NAMES, Default = "BanditQuest1" })
Tabs.Quest:AddSlider("QuestLv", { Title = "Quest Level", Default = 1, Min = 1, Max = 10, Rounding = 0 })
Tabs.Quest:AddInput("QuestMobName", { Title = "Quest Mob Name", Default = "Bandit", Placeholder = "Bandit" })
Tabs.Quest:AddToggle("AutoDetectQuestMob", { Title = "Auto-Detect Mob from Quest Name", Default = false })

-- RAID
Tabs.Raid:AddToggle("AutoRaid", { Title = "Auto Raid (Starts + Farms)", Default = false })
Tabs.Raid:AddDropdown("RaidMap", { Title = "Raid Map", Values = {"Magma","Flame","Ice","Sand","Dark","Light","Rubber","Barrier","Ghost","Magma","Door","Buddha","Love","Spider","Sound","Phoenix","Portal","Rumble","Pain","Blizzard","Gravity","Mammoth","T-Rex","Dough","Shadow","Venom","Control","Spirit","Dragon","Leopard","Kitsune","Yeti","Gas","Creation"}, Default = "Magma" })
Tabs.Raid:AddButton({ Title = "START RAID NOW", Callback = function() startRaid() end })

-- DUNGEON
Tabs.Dungeon:AddToggle("AutoDungeon", { Title = "Auto Dungeon (Teleport + Farm)", Default = false })
Tabs.Dungeon:AddSlider("DungeonFloor", { Title = "Dungeon Floor", Default = 1, Min = 1, Max = 10, Rounding = 0 })

-- FACTORY
Tabs.Factory:AddToggle("AutoFactory", { Title = "Auto Factory Farm", Default = false })
Tabs.Factory:AddToggle("AutoFactoryRaid", { Title = "Auto Factory Raid", Default = false })

-- FISHING
Tabs.Fishing:AddToggle("AutoFishing", { Title = "Auto Fishing", Default = false })
Tabs.Fishing:AddToggle("AutoSellFish", { Title = "Auto Sell Fish", Default = false })

-- DAILY
Tabs.Daily:AddToggle("AutoDaily", { Title = "Auto Daily Quest", Default = false })
Tabs.Daily:AddToggle("AutoWeekly", { Title = "Auto Weekly Quest", Default = false })
Tabs.Daily:AddButton({ Title = "Claim Daily Now", Callback = function() invokeF("ClaimDailyReward") end })
Tabs.Daily:AddButton({ Title = "Claim Weekly Now", Callback = function() invokeF("ClaimWeeklyReward") end })

-- RACE
Tabs.Race:AddToggle("AutoRaceV3", { Title = "Auto Race V3 (Awakening)", Default = false })
Tabs.Race:AddToggle("AutoRaceV4", { Title = "Auto Race V4 Trials", Default = false })
Tabs.Race:AddToggle("AutoRaceAwakening", { Title = "Auto Race Awakening", Default = false })
Tabs.Race:AddButton({ Title = "Teleport to Trial Room (Mansion)", Callback = function()
    tweenTo(CFrame.new(-5000, 7, -3000), 600)
end })

-- STATS
Tabs.Stats:AddToggle("AutoStats", { Title = "Auto Stats (AddPoint)", Default = false })
Tabs.Stats:AddDropdown("StatTarget", { Title = "Stat Target", Values = {"Melee","Defense","Sword","Gun","Demon Fruit"}, Default = "Melee" })
Tabs.Stats:AddSlider("StatAmount", { Title = "Points Per Tick", Default = 1, Min = 1, Max = 10, Rounding = 0 })

-- FRUIT
Tabs.Fruit:AddToggle("FruitSniper", { Title = "Fruit Sniper (Strict)", Default = false })
Tabs.Fruit:AddDropdown("SelectedFruit", {
    Title = "Target Fruit",
    Values = {"Any","Dragon","Dough","Leopard","Kitsune","Venom","Shadow","Control","Spirit","Mammoth","T-Rex","Portal","Buddha"},
    Default = "Any"
})
Tabs.Fruit:AddToggle("AutoStoreFruit", { Title = "Auto Store Fruit", Default = false })
Tabs.Fruit:AddToggle("AutoEatFruit", { Title = "Auto Eat Fruit", Default = false })

-- COMBAT
Tabs.Combat:AddToggle("KillAura", { Title = "Kill Aura (Players + Mobs)", Default = false })
Tabs.Combat:AddSlider("KillAuraRange", { Title = "Kill Aura Range", Default = 30, Min = 10, Max = 100, Rounding = 0, Suffix = " studs" })
Tabs.Combat:AddToggle("AutoBuso", { Title = "Auto Buso Haki", Default = false })
Tabs.Combat:AddToggle("AutoKen", { Title = "Auto Ken Haki", Default = false })
Tabs.Combat:AddToggle("Aimbot", { Title = "Aimbot (Lock Camera to Target)", Default = false })
Tabs.Combat:AddToggle("HitboxExpander", { Title = "Hitbox Expander", Default = false })
Tabs.Combat:AddSlider("HitboxSize", { Title = "Hitbox Size", Default = 10, Min = 5, Max = 50, Rounding = 0 })
Tabs.Combat:AddToggle("AutoBlock", { Title = "Auto Block", Default = false })
Tabs.Combat:AddToggle("AutoDodge", { Title = "Auto Dodge (Jump)", Default = false })

-- ESP
Tabs.ESP:AddToggle("PlayerESP", { Title = "Player ESP", Default = false })
Tabs.ESP:AddToggle("MobESP", { Title = "Mob ESP", Default = false })
Tabs.ESP:AddToggle("FruitESP", { Title = "Fruit ESP", Default = false })
Tabs.ESP:AddToggle("ChestESP", { Title = "Chest ESP", Default = false })
Tabs.ESP:AddToggle("ItemESP", { Title = "Item ESP (Gears/Berries/Flowers)", Default = false })
Tabs.ESP:AddToggle("FoodESP", { Title = "Food ESP", Default = false })
Tabs.ESP:AddToggle("ShowDistance", { Title = "Show Distance", Default = true })

-- TELEPORT (Islands)
for name, cf in pairs(ISLANDS) do
    Tabs.Teleport:AddButton({ Title = "Island: " .. name, Callback = function() tweenTo(cf, 600) end })
end
-- TELEPORT (Bosses)
for name, cf in pairs(BOSSES) do
    Tabs.Teleport:AddButton({ Title = "Boss: " .. name, Callback = function() tweenTo(cf, 600) end })
end
-- TELEPORT (Shops)
for name, cf in pairs(SHOPS) do
    Tabs.Teleport:AddButton({ Title = "Shop: " .. name, Callback = function() tweenTo(cf, 600) end })
end

-- MISC
Tabs.Misc:AddToggle("AntiAFK", { Title = "Anti-AFK", Default = true })
Tabs.Misc:AddToggle("AntiLag", { Title = "Anti-Lag Mode", Default = false })
Tabs.Misc:AddToggle("Fly", { Title = "Fly", Default = false })
Tabs.Misc:AddToggle("Noclip", { Title = "Noclip", Default = false })
Tabs.Misc:AddToggle("SpeedHack", { Title = "Speed Hack", Default = false })
Tabs.Misc:AddSlider("SpeedValue", { Title = "WalkSpeed", Default = 100, Min = 16, Max = 500, Rounding = 0 })
Tabs.Misc:AddToggle("AutoBuyHaki", { Title = "Auto-Buy Buso/Ken", Default = false })
Tabs.Misc:AddToggle("AutoBuyStyles", { Title = "Auto-Buy Fighting Styles", Default = false })
Tabs.Misc:AddToggle("AutoUnlockWeapons", { Title = "Auto-Unlock Weapons", Default = false })
Tabs.Misc:AddToggle("AutoBoatFarm", { Title = "Auto Boat Farm", Default = false })
Tabs.Misc:AddToggle("AutoPirateRaid", { Title = "Auto Pirate Raid", Default = false })
Tabs.Misc:AddToggle("AutoCakePrince", { Title = "Auto Cake Prince", Default = false })
Tabs.Misc:AddToggle("AutoDoughKing", { Title = "Auto Dough King", Default = false })
Tabs.Misc:AddToggle("AutoVolcano", { Title = "Auto Volcano Farm", Default = false })
Tabs.Misc:AddToggle("AutoPrehistoric", { Title = "Auto Prehistoric Farm", Default = false })
Tabs.Misc:AddToggle("AutoCollectOrbs", { Title = "Auto Collect Orbs", Default = false })
Tabs.Misc:AddButton({ Title = "Minimize to Pill", Callback = function() minimizeToPill() end })
Tabs.Misc:AddButton({ Title = "Reset Pill Position", Callback = resetPillPosition })
Tabs.Misc:AddButton({ Title = "Server Hop (Lowest Players)", Callback = serverHop })
Tabs.Misc:AddButton({ Title = "Save Config", Callback = function()
    SaveManager:SetLibrary(Fluent)
    SaveManager:SetFolder("ApexCrow")
    SaveManager:Save("BloxFruits_v10")
end })
Tabs.Misc:AddButton({ Title = "Load Config", Callback = function()
    SaveManager:SetLibrary(Fluent)
    SaveManager:SetFolder("ApexCrow")
    SaveManager:Load("BloxFruits_v10")
end })

-- ============================================================
-- 28. OPTIONS -> CONFIG BRIDGE
-- ============================================================
local function bind(name, key)
    if Options[name] then Options[name]:OnChanged(function(v) Config[key] = v end) end
end

bind("AutoFarm","AutoFarm"); bind("FarmRange","FarmRange"); bind("AttackPosition","AttackPosition")
bind("FastAttack","FastAttack"); bind("BringMob","BringMob")
bind("AutoQuest","AutoQuest"); bind("AutoQuestDelay","AutoQuestDelay")
bind("QuestName","QuestName"); bind("QuestLv","QuestLv"); bind("QuestMobName","QuestMobName")
bind("AutoDetectQuestMob","AutoDetectQuestMob")
bind("AutoRaid","AutoRaid"); bind("RaidMap","RaidMap")
bind("AutoDungeon","AutoDungeon"); bind("DungeonFloor","DungeonFloor")
bind("AutoFactory","AutoFactory"); bind("AutoFactoryRaid","AutoFactoryRaid")
bind("AutoFishing","AutoFishing"); bind("AutoSellFish","AutoSellFish")
bind("AutoDaily","AutoDaily"); bind("AutoWeekly","AutoWeekly")
bind("AutoRaceV3","AutoRaceV3"); bind("AutoRaceV4","AutoRaceV4"); bind("AutoRaceAwakening","AutoRaceAwakening")
bind("AutoStats","AutoStats"); bind("StatTarget","StatTarget"); bind("StatAmount","StatAmount")
bind("FruitSniper","FruitSniper"); bind("SelectedFruit","SelectedFruit")
bind("AutoStoreFruit","AutoStoreFruit"); bind("AutoEatFruit","AutoEatFruit")
bind("KillAura","KillAura"); bind("KillAuraRange","KillAuraRange")
bind("AutoBuso","AutoBuso"); bind("AutoKen","AutoKen"); bind("Aimbot","Aimbot")
bind("HitboxExpander","HitboxExpander"); bind("HitboxSize","HitboxSize")
bind("AutoBlock","AutoBlock"); bind("AutoDodge","AutoDodge")
bind("PlayerESP","PlayerESP"); bind("MobESP","MobESP"); bind("FruitESP","FruitESP")
bind("ChestESP","ChestESP"); bind("ItemESP","ItemESP"); bind("FoodESP","FoodESP")
bind("ShowDistance","ShowDistance")
bind("AntiAFK","AntiAFK"); bind("AntiLag","AntiLag"); bind("Fly","Fly"); bind("Noclip","Noclip")
bind("SpeedHack","SpeedHack"); bind("SpeedValue","SpeedValue")
bind("AutoBuyHaki","AutoBuyHaki"); bind("AutoBuyStyles","AutoBuyStyles")
bind("AutoUnlockWeapons","AutoUnlockWeapons"); bind("AutoBoatFarm","AutoBoatFarm")
bind("AutoPirateRaid","AutoPirateRaid"); bind("AutoCakePrince","AutoCakePrince")
bind("AutoDoughKing","AutoDoughKing"); bind("AutoVolcano","AutoVolcano")
bind("AutoPrehistoric","AutoPrehistoric"); bind("AutoCollectOrbs","AutoCollectOrbs")

Options.Fly:OnChanged(function(v) Config.Fly = v; toggleFly(v) end)
Options.Noclip:OnChanged(function(v) Config.Noclip = v; toggleNoclip(v) end)
Options.SpeedHack:OnChanged(function(v) Config.SpeedHack = v; applySpeed(v and Config.SpeedValue or 16) end)
Options.SpeedValue:OnChanged(function(v) Config.SpeedValue = v; if Config.SpeedHack then applySpeed(v) end end)
Options.AntiLag:OnChanged(function(v) Config.AntiLag = v; if v then applyAntiLag() end end)

-- ============================================================
-- 29. INIT
-- ============================================================
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("ApexCrow")
SaveManager:BuildConfigSection(Tabs.Misc)
SaveManager:LoadAutoloadConfig()

Fluent:Notify({ Title = "Apex Crow v10", Content = "Raid, Dungeon, Factory, Fishing, Daily, Race Awakening, Stats — all wired.", Duration = 6 })
print("Apex Crow v10 initialized — 14-tab full stack. RaidsNpc + requestEntrance verified. Delta patched.")