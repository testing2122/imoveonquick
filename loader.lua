--[[
    LunaIDE - Loader
    This script loads the LunaIDE into your Roblox experience.
    
    Usage:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/imoveonquick/main/loader.lua"))()
]]

-- Core modules list
local modules = {
    "main",
    "utilities",
    "ui",
    "editor",
    "filesystem",
    "settings"
}

-- Try to load from GitHub, fall back to local file system
local function loadModule(name)
    local success, content
    
    -- First try to load from local file system (for development)
    success, content = pcall(function()
        return readfile("D:/lunaIDE/" .. name .. ".lua")
    end)
    
    if success then
        print("Loaded local module:", name)
        return loadstring(content)()
    end
    
    -- If that fails, try to load from GitHub
    success, content = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/testing2122/imoveonquick/main/" .. name .. ".lua")
    end)
    
    if success then
        print("Loaded remote module:", name)
        return loadstring(content)()
    end
    
    -- If both fail, try to use the original IDE module
    if name == "editor" then
        success, content = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/biggaboy212/In-Game-IDE/main/update8/IDEModule.lua")
        end)
        
        if success then
            print("Falling back to original IDE module")
            return loadstring(content)()
        end
    end
    
    error("Failed to load module: " .. name)
end

-- Make loadModule available to other modules
_G.LunaIDE_loadModule = loadModule

-- Load the main module first
local LunaIDE = loadModule("main")

-- Initialize the IDE
local ide = LunaIDE.new()

-- Return the IDE instance
return ide 