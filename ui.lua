--[[
    LunaIDE - UI Module
    Handles the creation and management of the main interface
]]

local UI = {}
UI.__index = UI

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local ANIMATION_TIME = 0.3
local EASING_STYLE = Enum.EasingStyle.Quint
local EASING_DIR = Enum.EasingDirection.Out

-- Import utilities when this module is loaded
local Utilities

function UI.new(parent)
    local self = setmetatable({}, UI)
    self.Parent = parent
    Utilities = parent.Utilities or loadstring(game:HttpGet("https://raw.githubusercontent.com/testing2122/imoveonquick/main/utilities.lua"))()
    self.Connections = {}
    self.Dragging = false
    self.DragStart = nil
    self.StartPos = nil
    
    return self
end

function UI:CreateMainInterface()
    -- Create the main frame for the IDE
    local mainFrame = Utilities.Create("Frame", {
        Name = "LunaIDE",
        Size = UDim2.new(0, 1000, 0, 600),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Parent.DefaultTheme.Background,
        BorderSizePixel = 0,
        Parent = game.CoreGui
    })
    
    -- Round the corners
    Utilities.RoundCorners(mainFrame, 8)
    
    -- Add shadow
    Utilities.AddShadow(mainFrame, 30, 0.5)
    
    -- Create title bar
    local titleBar = self:CreateTitleBar(mainFrame)
    
    -- Create main content container
    local contentFrame = Utilities.Create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, 0, 1, -40), -- Subtract title bar height
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = mainFrame
    })
    
    -- Create left panel for file explorer
    local leftPanel = Utilities.Create("Frame", {
        Name = "LeftPanel",
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = self.Parent.DefaultTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = contentFrame
    })
    
    -- Create right panel for AI chat
    local rightPanel = Utilities.Create("Frame", {
        Name = "RightPanel",
        Size = UDim2.new(0, 250, 1, 0),
        Position = UDim2.new(1, -250, 0, 0),
        BackgroundColor3 = self.Parent.DefaultTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = contentFrame
    })
    
    -- Create center panel for code editor
    local centerPanel = Utilities.Create("Frame", {
        Name = "CenterPanel",
        Size = UDim2.new(1, -450, 1, 0), -- Full width minus left and right panels
        Position = UDim2.new(0, 200, 0, 0), -- Position after left panel
        BackgroundColor3 = self.Parent.DefaultTheme.Background,
        BorderSizePixel = 0,
        Parent = contentFrame
    })
    
    -- Create panel dividers
    self:CreateDivider(contentFrame, leftPanel, "right")
    self:CreateDivider(contentFrame, rightPanel, "left")
    
    -- Store references
    self.MainFrame = mainFrame
    self.ContentFrame = contentFrame
    self.LeftPanel = leftPanel
    self.CenterPanel = centerPanel
    self.RightPanel = rightPanel
    
    -- Make draggable
    self:MakeDraggable(titleBar, mainFrame)
    
    return {
        MainFrame = mainFrame,
        LeftPanel = leftPanel,
        CenterPanel = centerPanel,
        RightPanel = rightPanel,
        TitleBar = titleBar
    }
end

function UI:CreateTitleBar(parent)
    local titleBar = Utilities.Create("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Parent.DefaultTheme.Primary,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    -- Round top corners only
    local corner = Utilities.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = titleBar
    })
    
    -- Add bottom edge to make it look like only top corners are rounded
    local bottomEdge = Utilities.Create("Frame", {
        Name = "BottomEdge",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = self.Parent.DefaultTheme.Primary,
        BorderSizePixel = 0,
        Parent = titleBar
    })
    
    -- Logo/Title
    local logo = Utilities.Create("ImageLabel", {
        Name = "Logo",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11570895459", -- Moon icon
        Parent = titleBar
    })
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 44, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "LunaIDE",
        TextColor3 = self.Parent.DefaultTheme.Text,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Window controls
    local controlsFrame = Utilities.Create("Frame", {
        Name = "Controls",
        Size = UDim2.new(0, 90, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Parent = titleBar
    })
    
    -- Minimize button
    local minimizeBtn = self:CreateTitleButton(controlsFrame, "Minimize", "rbxassetid://11585775821", UDim2.new(0, 0, 0, 0))
    
    -- Maximize button
    local maximizeBtn = self:CreateTitleButton(controlsFrame, "Maximize", "rbxassetid://11585775653", UDim2.new(0, 30, 0, 0))
    
    -- Close button
    local closeBtn = self:CreateTitleButton(controlsFrame, "Close", "rbxassetid://11585775498", UDim2.new(0, 60, 0, 0))
    closeBtn.ImageColor3 = Color3.fromRGB(255, 100, 100)
    
    -- Button events
    minimizeBtn.MouseButton1Click:Connect(function()
        self:MinimizeWindow()
    end)
    
    maximizeBtn.MouseButton1Click:Connect(function()
        self:MaximizeWindow()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        self:CloseWindow()
    end)
    
    return titleBar
end

function UI:CreateTitleButton(parent, name, imageId, position)
    local button = Utilities.Create("ImageButton", {
        Name = name,
        Size = UDim2.new(0, 30, 0, 30),
        Position = position,
        BackgroundTransparency = 1,
        Image = imageId,
        ImageColor3 = self.Parent.DefaultTheme.Text,
        Parent = parent
    })
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {ImageColor3 = self.Parent.DefaultTheme.Accent})
    end)
    
    button.MouseLeave:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            ImageColor3 = name == "Close" and Color3.fromRGB(255, 100, 100) or self.Parent.DefaultTheme.Text
        })
    end)
    
    return button
end

function UI:CreateDivider(parent, panel, direction)
    local divider = Utilities.Create("Frame", {
        Name = direction .. "Divider",
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = self.Parent.DefaultTheme.Primary,
        BorderSizePixel = 0,
        Parent = parent
    })
    
    if direction == "right" then
        divider.Position = UDim2.new(0, panel.Size.X.Offset, 0, 0)
    else
        divider.Position = UDim2.new(0, panel.Position.X.Offset - 4, 0, 0)
    end
    
    -- Make divider draggable to resize panels
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        if direction == "right" then
            local newWidth = startPos + delta.X
            newWidth = math.clamp(newWidth, 150, 300) -- Minimum and maximum widths
            
            panel.Size = UDim2.new(0, newWidth, 1, 0)
            divider.Position = UDim2.new(0, newWidth, 0, 0)
            
            -- Update center panel
            self.CenterPanel.Position = UDim2.new(0, newWidth + 4, 0, 0)
            self.CenterPanel.Size = UDim2.new(1, -(newWidth + 4 + self.RightPanel.Size.X.Offset), 1, 0)
        else
            local newPos = startPos + delta.X
            local rightEdge = parent.AbsoluteSize.X
            local newWidth = rightEdge - newPos
            
            newWidth = math.clamp(newWidth, 200, 350) -- Minimum and maximum widths
            newPos = rightEdge - newWidth
            
            panel.Position = UDim2.new(0, newPos, 0, 0)
            panel.Size = UDim2.new(0, newWidth, 1, 0)
            divider.Position = UDim2.new(0, newPos - 4, 0, 0)
            
            -- Update center panel
            self.CenterPanel.Size = UDim2.new(1, -(self.LeftPanel.Size.X.Offset + 4 + newWidth), 1, 0)
        end
    end
    
    divider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = direction == "right" and panel.Size.X.Offset or panel.Position.X.Offset
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    divider.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            dragInput = input
            update(input)
        end
    end)
    
    return divider
end

function UI:MakeDraggable(dragObject, dragTarget)
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    
    local function update(input)
        local delta = input.Position - dragStart
        dragTarget.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X, 
            startPos.Y.Scale, 
            startPos.Y.Offset + delta.Y
        )
    end
    
    dragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = dragTarget.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            dragInput = input
            update(input)
        end
    end)
end

function UI:MinimizeWindow()
    local mainFrame = self.MainFrame
    local originalSize = mainFrame.Size
    local originalPosition = mainFrame.Position
    
    self.originalSize = originalSize
    self.originalPosition = originalPosition
    
    Utilities.Tween(mainFrame, Utilities.TweenInfo.Medium, {
        Size = UDim2.new(0, originalSize.X.Offset, 0, 40),
        Position = UDim2.new(0, originalPosition.X.Offset, 0, 40)
    })
    
    self.Minimized = true
end

function UI:MaximizeWindow()
    if self.Minimized then
        Utilities.Tween(self.MainFrame, Utilities.TweenInfo.Medium, {
            Size = self.originalSize,
            Position = self.originalPosition
        })
        
        self.Minimized = false
    else
        -- Toggle between normal and maximized
        if not self.Maximized then
            self.lastSize = self.MainFrame.Size
            self.lastPosition = self.MainFrame.Position
            
            Utilities.Tween(self.MainFrame, Utilities.TweenInfo.Medium, {
                Size = UDim2.new(1, -40, 1, -40),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            })
            
            self.Maximized = true
        else
            Utilities.Tween(self.MainFrame, Utilities.TweenInfo.Medium, {
                Size = self.lastSize,
                Position = self.lastPosition
            })
            
            self.Maximized = false
        end
    end
end

function UI:CloseWindow()
    -- Tween the window out
    Utilities.Tween(self.MainFrame, Utilities.TweenInfo.Medium, {
        Size = UDim2.new(0, self.MainFrame.Size.X.Offset, 0, 0),
        Position = UDim2.new(0.5, 0, 0, self.MainFrame.Position.Y.Offset + self.MainFrame.Size.Y.Offset/2),
        BackgroundTransparency = 1
    })
    
    -- Clean up all connections
    for _, connection in pairs(self.Connections) do
        if connection then connection:Disconnect() end
    end
    
    -- Wait for animation to complete before destroying
    task.delay(ANIMATION_TIME + 0.1, function()
        self.MainFrame:Destroy()
    end)
end

function UI:CreateButton(parent, text, size, position)
    local button = Utilities.Create("TextButton", {
        Name = text .. "Button",
        Size = size or UDim2.new(0, 120, 0, 36),
        Position = position or UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Parent.DefaultTheme.Secondary,
        Font = Enum.Font.GothamSemibold,
        Text = text,
        TextColor3 = self.Parent.DefaultTheme.Text,
        TextSize = 14,
        Parent = parent
    })
    
    -- Round corners
    Utilities.RoundCorners(button, 6)
    
    -- Add shine effect container
    local shineEffect = Utilities.CreateShineEffect(button)
    
    -- Hover and click effects
    button.MouseEnter:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.DefaultTheme.Accent,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4),
            Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset - 2, button.Position.Y.Scale, button.Position.Y.Offset - 2)
        })
        Utilities.AnimateShine(shineEffect)
    end)
    
    button.MouseLeave:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.DefaultTheme.Secondary,
            Size = size or UDim2.new(0, 120, 0, 36),
            Position = position or UDim2.new(0, 0, 0, 0)
        })
    end)
    
    button.MouseButton1Down:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.DefaultTheme.Primary,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 2),
            Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset + 1, button.Position.Y.Scale, button.Position.Y.Offset + 1)
        })
    end)
    
    button.MouseButton1Up:Connect(function()
        Utilities.Tween(button, Utilities.TweenInfo.Fast, {
            BackgroundColor3 = self.Parent.DefaultTheme.Accent,
            Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 4, button.Size.Y.Scale, button.Size.Y.Offset + 4),
            Position = UDim2.new(button.Position.X.Scale, button.Position.X.Offset - 2, button.Position.Y.Scale, button.Position.Y.Offset - 2)
        })
    end)
    
    return button
end

-- UI component creation methods will be implemented in separate files and imported
function UI:CreateEditorFrame(ui)
    -- This will be a basic frame that the editor component will populate
    local editorFrame = Utilities.Create("Frame", {
        Name = "EditorFrame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = ui.CenterPanel
    })
    
    return editorFrame
end

function UI:CreateFileExplorer(ui)
    -- This will be implemented in the FileSystem module
    local fileExplorer = Utilities.Create("Frame", {
        Name = "FileExplorer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = ui.LeftPanel
    })
    
    return fileExplorer
end

function UI:CreateSettingsPanel(ui)
    -- This will be implemented in the Settings module
    local settingsPanel = Utilities.Create("Frame", {
        Name = "SettingsPanel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = ui.MainFrame
    })
    
    return settingsPanel
end

function UI:CreateChatPanel(ui)
    -- Create a basic chat panel for AI assistance
    local chatPanel = Utilities.Create("Frame", {
        Name = "ChatPanel",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = ui.RightPanel
    })
    
    -- Chat header
    local chatHeader = Utilities.Create("Frame", {
        Name = "ChatHeader",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Parent.DefaultTheme.Primary,
        BorderSizePixel = 0,
        Parent = chatPanel
    })
    
    local chatTitle = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "AI Assistant",
        TextColor3 = self.Parent.DefaultTheme.Text,
        TextSize = 16,
        Parent = chatHeader
    })
    
    -- Chat messages container
    local messagesFrame = Utilities.Create("ScrollingFrame", {
        Name = "Messages",
        Size = UDim2.new(1, 0, 1, -90),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 6,
        ScrollBarImageColor3 = self.Parent.DefaultTheme.Secondary,
        Parent = chatPanel
    })
    
    -- Message input
    local inputContainer = Utilities.Create("Frame", {
        Name = "InputContainer",
        Size = UDim2.new(1, 0, 0, 50),
        Position = UDim2.new(0, 0, 1, -50),
        BackgroundColor3 = self.Parent.DefaultTheme.SecondaryBackground,
        BorderSizePixel = 0,
        Parent = chatPanel
    })
    
    local inputBox = Utilities.Create("TextBox", {
        Name = "InputBox",
        Size = UDim2.new(1, -70, 1, -16),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundColor3 = self.Parent.DefaultTheme.Background,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Ask the AI for help...",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 130),
        Text = "",
        TextColor3 = self.Parent.DefaultTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        ClearTextOnFocus = false,
        Parent = inputContainer
    })
    
    Utilities.RoundCorners(inputBox, 6)
    
    local sendButton = Utilities.Create("ImageButton", {
        Name = "SendButton",
        Size = UDim2.new(0, 36, 0, 36),
        Position = UDim2.new(1, -46, 0, 7),
        BackgroundColor3 = self.Parent.DefaultTheme.Primary,
        Image = "rbxassetid://11585779403", -- Send icon
        Parent = inputContainer
    })
    
    Utilities.RoundCorners(sendButton, 6)
    
    -- Button hover effect
    sendButton.MouseEnter:Connect(function()
        Utilities.Tween(sendButton, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.DefaultTheme.Accent})
    end)
    
    sendButton.MouseLeave:Connect(function()
        Utilities.Tween(sendButton, Utilities.TweenInfo.Fast, {BackgroundColor3 = self.Parent.DefaultTheme.Primary})
    end)
    
    return chatPanel
end

function UI:ConnectUIEvents()
    -- This will be implemented to connect UI interaction events
    -- For now, we'll leave this as a placeholder
end

function UI:ApplyTheme(theme)
    -- Apply theme colors to UI elements
    if not self.MainFrame then return end
    
    -- Main frame
    self.MainFrame.BackgroundColor3 = theme.Background
    
    -- Title bar
    local titleBar = self.MainFrame.TitleBar
    titleBar.BackgroundColor3 = theme.Primary
    titleBar.BottomEdge.BackgroundColor3 = theme.Primary
    titleBar.Title.TextColor3 = theme.Text
    
    -- Panels
    self.LeftPanel.BackgroundColor3 = theme.SecondaryBackground
    self.CenterPanel.BackgroundColor3 = theme.Background
    self.RightPanel.BackgroundColor3 = theme.SecondaryBackground
    
    -- More theme applications will be implemented
end

return UI 