--[[
    LunaIDE - FileSystem Module
    Handles file operations and file explorer
]]

local FileSystem = {}
FileSystem.__index = FileSystem

-- Services
local HttpService = game:GetService("HttpService")

-- Import utilities when this module is loaded
local Utilities

function FileSystem.new(parent)
    local self = setmetatable({}, FileSystem)
    self.Parent = parent
    Utilities = parent.Utilities
    
    -- Initialize file system storage
    self.Files = {}
    self.Folders = {}
    self.RootFolder = "workspace"
    self.CurrentPath = self.RootFolder
    
    -- Create some default folders
    self:CreateFolder("workspace/scripts")
    self:CreateFolder("workspace/modules")
    self:CreateFolder("workspace/config")
    
    -- Create a readme file
    self:SaveFile("workspace/README.lua", [[
--[[
    Welcome to LunaIDE
    
    This is a modern code editor for Roblox with features like:
    - Syntax highlighting
    - File explorer
    - Tabbed editing
    - Code execution
    - Beautiful purple theme
    
    Get started by creating a new file or exploring the file system.
]]
    ]])
    
    return self
end

function FileSystem:SetupFileExplorer(frame)
    self.Frame = frame
    
    -- Create file explorer header
    local header = Utilities.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Parent.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    local title = Utilities.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        Text = "File Explorer",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })
    
    -- Create new file button
    local newFileBtn = Utilities.Create("ImageButton", {
        Name = "NewFileButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 5),
        BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Image = "rbxassetid://11585775733", -- Document icon
        ImageColor3 = self.Parent.CurrentTheme.Text,
        Parent = header
    })
    
    Utilities.RoundCorners(newFileBtn, 6)
    
    -- Create new folder button
    local newFolderBtn = Utilities.Create("ImageButton", {
        Name = "NewFolderButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5),
        BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Image = "rbxassetid://11585775575", -- Folder icon
        ImageColor3 = self.Parent.CurrentTheme.Text,
        Parent = header
    })
    
    Utilities.RoundCorners(newFolderBtn, 6)
    
    -- Create search bar
    local searchBar = Utilities.Create("Frame", {
        Name = "SearchBar",
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 50),
        BackgroundColor3 = self.Parent.CurrentTheme.Background,
        BorderSizePixel = 0,
        Parent = frame
    })
    
    Utilities.RoundCorners(searchBar, 6)
    
    local searchIcon = Utilities.Create("ImageLabel", {
        Name = "SearchIcon",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11585776074", -- Search icon
        ImageColor3 = self.Parent.CurrentTheme.Text,
        Parent = searchBar
    })
    
    local searchInput = Utilities.Create("TextBox", {
        Name = "SearchInput",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 36, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search files...",
        PlaceholderColor3 = Color3.fromRGB(120, 120, 130),
        Text = "",
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchBar
    })
    
    -- Create file tree container
    local treeContainer = Utilities.Create("ScrollingFrame", {
        Name = "TreeContainer",
        Size = UDim2.new(1, 0, 1, -90),
        Position = UDim2.new(0, 0, 0, 90),
        BackgroundTransparency = 1,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Parent.CurrentTheme.Secondary,
        Parent = frame
    })
    
    local treeLayout = Utilities.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.Name,
        Padding = UDim.new(0, 2),
        Parent = treeContainer
    })
    
    -- Button events
    newFileBtn.MouseButton1Click:Connect(function()
        self:ShowNewFileDialog()
    end)
    
    newFolderBtn.MouseButton1Click:Connect(function()
        self:ShowNewFolderDialog()
    end)
    
    searchInput:GetPropertyChangedSignal("Text"):Connect(function()
        self:SearchFiles(searchInput.Text)
    end)
    
    -- Apply button hover effects
    for _, button in pairs({newFileBtn, newFolderBtn}) do
        button.MouseEnter:Connect(function()
            Utilities.Tween(button, Utilities.TweenInfo.Fast, {
                BackgroundColor3 = self.Parent.CurrentTheme.Accent,
                ImageColor3 = Color3.fromRGB(255, 255, 255)
            })
        end)
        
        button.MouseLeave:Connect(function()
            Utilities.Tween(button, Utilities.TweenInfo.Fast, {
                BackgroundColor3 = self.Parent.CurrentTheme.Secondary,
                ImageColor3 = self.Parent.CurrentTheme.Text
            })
        end)
    end
    
    -- Store references
    self.Header = header
    self.SearchBar = searchBar
    self.TreeContainer = treeContainer
    
    -- Populate file tree
    self:RefreshFileTree()
    
    return frame
end

function FileSystem:CreateFolderItem(name, path, isExpanded)
    local folderItem = Utilities.Create("Frame", {
        Name = "Folder_" .. name,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.TreeContainer
    })
    
    local indent = path:split("/").n - 1
    
    local folderButton = Utilities.Create("ImageButton", {
        Name = "FolderButton",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, indent * 15, 0, 0),
        BackgroundTransparency = 1,
        Image = "",
        Parent = folderItem
    })
    
    local expandIcon = Utilities.Create("ImageLabel", {
        Name = "ExpandIcon",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 5, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = isExpanded and "rbxassetid://11585776189" or "rbxassetid://11585776314", -- Down/Right arrow
        ImageColor3 = self.Parent.CurrentTheme.Text,
        Parent = folderButton
    })
    
    local folderIcon = Utilities.Create("ImageLabel", {
        Name = "FolderIcon",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 24, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11585775575", -- Folder icon
        ImageColor3 = self.Parent.CurrentTheme.Secondary,
        Parent = folderButton
    })
    
    local folderName = Utilities.Create("TextLabel", {
        Name = "FolderName",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 46, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = folderButton
    })
    
    -- Folder events
    folderButton.MouseButton1Click:Connect(function()
        self:ToggleFolderExpand(path, not isExpanded)
    end)
    
    folderButton.MouseEnter:Connect(function()
        folderButton.BackgroundTransparency = 0.9
        folderButton.BackgroundColor3 = self.Parent.CurrentTheme.Secondary
    end)
    
    folderButton.MouseLeave:Connect(function()
        folderButton.BackgroundTransparency = 1
    end)
    
    -- Context menu on right click
    folderButton.MouseButton2Click:Connect(function()
        self:ShowFolderContextMenu(folderItem, path)
    end)
    
    return folderItem
end

function FileSystem:CreateFileItem(name, path)
    local fileItem = Utilities.Create("Frame", {
        Name = "File_" .. name,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = self.TreeContainer
    })
    
    local pathParts = path:split("/")
    local indent = #pathParts - 1
    
    local fileButton = Utilities.Create("TextButton", {
        Name = "FileButton",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, indent * 15, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = fileItem
    })
    
    local fileIcon = Utilities.Create("ImageLabel", {
        Name = "FileIcon",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 24, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://11585775733", -- File icon
        ImageColor3 = self.Parent.CurrentTheme.Accent,
        Parent = fileButton
    })
    
    local fileName = Utilities.Create("TextLabel", {
        Name = "FileName",
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 46, 0, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = name,
        TextColor3 = self.Parent.CurrentTheme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = fileButton
    })
    
    -- File events
    fileButton.MouseButton1Click:Connect(function()
        self:OpenFile(path)
    end)
    
    fileButton.MouseEnter:Connect(function()
        fileButton.BackgroundTransparency = 0.9
        fileButton.BackgroundColor3 = self.Parent.CurrentTheme.Secondary
    end)
    
    fileButton.MouseLeave:Connect(function()
        fileButton.BackgroundTransparency = 1
    end)
    
    -- Context menu on right click
    fileButton.MouseButton2Click:Connect(function()
        self:ShowFileContextMenu(fileItem, path)
    end)
    
    return fileItem
end

function FileSystem:RefreshFileTree()
    -- Clear existing items
    for _, child in pairs(self.TreeContainer:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Add root folder
    local rootItem = self:CreateFolderItem("workspace", "workspace", true)
    
    -- Sort folders and files
    local sortedFolders = {}
    local sortedFiles = {}
    
    for path, _ in pairs(self.Folders) do
        if path ~= "workspace" then
            table.insert(sortedFolders, path)
        end
    end
    
    for path, _ in pairs(self.Files) do
        table.insert(sortedFiles, path)
    end
    
    table.sort(sortedFolders)
    table.sort(sortedFiles)
    
    -- Add folders first
    for _, path in ipairs(sortedFolders) do
        local parts = path:split("/")
        local name = parts[#parts]
        local isExpanded = self.Folders[path].Expanded
        
        if self:ShouldShowItem(path) then
            self:CreateFolderItem(name, path, isExpanded)
        end
    end
    
    -- Then add files
    for _, path in ipairs(sortedFiles) do
        local parts = path:split("/")
        local name = parts[#parts]
        
        if self:ShouldShowItem(path) then
            self:CreateFileItem(name, path)
        end
    end
    
    -- Update canvas size
    self:UpdateCanvasSize()
end

function FileSystem:ShouldShowItem(path)
    local parts = path:split("/")
    local currentPath = ""
    
    for i = 1, #parts - 1 do
        if i > 1 then
            currentPath = currentPath .. "/"
        end
        currentPath = currentPath .. parts[i]
        
        if self.Folders[currentPath] and not self.Folders[currentPath].Expanded then
            return false
        end
    end
    
    return true
end

function FileSystem:UpdateCanvasSize()
    local totalHeight = 0
    for _, child in pairs(self.TreeContainer:GetChildren()) do
        if child:IsA("Frame") then
            totalHeight = totalHeight + child.Size.Y.Offset
        end
    end
    
    self.TreeContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)
end

function FileSystem:ToggleFolderExpand(path, expand)
    if not self.Folders[path] then return end
    
    self.Folders[path].Expanded = expand
    self:RefreshFileTree()
end

function FileSystem:CreateFolder(path)
    local parts = path:split("/")
    local currentPath = ""
    
    for i, part in ipairs(parts) do
        if i > 1 then
            currentPath = currentPath .. "/"
        end
        currentPath = currentPath .. part
        
        if not self.Folders[currentPath] then
            self.Folders[currentPath] = {
                Expanded = true,
                Items = {}
            }
        end
    end
    
    self:RefreshFileTree()
    return path
end

function FileSystem:DeleteFolder(path)
    -- Delete this folder and all subfolders/files
    local foldersToDelete = {}
    local filesToDelete = {}
    
    -- Find all folders that start with this path
    for folderPath, _ in pairs(self.Folders) do
        if folderPath == path or folderPath:sub(1, #path + 1) == path .. "/" then
            table.insert(foldersToDelete, folderPath)
        end
    end
    
    -- Find all files in this folder or subfolders
    for filePath, _ in pairs(self.Files) do
        if filePath:sub(1, #path + 1) == path .. "/" then
            table.insert(filesToDelete, filePath)
        end
    end
    
    -- Delete the files first
    for _, filePath in ipairs(filesToDelete) do
        self.Files[filePath] = nil
    end
    
    -- Then delete the folders
    for _, folderPath in ipairs(foldersToDelete) do
        self.Folders[folderPath] = nil
    end
    
    self:RefreshFileTree()
end

function FileSystem:SaveFile(path, content)
    local parts = path:split("/")
    local fileName = parts[#parts]
    local folderPath = path:sub(1, -(#fileName + 2))
    
    -- Ensure the folder exists
    if folderPath ~= "" and not self.Folders[folderPath] then
        self:CreateFolder(folderPath)
    end
    
    -- Save the file
    self.Files[path] = {
        Content = content,
        LastModified = os.time()
    }
    
    -- Update file tree
    self:RefreshFileTree()
    
    return path
end

function FileSystem:DeleteFile(path)
    if self.Files[path] then
        self.Files[path] = nil
        self:RefreshFileTree()
        return true
    end
    return false
end

function FileSystem:OpenFile(path)
    if not self.Files[path] then return end
    
    local parts = path:split("/")
    local fileName = parts[#parts]
    local content = self.Files[path].Content
    
    -- Open the file in the editor
    if self.Parent.Editor then
        self.Parent.Editor:LoadFile(fileName, content)
    end
end

function FileSystem:RenameFile(oldPath, newName)
    if not self.Files[oldPath] then return false end
    
    local parts = oldPath:split("/")
    local folderPath = oldPath:sub(1, -(#parts[#parts] + 2))
    local newPath = folderPath .. "/" .. newName
    
    -- Copy the file to the new path
    self.Files[newPath] = self.Files[oldPath]
    
    -- Delete the old file
    self.Files[oldPath] = nil
    
    -- Update file tree
    self:RefreshFileTree()
    
    return newPath
end

function FileSystem:RenameFolder(oldPath, newName)
    if not self.Folders[oldPath] then return false end
    
    local parts = oldPath:split("/")
    local parentPath = oldPath:sub(1, -(#parts[#parts] + 2))
    local newPath = parentPath .. "/" .. newName
    
    -- Create the new folder
    self:CreateFolder(newPath)
    
    -- Move all files and folders
    for filePath, fileData in pairs(self.Files) do
        if filePath:sub(1, #oldPath + 1) == oldPath .. "/" then
            local relativePath = filePath:sub(#oldPath + 2)
            local newFilePath = newPath .. "/" .. relativePath
            self.Files[newFilePath] = fileData
            self.Files[filePath] = nil
        end
    end
    
    -- Process subfolders
    local foldersToProcess = {}
    for folderPath, folderData in pairs(self.Folders) do
        if folderPath:sub(1, #oldPath + 1) == oldPath .. "/" then
            table.insert(foldersToProcess, {
                OldPath = folderPath,
                NewPath = newPath .. folderPath:sub(#oldPath + 1),
                Data = folderData
            })
        end
    end
    
    -- Create new folders and copy data
    for _, folderInfo in ipairs(foldersToProcess) do
        self:CreateFolder(folderInfo.NewPath)
        self.Folders[folderInfo.NewPath].Expanded = folderInfo.Data.Expanded
    end
    
    -- Delete old folders
    for _, folderInfo in ipairs(foldersToProcess) do
        self.Folders[folderInfo.OldPath] = nil
    end
    
    -- Delete the old folder
    self.Folders[oldPath] = nil
    
    -- Update file tree
    self:RefreshFileTree()
    
    return newPath
end

function FileSystem:SearchFiles(query)
    if query == "" then
        -- Reset all folders to expanded
        for path, folder in pairs(self.Folders) do
            folder.Expanded = true
        end
        self:RefreshFileTree()
        return
    end
    
    query = query:lower()
    local matchingFiles = {}
    local matchingFolders = {}
    
    -- Search files
    for path, fileData in pairs(self.Files) do
        local parts = path:split("/")
        local fileName = parts[#parts]:lower()
        
        if fileName:find(query) then
            table.insert(matchingFiles, path)
            
            -- Also add parent folders to expand them
            local currentPath = ""
            for i = 1, #parts - 1 do
                if i > 1 then
                    currentPath = currentPath .. "/"
                end
                currentPath = currentPath .. parts[i]
                matchingFolders[currentPath] = true
            end
        end
    end
    
    -- Expand matching folders and collapse others
    for path, folder in pairs(self.Folders) do
        folder.Expanded = matchingFolders[path] or false
    end
    
    -- Make sure workspace is always expanded
    self.Folders["workspace"].Expanded = true
    
    self:RefreshFileTree()
end

function FileSystem:ShowNewFileDialog()
    -- In a real implementation, show a dialog to get the file name
    -- For now, we'll create a file with a default name
    local newFileName = "NewFile_" .. os.time() .. ".lua"
    local filePath = self.CurrentPath .. "/" .. newFileName
    
    self:SaveFile(filePath, "-- New file created on " .. os.date("%Y-%m-%d %H:%M:%S"))
    self:OpenFile(filePath)
end

function FileSystem:ShowNewFolderDialog()
    -- In a real implementation, show a dialog to get the folder name
    -- For now, we'll create a folder with a default name
    local newFolderName = "NewFolder_" .. os.time()
    local folderPath = self.CurrentPath .. "/" .. newFolderName
    
    self:CreateFolder(folderPath)
end

function FileSystem:ShowFileContextMenu(fileItem, path)
    -- In a real implementation, show a context menu with options like rename, delete, etc.
    -- For this simplified version, we'll just print the options
    print("File context menu for", path)
    print("Options: Open, Rename, Delete")
end

function FileSystem:ShowFolderContextMenu(folderItem, path)
    -- In a real implementation, show a context menu with options like rename, delete, etc.
    -- For this simplified version, we'll just print the options
    print("Folder context menu for", path)
    print("Options: New File, New Folder, Rename, Delete")
end

function FileSystem:ConnectEvents()
    -- This will be implemented to connect file system events
end

return FileSystem 