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

-- Creating a local closure to preserve the loadModule function
local LunaIDE
do
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
                return game:HttpGet("https://raw.githubusercontent.com/testing2122/imoveonquick/main/editor.lua")
            end)
            
            if success then
                print("Falling back to original IDE module")
                return loadstring(content)()
            end
        end
        
        error("Failed to load module: " .. name)
    end

    -- Load the main module first
    LunaIDE = loadModule("main")
    
    -- If the main module doesn't directly include the other modules,
    -- load them manually here if needed
    -- for _, moduleName in ipairs(modules) do
    --    if moduleName ~= "main" then
    --        loadModule(moduleName)
    --    end
    -- end
end

-- Initialize the IDE
local ide = LunaIDE.new()

-- Return the IDE instance
return ide 
