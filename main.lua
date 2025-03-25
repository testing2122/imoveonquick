--[[
    LunaIDE - Modern Roblox IDE
    Author: Claude
    Description: A beautiful, feature-rich code editor for Roblox
    with a moonlight purple fantasy theme
]]

local LunaIDE = {}
LunaIDE.__index = LunaIDE
LunaIDE.Version = "1.0.0"

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Directories where components are stored
local BASE_URL = "https://raw.githubusercontent.com/biggaboy212/In-Game-IDE/refs/heads/main/update8/IDEModule.lua"

-- Import components
local Components = {
    UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/LunaIDE/main/ui.lua"))(),
    CodeEditor = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/LunaIDE/main/editor.lua"))(),
    FileSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/LunaIDE/main/filesystem.lua"))(),
    Settings = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/LunaIDE/main/settings.lua"))(),
    Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/LunaIDE/main/utilities.lua"))(),
}

-- For development, allow local loading of files
local function loadComponents()
    local success, result = pcall(function()
        Components.UI = loadstring(readfile("D:/lunaIDE/ui.lua"))()
        Components.CodeEditor = loadstring(readfile("D:/lunaIDE/editor.lua"))()
        Components.FileSystem = loadstring(readfile("D:/lunaIDE/filesystem.lua"))()
        Components.Settings = loadstring(readfile("D:/lunaIDE/settings.lua"))()
        Components.Utilities = loadstring(readfile("D:/lunaIDE/utilities.lua"))()
    end)
    
    if not success then
        warn("Failed to load local components: " .. result)
        -- Fall back to the original IDE module for core functionality
        Components.CodeEditor = loadstring(game:HttpGet(BASE_URL))()
    end
end

-- Try to load local components first
loadComponents()

-- Theme settings
LunaIDE.DefaultTheme = {
    Primary = Color3.fromRGB(74, 57, 117),      -- Deep purple
    Secondary = Color3.fromRGB(116, 86, 174),   -- Medium purple
    Accent = Color3.fromRGB(199, 125, 255),     -- Light purple/pink
    Background = Color3.fromRGB(26, 24, 38),    -- Dark background
    SecondaryBackground = Color3.fromRGB(34, 31, 48), -- Slightly lighter background
    Text = Color3.fromRGB(220, 217, 252),       -- Light purple text
    Syntax = {
        Text = Color3.fromRGB(220, 217, 252),
        Background = Color3.fromRGB(18, 17, 31),
        Selection = Color3.fromRGB(255, 255, 255),
        SelectionBack = Color3.fromRGB(102, 90, 186),
        Operator = Color3.fromRGB(249, 117, 131),
        Number = Color3.fromRGB(153, 170, 255),
        String = Color3.fromRGB(177, 219, 255),
        Comment = Color3.fromRGB(121, 112, 169),
        Keyword = Color3.fromRGB(249, 117, 177),
        BuiltIn = Color3.fromRGB(153, 170, 255),
        LocalMethod = Color3.fromRGB(153, 170, 255),
        LocalProperty = Color3.fromRGB(198, 146, 240),
        Nil = Color3.fromRGB(153, 170, 255),
        Bool = Color3.fromRGB(153, 170, 255),
        Function = Color3.fromRGB(249, 117, 177),
        Local = Color3.fromRGB(249, 117, 177),
        Self = Color3.fromRGB(198, 146, 240),
        FunctionName = Color3.fromRGB(198, 146, 240),
        Bracket = Color3.fromRGB(153, 170, 255)
    }
}

function LunaIDE.new()
    local self = setmetatable({}, LunaIDE)
    
    -- Initialize components
    self.UI = Components.UI.new(self)
    self.Editor = Components.CodeEditor.new(self)
    self.FileSystem = Components.FileSystem.new(self)
    self.Settings = Components.Settings.new(self)
    self.Utilities = Components.Utilities
    
    -- Apply default theme
    self.CurrentTheme = self.DefaultTheme
    
    -- Create the main UI
    self:Initialize()
    
    return self
end

function LunaIDE:Initialize()
    -- Create the main UI frame
    self.MainUI = self.UI:CreateMainInterface()
    
    -- Set up the code editor
    self.EditorFrame = self.UI:CreateEditorFrame(self.MainUI)
    self.Editor:SetupEditor(self.EditorFrame)
    
    -- Set up the file explorer
    self.FileExplorerFrame = self.UI:CreateFileExplorer(self.MainUI)
    self.FileSystem:SetupFileExplorer(self.FileExplorerFrame)
    
    -- Set up settings panel
    self.SettingsPanel = self.UI:CreateSettingsPanel(self.MainUI)
    self.Settings:SetupSettingsPanel(self.SettingsPanel)
    
    -- Initialize AI chat panel
    self.ChatPanel = self.UI:CreateChatPanel(self.MainUI)
    
    -- Connect core events
    self:ConnectEvents()
    
    -- Load saved configurations if available
    self.Settings:LoadSavedConfigs()
    
    return self.MainUI
end

function LunaIDE:ConnectEvents()
    -- Connect UI events to their handlers
    self.UI:ConnectUIEvents()
    
    -- Connect file system events
    self.FileSystem:ConnectEvents()
    
    -- Connect editor events
    self.Editor:ConnectEvents()
    
    -- Connect settings events
    self.Settings:ConnectEvents()
end

function LunaIDE:ApplyTheme(theme)
    self.CurrentTheme = theme or self.DefaultTheme
    self.UI:ApplyTheme(self.CurrentTheme)
    self.Editor:ApplyTheme(self.CurrentTheme.Syntax)
end

function LunaIDE:SaveConfig(configName)
    return self.Settings:SaveConfig(configName)
end

function LunaIDE:LoadConfig(configName)
    return self.Settings:LoadConfig(configName)
end

-- Return the module
return LunaIDE 