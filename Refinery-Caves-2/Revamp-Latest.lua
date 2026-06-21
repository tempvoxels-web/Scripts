if not game:IsLoaded() then game.Loaded:Wait() end

local ScriptData = {
    Version = "REVAMP",
    LastUpdated = "6/20/26",
    CompatibleGameBuild = "14197",
    CurrentGameBuild = nil,

    Plot = nil,

    SetLocation = nil,
    IsAutoFarming = false,

    SelectedCollectableForAutoFarm = nil,

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
        -- GrabHandler = nil, -- no longer supported due to AC detection, kept for future reference.
    },
}

local Tables = loadstring(game:HttpGet('https://raw.githubusercontent.com/tempvoxels-web/Scripts/refs/heads/main/Refinery-Caves-2/Tables-Latest'))()
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if not Tables then warn("Failed to load Tables."); return end
if not Rayfield then warn("Failed to load Rayfield."); return end

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

local HasExited = false

local function NotifyExit(Content, Duration)
    if not Content or typeof(Content) ~= "string" then Content = "Please input content of exit or make it a string." end
    if not Duration or typeof(Duration) ~= "number" then Duration = 5 end

    HasExited = true

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
    if not getconnections then return error("Your executor does not support getconnections, please get a better one.") end

    for _, Idle in pairs(getconnections(LocalPlayer.Idled)) do
        Idle:Disable()
    end
end)

if not SuccessIdle then
    warn("Anti-Idle failed.\n\n" .. tostring(ErrIdle))
end

local function GetRemotes()
    local Events = ReplicatedStorage:FindFirstChild("Events"); if not Events then TellError("Could not get Events."); return end
    local Tools = Events:FindFirstChild("Tools"); if not Tools then TellError("Could not get Tools."); return end

    ScriptData.Remotes.Attack = Tools:FindFirstChild("Attack"); if not ScriptData.Remotes.Attack then TellError("Could not get Attack"); return end
    -- ScriptData.Remotes.GrabHandler = Events:FindFirstChild("GrabHandler"); if not ScriptData.Remotes.GrabHandler then TellError("Could not get GrabHandler"); return end

    return true
end

if not newcclosure or not hookmetamethod then
    NotifyExit("Incompatible executor detected.", 7.5); TellError("Script closed because the users executor does not support newcclosure, please get a better one.")
    return 
end 

local OldHook

local CheckRem = GetRemotes()

if not CheckRem then
    if OldHook then
        hookmetamethod(game, "__namecall", OldHook)
    end

    NotifyExit("Could not get all the remotes, unloading script..", 5)
end

OldHook = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if not ScriptData.Remotes.Attack then TellError("Attack remote suddenly dissapeared or failed to get caught."); hookmetamethod(game, "__namecall", OldHook); NotifyExit("Exiting the script because an error occured."); return end

    if not ScriptData.Toggles.PerfectHit and not ScriptData.Toggles.PerfectHit65 then
        return OldHook and OldHook(self, ...)
    end

    local Args = {...}

    local Success, Err = pcall(function()
        if not ScriptData.IsAutoFarming and self == ScriptData.Remotes.Attack and getnamecallmethod() == "FireServer" then
            local Arg = Args[1]

            if Arg and Arg.Alpha then
                if ScriptData.Toggles.PerfectHit65 then
                    Arg.Alpha = math.random(6451, 6500) / 10000
                elseif ScriptData.Toggles.PerfectHit then
                    Arg.Alpha = math.random(9951, 9999) / 10000
                end
            end
        end
    end)

    if not Success then
        TellError("Sudden hook failure on Attack.\n\n" .. tostring(Err))
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

    elseif ScriptData.IsAutoFarming then
        NotifyInformation("You can not use the held item teleport when auto farming.", 7.5)
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

                for i = 1, 4 do 
                    Model:PivotTo(ScriptData.SetLocation)
                    ApplyRandomVelocity(Model)
                end
            end)
        end

        return

    elseif ScriptData.IsAutoFarming then
        NotifyInformation("You can not use the item teleport aura when auto farming.", 7.5)
    end

    if Type ~= "Auto" and Type ~= "Held" and Type ~= "Aura" then TellError("Incorrect Type was parsed.  [AskItemTeleport]"); return end
end

-- -- -- -- -- -- -- -- -- --

Rayfield:Notify({
    Title = "Welcome!",
    Content = "Thank you for using VOXELS.RBX.",
    Image = "heart",
    Duration = 7.5,
})

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

        if not ScriptData.IsAutoFarming then
            ScriptData.SetLocation = HumanoidRootPart.CFrame
        end

        Rayfield:Notify({
            Title = "Set Location",
            Content = ScriptData.IsAutoFarming and "You are unable to set a new location when auto farming." or "New location has been set.",
            Image = ScriptData.IsAutoFarming and "info" or "cog",
            Duration = ScriptData.IsAutoFarming and 5 or 2.5,
        })

        if not ScriptData.IsAutoFarming and SavedPrevious or HasTeleported then 
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

local AutoFarmTab = Window:CreateTab("Auto-Farm")

AutoFarmTab:CreateSection("Auto-Farm")

local function GetOptions(Type)
    if not Type or typeof(Type) ~= "string" then TellError("Type is not a string or Type was not parsed."); return end

    local ReturnTable = {}

    if Tables.OreData and Type == "Ore" then
        for OreName, _ in pairs(Tables.OreData) do
            table.insert(ReturnTable, OreName)
        end

        table.sort(ReturnTable)
        table.insert(ReturnTable, 1, "None")
    end

    if Tables.TreeData and Type == "Tree" then
        for TreeName, _ in pairs(Tables.TreeData) do
            table.insert(ReturnTable, TreeName)
        end

        table.sort(ReturnTable)
        table.insert(ReturnTable, 1, "Placeholder")
    end

    if Type ~= "Ore" and Type ~= "Tree" then TellError("Incorrect Type was parsed.  [GetOptions]"); return end

    return ReturnTable
end

local OreOptions = GetOptions("Ore")
local TreeOptions = GetOptions("Tree")

local OreDropdown = nil
local TreeDropdown = nil

local UpdatingDropdown = false

OreDropdown = AutoFarmTab:CreateDropdown({
    Name = "Selected Ore",
    Options = OreOptions,
    CurrentOption = "None",
    MultipleOptions = false,
    Flag = "SelectedOre",
    Callback = function(o)
        if UpdatingDropdown then return end

        UpdatingDropdown = true
        TreeDropdown:Set({"Placeholder"})
        task.wait()
        UpdatingDropdown = false

        ScriptData.SelectedCollectableForAutoFarm = o[1]

        Rayfield:Notify({
            Title = "Selected Ore",
            Content = "Selected: " .. ScriptData.SelectedCollectableForAutoFarm,
            Image = "cog",
            Duration = 4,
        })
    end,
})

TreeDropdown = AutoFarmTab:CreateDropdown({
    Name = "Selected Tree",
    Options = TreeOptions,
    CurrentOption = "Placeholder",
    MultipleOptions = false,
    Flag = "TreeOre",
    Callback = function(o)
        if UpdatingDropdown then return end

        UpdatingDropdown = true
        OreDropdown:Set({"None"})
        task.wait()
        UpdatingDropdown = false

        ScriptData.SelectedCollectableForAutoFarm = o[1]

        Rayfield:Notify({
            Title = "Selected Tree",
            Content = "Selected: " .. ScriptData.SelectedCollectableForAutoFarm,
            Image = "cog",
            Duration = 4,
        })
    end,
})



-- -- -- -- -- -- -- -- -- --

local TeleportsTab = Window:CreateTab("Teleports")

local function TeleportToRequest(CFrame, LocationName)
    if not CFrame or typeof(CFrame) ~= "CFrame" then warn("CFrame was not parsed or CFrame is not a CFrame."); return end
    if not LocationName or typeof(LocationName) ~= "string" then warn("LocationName was not parsed or LocationName is not a string."); return end

    local Character = LocalPlayer.Character; if not Character then return end
    local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart"); if not HumanoidRootPart then return end

    HumanoidRootPart.CFrame = CFrame

    Rayfield:Notify({
        Title = "Teleported",
        Content = "Teleported to " .. LocationName,
        Image = "move-3d",
        Duration = 4,
    })
end

TeleportsTab:CreateSection("Plot")

TeleportsTab:CreateButton({
    Name = "Plot",
    Callback = function()
        TeleportToRequest(ScriptData.Plot.CFrame + Vector3.new(0,25,0), "your Plot")
    end
})

TeleportsTab:CreateSection("Shops")

TeleportsTab:CreateButton({
    Name = "Novabay Utility",
    Callback = function()
        TeleportToRequest(CFrame.new(1261, 44, -688), "Novabay Utility")
    end
})

TeleportsTab:CreateButton({
    Name = "Build'n Crate",
    Callback = function()
        TeleportToRequest(CFrame.new(1077, 45, -837), "Build'n Crate")
    end
})

TeleportsTab:CreateButton({
    Name = "Craig's Dealership",
    Callback = function()
        TeleportToRequest(CFrame.new(716, 48, -565), "Craig's Dealership")
    end
})

TeleportsTab:CreateButton({
    Name = "Nautic Finds",
    Callback = function()
        TeleportToRequest(CFrame.new(1802, 23, -1382), "Nautic Finds")
    end
})

TeleportsTab:CreateButton({
    Name = "Coal's Furniture",
    Callback = function()
        TeleportToRequest(CFrame.new(1193, 128, 540), "Coal's Furniture")
    end
})

TeleportsTab:CreateButton({
    Name = "Lush Cave Shop",
    Callback = function()
        TeleportToRequest(CFrame.new(-592, -514, 990), "Lush Cave Shop")
    end
})

TeleportsTab:CreateButton({
    Name = "Shack",
    Callback = function()
        TeleportToRequest(CFrame.new(1053, 281, 3925), "Shack")
    end
})

TeleportsTab:CreateButton({
    Name = "Dell's Shipyard",
    Callback = function()
        TeleportToRequest(CFrame.new(-179, 17, 3378), "Dell's Shipyard")
    end
})

TeleportsTab:CreateButton({
    Name = "Vi's Logics",
    Callback = function()
        TeleportToRequest(CFrame.new(-5149, 70, -2821), "Vi's Logics")
    end
})

TeleportsTab:CreateSection("Sellary's")

TeleportsTab:CreateButton({
    Name = "Nova Sellary",
    Callback = function()
        TeleportToRequest(CFrame.new(943, 46, -731), "Nova Sellary")
    end
})

TeleportsTab:CreateButton({
    Name = "Nautic Sellary",
    Callback = function()
        TeleportToRequest(CFrame.new(1571, 16, -1292), "Nautic Sellary")
    end
})

TeleportsTab:CreateDivider()

-- -- -- -- -- -- -- -- -- --

local MiscTab = Window:CreateTab("Misc")

-- -- -- -- -- -- -- -- -- --

local InformationTab = Window:CreateTab("Information")

InformationTab:CreateSection("Info")

local VersionInfo = InformationTab:CreateParagraph({Title = "Version: \n", Content = "Empty, SetVersion function might have broke or is bugged."})

local function SetVersion()
    if not ScriptData.Version or not ScriptData.LastUpdated or not ScriptData.CompatibleGameBuild or not ScriptData.CurrentGameBuild then TellError("Data error occured in SetVersion function."); NotifyInformation("Unable to get correct versions, script may be broken/patched", 7.5, true); return end

    VersionInfo:Set({Title = "Version: \n", Content = 
("Script Version: " .. ScriptData.Version .. 
"\n" .. "Last Updated: " .. ScriptData.LastUpdated .. "  (MM/DD/YY)" .. 
"\n" .. "Compatible Game Build: " .. ScriptData.CompatibleGameBuild .. 
"\n" .. "Current Game Build: ".. tostring(ScriptData.CurrentGameBuild))})
end

SetVersion()

InformationTab:CreateSection("Debug")

local function DataRequestClipboard(Type)
    if not Type or typeof(Type) ~= "string" then TellError("Type is not a string or Type was not parsed."); return end
    if not setclipboard then return end

    local ContentFolder = ReplicatedStorage:FindFirstChild("Content"); if not ContentFolder then TellError("Could not get ContentFolder.  [DataRequestClipboard]"); return end
    local TableOutput = "local ".. Type .." = {\n"

    if Type == "OreData" then
        local OresFolder = ContentFolder:FindFirstChild("Ores"); if not OresFolder then TellError("Could not get OresFolder.  [DataRequestClipboard]"); return end

        for _, Ore in ipairs(OresFolder:GetChildren()) do
	        if Ore.ClassName == "Model" then
                local FoundTier = nil

                for _, Tier in ipairs(Ore:GetDescendants()) do
                    if Tier.Name == "Tier" and Tier.ClassName == "NumberValue" then
                        FoundTier = Tier.Value
                    end
                end

		        TableOutput ..= string.format(
			        '\t["%s"] = {\n\t\tKnownArea = nil,\n\t\tTier = %s,\n\t\tType = nil,\n\t},\n',
			        Ore.Name,
                    tostring(FoundTier)
		        )
	        end
        end
    end
    
    if Type == "TreeData" then
        local TreesFolder = ContentFolder:FindFirstChild("Trees"); if not TreesFolder then TellError("Could not get TreesFolder.  [DataRequestClipboard]"); return end

        for _, Tree in ipairs(TreesFolder:GetChildren()) do
	        if Tree.ClassName == "ModuleScript" then
                local FoundTier = nil

                for _, Tier in ipairs(Tree:GetDescendants()) do
                    if Tier.Name == "Tier" and Tier.ClassName == "NumberValue" then
                        FoundTier = Tier.Value
                    end
                end

		        TableOutput ..= string.format(
			        '\t["%s"] = {\n\t\tKnownArea = nil,\n\t\tTier = %s,\n\t\tType = nil,\n\t},\n',
			        Tree.Name,
                    tostring(FoundTier)
		        )
	        end
        end
    end

    if Type ~= "OreData" and Type ~= "TreeData" then TellError("Incorrect Type was parsed.  [DataRequestClipboard]"); return end

    TableOutput ..= "}"
    setclipboard(TableOutput)

    return true
end

local SelectedTableType = "OreData"

InformationTab:CreateDropdown({
    Name = "Selected Table",
    Options = {"OreData", "TreeData"},
    CurrentOption = {"OreData"},
    MultipleOptions = false,
    Flag = "SelectedTable",
    Callback = function(o)
        SelectedTableType = o[1]
    end,
})

InformationTab:CreateButton({
    Name = "Copy Selected Table to Clipboard",
    Callback = function()
        local ClipboardRequestReturn = DataRequestClipboard(SelectedTableType)

        Rayfield:Notify({
            Title = ClipboardRequestReturn and "Successfully copied" or "Could not copy.",
            Content = ClipboardRequestReturn and "Press Ctrl+V to paste somewhere else." or "If you think this is an error that shouldn't occur, please contact VOXELS.RBX.",
            Image = ClipboardRequestReturn and "check" or "frown",
            Duration = 4,
        })
    end,
})

local LastBuildCheck = 0
local CooldownDuration = 5

InformationTab:CreateButton({
    Name = "Attempt Build Recheck",
    Callback = function()
        local CurrentTime = tick()

        if CurrentTime - LastBuildCheck >= CooldownDuration then
            LastBuildCheck = CurrentTime

            ScriptData.CurrentGameBuild = CheckGameBuild()

            SetVersion()

            Rayfield:Notify({
                Title = "Build Recheck",
                Content = "The build has been rechecked, if it shows a 0 this might be a game fault, if it shows UNKNOWN please contact VOXELS.RBX.",
                Image = "check",
                Duration = 15,
            })
        else
            local TimeLeft = math.ceil(CooldownDuration - (CurrentTime - LastBuildCheck))

            Rayfield:Notify({
                Title = "Cooldown",
                Content = "Please wait. (" .. TimeLeft .. "s)",
                Image = "loader",
                Duration = 3,
            })
        end
    end,
})

InformationTab:CreateSection("Extra")

InformationTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        hookmetamethod(game, "__namecall", OldHook)

        NotifyExit("Made by VOXELS.RBX", 0)
    end,
})

if ScriptData.CurrentGameBuild ~= "Unknown" and ScriptData.CompatibleGameBuild ~= ScriptData.CurrentGameBuild then
    NotifyInformation("Incompatible game version detected! script may be broken/detected.", 7.5, true)
end

InformationTab:CreateDivider()

task.spawn(function()
    while not HasExited do task.wait(2.5)
        local LoopCheckRem = GetRemotes()

        if not LoopCheckRem and not HasExited then
            TellError("A remote suddenly dissapeared or got moved.  [LoopCheckRem]")
            hookmetamethod(game, "__namecall", OldHook)
            NotifyExit("Exiting the script because a critical error occured.", 5)
            break
        elseif HasExited then
            break
        end
    end
end)
