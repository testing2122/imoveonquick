--[[
    LunaIDE - Code Editor Module
    Integrates with the original IDE module to provide code editing capabilities
]]

local CodeEditor = {}
CodeEditor.__index = CodeEditor

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Import utilities when this module is loaded
local Utilities
local OriginalIDE

function CodeEditor.new(parent)
    local self = setmetatable({}, CodeEditor)
    self.Parent = parent
    Utilities = parent.Utilities
    
    -- Try to load the original IDE module that contains the code editing capabilities
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/biggaboy212/In-Game-IDE/main/update8/IDEModule.lua"))()
    end)
    
    if success then
        OriginalIDE = result
    else
        warn("Failed to load original IDE module:", result)
    end
    
    self.CurrentFile = nil
    self.History = {}
    self.HistoryIndex = 0
    self.UnsavedChanges = false
    
    return self
end

function CodeEditor:SetupEditor(frame)
    self.Frame = frame
    
    -- Create top toolbar
    local toolbar = Utilities.Create("Frame", {
        Name = "Toolbar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Parent.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    -- Create run button
    local runButton = self:CreateToolbarButton(toolbar, "Run", "rbxassetid://11585779232", UDim2.new(0, 10, 0, 5))
    
    -- Create save button
    local saveButton = self:CreateToolbarButton(toolbar, "Save", "rbxassetid://11585776082", UDim2.new(0, 60, 0, 5))
    
    -- Create undo button
    local undoButton = self:CreateToolbarButton(toolbar, "Undo", "rbxassetid://11585776385", UDim2.new(0, 110, 0, 5))
    
    -- Create redo button
    local redoButton = self:CreateToolbarButton(toolbar, "Redo", "rbxassetid://11585775961", UDim2.new(0, 160, 0, 5))
    
    -- Button events
    runButton.MouseButton1Click:Connect(function()
        self:RunCode()
    end)
    
    saveButton.MouseButton1Click:Connect(function()
        self:SaveFile()
    end)
    
    undoButton.MouseButton1Click:Connect(function()
        self:Undo()
    end)
    
    redoButton.MouseButton1Click:Connect(function()
        self:Redo()
    end)
    
    -- Create tab bar
    local tabBar = Utilities.Create("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = self.Parent.CurrentTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    local tabContainer = Utilities.Create("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -40, 1, 0),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0,
        Parent = tabBar
    })
    
    local tabButtonsLayout = Utilities.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = tabContainer
    })
    
    -- Create editor container
    local editorContainer = Utilities.Create("Frame", {
        Name = "EditorContainer",
        Size = UDim2.new(1, 0, 1, -70),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = self.Parent.CurrentTheme.Syntax.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = frame
    })
    
    -- Initialize the code editor using the original IDE module
    if OriginalIDE then
        self.Editor = OriginalIDE.CodeFrame.new()
        self.Editor.Frame.Size = UDim2.new(1, 0, 1, 0)
        self.Editor.Frame.Position = UDim2.new(0, 0, 0, 0)
        self.Editor.Frame.Parent = editorContainer
        
        -- Apply our custom theme
        self:ApplyTheme(self.Parent.CurrentTheme.Syntax)
    else
        -- Fallback if original IDE module failed to load
        local fallbackText = Utilities.Create("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 0,
            BackgroundColor3 = self.Parent.CurrentTheme.Syntax.Background,
            Text = "Failed to load code editor component.\nPlease check console for errors.",
            TextColor3 = self.Parent.CurrentTheme.Syntax.Text,
            Font = Enum.Font.Code,
            TextSize = 16,
            Parent = editorContainer
        })
    end
    
    -- Store references
    self.Toolbar = toolbar
    self.TabBar = tabBar
    self.TabContainer = tabContainer
    self.EditorContainer = editorContainer
    
    -- Create a default tab
    self:CreateTab("Untitled.lua", true)
end

function CodeEditor:CreateToolbarButton(parent, name, icon, position)
    local button = Utilities.Create("ImageButton", {
        Name = name .. "Button",
        Size = UDim2.new(0, 30, 0, 30),
        Position = position,
        BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Image = icon,
        ImageColor3 = self.Parent.CurrentTheme.Text,
        Parent = parent
    })
    
    Utilities.RoundCorners(button, 6)
    
    -- Add tooltip
    local tooltip = Utilities.Create("TextLabel", {
        Name = "Tooltip",
        Text = name,
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(0.5, 0, 1, 5),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
        TextColor3 = self.Parent.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Visible = false,
        ZIndex = 10,
        Parent = button
    })
    
    Utilities.RoundCorners(tooltip, 4)
    
    -- Button hover and click effects
    button.MouseEnter:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.CurrentTheme.Accent,
            ImageColor3 = Color3.fromRGB(255, 255, 255)
        })
        tooltip.Visible = true
    end)
    
    button.MouseLeave:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
            ImageColor3 = self.Parent.CurrentTheme.Text
        })
        tooltip.Visible = false
    end)
    
    button.MouseButton1Down:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.CurrentTheme.Primary,
            Size = UDim2.new(0, 28, 0, 28),
            Position = UDim2.new(position.X.Scale, position.X.Offset + 1, position.Y.Scale, position.Y.Offset + 1)
        })
    end)
    
    button.MouseButton1Up:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.CurrentTheme.Accent,
            Size = UDim2.new(0, 30, 0, 30),
            Position = position
        })
    end)
    
    return button
end

function CodeEditor:CreateTab(fileName, select)
    local tabButton = Utilities.Create("TextButton", {
        Name = fileName .. "Tab",
        Size = UDim2.new(0, 120, 1, 0),
        BackgroundColor3 = select and self.Parent.CurrentTheme.Primary or self.Parent.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        Text = " " .. fileName,
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TabContainer
    })
    
    local closeButton = Utilities.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -25, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = self.Parent.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = tabButton
    })
    
    -- Round just the top corners
    local corner = Utilities.Create("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = tabButton
    })
    
    -- Update canvas size for tab container
    local totalWidth = 0
    for _, child in pairs(self.TabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            totalWidth = totalWidth + child.Size.X.Offset + 2
        end
    end
    self.TabContainer.CanvasSize = UDim2.new(0, totalWidth, 0, 0)
    
    -- Tab button events
    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(fileName)
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        self:CloseTab(fileName)
    end)
    
    -- Add tab to collection
    self.TabContainer[fileName] = {
        Button = tabButton,
        Content = self.Editor and self.Editor:GetText() or ""
    }
    
    -- Select the tab if requested
    if select then
        self:SelectTab(fileName)
    end
    
    return tabButton
end

function CodeEditor:SelectTab(fileName)
    -- Update tab visuals
    for _, child in pairs(self.TabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == fileName .. "Tab" then
                Utilities.Tween(child, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.CurrentTheme.Primary})
            else
                Utilities.Tween(child, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.CurrentTheme.Secondary})
            end
        end
    end
    
    -- Save current content if there's a current file
    if self.CurrentFile and self.Editor then
        self.TabContainer[self.CurrentFile].Content = self.Editor:GetText()
    end
    
    -- Set the current file and update editor content
    self.CurrentFile = fileName
    
    if self.Editor and self.TabContainer[fileName] then
        self.Editor:SetText(self.TabContainer[fileName].Content or "")
        
        -- Clear history for new tab
        self.History = {}
        self.HistoryIndex = 0
        
        -- Add initial state to history
        self:AddToHistory(self.Editor:GetText())
    end
end

function CodeEditor:CloseTab(fileName)
    local tab = self.TabContainer[fileName .. "Tab"]
    if tab then
        tab:Destroy()
        self.TabContainer[fileName] = nil
        
        -- Select another tab if available, or create a new one if this was the last
        local anyTabSelected = false
        for name, _ in pairs(self.TabContainer) do
            if name:match("Tab$") then
                self:SelectTab(name:sub(1, -4))
                anyTabSelected = true
                break
            end
        end
        
        if not anyTabSelected then
            self:CreateTab("Untitled.lua", true)
        end
    end
end

function CodeEditor:SaveFile()
    if not self.CurrentFile then return end
    
    -- Get the current text
    local text = self.Editor and self.Editor:GetText() or ""
    
    -- If the file is "Untitled.lua", prompt for a name
    if self.CurrentFile == "Untitled.lua" then
        -- In a real implementation, show a dialog to get a file name
        -- For now, we'll just save it with a timestamp
        local newName = "Script_" .. os.time() .. ".lua"
        self.CurrentFile = newName
        
        -- Update tab
        local oldTab = self.TabContainer["Untitled.luaTab"]
        if oldTab then
            oldTab.Name = newName .. "Tab"
            oldTab.Text = " " .. newName
        end
    end
    
    -- Save the file using the filesystem module
    if self.Parent.FileSystem then
        self.Parent.FileSystem:SaveFile(self.CurrentFile, text)
        self.UnsavedChanges = false
    else
        warn("FileSystem module not available, cannot save file")
    end
end

function CodeEditor:LoadFile(fileName, content)
    -- Check if the file is already open in a tab
    for name, _ in pairs(self.TabContainer) do
        if name:match("Tab$") and name:sub(1, -4) == fileName then
            self:SelectTab(fileName)
            return
        end
    end
    
    -- Create a new tab for the file
    self:CreateTab(fileName, true)
    
    -- Set the content
    if content and self.Editor then
        self.Editor:SetText(content)
        
        -- Clear history and add initial state
        self.History = {}
        self.HistoryIndex = 0
        self:AddToHistory(content)
    end
end

function CodeEditor:RunCode()
    if not self.Editor then return end
    
    local code = self.Editor:GetText()
    
    -- Save before running if there are unsaved changes
    if self.UnsavedChanges then
        self:SaveFile()
    end
    
    -- Execute the code in a protected call
    local success, result = pcall(function()
        return loadstring(code)()
    end)
    
    if not success then
        warn("Error running code:", result)
        -- In a full implementation, display the error in the UI
    end
end

function CodeEditor:AddToHistory(text)
    -- Truncate history if we're not at the latest point
    if self.HistoryIndex < #self.History then
        for i = #self.History, self.HistoryIndex + 1, -1 do
            table.remove(self.History, i)
        end
    end
    
    -- Add new state to history
    table.insert(self.History, text)
    self.HistoryIndex = #self.History
    
    -- Limit history size
    if #self.History > 100 then
        table.remove(self.History, 1)
        self.HistoryIndex = #self.History
    end
    
    -- Mark as having unsaved changes
    self.UnsavedChanges = true
end

function CodeEditor:Undo()
    if not self.Editor then return end
    
    if self.HistoryIndex > 1 then
        self.HistoryIndex = self.HistoryIndex - 1
        local text = self.History[self.HistoryIndex]
        self.Editor:SetText(text)
    end
end

function CodeEditor:Redo()
    if not self.Editor then return end
    
    if self.HistoryIndex < #self.History then
        self.HistoryIndex = self.HistoryIndex + 1
        local text = self.History[self.HistoryIndex]
        self.Editor:SetText(text)
    end
end

function CodeEditor:ApplyTheme(syntaxTheme)
    if not self.Editor then return end
    
    -- Apply syntax highlighting theme
    self.Editor:ApplyTheme()
    
    -- Apply UI theme
    if self.EditorContainer then
        self.EditorContainer.BackgroundColor3 = syntaxTheme.Background
    end
    
    -- Apply toolbar theme
    if self.Toolbar then
        self.Toolbar.BackgroundColor3 = self.Parent.CurrentTheme.Primary
    end
    
    -- Apply tab bar theme
    if self.TabBar then
        self.TabBar.BackgroundColor3 = self.Parent.CurrentTheme.SecondaryBackground
    end
    
    -- Apply theme to tabs
    for _, child in pairs(self.TabContainer:GetChildren()) do
        if child:IsA("TextButton") then
            if child.Name == (self.CurrentFile and self.CurrentFile .. "Tab" or "") then
                child.BackgroundColor3 = self.Parent.CurrentTheme.Primary
            else
                child.BackgroundColor3 = self.Parent.CurrentTheme.Secondary
            end
            child.TextColor3 = self.Parent.CurrentTheme.Text
        end
    end
end

function CodeEditor:ConnectEvents()
    if not self.Editor then return end
    
    -- Detect text changes to update history
    self.Editor.TextChanged = self.Editor.TextChanged or Signal.new()
    self.Editor.TextChanged:Connect(function()
        self:AddToHistory(self.Editor:GetText())
    end)
    
    -- Connect keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.S and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:SaveFile()
        elseif input.KeyCode == Enum.KeyCode.Z and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:Undo()
        elseif input.KeyCode == Enum.KeyCode.Y and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            self:Redo()
        end
    end)
end

return CodeEditor 