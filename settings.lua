--[[
    LunaIDE - Settings Module
    Handles user preferences and configurations
]]

local Settings = {}
Settings.__index = Settings

-- Services
local HttpService = game:GetService("HttpService")

-- Import utilities when this module is loaded
local Utilities

function Settings.new(parent)
    local self = setmetatable({}, Settings)
    self.Parent = parent
    Utilities = parent.Utilities
    
    -- Default settings
    self.DefaultSettings = {
        Editor = {
            FontSize = 16,
            TabSize = 4,
            WordWrap = false,
            LineNumbers = true,
            AutoIndent = true,
            HighlightActiveLine = true
        },
        UI = {
            Theme = "Dark Purple", -- Default theme name
            ShowMinimap = true,
            ShowStatusBar = true
        }
    }
    
    -- Current settings (copy of defaults initially)
    self.CurrentSettings = Utilities.DeepCopy(self.DefaultSettings)
    
    -- Saved configurations
    self.SavedConfigs = {
        ["Default"] = Utilities.DeepCopy(self.Parent.DefaultTheme)
    }
    
    return self
end

function Settings:SetupSettingsPanel(panel)
    self.Panel = panel
    
    -- Header
    local header = Utilities.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = self.Parent.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = panel
    })
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 20, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Settings",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    local closeButton = Utilities.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -40, 0, 10),
        BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 24,
        Parent = header
    })
    
    Utilities.RoundCorners(closeButton, 6)
    
    -- Content container
    local content = Utilities.Create("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 700), -- Will be updated based on content
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = self.Parent.CurrentTheme.Secondary,
        Parent = panel
    })
    
    -- Create settings sections
    self:CreateThemeSection(content, UDim2.new(0, 20, 0, 20))
    self:CreateEditorSection(content, UDim2.new(0, 20, 0, 300))
    self:CreateConfigSection(content, UDim2.new(0, 20, 0, 500))
    
    -- Button events
    closeButton.MouseButton1Click:Connect(function()
        self:CloseSettings()
    end)
    
    closeButton.MouseEnter:Connect(function()
        Utilities.Tween(closeButton, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.CurrentTheme.Accent})
    end)
    
    closeButton.MouseLeave:Connect(function()
        Utilities.Tween(closeButton, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.CurrentTheme.Secondary})
    end)
    
    -- Store references
    self.Header = header
    self.Content = content
    
    return panel
end

function Settings:CreateThemeSection(parent, position)
    local section = Utilities.Create("Frame", {
        Name = "ThemeSection",
        Size = UDim2.new(1, -40, 0, 250),
        Position = position,
        BackgroundColor3 = self.Parent.CurrentTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    Utilities.RoundCorners(section, 8)
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Theme Settings",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    -- Color pickers for theme elements
    local colorElements = {
        {Name = "Primary", Color = self.Parent.CurrentTheme.Primary, Y = 50},
        {Name = "Secondary", Color = self.Parent.CurrentTheme.Secondary, Y = 90},
        {Name = "Accent", Color = self.Parent.CurrentTheme.Accent, Y = 130},
        {Name = "Background", Color = self.Parent.CurrentTheme.Background, Y = 170},
        {Name = "Text", Color = self.Parent.CurrentTheme.Text, Y = 210}
    }
    
    for _, element in ipairs(colorElements) do
        self:CreateColorPicker(section, element.Name, element.Color, UDim2.new(0, 10, 0, element.Y))
    end
    
    return section
end

function Settings:CreateEditorSection(parent, position)
    local section = Utilities.Create("Frame", {
        Name = "EditorSection",
        Size = UDim2.new(1, -40, 0, 170),
        Position = position,
        BackgroundColor3 = self.Parent.CurrentTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    Utilities.RoundCorners(section, 8)
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Editor Settings",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    -- Font size slider
    self:CreateSlider(section, "Font Size", self.CurrentSettings.Editor.FontSize, 8, 24, 1, UDim2.new(0, 10, 0, 50), function(value)
        self.CurrentSettings.Editor.FontSize = value
        if self.Parent.Editor and self.Parent.Editor.Editor then
            self.Parent.Editor.Editor.FontSize = value
            self.Parent.Editor.Editor:Refresh()
        end
    end)
    
    -- Toggle options
    local toggleOptions = {
        {Name = "Word Wrap", Value = self.CurrentSettings.Editor.WordWrap, Y = 90, Callback = function(value)
            self.CurrentSettings.Editor.WordWrap = value
            -- Apply to editor
        end},
        {Name = "Line Numbers", Value = self.CurrentSettings.Editor.LineNumbers, Y = 130, Callback = function(value)
            self.CurrentSettings.Editor.LineNumbers = value
            -- Apply to editor
        end}
    }
    
    for _, option in ipairs(toggleOptions) do
        self:CreateToggle(section, option.Name, option.Value, UDim2.new(0, 10, 0, option.Y), option.Callback)
    end
    
    return section
end

function Settings:CreateConfigSection(parent, position)
    local section = Utilities.Create("Frame", {
        Name = "ConfigSection",
        Size = UDim2.new(1, -40, 0, 150),
        Position = position,
        BackgroundColor3 = self.Parent.CurrentTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    Utilities.RoundCorners(section, 8)
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "Configuration",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    -- Config name input
    local configNameLabel = Utilities.Create("TextLabel", {
        Name = "ConfigNameLabel",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = "Configuration Name:",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section
    })
    
    local configNameInput = Utilities.Create("TextBox", {
        Name = "ConfigNameInput",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 75),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Enter configuration name...",
        Text = "",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        ClearTextOnFocus = false,
        Parent = section
    })
    
    Utilities.RoundCorners(configNameInput, 6)
    
    -- Save and load buttons
    local saveButton = self.Parent.UI:CreateButton(section, "Save Config", UDim2.new(0, 120, 0, 36), UDim2.new(0, 10, 0, 115))
    local loadButton = self.Parent.UI:CreateButton(section, "Load Config", UDim2.new(0, 120, 0, 36), UDim2.new(0, 140, 0, 115))
    
    -- Button events
    saveButton.MouseButton1Click:Connect(function()
        local configName = configNameInput.Text
        if configName and configName ~= "" then
            self:SaveConfig(configName)
        end
    end)
    
    loadButton.MouseButton1Click:Connect(function()
        local configName = configNameInput.Text
        if configName and self.SavedConfigs[configName] then
            self:LoadConfig(configName)
        end
    end)
    
    return section
end

function Settings:CreateColorPicker(parent, name, defaultColor, position)
    local container = Utilities.Create("Frame", {
        Name = name .. "Color",
        Size = UDim2.new(1, -20, 0, 30),
        Position = position,
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Utilities.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name .. ":",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local colorDisplay = Utilities.Create("Frame", {
        Name = "ColorDisplay",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utilities.RoundCorners(colorDisplay, 6)
    
    local r = Utilities.Create("TextBox", {
        Name = "R",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 150, 0, 0),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = tostring(math.floor(defaultColor.R * 255)),
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        Parent = container
    })
    
    Utilities.RoundCorners(r, 6)
    
    local g = Utilities.Create("TextBox", {
        Name = "G",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 195, 0, 0),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = tostring(math.floor(defaultColor.G * 255)),
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        Parent = container
    })
    
    Utilities.RoundCorners(g, 6)
    
    local b = Utilities.Create("TextBox", {
        Name = "B",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 240, 0, 0),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = tostring(math.floor(defaultColor.B * 255)),
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        Parent = container
    })
    
    Utilities.RoundCorners(b, 6)
    
    -- Function to update color from RGB inputs
    local function updateColor()
        local rVal = tonumber(r.Text) or 0
        local gVal = tonumber(g.Text) or 0
        local bVal = tonumber(b.Text) or 0
        
        rVal = math.clamp(rVal, 0, 255)
        gVal = math.clamp(gVal, 0, 255)
        bVal = math.clamp(bVal, 0, 255)
        
        local newColor = Color3.fromRGB(rVal, gVal, bVal)
        colorDisplay.BackgroundColor3 = newColor
        
        -- Update theme color
        if self.Parent.CurrentTheme[name] then
            self.Parent.CurrentTheme[name] = newColor
            self.Parent:ApplyTheme(self.Parent.CurrentTheme)
        end
    end
    
    -- Connect text box events
    for _, textBox in pairs({r, g, b}) do
        textBox.FocusLost:Connect(function()
            updateColor()
        end)
    end
    
    return container
end

function Settings:CreateSlider(parent, name, defaultValue, min, max, step, position, callback)
    local container = Utilities.Create("Frame", {
        Name = name .. "Slider",
        Size = UDim2.new(1, -20, 0, 30),
        Position = position,
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Utilities.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name .. ":",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local sliderBg = Utilities.Create("Frame", {
        Name = "SliderBg",
        Size = UDim2.new(0, 200, 0, 10),
        Position = UDim2.new(0, 110, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utilities.RoundCorners(sliderBg, 5)
    
    local sliderFill = Utilities.Create("Frame", {
        Name = "SliderFill",
        Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Parent.CurrentTheme.Accent,
        BorderSizePixel = 0,
        Parent = sliderBg
    })
    
    Utilities.RoundCorners(sliderFill, 5)
    
    local sliderThumb = Utilities.Create("Frame", {
        Name = "SliderThumb",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((defaultValue - min) / (max - min), 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Parent.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = sliderBg
    })
    
    Utilities.RoundCorners(sliderThumb, 8)
    
    local valueLabel = Utilities.Create("TextLabel", {
        Name = "ValueLabel",
        Size = UDim2.new(0, 40, 1, 0),
        Position = UDim2.new(0, 320, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = tostring(defaultValue),
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        Parent = container
    })
    
    -- Slider functionality
    local dragging = false
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
            local value = min + (relativeX / sliderBg.AbsoluteSize.X) * (max - min)
            value = math.floor(value / step + 0.5) * step
            value = math.clamp(value, min, max)
            
            sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            sliderThumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            valueLabel.Text = tostring(value)
            
            if callback then callback(value) end
        end
    end)
    
    sliderBg.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local relativeX = math.clamp(input.Position.X - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
            local value = min + (relativeX / sliderBg.AbsoluteSize.X) * (max - min)
            value = math.floor(value / step + 0.5) * step
            value = math.clamp(value, min, max)
            
            sliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            sliderThumb.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            valueLabel.Text = tostring(value)
            
            if callback then callback(value) end
        end
    end)
    
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return container
end

function Settings:CreateToggle(parent, name, defaultValue, position, callback)
    local container = Utilities.Create("Frame", {
        Name = name .. "Toggle",
        Size = UDim2.new(1, -20, 0, 30),
        Position = position,
        BackgroundTransparency = 1,
        Parent = parent
    })
    
    local label = Utilities.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name .. ":",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container
    })
    
    local toggleBg = Utilities.Create("Frame", {
        Name = "ToggleBg",
        Size = UDim2.new(0, 50, 0, 24),
        Position = UDim2.new(0, 210, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = defaultValue and self.Parent.CurrentTheme.Accent or self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = container
    })
    
    Utilities.RoundCorners(toggleBg, 12)
    
    local toggleThumb = Utilities.Create("Frame", {
        Name = "ToggleThumb",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(defaultValue and 1 or 0, defaultValue and -22 or 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = self.Parent.CurrentTheme.Text,
        BorderSizePixel = 0,
        Parent = toggleBg
    })
    
    Utilities.RoundCorners(toggleThumb, 10)
    
    -- Toggle functionality
    local value = defaultValue
    
    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            value = not value
            
            Utilities.Tween(toggleBg, Utilities.TweenInfo.Fast, {
                BackgroundColor3 = value and self.Parent.CurrentTheme.Accent or self.Parent.CurrentTheme.Background
            })
            
            Utilities.Tween(toggleThumb, Utilities.TweenInfo.Fast, {
                Position = UDim2.new(value and 1 or 0, value and -22 or 2, 0.5, 0)
            })
            
            if callback then callback(value) end
        end
    end)
    
    return container
end

function Settings:CloseSettings()
    if self.Panel then
        self.Panel.Visible = false
    end
end

function Settings:OpenSettings()
    if self.Panel then
        self.Panel.Visible = true
    end
end

function Settings:SaveConfig(configName)
    self.SavedConfigs[configName] = Utilities.DeepCopy(self.Parent.CurrentTheme)
    return true
end

function Settings:LoadConfig(configName)
    if self.SavedConfigs[configName] then
        local theme = Utilities.DeepCopy(self.SavedConfigs[configName])
        self.Parent:ApplyTheme(theme)
        return true
    end
    return false
end

function Settings:LoadSavedConfigs()
    -- In a real implementation, you would load configs from a file or database
    -- For now, we'll just use the default config
    return self:LoadConfig("Default")
end

function Settings:ConnectEvents()
    -- Connect settings-related events
end

return Settings 