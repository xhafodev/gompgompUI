local cloneref = cloneref or function(Object) return Object end;

local InputService = cloneref(game:GetService('UserInputService'));
local TextService = cloneref(game:GetService('TextService'));
local TweenService = cloneref(game:GetService('TweenService'));
local CoreGui = cloneref(game:GetService('CoreGui'));
local RunService = cloneref(game:GetService('RunService'));
local GuiService = cloneref(game:GetService('GuiService'));
local Workspace = cloneref(game:GetService('Workspace'));
local RenderStepped = RunService.RenderStepped;
local LocalPlayer = cloneref(game:GetService('Players')).LocalPlayer;
local Mouse = cloneref(LocalPlayer:GetMouse());

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ScreenGui = Instance.new('ScreenGui');
ProtectGui(ScreenGui);

ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
ScreenGui.Parent = CoreGui;

local Toggles = {};
local Options = {};

getgenv().Toggles = Toggles;
getgenv().Options = Options;

local Library = {
    Registry = {};
    RegistryMap = {};

    HudRegistry = {};

    Font = Enum.Font.Roboto;
    IntroTextSize = 52;
    IntroPixelGap = 60;
    FontColor = Color3.fromRGB(255, 255, 255);
    FontColor2 = Color3.fromRGB(255, 255, 255);
    MainColor = Color3.fromRGB(10, 10, 10);
    SelectedTabColor = Color3.fromRGB(10, 10, 10);
    BackgroundColor = Color3.fromRGB(10, 10, 10);
    AccentColor = Color3.fromRGB(100, 104, 173);
    OutlineColor = Color3.fromRGB(25, 25, 25);

    Black = Color3.new(0, 0, 0);

    OpenedFrames = {};

    Signals = {};
    ScreenGui = ScreenGui;

    KeybindListVisible = true;
    KeybindShowOnlyActive = false;
};

local RainbowStep = 0
local Hue = 0

table.insert(Library.Signals, RenderStepped:Connect(function(Delta)
    RainbowStep = RainbowStep + Delta

    if RainbowStep >= (1 / 60) then
        RainbowStep = 0

        Hue = Hue + (1 / 400);

        if Hue > 1 then
            Hue = 0;
        end;

        Library.CurrentRainbowHue = Hue;
        Library.CurrentRainbowColor = Color3.fromHSV(Hue, 0.8, 1);
    end
end))

function Library:AttemptSave()
    if Library.SaveManager then
        Library.SaveManager:Save();
    end;
end;

function Library:LoadLogoImage()
    return false;
end;

function Library:Create(Class, Properties)
    local _Instance = Class;

    if type(Class) == 'string' then
        _Instance = Instance.new(Class);
    end;

    for Property, Value in next, Properties do
        _Instance[Property] = Value;
    end;

    return _Instance;
end;

function Library:GetPixelFontFace()
    if Library._PixelFontFace then
        return Library._PixelFontFace;
    end;

    local Ok, Face = pcall(function()
        return Font.new('rbxasset://fonts/families/PressStart2P.json', Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    end);

    if Ok and Face then
        Library._PixelFontFace = Face;
    else
        Ok, Face = pcall(function()
            return Font.fromEnum(Enum.Font.RobotoMono);
        end);

        Library._PixelFontFace = Ok and Face or Font.fromEnum(Enum.Font.Code);
    end;

    return Library._PixelFontFace;
end;

function Library:TweenIntroStep(Duration, EasingStyle, EasingDirection, Step)
    local Info = TweenInfo.new(Duration, EasingStyle, EasingDirection);
    local StartTime = tick();

    while true do
        local Elapsed = tick() - StartTime;
        local Alpha = math.clamp(Elapsed / Duration, 0, 1);
        local T = TweenService:GetValue(Alpha, Info.EasingStyle, Info.EasingDirection);

        Step(T);

        if Alpha >= 1 then
            break;
        end;

        RenderStepped:Wait();
    end;
end;

function Library:FormatText(Text)
    if type(Text) ~= 'string' then
        return Text;
    end;

    if Text:find('<') then
        return Text;
    end;

    return Text:lower();
end;

function Library:CreateLabel(Properties, IsHud)
    if Properties and Properties.Text and not Properties.RichText then
        Properties.Text = Library:FormatText(Properties.Text);
    end;

    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor or Library.AccentColor;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });

    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor';
    }, IsHud);

    return Library:Create(_Instance, Properties);
end;

function Library:CreateLabel2(Properties, IsHud)
    if Properties and Properties.Text and not Properties.RichText then
        Properties.Text = Library:FormatText(Properties.Text);
    end;

    local _Instance = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        Font = Library.Font;
        TextColor3 = Library.FontColor2;
        TextSize = 16;
        TextStrokeTransparency = 0;
    });
    Library:AddToRegistry(_Instance, {
        TextColor3 = 'FontColor2';
    }, IsHud);
    return Library:Create(_Instance, Properties);
end;

function Library:MakeDraggable(Instance, Cutoff)
    Instance.Active = true;

   Instance.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local ObjPos = Vector2.new(
                Mouse.X - Instance.AbsolutePosition.X,
                Mouse.Y - Instance.AbsolutePosition.Y
            );

            if ObjPos.Y > (Cutoff or 40) then
                return;
            end;

            while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                Instance.Position = UDim2.new(
                    0,
                    Mouse.X - ObjPos.X + (Instance.Size.X.Offset * Instance.AnchorPoint.X),
                    0,
                    Mouse.Y - ObjPos.Y + (Instance.Size.Y.Offset * Instance.AnchorPoint.Y)
                );

                RenderStepped:Wait();
            end;
        end;
    end)
end;

function Library:AddToolTip(InfoStr, HoverInstance)
    local X, Y = Library:GetTextBounds(InfoStr, Library.Font, 14);
    local Tooltip = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor,        
        BorderColor3 = Library.OutlineColor,

        Size = UDim2.fromOffset(X + 5, Y + 4),
        ZIndex = 100,
        Parent = Library.ScreenGui,

        Visible = false,
    })

    local Label = Library:CreateLabel({
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.fromOffset(X, Y);
        TextSize = 14;
        Text = InfoStr,
        TextColor3 = Library.FontColor,
        TextXAlignment = Enum.TextXAlignment.Left;
        ZIndex = Tooltip.ZIndex + 1,

        Parent = Tooltip;
    });

    Library:AddToRegistry(Tooltip, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    Library:AddToRegistry(Label, {
        TextColor3 = 'FontColor',
    });
    
    local IsHovering = false
    HoverInstance.MouseEnter:Connect(function()
        IsHovering = true
        
        Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        Tooltip.Visible = true

        while IsHovering do
            RunService.Heartbeat:Wait()
            Tooltip.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y + 12)
        end
    end)

    HoverInstance.MouseLeave:Connect(function()
        IsHovering = false
        Tooltip.Visible = false
    end)
end

function Library:OnHighlight(HighlightInstance, Instance, Properties, PropertiesDefault)
    HighlightInstance.MouseEnter:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, Properties do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)

    HighlightInstance.MouseLeave:Connect(function()
        local Reg = Library.RegistryMap[Instance];

        for Property, ColorIdx in next, PropertiesDefault do
            Instance[Property] = Library[ColorIdx] or ColorIdx;

            if Reg and Reg.Properties[Property] then
                Reg.Properties[Property] = ColorIdx;
            end;
        end;
    end)
end;

function Library:MouseIsOverOpenedFrame()
    for Frame, _ in next, Library.OpenedFrames do
        local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

        if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
            and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

            return true;
        end;
    end;
end;

function Library:IsMouseOverFrame(Frame)
    local AbsPos, AbsSize = Frame.AbsolutePosition, Frame.AbsoluteSize;

    if Mouse.X >= AbsPos.X and Mouse.X <= AbsPos.X + AbsSize.X
        and Mouse.Y >= AbsPos.Y and Mouse.Y <= AbsPos.Y + AbsSize.Y then

        return true;
    end;
end

function Library:MapValue(Value, MinA, MaxA, MinB, MaxB)
    return (1 - ((Value - MinA) / (MaxA - MinA))) * MinB + ((Value - MinA) / (MaxA - MinA)) * MaxB;
end;

function Library:GetTextBounds(Text, Font, Size, Resolution)
    local Bounds = TextService:GetTextSize(Text, Size, Font, Resolution or Vector2.new(1920, 1080))
    return Bounds.X, Bounds.Y
end;

function Library:GetDarkerColor(Color)
    local H, S, V = Color3.toHSV(Color);
    return Color3.fromHSV(H, S, V / 5);
end; 
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor);

function Library:AddToRegistry(Instance, Properties, IsHud)
    local Idx = #Library.Registry + 1;
    local Data = {
        Instance = Instance;
        Properties = Properties;
        Idx = Idx;
    };

    table.insert(Library.Registry, Data);
    Library.RegistryMap[Instance] = Data;

    if IsHud then
        table.insert(Library.HudRegistry, Data);
    end;
end;

function Library:RemoveFromRegistry(Instance)
    local Data = Library.RegistryMap[Instance];

    if Data then
        for Idx = #Library.Registry, 1, -1 do
            if Library.Registry[Idx] == Data then
                table.remove(Library.Registry, Idx);
            end;
        end;

        for Idx = #Library.HudRegistry, 1, -1 do
            if Library.HudRegistry[Idx] == Data then
                table.remove(Library.HudRegistry, Idx);
            end;
        end;

        Library.RegistryMap[Instance] = nil;
    end;
end;

function Library:UpdateColorsUsingRegistry()
    -- TODO: Could have an 'active' list of objects
    -- where the active list only contains Visible objects.

    -- IMPL: Could setup .Changed events on the AddToRegistry function
    -- that listens for the 'Visible' propert being changed.
    -- Visible: true => Add to active list, and call UpdateColors function
    -- Visible: false => Remove from active list.

    -- The above would be especially efficient for a rainbow menu color or live color-changing.

    for Idx, Object in next, Library.Registry do
        for Property, ColorIdx in next, Object.Properties do
            if type(ColorIdx) == 'string' then
                Object.Instance[Property] = Library[ColorIdx];
            elseif type(ColorIdx) == 'function' then
                Object.Instance[Property] = ColorIdx()
            end
        end;
    end;
end;

function Library:GiveSignal(Signal)
    -- Only used for signals not attached to library instances, as those should be cleaned up on object destruction by Roblox
    table.insert(Library.Signals, Signal)
end

function Library:Unload()
    -- Unload all of the signals
    for Idx = #Library.Signals, 1, -1 do
        local Connection = table.remove(Library.Signals, Idx)
        Connection:Disconnect()
    end

     -- Call our unload callback, maybe to undo some hooks etc
    if Library.OnUnload then
        Library.OnUnload()
    end

    ScreenGui:Destroy()
end

function Library:OnUnload(Callback)
    Library.OnUnload = Callback
end

Library:GiveSignal(ScreenGui.DescendantRemoving:Connect(function(Instance)
    if Library.RegistryMap[Instance] then
        Library:RemoveFromRegistry(Instance);
    end;
end))

local BaseAddons = {};

do
    local Funcs = {};

    function Funcs:AddColorPicker(Idx, Info)
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        local         ColorPicker = {
            Value = Info.Default;
            Type = 'ColorPicker';
            Title = Library:FormatText(type(Info.Title) == 'string' and Info.Title or 'colorpicker'),
            FlagName = Library:FormatText(type(Info.FlagName) == 'string' and Info.FlagName or Idx),
        };

        function ColorPicker:SetHSVFromRGB(Color)
            local H, S, V = Color3.toHSV(Color);

            ColorPicker.Hue = H;
            ColorPicker.Sat = S;
            ColorPicker.Vib = V;
        end;

        ColorPicker:SetHSVFromRGB(ColorPicker.Value);

        local DisplayFrame = Library:Create('Frame', {
            BackgroundColor3 = ColorPicker.Value;
            BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(0, 28, 0, 14);
            ZIndex = 6;
            Parent = ToggleLabel;
        });

        local RelativeOffset = 0;

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local PickerFrameOuter = Library:Create('Frame', {
            Name = 'Color';
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 20 + RelativeOffset + 1);
            Size = UDim2.new(1, -13, 0, 280);
            Visible = false;
            ZIndex = 15;
            Parent = Container.Parent;
        });

        local PickerFrameInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 16;
            Parent = PickerFrameOuter;
        });

        local TitleLabel = Library:CreateLabel2({
            Size = UDim2.new(0.5, -5, 0, 16);
            Position = UDim2.fromOffset(5, 4);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 14;
            Text = ColorPicker.Title;
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local FlagLabel = Library:CreateLabel({
            Size = UDim2.new(0.5, -5, 0, 16);
            Position = UDim2.new(0.5, 0, 0, 4);
            TextXAlignment = Enum.TextXAlignment.Right;
            TextSize = 13;
            Text = ColorPicker.FlagName;
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HeaderLine = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Position = UDim2.new(0, 4, 0, 22);
            Size = UDim2.new(1, -8, 0, 1);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 28);
            Size = UDim2.new(1, -8, 0, 130);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local SatVibMapInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = SatVibMapOuter;
        });

        local SatVibMap = Library:Create('ImageLabel', {
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Image = 'rbxassetid://4155801252';
            Parent = SatVibMapInner;
        });

        local SatVibCursor = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 1;
            Size = UDim2.fromOffset(6, 6);
            ZIndex = 19;
            Parent = SatVibMapInner;
        });

        local HueSelectorOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 164);
            Size = UDim2.new(1, -8, 0, 12);
            ZIndex = 17;
            Parent = PickerFrameInner;
        });

        local HueSelectorInner = Library:Create('Frame', {
            BackgroundColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 18;
            Parent = HueSelectorOuter;
        });

        local HueCursor = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderColor3 = Color3.new(1, 1, 1);
            BorderSizePixel = 1;
            Size = UDim2.new(0, 6, 1, 4);
            Position = UDim2.new(0, -3, 0.5, -2);
            AnchorPoint = Vector2.new(0, 0.5);
            ZIndex = 19;
            Parent = HueSelectorInner;
        });

        local function CreateInputBox(Position, Size, Placeholder)
            local Outer = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = Position;
                Size = Size;
                ZIndex = 18;
                Parent = PickerFrameInner;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = Outer;
            });

            local Box = Library:Create('TextBox', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, -4, 1, 0);
                Position = UDim2.fromOffset(2, 0);
                Font = Library.Font;
                PlaceholderColor3 = Color3.fromRGB(100, 100, 100);
                PlaceholderText = Placeholder;
                Text = '';
                TextColor3 = Library.FontColor2;
                TextSize = 13;
                TextStrokeTransparency = 0;
                TextXAlignment = Enum.TextXAlignment.Center;
                ZIndex = 20;
                Parent = Inner;
            });

            Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
            Library:AddToRegistry(Box, { TextColor3 = 'FontColor2'; });

            return Box, Outer;
        end;

        local InputY = 182;
        local InputW = (PickerFrameInner.AbsoluteSize.X > 0 and (PickerFrameInner.AbsoluteSize.X - 8 - 12) / 4) or 48;
        local RBox = CreateInputBox(UDim2.new(0, 4, 0, InputY), UDim2.new(0.25, -5, 0, 20), 'R');
        local GBox = CreateInputBox(UDim2.new(0.25, 1, 0, InputY), UDim2.new(0.25, -5, 0, 20), 'G');
        local BBox = CreateInputBox(UDim2.new(0.5, -2, 0, InputY), UDim2.new(0.25, -5, 0, 20), 'B');
        local HexBox = CreateInputBox(UDim2.new(0.75, -3, 0, InputY), UDim2.new(0.25, -1, 0, 20), 'Hex');

        local function CreatePickerButton(Text, Position, Size)
            local Outer = Library:Create('Frame', {
                BorderColor3 = Color3.new(0, 0, 0);
                Position = Position;
                Size = Size;
                ZIndex = 18;
                Parent = PickerFrameInner;
            });

            local Inner = Library:Create('Frame', {
                BackgroundColor3 = Library.MainColor;
                BorderColor3 = Library.OutlineColor;
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 18;
                Parent = Outer;
            });

            local Btn = Library:Create('TextButton', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Font = Library.Font;
                Text = Text;
                TextColor3 = Library.FontColor2;
                TextSize = 13;
                ZIndex = 20;
                Parent = Inner;
            });

            Library:AddToRegistry(Inner, { BackgroundColor3 = 'MainColor'; BorderColor3 = 'OutlineColor'; });
            Library:AddToRegistry(Btn, { TextColor3 = 'FontColor2'; });

            return Btn;
        end;

        local CopyBtn = CreatePickerButton('Copy', UDim2.new(0, 4, 0, 208), UDim2.new(0.5, -6, 0, 22));
        local PasteBtn = CreatePickerButton('Paste', UDim2.new(0.5, 2, 0, 208), UDim2.new(0.5, -6, 0, 22));
        local ConfirmBtn = CreatePickerButton('Confirm', UDim2.new(0, 4, 0, 236), UDim2.new(1, -8, 0, 22));

        Library:AddToRegistry(PickerFrameInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });
        Library:AddToRegistry(SatVibMapInner, { BackgroundColor3 = 'BackgroundColor'; BorderColor3 = 'OutlineColor'; });

        local SequenceTable = {};

        for Hue = 0, 1, 0.1 do
            table.insert(SequenceTable, ColorSequenceKeypoint.new(Hue, Color3.fromHSV(Hue, 1, 1)));
        end;

        Library:Create('UIGradient', {
            Color = ColorSequence.new(SequenceTable);
            Rotation = 0;
            Parent = HueSelectorInner;
        });

        local function UpdateCursors()
            SatVibCursor.Position = UDim2.new(ColorPicker.Sat, -3, 1 - ColorPicker.Vib, -3);
            HueCursor.Position = UDim2.new(ColorPicker.Hue, -3, 0.5, -2);
        end;

        function ColorPicker:Display()
            ColorPicker.Value = Color3.fromHSV(ColorPicker.Hue, ColorPicker.Sat, ColorPicker.Vib);
            SatVibMap.BackgroundColor3 = Color3.fromHSV(ColorPicker.Hue, 1, 1);

            Library:Create(DisplayFrame, {
                BackgroundColor3 = ColorPicker.Value;
                BorderColor3 = Library:GetDarkerColor(ColorPicker.Value);
            });

            local r = math.floor(ColorPicker.Value.R * 255);
            local g = math.floor(ColorPicker.Value.G * 255);
            local b = math.floor(ColorPicker.Value.B * 255);

            RBox.Text = tostring(r);
            GBox.Text = tostring(g);
            BBox.Text = tostring(b);
            HexBox.Text = ColorPicker.Value:ToHex();

            UpdateCursors();

            if ColorPicker.Changed then
                ColorPicker.Changed(ColorPicker.Value)
            end;
        end;

        local function ApplyFromRGB(r, g, b)
            if r and g and b then
                ColorPicker:SetHSVFromRGB(Color3.fromRGB(
                    math.clamp(tonumber(r) or 0, 0, 255),
                    math.clamp(tonumber(g) or 0, 0, 255),
                    math.clamp(tonumber(b) or 0, 0, 255)
                ));
                ColorPicker:Display();
            end;
        end;

        RBox.FocusLost:Connect(function(enter)
            if enter then ApplyFromRGB(RBox.Text, GBox.Text, BBox.Text) end
        end);
        GBox.FocusLost:Connect(function(enter)
            if enter then ApplyFromRGB(RBox.Text, GBox.Text, BBox.Text) end
        end);
        BBox.FocusLost:Connect(function(enter)
            if enter then ApplyFromRGB(RBox.Text, GBox.Text, BBox.Text) end
        end);

        HexBox.FocusLost:Connect(function(enter)
            if enter then
                local hex = HexBox.Text:gsub('#', '');
                local success, result = pcall(Color3.fromHex, hex);
                if success and typeof(result) == 'Color3' then
                    ColorPicker:SetHSVFromRGB(result);
                    ColorPicker:Display();
                end;
            end;
        end);

        CopyBtn.MouseButton1Click:Connect(function()
            Library.ColorClipboard = ColorPicker.Value;
        end);

        PasteBtn.MouseButton1Click:Connect(function()
            if Library.ColorClipboard then
                ColorPicker:SetValueRGB(Library.ColorClipboard);
            end;
        end);

        ConfirmBtn.MouseButton1Click:Connect(function()
            ColorPicker:Hide();
            Library:AttemptSave();
        end);

        function ColorPicker:OnChanged(Func)
            ColorPicker.Changed = Func;
            Func(ColorPicker.Value)
        end;

        function ColorPicker:Show()
            for Frame, Val in next, Library.OpenedFrames do
                if Frame.Name == 'Color' then
                    Frame.Visible = false;
                    Library.OpenedFrames[Frame] = nil;
                end;
            end;

            PickerFrameOuter.Visible = true;
            Library.OpenedFrames[PickerFrameOuter] = true;
        end;

        function ColorPicker:Hide()
            PickerFrameOuter.Visible = false;
            Library.OpenedFrames[PickerFrameOuter] = nil;
        end;

        function ColorPicker:SetValue(HSV)
            local Color = Color3.fromHSV(HSV[1], HSV[2], HSV[3]);

            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        function ColorPicker:SetValueRGB(Color)
            ColorPicker:SetHSVFromRGB(Color);
            ColorPicker:Display();
        end;

        SatVibMap.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = SatVibMap.AbsolutePosition.X;
                    local MaxX = MinX + SatVibMap.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    local MinY = SatVibMap.AbsolutePosition.Y;
                    local MaxY = MinY + SatVibMap.AbsoluteSize.Y;
                    local MouseY = math.clamp(Mouse.Y, MinY, MaxY);

                    ColorPicker.Sat = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker.Vib = 1 - ((MouseY - MinY) / (MaxY - MinY));
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        HueSelectorInner.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    local MinX = HueSelectorInner.AbsolutePosition.X;
                    local MaxX = MinX + HueSelectorInner.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);

                    ColorPicker.Hue = (MouseX - MinX) / (MaxX - MinX);
                    ColorPicker:Display();

                    RenderStepped:Wait();
                end;

                Library:AttemptSave();
            end;
        end);

        DisplayFrame.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if PickerFrameOuter.Visible then
                    ColorPicker:Hide();
                else
                    ColorPicker:Show();
                end;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = PickerFrameOuter.AbsolutePosition, PickerFrameOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ColorPicker:Hide();
                end;
            end;
        end))

        ColorPicker:Display();
        ColorPicker.DisplayFrame = DisplayFrame

        Options[Idx] = ColorPicker;

        return self;
    end;

    function Funcs:AddKeyPicker(Idx, Info)
        local ParentObj = self;
        local ToggleLabel = self.TextLabel;
        local Container = self.Container;

        local KeyPicker = {
            Value = Info.Default or 'None';
            Toggled = false;
            Mode = Info.Mode or 'Toggle';
            Type = 'KeyPicker';

            SyncToggleState = Info.SyncToggleState or false;
        };

        local function FormatKey(Key)
            if Key == nil or Key == '' or Key == 'None' then
                return 'none';
            end;

            return Library:FormatText(Key);
        end;

        if KeyPicker.SyncToggleState then
            Info.Modes = { 'Toggle' }
            Info.Mode = 'Toggle'
        end

        local RelativeOffset = 0;

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local PickOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 28, 0, 15);
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 0, 0, 0);
            ZIndex = 6;
            Parent = (ParentObj.Type == 'Toggle' and ParentObj.AddonHolder) or ToggleLabel;
        });

        local PickInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 7;
            Parent = PickOuter;
        });

        Library:AddToRegistry(PickInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        local DisplayLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 13;
            Text = FormatKey(Info.Default);
            TextWrapped = true;
            ZIndex = 8;
            Parent = PickInner;
        });

        local ModeSelectOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(1, 0, 0, RelativeOffset + 1);
            Size = UDim2.new(0, 60, 0, 45 + 2);
            Visible = false;
            ZIndex = 14;
            Parent = Container.Parent;
        });

        local ModeSelectInner = Library:Create('Frame', {
            BackgroundColor3 = Library.BackgroundColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 15;
            Parent = ModeSelectOuter;
        });

        Library:AddToRegistry(ModeSelectInner, {
            BackgroundColor3 = 'BackgroundColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIListLayout', {
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = ModeSelectInner;
        });

        local ContainerRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 18);
            Visible = false;
            ZIndex = 110;
            Parent = Library.KeybindContainer;
        });

        KeyPicker.ContainerRow = ContainerRow;

        local NameLabel = Library:CreateLabel2({
            Size = UDim2.new(1, -36, 1, 0);
            Position = UDim2.fromOffset(0, 0);
            TextXAlignment = Enum.TextXAlignment.Left;
            TextSize = 13;
            Text = Info.Text or '';
            ZIndex = 111;
            Parent = ContainerRow;
        }, true);

        local KeyLabel = Library:CreateLabel2({
            Size = UDim2.new(0, 32, 1, 0);
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 0, 0, 0);
            TextXAlignment = Enum.TextXAlignment.Right;
            TextSize = 13;
            Text = FormatKey(KeyPicker.Value);
            ZIndex = 111;
            Parent = ContainerRow;
        }, true);

        local Modes = Info.Modes or { 'Always', 'Toggle', 'Hold' };
        local ModeButtons = {};

        for Idx, Mode in next, Modes do
            local ModeButton = {};

            local Label = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 15);
                TextSize = 13;
                Text = Mode;
                ZIndex = 16;
                Parent = ModeSelectInner;
            });

            function ModeButton:Select()
                for _, Button in next, ModeButtons do
                    Button:Deselect();
                end;

                KeyPicker.Mode = Mode;

                Label.TextColor3 = Library.AccentColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'AccentColor';

                ModeSelectOuter.Visible = false;
            end;

            function ModeButton:Deselect()
                KeyPicker.Mode = nil;

                Label.TextColor3 = Library.FontColor;
                Library.RegistryMap[Label].Properties.TextColor3 = 'FontColor';
            end;

            Label.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    ModeButton:Select();
                    Library:AttemptSave();
                end;
            end);

            if Mode == KeyPicker.Mode then
                ModeButton:Select();
            end;

            ModeButtons[Mode] = ModeButton;
        end;

        function KeyPicker:Update()
            if Info.NoUI then
                return;
            end;

            local KeyText = FormatKey(KeyPicker.Value);
            local HasKey = KeyText ~= 'none';
            local IsOn = ParentObj.Type ~= 'Toggle' or ParentObj.Value;
            local ShowRow = true;

            if Library.KeybindShowOnlyActive then
                ShowRow = IsOn and HasKey;
            end;

            NameLabel.Text = Library:FormatText(Info.Text or '');
            KeyLabel.Text = KeyText;
            KeyLabel.Size = UDim2.new(0, math.max(KeyLabel.TextBounds.X + 4, 28), 1, 0);

            ContainerRow.Visible = ShowRow;
            NameLabel.TextColor3 = Library.FontColor2;
            KeyLabel.TextColor3 = Library.FontColor2;

            Library.RegistryMap[NameLabel].Properties.TextColor3 = 'FontColor2';
            Library.RegistryMap[KeyLabel].Properties.TextColor3 = 'FontColor2';

            Library:RefreshKeybindList();
        end;

        function KeyPicker:GetState()
            if KeyPicker.Value == 'None' or KeyPicker.Value == '' then
                return false;
            end;

            if KeyPicker.Mode == 'Always' then
                return true;
            elseif KeyPicker.Mode == 'Hold' then
                local Key = KeyPicker.Value;

                if Key == 'MB1' or Key == 'MB2' then
                    return Key == 'MB1' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
                        or Key == 'MB2' and InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2);
                else
                    return InputService:IsKeyDown(Enum.KeyCode[KeyPicker.Value]);
                end;
            else
                return KeyPicker.Toggled;
            end;
        end;

        function KeyPicker:SetValue(Data)
            local Key, Mode = Data[1], Data[2];
            KeyPicker.Value = Key or 'None';
            DisplayLabel.Text = FormatKey(KeyPicker.Value);
            ModeButtons[Mode]:Select();
            KeyPicker:Update();
        end;

        function KeyPicker:OnClick(Callback)
            KeyPicker.Clicked = Callback
        end


        if ParentObj.Addons then
            table.insert(ParentObj.Addons, KeyPicker)
        end

        function KeyPicker:DoClick()
            if ParentObj.Type == 'Toggle' and KeyPicker.SyncToggleState then
                ParentObj:SetValue(not ParentObj.Value)
            end

            if KeyPicker.Clicked then
                KeyPicker.Clicked()
            end
        end

        local Picking = false;

        PickOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Picking = true;

                DisplayLabel.Text = '';

                local Break;
                local Text = '';

                task.spawn(function()
                    while (not Break) do
                        if Text == '...' then
                            Text = '';
                        end;

                        Text = Text .. '.';
                        DisplayLabel.Text = Text;

                        wait(0.4);
                    end;
                end);

                wait(0.2);

                local Event;
                Event = InputService.InputBegan:Connect(function(Input)
                    local Key;

                    if Input.UserInputType == Enum.UserInputType.Keyboard then
                        Key = Input.KeyCode.Name;
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        Key = 'MB1';
                    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                        Key = 'MB2';
                    end;

                    Break = true;
                    Picking = false;

                    DisplayLabel.Text = FormatKey(Key);
                    KeyPicker.Value = Key;

                    Library:AttemptSave();

                    Event:Disconnect();
                end);
            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and not Library:MouseIsOverOpenedFrame() then
                ModeSelectOuter.Visible = true;
            end;
        end);

        Library:GiveSignal(InputService.InputBegan:Connect(function(Input)
            if (not Picking) then
                if KeyPicker.Mode == 'Toggle' then
                    local Key = KeyPicker.Value;

                    if Key == 'None' or Key == '' then
                        return;
                    end;

                    if Key == 'MB1' or Key == 'MB2' then
                        if Key == 'MB1' and Input.UserInputType == Enum.UserInputType.MouseButton1
                        or Key == 'MB2' and Input.UserInputType == Enum.UserInputType.MouseButton2 then
                            KeyPicker.Toggled = not KeyPicker.Toggled
                            KeyPicker:DoClick()
                        end;
                    elseif Input.UserInputType == Enum.UserInputType.Keyboard then
                        if Input.KeyCode.Name == Key then
                            KeyPicker.Toggled = not KeyPicker.Toggled;
                            KeyPicker:DoClick()
                        end;
                    end;
                end;

                KeyPicker:Update();
            end;

            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ModeSelectOuter.AbsolutePosition, ModeSelectOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    ModeSelectOuter.Visible = false;
                end;
            end;
        end))

        Library:GiveSignal(InputService.InputEnded:Connect(function(Input)
            if (not Picking) then
                KeyPicker:Update();
            end;
        end))

        KeyPicker:Update();

        Options[Idx] = KeyPicker;

        return self;
    end;

    BaseAddons.__index = Funcs;
    BaseAddons.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

local BaseGroupbox = {};

do
    local Funcs = {};

    function Funcs:AddBlank(Size)
        local Groupbox = self;
        local Container = Groupbox.Container;

        Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, Size);
            ZIndex = 1;
            Parent = Container;
        });
    end;

    function Funcs:AddLabel(Text, DoesWrap)
        local Label = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local TextLabel = Library:CreateLabel({
            Size = UDim2.new(1, -4, 0, 15);
            TextSize = 14;
            Text = Text;
            TextWrapped = DoesWrap or false,
            RichText = true,
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        if DoesWrap then
            local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
            TextLabel.Size = UDim2.new(1, -4, 0, Y)
        else
            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 4);
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Right;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TextLabel;
            });
        end

        Label.TextLabel = TextLabel;
        Label.Container = Container;

        function Label:SetText(Text)
            TextLabel.Text = Text

            if DoesWrap then
                local Y = select(2, Library:GetTextBounds(Text, Library.Font, 14, Vector2.new(TextLabel.AbsoluteSize.X, math.huge)))
                TextLabel.Size = UDim2.new(1, -4, 0, Y)
            end

            Groupbox:Resize();
        end

        if (not DoesWrap) then
            setmetatable(Label, BaseAddons);
        end

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Label;
    end;

    function Funcs:AddButton(Text, Func)
        Text = Library:FormatText(Text);

        local Button = {};

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ButtonOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(ButtonOuter, {
            BorderColor3 = 'Black';
        });

        local ButtonInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ButtonOuter;
        });

        Library:AddToRegistry(ButtonInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = ButtonInner;
        });

        local ButtonLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 1, 0);
            TextSize = 14;
            Text = Text;
            ZIndex = 6;
            Parent = ButtonInner;
        });

        Library:OnHighlight(ButtonOuter, ButtonOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        ButtonOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Func();
            end;
        end);

        function Button:AddTooltip(tip)
            if type(tip) == 'string' then
                Library:AddToolTip(tip, ButtonOuter)
            end
            return Button
        end

        function Button:AddButton(Text, Func)
            local SubButton = {}

            ButtonOuter.Size = UDim2.new(0.5, -2, 0, 20)
            
            local Outer = ButtonOuter:Clone()
            local Inner = Outer.Frame;
            local Label = Inner:FindFirstChildWhichIsA('TextLabel')

            Outer.Position = UDim2.new(1, 2, 0, 0)
            Outer.Size = UDim2.fromOffset(ButtonOuter.AbsoluteSize.X - 2, ButtonOuter.AbsoluteSize.Y)
            Outer.Parent = ButtonOuter

            Label.Text = Text;

            Library:AddToRegistry(Inner, {
                BackgroundColor3 = 'MainColor';
                BorderColor3 = 'OutlineColor';
            });
    
            Library:OnHighlight(Outer, Outer,
                { BorderColor3 = 'AccentColor' },
                { BorderColor3 = 'Black' }
            )

            Library:Create('UIGradient', {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
                });

                Rotation = 90;
                Parent = Inner;
            });

            Outer.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                    Func();
                end;
            end);

            function SubButton:AddTooltip(tip)
                if type(tip) == 'string' then
                    Library:AddToolTip(tip, Outer)
                end
                return SubButton
            end

            return SubButton
        end 

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        return Button;
    end;

    function Funcs:AddDivider()
        local Groupbox = self;
        local Container = self.Container

        local Divider = {
            Type = 'Divider',
        }

        Groupbox:AddBlank(2);
        local DividerOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 5);
            ZIndex = 5;
            Parent = Container;
        });


        local DividerInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DividerOuter;
        });

        Library:AddToRegistry(DividerOuter, {
            BorderColor3 = 'Black';
        });

        Library:AddToRegistry(DividerInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Groupbox:AddBlank(9);
        Groupbox:Resize();
    end

    function Funcs:AddInput(Idx, Info)
        local Textbox = {
            Value = Info.Default or '';
            Numeric = Info.Numeric or false;
            Finished = Info.Finished or false;
            Type = 'Input';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local InputLabel = Library:CreateLabel({
            Size = UDim2.new(1, 0, 0, 15);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 5;
            Parent = Container;
        });

        Groupbox:AddBlank(1);

        local TextBoxOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        local TextBoxInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = TextBoxOuter;
        });

        Library:AddToRegistry(TextBoxInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:OnHighlight(TextBoxOuter, TextBoxOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then 
            Library:AddToolTip(Info.Tooltip, TextBoxOuter)
        end

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = TextBoxInner;
        });

        local Container = Library:Create('Frame', {
            BackgroundTransparency = 1;
            ClipsDescendants = true;

            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);

            ZIndex = 7;
            Parent = TextBoxInner;
        })

        local Box = Library:Create('TextBox', {
            BackgroundTransparency = 1;

            Position = UDim2.fromOffset(0, 0),
            Size = UDim2.fromScale(5, 1),
            
            Font = Library.Font;
            PlaceholderColor3 = Color3.fromRGB(190, 190, 190);
            PlaceholderText = Info.Placeholder or '';

            Text = Info.Default or '';
            TextColor3 = Library.FontColor;
            TextSize = 14;
            TextStrokeTransparency = 0;
            TextXAlignment = Enum.TextXAlignment.Left;

            ZIndex = 7;
            Parent = Container;
        });
        
        function Textbox:SetValue(Text)
            if Info.MaxLength and #Text > Info.MaxLength then
                Text = Text:sub(1, Info.MaxLength);
            end;

            if Textbox.Numeric then
                if (not tonumber(Text)) and Text:len() > 0 then
                    Text = Textbox.Value 
                end
            end

            Textbox.Value = Text;
            Box.Text = Text;
                
            if Textbox.Changed then
                Textbox.Changed(Textbox.Value)
            end;
        end;

        if Textbox.Finished then
            Box.FocusLost:Connect(function(enter)
                if not enter then return end
                
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end)
        else 
            Box:GetPropertyChangedSignal('Text'):Connect(function()
                Textbox:SetValue(Box.Text);
                Library:AttemptSave();
            end);
        end

        -- https://devforum.roblox.com/t/how-to-make-textboxes-follow-current-cursor-position/1368429/6
        -- thank you nicemike40 :)

        local function Update()
            local PADDING = 5
            local reveal = Container.AbsoluteSize.X

            if not Box:IsFocused() or Box.TextBounds.X <= reveal - 2 * PADDING then
                -- we aren't focused, or we fit so be normal
                Box.Position = UDim2.new(0, PADDING, 0, 0)
            else
                -- we are focused and don't fit, so adjust position
                local cursor = Box.CursorPosition
                if cursor ~= -1 then
                    -- calculate pixel width of text from start to cursor
                    local subtext = string.sub(Box.Text, 1, cursor-1)
                    local width = TextService:GetTextSize(subtext, Box.TextSize, Box.Font, Vector2.new(math.huge, math.huge)).X
                    
                    -- check if we're inside the box with the cursor
                    local currentCursorPos = Box.Position.X.Offset + width

                    -- adjust if necessary
                    if currentCursorPos < PADDING then
                        Box.Position = UDim2.fromOffset(PADDING-width, 0)
                    elseif currentCursorPos > reveal - PADDING - 1 then
                        Box.Position = UDim2.fromOffset(reveal-width-PADDING-1, 0)
                    end
                end
            end
        end

        task.spawn(Update)

        Box:GetPropertyChangedSignal('Text'):Connect(Update)
        Box:GetPropertyChangedSignal('CursorPosition'):Connect(Update)
        Box.FocusLost:Connect(Update)
        Box.Focused:Connect(Update)

        Library:AddToRegistry(Box, {
            TextColor3 = 'FontColor';
        });

        function Textbox:OnChanged(Func)
            Textbox.Changed = Func;
            Func(Textbox.Value);
        end;

        Groupbox:AddBlank(5);
        Groupbox:Resize();

        Options[Idx] = Textbox;

        return Textbox;
    end;

    function Funcs:AddToggle(Idx, Info)
        local Toggle = {
            Value = Info.Default or false;
            Type = 'Toggle';

            Addons = {},
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local ToggleRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, -4, 0, 15);
            ZIndex = 5;
            Parent = Container;
        });

        local ToggleOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(0, 13, 0, 13);
            ZIndex = 5;
            Parent = ToggleRow;
        });

        Library:AddToRegistry(ToggleOuter, {
            BorderColor3 = 'Black';
        });

        local ToggleInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = ToggleOuter;
        });

        Library:AddToRegistry(ToggleInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local ToggleLabel = Library:CreateLabel({
            Size = UDim2.new(1, -58, 1, 0);
            Position = UDim2.new(0, 19, 0, 0);
            TextSize = 14;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            ZIndex = 6;
            Parent = ToggleRow;
        });

        Toggle.AddonHolder = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(0, 32, 1, 0);
            AnchorPoint = Vector2.new(1, 0);
            Position = UDim2.new(1, 0, 0, 0);
            ZIndex = 7;
            Parent = ToggleRow;
        });

        local ToggleRegion = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 8;
            Parent = ToggleRow;
        });

        Library:OnHighlight(ToggleRegion, ToggleOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        function Toggle:UpdateColors()
            Toggle:Display();
        end;

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, ToggleRegion)
        end

        function Toggle:Display()
            ToggleInner.BackgroundColor3 = Toggle.Value and Library.AccentColor or Library.MainColor;
            ToggleInner.BorderColor3 = Toggle.Value and Library.AccentColorDark or Library.OutlineColor;

            Library.RegistryMap[ToggleInner].Properties.BackgroundColor3 = Toggle.Value and 'AccentColor' or 'MainColor';
            Library.RegistryMap[ToggleInner].Properties.BorderColor3 = Toggle.Value and 'AccentColorDark' or 'OutlineColor';
        end;

        function Toggle:OnChanged(Func)
            Toggle.Changed = Func;
            Func(Toggle.Value);
        end;

        function Toggle:SetValue(Bool)
            Bool = (not not Bool);

            Toggle.Value = Bool;
            Toggle:Display();

            for _, Addon in next, Toggle.Addons do
                if Addon.Type == 'KeyPicker' and Addon.SyncToggleState then
                    Addon.Toggled = Bool
                end;

                if Addon.Type == 'KeyPicker' and Addon.Update then
                    Addon:Update();
                end;
            end

            if Toggle.Changed then
                Toggle.Changed(Toggle.Value)
            end;
        end;

        ToggleRegion.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                Toggle:SetValue(not Toggle.Value) -- Why was it not like this from the start?
                Library:AttemptSave();
            end;
        end);

        Toggle:Display();
        Groupbox:AddBlank(Info.BlankSize or 5 + 2);
        Groupbox:Resize();

        Toggle.TextLabel = ToggleLabel;
        Toggle.Container = Container;
        setmetatable(Toggle, BaseAddons);

        Toggles[Idx] = Toggle;

        return Toggle;
    end;

    function Funcs:AddSlider(Idx, Info)
        Info.Text = Library:FormatText(Info.Text);
        assert(Info.Default and Info.Text and Info.Min and Info.Max and Info.Rounding, 'Bad Slider Data');

        local Slider = {
            Value = Info.Default;
            Min = Info.Min;
            Max = Info.Max;
            Rounding = Info.Rounding;
            Type = 'Slider';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local HeaderRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 0, 14);
            ZIndex = 5;
            Parent = Container;
        });

        Library:CreateLabel({
            Size = UDim2.new(1, -50, 1, 0);
            TextSize = 13;
            Text = Info.Text;
            TextXAlignment = Enum.TextXAlignment.Left;
            TextYAlignment = Enum.TextYAlignment.Bottom;
            ZIndex = 5;
            Parent = HeaderRow;
        });

        local ValueLabel = Library:CreateLabel2({
            Size = UDim2.new(0, 50, 1, 0);
            Position = UDim2.new(1, -50, 0, 0);
            TextSize = 13;
            Text = tostring(Info.Default);
            TextXAlignment = Enum.TextXAlignment.Right;
            TextYAlignment = Enum.TextYAlignment.Bottom;
            ZIndex = 5;
            Parent = HeaderRow;
        });

        Groupbox:AddBlank(2);

        local SliderOuter = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(1, -4, 0, 8);
            ZIndex = 5;
            Parent = Container;
        });

        local SliderTrack = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = SliderOuter;
        });

        Library:AddToRegistry(SliderTrack, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Fill = Library:Create('Frame', {
            BackgroundColor3 = Library.AccentColor;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 0, 1, 0);
            ZIndex = 7;
            Parent = SliderTrack;
        });

        Library:AddToRegistry(Fill, {
            BackgroundColor3 = 'AccentColor';
        });

        Library:OnHighlight(SliderOuter, SliderTrack,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'OutlineColor' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, SliderOuter)
        end

        local FillTween;

        function Slider:UpdateColors()
            Fill.BackgroundColor3 = Library.AccentColor;
        end;

        function Slider:GetScale()
            return (Slider.Value - Slider.Min) / (Slider.Max - Slider.Min);
        end;

        function Slider:Display(Tween, Duration)
            local Suffix = Info.Suffix or '';
            local Scale = Slider:GetScale();

            ValueLabel.Text = string.format('%s%s', Slider.Value, Suffix);

            local TargetSize = UDim2.new(Scale, 0, 1, 0);

            if Tween then
                if FillTween then
                    FillTween:Cancel();
                end;

                FillTween = TweenService:Create(Fill, TweenInfo.new(Duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = TargetSize;
                });

                FillTween:Play();
            else
                Fill.Size = TargetSize;
            end;
        end;

        function Slider:OnChanged(Func)
            Slider.Changed = Func;
            Func(Slider.Value);
        end;

        local function Round(Value)
            if Slider.Rounding == 0 then
                return math.floor(Value);
            end;

            return tonumber(string.format('%.' .. Slider.Rounding .. 'f', Value))
        end;

        function Slider:GetValueFromScale(Scale)
            return Round(Library:MapValue(Scale, 0, 1, Slider.Min, Slider.Max));
        end;

        function Slider:SetValue(Str)
            local Num = tonumber(Str);

            if (not Num) then
                return;
            end;

            Num = math.clamp(Num, Slider.Min, Slider.Max);

            Slider.Value = Num;
            Slider:Display(true);

            if Slider.Changed then
                Slider.Changed(Slider.Value)
            end;
        end;

        SliderTrack.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                local function UpdateFromMouse()
                    local MinX = SliderTrack.AbsolutePosition.X;
                    local MaxX = MinX + SliderTrack.AbsoluteSize.X;
                    local MouseX = math.clamp(Mouse.X, MinX, MaxX);
                    local Scale = (MouseX - MinX) / math.max(MaxX - MinX, 1);
                    local nValue = Slider:GetValueFromScale(Scale);
                    local OldValue = Slider.Value;

                    Slider.Value = nValue;
                    Slider:Display(true, 0.1);

                    if nValue ~= OldValue and Slider.Changed then
                        Slider.Changed(Slider.Value)
                    end;
                end;

                UpdateFromMouse();

                while InputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
                    UpdateFromMouse();
                    RenderStepped:Wait();
                end;

                Slider:Display(true, 0.18);
                Library:AttemptSave();
            end;
        end);

        Slider:Display(true, 0.18);
        Groupbox:AddBlank(Info.BlankSize or 8);
        Groupbox:Resize();

        Options[Idx] = Slider;

        return Slider;
    end;

    function Funcs:AddDropdown(Idx, Info)
        Info.Text = Library:FormatText(Info.Text);

        for i, Value in next, Info.Values do
            Info.Values[i] = Library:FormatText(Value);
        end;

        assert(Info.Text and Info.Values, 'Bad Dropdown Data');

        local Dropdown = {
            Values = Info.Values;
            Value = Info.Multi and {};
            Multi = Info.Multi;
            Type = 'Dropdown';
        };

        local Groupbox = self;
        local Container = Groupbox.Container;

        local RelativeOffset = 0;

        if not Info.Compact then
            local DropdownLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 0, 10);
                TextSize = 14;
                Text = Info.Text;
                TextXAlignment = Enum.TextXAlignment.Left;
                TextYAlignment = Enum.TextYAlignment.Bottom;
                ZIndex = 5;
                Parent = Container;
            });

            Groupbox:AddBlank(3);
        end

        for _, Element in next, Container:GetChildren() do
            if not Element:IsA('UIListLayout') then
                RelativeOffset = RelativeOffset + Element.Size.Y.Offset;
            end;
        end;

        local DropdownOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Size = UDim2.new(1, -4, 0, 20);
            ZIndex = 5;
            Parent = Container;
        });

        Library:AddToRegistry(DropdownOuter, {
            BorderColor3 = 'Black';
        });

        local DropdownInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 6;
            Parent = DropdownOuter;
        });

        Library:AddToRegistry(DropdownInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        Library:Create('UIGradient', {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212))
            });
            Rotation = 90;
            Parent = DropdownInner;
        });

        local DropdownArrow = Library:Create('ImageLabel', {
            AnchorPoint = Vector2.new(0, 0.5);
            BackgroundTransparency = 1;
            Position = UDim2.new(1, -16, 0.5, 0);
            Size = UDim2.new(0, 12, 0, 12);
            Image = 'http://www.roblox.com/asset/?id=6282522798';
            ZIndex = 7;
            Parent = DropdownInner;
        });

        local ItemList = Library:CreateLabel({
            Position = UDim2.new(0, 5, 0, 0);
            Size = UDim2.new(1, -5, 1, 0);
            TextSize = 14;
            Text = '--';
            TextXAlignment = Enum.TextXAlignment.Left;
            TextWrapped = true;
            ZIndex = 7;
            Parent = DropdownInner;
        });

        Library:OnHighlight(DropdownOuter, DropdownOuter,
            { BorderColor3 = 'AccentColor' },
            { BorderColor3 = 'Black' }
        );

        if type(Info.Tooltip) == 'string' then
            Library:AddToolTip(Info.Tooltip, DropdownOuter)
        end

        local MAX_DROPDOWN_ITEMS = 8;

        local ListOuter = Library:Create('Frame', {
            BorderColor3 = Color3.new(0, 0, 0);
            Position = UDim2.new(0, 4, 0, 20 + RelativeOffset + 1 + 20);
            Size = UDim2.new(1, -8, 0, MAX_DROPDOWN_ITEMS * 20 + 2);
            ZIndex = 20;
            Visible = false;
            Parent = Container.Parent;
        });

        local ListInner = Library:Create('Frame', {
            BackgroundColor3 = Library.MainColor;
            BorderColor3 = Library.OutlineColor;
            BorderMode = Enum.BorderMode.Inset;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListOuter;
        });

        Library:AddToRegistry(ListInner, {
            BackgroundColor3 = 'MainColor';
            BorderColor3 = 'OutlineColor';
        });

        local Scrolling = Library:Create('ScrollingFrame', {
            BackgroundTransparency = 1;
            CanvasSize = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 21;
            Parent = ListInner;

            TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
            BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',

            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor, 
        });

        Library:AddToRegistry(Scrolling, {
            ScrollBarImageColor3 = 'AccentColor'
        })

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 0);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = Scrolling;
        });

        function Dropdown:Display()
            local Values = Dropdown.Values;
            local Str = '';

            if Info.Multi then
                for Idx, Value in next, Values do
                    if Dropdown.Value[Value] then
                        Str = Str .. Value .. ', ';
                    end;
                end;

                Str = Str:sub(1, #Str - 2);
            else
                Str = Dropdown.Value or '';
            end;

            ItemList.Text = (Str == '' and '--' or Str);
        end;

        function Dropdown:GetActiveValues()
            if Info.Multi then
                local T = {};

                for Value, Bool in next, Dropdown.Value do
                    table.insert(T, Value);
                end;

                return T;
            else
                return Dropdown.Value and 1 or 0;
            end;
        end;

        function Dropdown:SetValues()
            local Values = Dropdown.Values;
            local Buttons = {};

            for _, Element in next, Scrolling:GetChildren() do
                if not Element:IsA('UIListLayout') then
                    -- Library:RemoveFromRegistry(Element);
                    Element:Destroy();
                end;
            end;

            local Count = 0;

            for Idx, Value in next, Values do
                local Table = {};

                Count = Count + 1;

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Library.OutlineColor;
                    BorderMode = Enum.BorderMode.Middle;
                    Size = UDim2.new(1, -1, 0, 20);
                    ZIndex = 23;
                    Active = true,
                    Parent = Scrolling;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                    BorderColor3 = 'OutlineColor';
                });

                local ButtonLabel = Library:CreateLabel({
                    Size = UDim2.new(1, -6, 1, 0);
                    Position = UDim2.new(0, 6, 0, 0);
                    TextSize = 14;
                    Text = Value;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 25;
                    Parent = Button;
                });

                Library:OnHighlight(Button, Button,
                    { BorderColor3 = 'AccentColor', ZIndex = 24 },
                    { BorderColor3 = 'OutlineColor', ZIndex = 23 }
                );

                local Selected;

                if Info.Multi then
                    Selected = Dropdown.Value[Value];
                else
                    Selected = Dropdown.Value == Value;
                end;

                function Table:UpdateButton()
                    if Info.Multi then
                        Selected = Dropdown.Value[Value];
                    else
                        Selected = Dropdown.Value == Value;
                    end;

                    ButtonLabel.TextColor3 = Selected and Library.AccentColor or Library.FontColor;
                    Library.RegistryMap[ButtonLabel].Properties.TextColor3 = Selected and 'AccentColor' or 'FontColor';
                end;

                ButtonLabel.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local Try = not Selected;

                        if Dropdown:GetActiveValues() == 1 and (not Try) and (not Info.AllowNull) then
                        else
                            if Info.Multi then
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value[Value] = true;
                                else
                                    Dropdown.Value[Value] = nil;
                                end;
                            else
                                Selected = Try;

                                if Selected then
                                    Dropdown.Value = Value;
                                else
                                    Dropdown.Value = nil;
                                end;

                                for _, OtherButton in next, Buttons do
                                    OtherButton:UpdateButton();
                                end;
                            end;

                            Table:UpdateButton();
                            Dropdown:Display();

                            if Dropdown.Changed then
                                Dropdown.Changed(Dropdown.Value)
                            end;

                            Library:AttemptSave();
                        end;
                    end;
                end);

                Table:UpdateButton();
                Dropdown:Display();

                Buttons[Button] = Table;
            end;

            local Y = math.clamp(Count * 20, 0, MAX_DROPDOWN_ITEMS * 20) + 1;
            ListOuter.Size = UDim2.new(1, -8, 0, Y);
            Scrolling.CanvasSize = UDim2.new(0, 0, 0, (Count * 20) + 1);

            -- ListOuter.Size = UDim2.new(1, -8, 0, (#Values * 20) + 2);
        end;

        function Dropdown:OpenDropdown()
            ListOuter.Visible = true;
            Library.OpenedFrames[ListOuter] = true;
            DropdownArrow.Rotation = 180;
        end;

        function Dropdown:CloseDropdown()
            ListOuter.Visible = false;
            Library.OpenedFrames[ListOuter] = nil;
            DropdownArrow.Rotation = 0;
        end;

        function Dropdown:OnChanged(Func)
            Dropdown.Changed = Func;
            Func(Dropdown.Value);
        end;

        function Dropdown:SetValue(Val)
            if Dropdown.Multi then
                local nTable = {};

                for Value, Bool in next, Val do
                    if table.find(Dropdown.Values, Value) then
                        nTable[Value] = true
                    end;
                end;

                Dropdown.Value = nTable;
            else
                if (not Val) then
                    Dropdown.Value = nil;
                elseif table.find(Dropdown.Values, Val) then
                    Dropdown.Value = Val;
                end;
            end;

            Dropdown:SetValues();
            Dropdown:Display();
            
            if Dropdown.Changed then Dropdown.Changed(Dropdown.Value) end
        end;

        DropdownOuter.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                if ListOuter.Visible then
                    Dropdown:CloseDropdown();
                else
                    Dropdown:OpenDropdown();
                end;
            end;
        end);

        InputService.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                local AbsPos, AbsSize = ListOuter.AbsolutePosition, ListOuter.AbsoluteSize;

                if Mouse.X < AbsPos.X or Mouse.X > AbsPos.X + AbsSize.X
                    or Mouse.Y < (AbsPos.Y - 20 - 1) or Mouse.Y > AbsPos.Y + AbsSize.Y then

                    Dropdown:CloseDropdown();
                end;
            end;
        end);

        Dropdown:SetValues();
        Dropdown:Display();

        local Defaults = {}

        if type(Info.Default) == 'string' then
            local Idx = table.find(Dropdown.Values, Info.Default)
            if Idx then
                table.insert(Defaults, Idx)
            end
        elseif type(Info.Default) == 'table' then
            for _, Value in next, Info.Default do
                local Idx = table.find(Dropdown.Values, Value)
                if Idx then
                    table.insert(Defaults, Idx)
                end
            end
        elseif type(Info.Default) == 'number' and Dropdown.Values[Info.Default] ~= nil then
            table.insert(Defaults, Info.Default)
        end

        if next(Defaults) then
            for i = 1, #Defaults do
                local Index = Defaults[i]
                if Info.Multi then
                    Dropdown.Value[Dropdown.Values[Index]] = true
                else
                    Dropdown.Value = Dropdown.Values[Index];
                end

                if (not Info.Multi) then break end
            end

            Dropdown:SetValues();
            Dropdown:Display();
        end

        Groupbox:AddBlank(Info.BlankSize or 5);
        Groupbox:Resize();

        Options[Idx] = Dropdown;

        return Dropdown;
    end;

    BaseGroupbox.__index = Funcs;
    BaseGroupbox.__namecall = function(Table, Key, ...)
        return Funcs[Key](...);
    end;
end;

-- < Create other UI elements >
do
    Library.NotificationArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 0, 0, 40);
        Size = UDim2.new(0, 300, 0, 200);
        ZIndex = 100;
        Parent = ScreenGui;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 4);
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = Library.NotificationArea;
    });

    local WatermarkOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0.5, 0);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0.5, 0, 0, 8);
        Size = UDim2.new(0, 213, 0, 22);
        ZIndex = 200;
        Visible = false;
        Parent = ScreenGui;
    });

    local WatermarkInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.AccentColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 201;
        Parent = WatermarkOuter;
    });

    Library:AddToRegistry(WatermarkInner, {
        BorderColor3 = 'AccentColor';
    });

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 202;
        Parent = WatermarkInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local WatermarkLabel = Library:CreateLabel2({
        Position = UDim2.new(0, 5, 0, 0);
        Size = UDim2.new(1, -10, 1, 0);
        TextSize = 14;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 203;
        Parent = InnerFrame;
    });

    Library.Watermark = WatermarkOuter;
    Library.WatermarkText = WatermarkLabel;

    local KeybindOuter = Library:Create('Frame', {
        AnchorPoint = Vector2.new(0, 0.5);
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 10, 0.5, 0);
        Size = UDim2.new(0, 180, 0, 28);
        Visible = false;
        ZIndex = 100;
        Parent = ScreenGui;
    });

    local KeybindInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = KeybindOuter;
    });

    Library:AddToRegistry(KeybindInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local KeybindGradientFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 102;
        Parent = KeybindInner;
    });

    Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = KeybindGradientFrame;
    });

    local KeybindLabel = Library:CreateLabel2({
        Size = UDim2.new(1, -10, 0, 18);
        Position = UDim2.fromOffset(5, 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = 'keybinds';
        TextSize = 14;
        ZIndex = 104;
        Parent = KeybindGradientFrame;
    });

    local KeybindSeparator = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 0, 0, 18);
        Size = UDim2.new(1, 0, 0, 1);
        ZIndex = 104;
        Parent = KeybindGradientFrame;
    });

    local KeybindContainer = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, -22);
        Position = UDim2.new(0, 0, 0, 22);
        ZIndex = 1;
        Parent = KeybindGradientFrame;
    });

    Library:Create('UIListLayout', {
        FillDirection = Enum.FillDirection.Vertical;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = KeybindContainer;
    });

    Library:Create('UIPadding', {
        PaddingLeft = UDim.new(0, 5),
        PaddingRight = UDim.new(0, 5),
        Parent = KeybindContainer,
    })

    Library.KeybindFrame = KeybindOuter;
    Library.KeybindContainer = KeybindContainer;
    Library:MakeDraggable(KeybindOuter);
end;

function Library:SetWatermarkVisibility(Bool)
    Library.Watermark.Visible = Bool;
end;

function Library:SetKeybindListVisible(Bool)
    Library.KeybindListVisible = Bool;
    Library:RefreshKeybindList();
end;

function Library:SetKeybindShowOnlyActive(Bool)
    Library.KeybindShowOnlyActive = Bool;

    for _, Option in next, Options do
        if type(Option) == 'table' and Option.Type == 'KeyPicker' and Option.Update then
            Option:Update();
        end;
    end;
end;

function Library:RefreshAllKeybinds()
    for _, Option in next, Options do
        if type(Option) == 'table' and Option.Type == 'KeyPicker' and Option.Update then
            Option:Update();
        end;
    end;
end;

function Library:RefreshKeybindList()
    if not Library.KeybindListVisible then
        Library.KeybindFrame.Visible = false;
        return;
    end;

    local YSize = 0;
    local XSize = 160;
    local HasRows = false;

    for _, Row in next, Library.KeybindContainer:GetChildren() do
        if Row:IsA('Frame') and Row.Visible then
            HasRows = true;
            YSize = YSize + 18;

            local NameWidth = 0;
            local KeyWidth = 0;

            for _, Label in next, Row:GetChildren() do
                if Label:IsA('TextLabel') then
                    if Label.AnchorPoint.X == 1 then
                        KeyWidth = math.max(KeyWidth, Label.TextBounds.X + 4);
                    else
                        NameWidth = math.max(NameWidth, Label.TextBounds.X);
                    end;
                end;
            end;

            local RowWidth = NameWidth + KeyWidth + 20;
            if RowWidth > XSize then
                XSize = RowWidth;
            end;
        end;
    end;

    Library.KeybindFrame.Visible = HasRows;
    Library.KeybindFrame.Size = UDim2.new(0, XSize, 0, YSize + 28);
end;

function Library:CreateIntroDrawText(Text, Color)
    local Label = Drawing.new('Text');

    Label.Text = Text;
    Label.Font = 3;
    Label.Size = Library.IntroTextSize;
    Label.Color = Color;
    Label.Outline = true;
    Label.OutlineColor = Color3.new(0, 0, 0);
    Label.Center = true;
    Label.Visible = true;
    Label.Transparency = 0;

    return Label;
end;

function Library:PlayIntro(Callback)
    if Library.IntroPlayed then
        if Callback then
            Callback();
        end;

        return;
    end;

    Library.IntroPlayed = true;

    local IntroDuration = 7;
    local Start = tick();
    local Camera = Workspace.CurrentCamera;

    local function GetCenter()
        local Viewport = Camera.ViewportSize;

        return Viewport.X / 2, Viewport.Y / 2;
    end;

    local function WaitUntil(Elapsed)
        local Remaining = Elapsed - (tick() - Start);

        if Remaining > 0 then
            task.wait(Remaining);
        end;
    end;

    local function FinishIntro()
        if Callback then
            Callback();
        end;
    end;

    local UseDrawing = typeof(Drawing) == 'table' and typeof(Drawing.new) == 'function';

    if UseDrawing then
        local CenterX, CenterY = GetCenter();
        local Gap = Library.IntroPixelGap;

        local Gomp1 = Library:CreateIntroDrawText('gomp', Library.FontColor2);
        local Gomp2 = Library:CreateIntroDrawText('gomp', Library.AccentColor);

        Gomp1.Position = Vector2.new(CenterX, CenterY - 220);
        Gomp2.Position = Vector2.new(CenterX + Gap * 3, CenterY);
        Gomp2.Transparency = 1;

        Library:TweenIntroStep(2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, function(T)
            Gomp1.Position = Vector2.new(CenterX, CenterY - 220 + (220 * T));
        end);

        WaitUntil(2);

        Gomp2.Transparency = 0;

        local Gomp1Start = Gomp1.Position;
        local Gomp1Goal = Vector2.new(CenterX - Gap, CenterY);
        local Gomp2Start = Gomp2.Position;
        local Gomp2Goal = Vector2.new(CenterX + Gap, CenterY);

        Library:TweenIntroStep(1.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, function(T)
            Gomp1.Position = Gomp1Start:Lerp(Gomp1Goal, T);
            Gomp2.Position = Gomp2Start:Lerp(Gomp2Goal, T);
        end);

        WaitUntil(4);
        WaitUntil(5.5);

        Library:TweenIntroStep(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function(T)
            Gomp1.Transparency = T;
            Gomp2.Transparency = T;
        end);

        WaitUntil(IntroDuration);

        Gomp1:Remove();
        Gomp2:Remove();

        FinishIntro();

        return;
    end;

    local Intro = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 500;
        Parent = ScreenGui;
    });

    local Group = Library:Create('Frame', {
        BackgroundTransparency = 1;
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, 0);
        Size = UDim2.fromOffset(480, 120);
        ZIndex = 501;
        Parent = Intro;
    });

    local PixelFace = Library:GetPixelFontFace();

    local Gomp1 = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        FontFace = PixelFace;
        Text = 'gomp';
        TextColor3 = Library.FontColor2;
        TextSize = Library.IntroTextSize;
        TextStrokeTransparency = 0;
        Size = UDim2.fromOffset(180, 100);
        AnchorPoint = Vector2.new(0.5, 0.5);
        Position = UDim2.new(0.5, 0, 0.5, -220);
        ZIndex = 502;
        Parent = Group;
    });

    local Gomp2 = Library:Create('TextLabel', {
        BackgroundTransparency = 1;
        FontFace = PixelFace;
        Text = 'gomp';
        TextColor3 = Library.AccentColor;
        TextSize = Library.IntroTextSize;
        TextStrokeTransparency = 0;
        Size = UDim2.fromOffset(180, 100);
        AnchorPoint = Vector2.new(0, 0.5);
        Position = UDim2.new(1.35, 0, 0.5, 0);
        TextTransparency = 1;
        ZIndex = 502;
        Parent = Group;
    });

    TweenService:Create(Gomp1, TweenInfo.new(2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 0, 0.5, 0);
    }):Play();

    WaitUntil(2);

    Gomp2.TextTransparency = 0;

    TweenService:Create(Gomp1, TweenInfo.new(1.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        AnchorPoint = Vector2.new(1, 0.5);
        Position = UDim2.new(0.5, -8, 0.5, 0),
    }):Play();

    TweenService:Create(Gomp2, TweenInfo.new(1.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, 8, 0.5, 0),
    }):Play();

    WaitUntil(4);
    WaitUntil(5.5);

    TweenService:Create(Gomp1, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 1;
    }):Play();

    TweenService:Create(Gomp2, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 1;
    }):Play();

    WaitUntil(IntroDuration);

    Intro:Destroy();

    FinishIntro();
end;

function Library:StartWatermark()
    if Library.WatermarkThread then
        return;
    end;

    Library.WatermarkThread = true;
    Library._WatermarkFPS = 0;
    Library._WatermarkFrames = 0;
    Library._WatermarkLast = tick();

    table.insert(Library.Signals, RunService.RenderStepped:Connect(function()
        Library._WatermarkFrames = Library._WatermarkFrames + 1;

        local Now = tick();
        if Now - Library._WatermarkLast >= 1 then
            Library._WatermarkFPS = Library._WatermarkFrames;
            Library._WatermarkFrames = 0;
            Library._WatermarkLast = Now;
        end;
    end));

    task.spawn(function()
        while not Library.Unloaded do
            local Accent = Library.AccentColor;
            local AccentRgb = string.format(
                '%d,%d,%d',
                math.floor(Accent.R * 255),
                math.floor(Accent.G * 255),
                math.floor(Accent.B * 255)
            );

            local Plain = string.format(
                'gomp gomp  %d fps  %s  %s  %d',
                Library._WatermarkFPS or 0,
                Library:FormatText(LocalPlayer.Name),
                os.date('%H:%M:%S'),
                LocalPlayer.UserId
            );

            local Text = string.format(
                '<font color="rgb(255,255,255)">gomp</font><font color="rgb(%s)">gomp</font>  %d fps  %s  %s  %d',
                AccentRgb,
                Library._WatermarkFPS or 0,
                Library:FormatText(LocalPlayer.Name),
                os.date('%H:%M:%S'),
                LocalPlayer.UserId
            );

            local X = select(1, Library:GetTextBounds(Plain, Library.Font, 14));
            Library.Watermark.Size = UDim2.new(0, math.max(X + 16, 200), 0, 22);
            Library.WatermarkText.Text = Text;

            task.wait(0.25);
        end;
    end);
end;

function Library:SetWatermark(Text)
    Library.WatermarkText.Text = Text;
    local X = select(1, Library:GetTextBounds(Text, Library.Font, 14));
    Library.Watermark.Size = UDim2.new(0, math.max(X + 16, 200), 0, 22);
end;

function Library:Notify(Text, Time)
    local XSize, YSize = Library:GetTextBounds(Text, Library.Font, 14);

    YSize = YSize + 7

    local NotifyOuter = Library:Create('Frame', {
        BorderColor3 = Color3.new(0, 0, 0);
        Position = UDim2.new(0, 100, 0, 10);
        Size = UDim2.new(0, 0, 0, YSize);
        ClipsDescendants = true;
        ZIndex = 100;
        Parent = Library.NotificationArea;
    });

    local NotifyInner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 101;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(NotifyInner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    }, true);

    local InnerFrame = Library:Create('Frame', {
        BackgroundColor3 = Color3.new(1, 1, 1);
        BorderSizePixel = 0;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 102;
        Parent = NotifyInner;
    });

    local Gradient = Library:Create('UIGradient', {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
            ColorSequenceKeypoint.new(1, Library.MainColor),
        });
        Rotation = -90;
        Parent = InnerFrame;
    });

    Library:AddToRegistry(Gradient, {
        Color = function()
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library:GetDarkerColor(Library.MainColor)),
                ColorSequenceKeypoint.new(1, Library.MainColor),
            });
        end
    });

    local NotifyLabel = Library:CreateLabel({
        Position = UDim2.new(0, 4, 0, 0);
        Size = UDim2.new(1, -4, 1, 0);
        Text = Text;
        RichText = true;
        TextXAlignment = Enum.TextXAlignment.Left;
        TextSize = 14;
        ZIndex = 103;
        Parent = InnerFrame;
    });

    local LeftColor = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Position = UDim2.new(0, -1, 0, -1);
        Size = UDim2.new(0, 3, 1, 2);
        ZIndex = 104;
        Parent = NotifyOuter;
    });

    Library:AddToRegistry(LeftColor, {
        BackgroundColor3 = 'AccentColor';
    }, true);

    pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, XSize + 8 + 4, 0, YSize), 'Out', 'Quad', 0.4, true);

    task.spawn(function()
        wait(Time or 5);

        pcall(NotifyOuter.TweenSize, NotifyOuter, UDim2.new(0, 0, 0, YSize), 'Out', 'Quad', 0.4, true);

        wait(0.4);

        NotifyOuter:Destroy();
    end);
end;

function Library:CreateWindow(...)
    local Arguments = { ... }
    local Config = { AnchorPoint = Vector2.zero }

    if type(...) == 'table' then
        Config = ...;
    else
        Config.Title = Arguments[1]
        Config.AutoShow = Arguments[2] or false;
    end
    
    if type(Config.Title) ~= 'string' then Config.Title = 'No title' end
    
    if typeof(Config.Position) ~= 'UDim2' then Config.Position = UDim2.fromOffset(175, 50) end
    if typeof(Config.Size) ~= 'UDim2' then Config.Size = UDim2.fromOffset(750, 580) end

    if Config.Center then
        Config.AnchorPoint = Vector2.new(0.5, 0.5)
        Config.Position = UDim2.fromScale(0.5, 0.5)
    end

    local Window = {
        Tabs = {};
    };

    local Outer = Library:Create('Frame', {
        AnchorPoint = Config.AnchorPoint,
        BackgroundColor3 = Color3.new(0, 0, 0);
        BorderSizePixel = 0;
        Position = Config.Position,
        Size = Config.Size,
        Visible = false;
        ZIndex = 1;
        Parent = ScreenGui;
    });

    Library:MakeDraggable(Outer, 25);

    local Inner = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 1, 0, 1);
        Size = UDim2.new(1, -2, 1, -2);
        ZIndex = 2;
        Parent = Outer;
    });

    Library:AddToRegistry(Inner, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    local WindowLabel = Library:CreateLabel2({
        AnchorPoint = Vector2.new(0.5, 0);
        Position = UDim2.new(0.5, 0, 0, 0);
        Size = UDim2.new(1, 0, 0, 25);
        RichText = true;
        Text = Config.Title or '';
        TextXAlignment = Enum.TextXAlignment.Center;
        ZIndex = 1;
        Parent = Inner;
    });

    local MainSectionOuter = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 25);
        Size = UDim2.new(1, -16, 1, -33);
        ZIndex = 1;
        Parent = Inner;
    });

    Library:AddToRegistry(MainSectionOuter, {
        BackgroundColor3 = 'BackgroundColor';
        BorderColor3 = 'OutlineColor';
    });

    local MainSectionInner = Library:Create('Frame', {
        BackgroundColor3 = Library.BackgroundColor;
        BorderColor3 = Color3.new(0, 0, 0);
        BorderMode = Enum.BorderMode.Inset;
        Position = UDim2.new(0, 0, 0, 0);
        Size = UDim2.new(1, 0, 1, 0);
        ZIndex = 1;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(MainSectionInner, {
        BackgroundColor3 = 'BackgroundColor';
    });

    local Highlight = Library:Create('Frame', {
        BackgroundColor3 = Library.AccentColor;
        BorderSizePixel = 0;
        Size = UDim2.new(1, 0, 0, 1);
        ZIndex = 5;
        Parent = MainSectionOuter;
    });

    Library:AddToRegistry(Highlight, {
        BackgroundColor3 = 'AccentColor';
    });

    local TabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 8);
        Size = UDim2.new(1, -16, 0, 25);
        ZIndex = 1;
        Parent = MainSectionInner;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 0);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = TabArea;
    });

    local SubTabArea = Library:Create('Frame', {
        BackgroundTransparency = 1;
        Position = UDim2.new(0, 8, 0, 33);
        Size = UDim2.new(1, -16, 0, 22);
        Visible = false;
        ZIndex = 2;
        Parent = MainSectionInner;
    });

    Library:Create('UIListLayout', {
        Padding = UDim.new(0, 12);
        FillDirection = Enum.FillDirection.Horizontal;
        SortOrder = Enum.SortOrder.LayoutOrder;
        Parent = SubTabArea;
    });

    local TabContainer = Library:Create('Frame', {
        BackgroundColor3 = Library.MainColor;
        BorderColor3 = Library.OutlineColor;
        Position = UDim2.new(0, 8, 0, 34);
        Size = UDim2.new(1, -16, 1, -42);
        ZIndex = 2;
        Parent = MainSectionInner;
    });

    local function UpdateTabContainerLayout(HasSubTabs)
        if HasSubTabs then
            SubTabArea.Visible = true;
            TabContainer.Position = UDim2.new(0, 8, 0, 58);
            TabContainer.Size = UDim2.new(1, -16, 1, -66);
        else
            SubTabArea.Visible = false;
            TabContainer.Position = UDim2.new(0, 8, 0, 34);
            TabContainer.Size = UDim2.new(1, -16, 1, -42);
        end;
    end;

    Window.SubTabArea = SubTabArea;
    Window.UpdateTabContainerLayout = UpdateTabContainerLayout;

    Library:AddToRegistry(TabContainer, {
        BackgroundColor3 = 'MainColor';
        BorderColor3 = 'OutlineColor';
    });

    function Window:SetWindowTitle(Title)
        WindowLabel.Text = Title;
    end;

    function Window:AddTab(Name)
        Name = Library:FormatText(Name);

        local Tab = {
            Groupboxes = {};
            Tabboxes = {};
            SubTabs = {};
            SubTabCount = 0;
        };

        local TabButtonWidth = Library:GetTextBounds(Name, Library.Font, 16);

        local TabButton = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(0, TabButtonWidth + 16, 1, 0);
            ZIndex = 1;
            Parent = TabArea;
        });

        local TabButtonLabel = Library:CreateLabel({
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, -1);
            Text = Name;
            ZIndex = 1;
            Parent = TabButton;
        });

        local Highlight = Library:Create('Frame', {
            BackgroundColor3 = Library.FontColor2;
            BorderSizePixel = 0;
            Size = UDim2.new(1, 0, 0, 1);
            Position = UDim2.new(0, 0, 1, -1);
            Visible = false;
            ZIndex = 3;
            Parent = TabButton;
        });

        Library:AddToRegistry(Highlight, {
            BackgroundColor3 = 'FontColor2';
        });

        local Blocker = Library:Create('Frame', {
            BackgroundTransparency = 1;
            BorderSizePixel = 0;
            Size = UDim2.new(0, 0, 0, 0);
            ZIndex = 3;
            Parent = TabButton;
        });

        local TabFrame = Library:Create('Frame', {
            Name = 'TabFrame';
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 0, 0, 0);
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = TabContainer;
        });

        local SubTabRow = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            Visible = false;
            ZIndex = 2;
            Parent = SubTabArea;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 12);
            FillDirection = Enum.FillDirection.Horizontal;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = SubTabRow;
        });

        Tab.SubTabRow = SubTabRow;

        local DefaultContent = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Size = UDim2.new(1, 0, 1, 0);
            ZIndex = 2;
            Parent = TabFrame;
        });

        local LeftSide = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0, 8, 0, 8);
            Size = UDim2.new(0.5, -12, 1, -16);
            ZIndex = 2;
            Parent = DefaultContent;
        });

        local RightSide = Library:Create('Frame', {
            BackgroundTransparency = 1;
            Position = UDim2.new(0.5, 4, 0, 8);
            Size = UDim2.new(0.5, -12, 1, -16);
            ZIndex = 2;
            Parent = DefaultContent;
        });

        Tab.ActiveContent = DefaultContent;
        Tab.LeftSide = LeftSide;
        Tab.RightSide = RightSide;

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = LeftSide;
        });

        Library:Create('UIListLayout', {
            Padding = UDim.new(0, 8);
            FillDirection = Enum.FillDirection.Vertical;
            SortOrder = Enum.SortOrder.LayoutOrder;
            Parent = RightSide;
        });

        function Tab:GetSides()
            return Tab.LeftSide, Tab.RightSide;
        end;

        function Tab:HideAllSubTabRows()
            for _, OtherTab in next, Window.Tabs do
                if OtherTab.SubTabRow then
                    OtherTab.SubTabRow.Visible = false;
                end;
            end;
        end;

        function Tab:ShowTab()
            for _, OtherTab in next, Window.Tabs do
                OtherTab:HideTab();
            end;

            TabFrame.Visible = true;
            TabButtonLabel.TextColor3 = Library.FontColor2;
            Highlight.Visible = true;
            Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = 'FontColor2';

            Tab:HideAllSubTabRows();

            if Tab.SubTabCount > 0 then
                SubTabRow.Visible = true;
                UpdateTabContainerLayout(true);

                if Tab.ActiveSubTabName and Tab.SubTabs[Tab.ActiveSubTabName] then
                    Tab.SubTabs[Tab.ActiveSubTabName]:Show();
                else
                    for _, SubTab in next, Tab.SubTabs do
                        SubTab:Show();
                        break;
                    end;
                end;
            else
                UpdateTabContainerLayout(false);
            end;
        end;


        function Tab:HideTab()
            TabButtonLabel.TextColor3 = Library.FontColor;
            Highlight.Visible = false;
            Library.RegistryMap[TabButtonLabel].Properties.TextColor3 = 'FontColor';
            TabFrame.Visible = false;

            if Tab.SubTabRow then
                Tab.SubTabRow.Visible = false;
            end;
        end;

        function Tab:AddSubTab(Name)
            Name = Library:FormatText(Name);
            Tab.SubTabCount = Tab.SubTabCount + 1;

            local SubTab = {
                Name = Name;
            };

            local Content = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Size = UDim2.new(1, 0, 1, 0);
                Visible = false;
                ZIndex = 2;
                Parent = TabFrame;
            });

            SubTab.LeftSide = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 8, 0, 8);
                Size = UDim2.new(0.5, -12, 1, -16);
                ZIndex = 2;
                Parent = Content;
            });

            SubTab.RightSide = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0.5, 4, 0, 8);
                Size = UDim2.new(0.5, -12, 1, -16);
                ZIndex = 2;
                Parent = Content;
            });

            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 8);
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = SubTab.LeftSide;
            });

            Library:Create('UIListLayout', {
                Padding = UDim.new(0, 8);
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = SubTab.RightSide;
            });

            SubTab.Content = Content;

            local ButtonWidth = Library:GetTextBounds(Name, Library.Font, 14);

            local SubTabButton = Library:Create('Frame', {
                BackgroundTransparency = 1;
                BorderSizePixel = 0;
                Size = UDim2.new(0, ButtonWidth + 8, 1, 0);
                ZIndex = 3;
                Parent = SubTabRow;
            });

            local SubTabLabel = Library:CreateLabel({
                Size = UDim2.new(1, 0, 1, -2);
                TextSize = 14;
                Text = Name;
                ZIndex = 4;
                Parent = SubTabButton;
            });

            local SubTabUnderline = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Position = UDim2.new(0, 0, 1, -1);
                Size = UDim2.new(1, 0, 0, 1);
                Visible = false;
                ZIndex = 4;
                Parent = SubTabButton;
            });

            Library:AddToRegistry(SubTabUnderline, {
                BackgroundColor3 = 'AccentColor';
            });

            function SubTab:Show()
                for _, Other in next, Tab.SubTabs do
                    Other:Hide();
                end;

                Content.Visible = true;
                Tab.LeftSide = SubTab.LeftSide;
                Tab.RightSide = SubTab.RightSide;
                Tab.ActiveSubTabName = Name;

                SubTabLabel.TextColor3 = Library.FontColor2;
                Library.RegistryMap[SubTabLabel].Properties.TextColor3 = 'FontColor2';
                SubTabUnderline.Visible = true;
            end;

            function SubTab:Hide()
                Content.Visible = false;
                SubTabLabel.TextColor3 = Library.FontColor;
                Library.RegistryMap[SubTabLabel].Properties.TextColor3 = 'FontColor';
                SubTabUnderline.Visible = false;
            end;

            function SubTab:AddGroupbox(Info)
                local Groupbox = {};
                Info.Name = Library:FormatText(Info.Name);

                local BoxOuter = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Library.OutlineColor;
                    Size = UDim2.new(1, 0, 0, 507);
                    ZIndex = 2;
                    Parent = Info.Side == 1 and SubTab.LeftSide or SubTab.RightSide;
                });

                Library:AddToRegistry(BoxOuter, {
                    BackgroundColor3 = 'BackgroundColor';
                    BorderColor3 = 'OutlineColor';
                });

                local BoxInner = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    BorderMode = Enum.BorderMode.Inset;
                    Size = UDim2.new(1, 0, 1, 0);
                    ZIndex = 4;
                    Parent = BoxOuter;
                });

                Library:AddToRegistry(BoxInner, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local BoxHighlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 1);
                    ZIndex = 5;
                    Parent = BoxInner;
                });

                Library:AddToRegistry(BoxHighlight, {
                    BackgroundColor3 = 'AccentColor';
                });

                Library:CreateLabel2({
                    Size = UDim2.new(1, 0, 0, 18);
                    Position = UDim2.new(0, 4, 0, 2);
                    TextSize = 14;
                    Text = Info.Name;
                    TextXAlignment = Enum.TextXAlignment.Left;
                    ZIndex = 5;
                    Parent = BoxInner;
                });

                local Container = Library:Create('Frame', {
                    BackgroundTransparency = 1;
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Groupbox:Resize()
                    local Size = 0;

                    for _, Element in next, Groupbox.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2);
                end;

                Groupbox.Container = Container;
                setmetatable(Groupbox, BaseGroupbox);

                Groupbox:AddBlank(3);
                Groupbox:Resize();

                return Groupbox;
            end;

            function SubTab:AddLeftGroupbox(BoxName)
                return SubTab:AddGroupbox({ Side = 1; Name = BoxName; });
            end;

            function SubTab:AddRightGroupbox(BoxName)
                return SubTab:AddGroupbox({ Side = 2; Name = BoxName; });
            end;

            SubTabButton.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                    SubTab:Show();
                end;
            end);

            Tab.SubTabs[Name] = SubTab;

            if Tab.SubTabCount == 1 then
                DefaultContent.Visible = false;
                SubTab:Show();
            end;

            if TabFrame.Visible then
                SubTabRow.Visible = true;
                UpdateTabContainerLayout(true);
            end;

            return SubTab;
        end;

        function Tab:AddGroupbox(Info)
            local Groupbox = {};
            Info.Name = Library:FormatText(Info.Name);

            local SideLeft, SideRight = Tab:GetSides();

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 0, 507);
                ZIndex = 2;
                Parent = Info.Side == 1 and SideLeft or SideRight;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 1);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local GroupboxLabel = Library:CreateLabel2({
                Size = UDim2.new(1, 0, 0, 18);
                Position = UDim2.new(0, 4, 0, 2);
                TextSize = 14;
                Text = Info.Name;
                TextXAlignment = Enum.TextXAlignment.Left;
                ZIndex = 5;
                Parent = BoxInner;
            });

            local Container = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 4, 0, 20);
                Size = UDim2.new(1, -4, 1, -20);
                ZIndex = 1;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Vertical;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = Container;
            });

            function Groupbox:Resize()
                local Size = 0;

                for _, Element in next, Groupbox.Container:GetChildren() do
                    if not Element:IsA('UIListLayout') then
                        Size = Size + Element.Size.Y.Offset;
                    end;
                end;

                BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2);
            end;

            Groupbox.Container = Container;
            setmetatable(Groupbox, BaseGroupbox);

            Groupbox:AddBlank(3);
            Groupbox:Resize();

            Tab.Groupboxes[Info.Name] = Groupbox;

            return Groupbox;
        end;

        function Tab:AddLeftGroupbox(Name)
            return Tab:AddGroupbox({ Side = 1; Name = Name; });
        end;

        function Tab:AddRightGroupbox(Name)
            return Tab:AddGroupbox({ Side = 2; Name = Name; });
        end;

        function Tab:AddTabbox(Info)
            local Tabbox = {
                Tabs = {};
            };

            local SideLeft, SideRight = Tab:GetSides();

            local BoxOuter = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Library.OutlineColor;
                Size = UDim2.new(1, 0, 0, 0);
                ZIndex = 2;
                Parent = Info.Side == 1 and SideLeft or SideRight;
            });

            Library:AddToRegistry(BoxOuter, {
                BackgroundColor3 = 'BackgroundColor';
                BorderColor3 = 'OutlineColor';
            });

            local BoxInner = Library:Create('Frame', {
                BackgroundColor3 = Library.BackgroundColor;
                BorderColor3 = Color3.new(0, 0, 0);
                BorderMode = Enum.BorderMode.Inset;
                Size = UDim2.new(1, 0, 1, 0);
                ZIndex = 4;
                Parent = BoxOuter;
            });

            Library:AddToRegistry(BoxInner, {
                BackgroundColor3 = 'BackgroundColor';
            });

            local Highlight = Library:Create('Frame', {
                BackgroundColor3 = Library.AccentColor;
                BorderSizePixel = 0;
                Size = UDim2.new(1, 0, 0, 1);
                ZIndex = 10;
                Parent = BoxInner;
            });

            Library:AddToRegistry(Highlight, {
                BackgroundColor3 = 'AccentColor';
            });

            local TabboxButtons = Library:Create('Frame', {
                BackgroundTransparency = 1;
                Position = UDim2.new(0, 0, 0, 1);
                Size = UDim2.new(1, 0, 0, 18);
                ZIndex = 5;
                Parent = BoxInner;
            });

            Library:Create('UIListLayout', {
                FillDirection = Enum.FillDirection.Horizontal;
                HorizontalAlignment = Enum.HorizontalAlignment.Left;
                SortOrder = Enum.SortOrder.LayoutOrder;
                Parent = TabboxButtons;
            });

            function Tabbox:AddTab(Name)
                local Tab = {};

                local Button = Library:Create('Frame', {
                    BackgroundColor3 = Library.MainColor;
                    BorderColor3 = Color3.new(0, 0, 0);
                    Size = UDim2.new(0.5, 0, 1, 0);
                    ZIndex = 6;
                    Parent = TabboxButtons;
                });

                Library:AddToRegistry(Button, {
                    BackgroundColor3 = 'MainColor';
                });

                local ButtonLabel = Library:CreateLabel2({
                    Size = UDim2.new(1, 0, 1, 0);
                    TextSize = 14;
                    Text = Name;
                    TextColor3 = Color3.fromRGB(198, 198, 198);
                    TextXAlignment = Enum.TextXAlignment.Center;
                    ZIndex = 7;
                    Parent = Button;
                });

                local Highlight = Library:Create('Frame', {
                    BackgroundColor3 = Library.AccentColor;
                    BorderSizePixel = 0;
                    Size = UDim2.new(1, 0, 0, 1);
                    ZIndex = 5;
                    Parent = ButtonLabel;
                });
    
                Library:AddToRegistry(Highlight, {
                    BackgroundColor3 = 'AccentColor';
                });

                local Block = Library:Create('Frame', {
                    BackgroundColor3 = Library.BackgroundColor;
                    BorderSizePixel = 0;
                    Position = UDim2.new(0, 0, 1, 0);
                    Size = UDim2.new(0.99, 0, 0, 1);
                    Visible = false;
                    ZIndex = 9;
                    Parent = Button;
                });

                Library:AddToRegistry(Block, {
                    BackgroundColor3 = 'BackgroundColor';
                });

                local Container = Library:Create('Frame', {
                    Position = UDim2.new(0, 4, 0, 20);
                    Size = UDim2.new(1, -4, 1, -20);
                    ZIndex = 1;
                    Visible = false;
                    Parent = BoxInner;
                });

                Library:Create('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical;
                    SortOrder = Enum.SortOrder.LayoutOrder;
                    Parent = Container;
                });

                function Tab:Show()
                    for _, Tab in next, Tabbox.Tabs do
                        Tab:Hide();
                    end;

                    Container.Visible = true;
                    Block.Visible = true;

                    Button.BackgroundColor3 = Library.BackgroundColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'BackgroundColor';
                end;

                function Tab:Hide()
                    Container.Visible = false;
                    Block.Visible = false;

                    Button.BackgroundColor3 = Library.MainColor;
                    Library.RegistryMap[Button].Properties.BackgroundColor3 = 'MainColor';
                end;

                function Tab:Resize()
                    local TabCount = 0;

                    for _, Tab in next, Tabbox.Tabs do
                        TabCount = TabCount +  1;
                    end;

                    for _, Button in next, TabboxButtons:GetChildren() do
                        if not Button:IsA('UIListLayout') then
                            Button.Size = UDim2.new(1 / TabCount, 0, 1, 0);
                        end;
                    end;

                    local Size = 0;

                    for _, Element in next, Tab.Container:GetChildren() do
                        if not Element:IsA('UIListLayout') then
                            Size = Size + Element.Size.Y.Offset;
                        end;
                    end;

                    if BoxOuter.Size.Y.Offset < 20 + Size + 2 then
                        BoxOuter.Size = UDim2.new(1, 0, 0, 20 + Size + 2);
                    end;
                end;

                Button.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 and not Library:MouseIsOverOpenedFrame() then
                        Tab:Show();
                    end;
                end);

                Tab.Container = Container;
                Tabbox.Tabs[Name] = Tab;

                setmetatable(Tab, BaseGroupbox);

                Tab:AddBlank(3);
                Tab:Resize();

                if #TabboxButtons:GetChildren() == 2 then
                    Tab:Show();
                end;

                return Tab;
            end;

            Tab.Tabboxes[Info.Name or ''] = Tabbox;

            return Tabbox;
        end;

        function Tab:AddLeftTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 1; });
        end;

        function Tab:AddRightTabbox(Name)
            return Tab:AddTabbox({ Name = Name, Side = 2; });
        end;

        TabButton.InputBegan:Connect(function(Input)
            if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                Tab:ShowTab();
            end;
        end);

        -- This was the first tab added, so we show it by default.
        if #TabContainer:GetChildren() == 1 then
            Tab:ShowTab();
        end;

        Window.Tabs[Name] = Tab;
        return Tab;
    end;

    local ModalElement = Library:Create('TextButton', {
        BackgroundTransparency = 1;
        Size = UDim2.new(0, 0, 0, 0);
        Visible = true;
        Text = '';
        Modal = false;
        Parent = ScreenGui;
    });

    function Library.Toggle()
        Outer.Visible = not Outer.Visible;
        ModalElement.Modal = Outer.Visible;

        local oIcon = Mouse.Icon;
        local State = InputService.MouseIconEnabled;

        local Cursor = Drawing.new('Triangle');
        Cursor.Thickness = 1;
        Cursor.Filled = true;

        while Outer.Visible do
            local mPos = Workspace.CurrentCamera:WorldToViewportPoint(Mouse.Hit.p);

            Cursor.Color = Library.AccentColor;
            Cursor.PointA = Vector2.new(mPos.X, mPos.Y);
            Cursor.PointB = Vector2.new(mPos.X, mPos.Y) + Vector2.new(6, 14);
            Cursor.PointC = Vector2.new(mPos.X, mPos.Y) + Vector2.new(-6, 14);

            Cursor.Visible = not InputService.MouseIconEnabled;

            RenderStepped:Wait();
        end;

        Cursor:Remove();
    end

    Library:GiveSignal(InputService.InputBegan:Connect(function(Input, Processed)
        if type(Library.ToggleKeybind) == 'table' and Library.ToggleKeybind.Type == 'KeyPicker' then
            if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode.Name == Library.ToggleKeybind.Value then
                task.spawn(Library.Toggle)
            end
        end

        if Input:IsModifierKeyDown(Enum.ModifierKey.Ctrl) and Outer.Visible then
            local HoveringColorPicker = nil

            for i, colorPicker in next, Options do
                if colorPicker.Type == 'ColorPicker' then
                    local displayFrame = colorPicker.DisplayFrame
                    local tabFrame = displayFrame and displayFrame:findFirstAncestor('TabFrame')

                    if tabFrame.Visible and Library:IsMouseOverFrame(colorPicker.DisplayFrame) then
                        HoveringColorPicker = colorPicker
                        break
                    end
                end
            end

            if not HoveringColorPicker then
                return
            end

            if Input.KeyCode == Enum.KeyCode.C then
                Library.ColorClipboard = HoveringColorPicker.Value
            elseif Input.KeyCode == Enum.KeyCode.V and Library.ColorClipboard then
                HoveringColorPicker:SetValueRGB(Library.ColorClipboard)
            end
        end
    end))

    Window.Holder = Outer;

    return Window;
end;

return Library
