if not game:IsLoaded() then game.Loaded:Wait() end

local ScriptData = {
    Version = "REVAMP",
    LastUpdated = "6/18/26",
    CompatibleGameBuild = "14194",
    CurrentGameBuild = nil,

    Plot = nil,

    SetLocation = nil,
    IsAutoFarming = false,

    Toggles = {
        EnableKeybinds = false,

        PerfectHit = false,
        PerfectHit65 = false,
    },

    Sliders = {
        AuraDistance = 15,
    },

    Remotes = {
        Attack = nil,
        GrabHandler = nil,
    },
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if not Rayfield then
    warn("Failed to load Rayfield.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "Refinery Caves 2 | Voxels.RBX",
    Icon = "sparkle",
    LoadingTitle = "Refinery Caves 2 | Voxels.RBX",
    LoadingSubtitle = "Last Updated: " .. ScriptData.LastUpdated,
    ShowText = "",
    Theme = "Amethyst",

    ToggleUIKeybind = Enum.KeyCode.RightShift,

    DisableRayfieldPrompts = true,
    DisableBuildWarnings = true,

    ConfigurationSaving = {
        Enabled = false,
        FolderName = "VRBX_Configs",
        FileName = "Config_Main_RC2"
    },

    Discord = {
        Enabled = true,
        Invite = "discord.gg/c4byf5cdRd",
        RememberJoins = false
    },
})

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local function WipeScriptData(Table)
    for k, v in pairs(Table) do
        if type(v) == "table" then
            WipeScriptData(v)
        elseif type(v) == "boolean" then
            Table[k] = false
        elseif type(v) == "number" then
            Table[k] = 0
        else
            Table[k] = nil
        end
    end
end

local function TellError(Info)
    if Info then
        warn(tostring(Info))
    elseif not Info then
        warn("Unknown error has occured!")
    end
end

local function NotifyInformation(Content, Duration, Urgent)
    if not Content or typeof(Content) ~= "string" then Content = "Please input content of notification or make it a string." end
    if not Duration or typeof(Duration) ~= "number" then Duration = 5 end

    if not Urgent then
        Rayfield:Notify({
            Title = "Information",
            Content = Content,
            Image = "info",
            Duration = Duration,
        })
    elseif Urgent then
        Rayfield:Notify({
            Title = "Important Information",
            Content = Content,
            Image = "shield-alert",
            Duration = Duration,
        })
    end
end

local function NotifyExit(Content, Duration)
    if not Content or typeof(Content) ~= "string" then Content = "Please input content of exit or make it a string." end
    if not Duration or typeof(Duration) ~= "number" then Duration = 5 end

    if Duration ~= 0 then
        Rayfield:Notify({
            Title = "Exit",
            Content = Content,
            Image = "alert-triangle",
            Duration = Duration,
        })
    end

    WipeScriptData(ScriptData)

    if Duration ~= 0 then task.wait(Duration) end

    Rayfield:Destroy()
end

local function CheckGameBuild()
    local FoundBuild = nil
    local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui"); if not PlayerGui then TellError("Could not find PlayerGui."); NotifyInformation("Could not pull game build! script may be broken/detected.", 7.5, true); return "Unknown" end

    for _,v in ipairs(PlayerGui:GetDescendants()) do
        if v.Name == "Build" and v.ClassName == "TextLabel" and string.find(string.lower(v.Text), "build") then
            FoundBuild = string.match(string.lower(v.Text), "build:%s*(%d+)")

            print("Build: " .. tostring(FoundBuild))
        end
    end

    if not FoundBuild then TellError("Could not find the current game build."); NotifyInformation("Could not pull game build! script may be broken/detected.", 7.5, true); return "Unknown" end

    return FoundBuild
end

local function GetPlot()
    local Plots = Workspace:FindFirstChild("Plots"); if not Plots then TellError("Could not get plots."); return end

    for _, FoundPlot in pairs(Plots:GetChildren()) do
        if FoundPlot:GetAttribute("Owner") and FoundPlot:GetAttribute("Owner") == tostring(LocalPlayer) then
            local Plot = FoundPlot:FindFirstChild("Plot"); if not Plot then return end

            return Plot
        end
    end
end

ScriptData.CurrentGameBuild = CheckGameBuild()

local StartTime = tick()
local SentInformation = false
local SentExit = false

repeat
    ScriptData.Plot = GetPlot()

    if not SentInformation and tick() - StartTime > 10 then
        SentInformation = true
        NotifyInformation("Your plot is taking longer to load, this might be a loading error.", 5)
    elseif not SentExit and tick() - StartTime > 60 then
        SentExit = true
        NotifyExit("Could not get plot in time! unloading script..", 5)
        return
    end
    task.wait(0.25)
until ScriptData.Plot ~= nil

local SuccessIdle, ErrIdle = pcall(function()
    if not getconnections then return error("Your executor is dogwater and doesn't have getconnections 💀💀") end

    for _, Idle in pairs(getconnections(LocalPlayer.Idled)) do
        Idle:Disable()
    end
end)

if not SuccessIdle then
    warn("Anti-Idle failed. | Error: " .. tostring(ErrIdle))
end

local function GetRemotes()
    local Events = ReplicatedStorage:FindFirstChild("Events"); if not Events then TellError("Could not get Events."); return end
    local Tools = Events:FindFirstChild("Tools"); if not Tools then TellError("Could not get Tools."); return end

    ScriptData.Remotes.Attack = Tools:FindFirstChild("Attack"); if not ScriptData.Remotes.Attack then TellError("Could not get Attack"); return end
    ScriptData.Remotes.GrabHandler = Events:FindFirstChild("GrabHandler"); if not ScriptData.Remotes.GrabHandler then TellError("Could not get GrabHandler"); return end

    return true
end

local CheckRem = GetRemotes()

if not CheckRem then
    NotifyExit("Could not get all the remotes, unloading script..", 5)
end

if not newcclosure then warn("Executor absolute hot steaming garbage, get a better one."); return end 

local OldHook
OldHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not ScriptData.IsAutoFarming and self == ScriptData.Remotes.Attack and getnamecallmethod() == "FireServer" then
        local Arg = ...

        if Arg and Arg.Alpha then
            if ScriptData.Toggles.PerfectHit65 then
                Arg.Alpha = math.random(6451, 6500) / 10000
            elseif ScriptData.Toggles.PerfectHit then
                Arg.Alpha = math.random(9951, 9999) / 10000
            end
        end
    end

    return OldHook(self, ...)
end))

local Overlap = OverlapParams.new()

local function AskItemTeleport(Type)
    if not Type or typeof(Type) ~= "string" then TellError("Type is not a string or Type was not parsed."); return end

    if not ScriptData.SetLocation then 
        NotifyInformation("Please set a location before trying to teleport items.", 5)
        return 
    end

    local Character = LocalPlayer.Character; if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart"); if not HumanoidRootPart then return end

    Overlap.FilterDescendantsInstances = {Character}

    local function GetParts(Value)
        if not Value or typeof(Value) ~= "number" then TellError("No number value set for Value or none was parsed.  [GetParts]"); return end

        local Parts = Workspace:GetPartBoundsInRadius(
            HumanoidRootPart.Position,
            Value,
            Overlap
        )

        return Parts
    end

    local function ApplyRandomVelocity(Model)
        local Root = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart")

        if Root then
            Root.AssemblyLinearVelocity = Vector3.new(math.random(-3, 3), math.random(-3, 3), math.random(-3, 3))
        end
    end

    local function GetOwnershipStatus(Model)
        if not Model then TellError("Model not found or was not parsed.  [GetOwnershipStatus]"); return end

        local Root = Model:FindFirstChildWhichIsA("BasePart") or Model.PrimaryPart
        if not Root then return false end

        if Root.Anchored then
            return false
        else
            return not Root:IsGrounded() and Root.ReceiveAge < 0.1
        end
    end

    if Type == "Auto" then

        return
    end

    if not ScriptData.IsAutoFarming and Type == "Held" then
        local Parts = GetParts(12.5)
        if next(Parts) == nil then TellError("No parts found.  [Held]"); return end

        for _,Part in ipairs(Parts) do
            local Model = Part:FindFirstAncestorWhichIsA("Model")
            local Pivot = Model:GetPivot().Position

            if Model and Model.Parent.Name == "Grab" then
                for _, Grab in ipairs(Model:GetDescendants()) do
                    if Grab.Name == "_Grab" then
                        Model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

                        Model:PivotTo(ScriptData.SetLocation)
                        ApplyRandomVelocity(Model)
                    end
                end
            end
        end

        return
    end

    if not ScriptData.IsAutoFarming and Type == "Aura" then
        local ValidModels = {}
        local Parts = GetParts(ScriptData.Sliders.AuraDistance)
        if next(Parts) == nil then TellError("No parts found.  [Aura]"); return end

        for _,Part in ipairs(Parts) do
            local Model = Part:FindFirstAncestorWhichIsA("Model")

            if Model and Model.Parent.Name == "Grab" then
                local Ownership = GetOwnershipStatus(Model)

                if Ownership then
                    table.insert(ValidModels, Model)
                end
            end
        end

        if next(ValidModels) == nil then TellError("No valid models found.  [Aura]"); return end

        for _,Model in ipairs(ValidModels) do
            task.spawn(function()
                Model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

                local Part = Model:FindFirstChildWhichIsA("Part"); if not Part then TellError("Could not get part from model.  [Aura]"); return end
                local Pivot = Model:GetPivot().Position

                Model:PivotTo(ScriptData.SetLocation)
                ApplyRandomVelocity(Model)
            end)
        end

        return
    end

    if Type ~= "Auto" and Type ~= "Held" and Type ~= "Aura" then TellError("Incorrect Type was parsed.  [AskItemTeleport]") return end
end


-- -- -- -- -- -- -- -- -- -- 

local MainTab = Window:CreateTab("Main")

MainTab:CreateSection("Main")

MainTab:CreateToggle({
    Name = "Enable Keybinds",
    CurrentValue = false,
    Flag = "EnableKeybinds",
    Callback = function(v)
        ScriptData.Toggles.EnableKeybinds = v

        Rayfield:Notify({
            Title = "Enable Keybinds",
            Content = v
                and ("Keybinds enabled.")
                or "Disabled.",
            Image = v and "book-check" or "book-minus",
            Duration = 4,
        })
    end,
})

local SavedPrevious = nil
local HasTeleported = false

MainTab:CreateButton({
    Name = "Set Location",
    Callback = function()
        local Character = LocalPlayer.Character; if not Character then return end
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart"); if not HumanoidRootPart then return end

        ScriptData.SetLocation = HumanoidRootPart.CFrame

        Rayfield:Notify({
            Title = "Set Location",
            Content = "New location has been set.",
            Image = "cog",
            Duration = 2.5,
        })

        if SavedPrevious or HasTeleported then 
            SavedPrevious = nil
            HasTeleported = false
        end
    end,
})

MainTab:CreateButton({
    Name = "Teleport Back & Forth",
    Callback = function()
        if not ScriptData.SetLocation then NotifyInformation("Please set a location before trying to teleport items or yourself.", 7.5); return end

        local Character = LocalPlayer.Character; if not Character then return end
        local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart"); if not HumanoidRootPart then return end

        Rayfield:Notify({
            Title = not HasTeleported 
                and "Teleported to set location." 
                or "Teleported back.",
            Content = not HasTeleported
                and "Teleported to your set location."
                or "Teleported back to before you teleported.",
            Image = "info",
            Duration = 2.5,
        })

        if not HasTeleported then 
            HasTeleported = true
            SavedPrevious = HumanoidRootPart.CFrame
            HumanoidRootPart.CFrame = ScriptData.SetLocation
        elseif HasTeleported and SavedPrevious then
            HasTeleported = false
            HumanoidRootPart.CFrame = SavedPrevious
        end
    end,
})

MainTab:CreateSlider({
    Name = "Aura Distance",
    Range = {1, 30},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 15,
    Flag = "AuraDistance",
    Callback = function(v)
        ScriptData.Sliders.AuraDistance = v
    end,
})

MainTab:CreateKeybind({
   Name = "Teleport Held Item",
   CurrentKeybind = "G",
   HoldToInteract = false,
   Flag = "TeleportHeldItem",
   Callback = function(k)
        if ScriptData.Toggles.EnableKeybinds then
            AskItemTeleport("Held")
        end
   end,
})

MainTab:CreateKeybind({
   Name = "Item Teleport Aura",
   CurrentKeybind = "Y",
   HoldToInteract = false,
   Flag = "TeleportHeldItem",
   Callback = function(k)
        if ScriptData.Toggles.EnableKeybinds then
            AskItemTeleport("Aura")
        end
   end,
})

MainTab:CreateSection("Pickaxe")

MainTab:CreateToggle({
    Name = "Perfect Hit",
    CurrentValue = false,
    Flag = "PerfectHit",
    Callback = function(v)
        ScriptData.Toggles.PerfectHit = v

        Rayfield:Notify({
            Title = "Perfect Hit",
            Content = v
                and "Always perfectly hits for you (100%)."
                or "Disabled.",
            Image = v and "book-check" or "book-minus",
            Duration = 4,
        })
    end,
})

MainTab:CreateToggle({
    Name = "Perfect Hit [65%]",
    CurrentValue = false,
    Flag = "PerfectHit65",
    Callback = function(v)
        ScriptData.Toggles.PerfectHit65 = v

        Rayfield:Notify({
            Title = "Perfect Hit [65%]",
            Content = v
                and "Always perfectly does 65% damage (good for blastshards)."
                or "Disabled.",
            Image = v and "book-check" or "book-minus",
            Duration = 4,
        })
    end,
})

MainTab:CreateDivider()

-- -- -- -- -- -- -- -- -- --

local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateSection("Info")

SettingsTab:CreateParagraph({Title = "Version: \n", Content = 
("Script Version: " .. ScriptData.Version .. 
"\n" .. "Last Updated: " .. ScriptData.LastUpdated .. "  (MM/DD/YY)" .. 
"\n" .. "Compatible Game Build: " .. ScriptData.CompatibleGameBuild .. 
"\n" .. "Current Game Build: ".. tostring(ScriptData.CurrentGameBuild))})

SettingsTab:CreateSection("Misc")

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        hookmetamethod(game, "__namecall", OldHook)

        NotifyExit("Made by VOXELS.RBX", 0)
    end,
})

if ScriptData.CurrentGameBuild ~= "Unknown" and ScriptData.CompatibleGameBuild ~= ScriptData.CurrentGameBuild then
    NotifyInformation("Incompatible game version detected! script may be broken/detected.", 7.5, true)
end

SettingsTab:CreateDivider()
