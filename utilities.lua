--[[
    LunaIDE - Utilities Module
    Contains helper functions used throughout the IDE
]]

local Utilities = {}

-- Services
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- Tween info presets
Utilities.TweenInfo = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Medium = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Bounce = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
}

-- Create a simple instance with properties
function Utilities.Create(className, properties)
    local instance = Instance.new(className)
    for k, v in pairs(properties) do
        if k ~= "Parent" then -- Set parent last
            instance[k] = v
        end
    end
    if properties.Parent then
        instance.Parent = properties.Parent
    end
    return instance
end

-- Create a tween for an object
function Utilities.Tween(object, tweenInfo, properties)
    local tween = TweenService:Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Create a shine effect (gradient that moves across a button)
function Utilities.CreateShineEffect(button)
    local shine = Utilities.Create("Frame", {
        Name = "Shine",
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(-1, 0, 0, 0),
        Parent = button,
        ClipsDescendants = true,
        ZIndex = button.ZIndex + 1
    })
    
    local uiGradient = Utilities.Create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9),
            NumberSequenceKeypoint.new(0.5, 0.7),
            NumberSequenceKeypoint.new(1, 0.9)
        }),
        Parent = shine
    })
    
    return shine
end

-- Play shine animation
function Utilities.AnimateShine(shine)
    Utilities.Tween(shine, TweenInfo.new(0.5), {Position = UDim2.new(1, 0, 0, 0)})
    task.delay(0.5, function()
        shine.Position = UDim2.new(-1, 0, 0, 0)
    end)
end

-- Create a ripple effect
function Utilities.CreateRipple(parent, x, y)
    local ripple = Utilities.Create("Frame", {
        Name = "Ripple",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.8,
        Position = UDim2.new(0, x, 0, y),
        Size = UDim2.new(0, 0, 0, 0),
        ZIndex = parent.ZIndex + 1,
        Parent = parent
    })
    
    Utilities.Create("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = ripple
    })
    
    local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 1.5
    
    Utilities.Tween(ripple, Utilities.TweenInfo.Slow, {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    })
    
    task.delay(0.5, function()
        ripple:Destroy()
    end)
end

-- Round corners of a UI element
function Utilities.RoundCorners(instance, radius)
    local corner = Utilities.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent = instance
    })
    return corner
end

-- Add a shadow to a UI element
function Utilities.AddShadow(instance, size, transparency)
    local shadow = Utilities.Create("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://297774371",
        ImageColor3 = Color3.fromRGB(0, 0, 0),
        ImageTransparency = transparency or 0.5,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(1, size or 20, 1, size or 20),
        ZIndex = instance.ZIndex - 1,
        Parent = instance
    })
    return shadow
end

-- Apply a stroke to an element
function Utilities.AddStroke(instance, color, thickness, transparency)
    local stroke = Utilities.Create("UIStroke", {
        Color = color or Color3.fromRGB(255, 255, 255),
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        Parent = instance
    })
    return stroke
end

-- Generate a unique ID
function Utilities.GenerateUID()
    return HttpService:GenerateGUID(false)
end

-- Fast wait function
function Utilities.FastWait(duration)
    duration = duration or 0
    local start = os.clock()
    while os.clock() - start < duration do
        RunService.Heartbeat:Wait()
    end
end

-- Deep copy a table
function Utilities.DeepCopy(original)
    local copy
    if type(original) == "table" then
        copy = {}
        for k, v in pairs(original) do
            copy[k] = Utilities.DeepCopy(v)
        end
    else
        copy = original
    end
    return copy
end

-- Clamp a value between min and max
function Utilities.Clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

-- Lerp between two values
function Utilities.Lerp(a, b, t)
    return a + (b - a) * t
end

-- Lerp between two colors
function Utilities.LerpColor(colorA, colorB, t)
    return Color3.new(
        Utilities.Lerp(colorA.R, colorB.R, t),
        Utilities.Lerp(colorA.G, colorB.G, t),
        Utilities.Lerp(colorA.B, colorB.B, t)
    )
end

-- Format a string with placeholders
function Utilities.Format(str, ...)
    local args = {...}
    return string.gsub(str, "{(%d+)}", function(i)
        return tostring(args[tonumber(i)])
    end)
end

return Utilities 