local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local Library = {
	Flags = {},
	Elements = {},
	NotifyOrder = 0,
}

local Rows = {}
local Connections = {}
local Covers = {}
local GroupTweens = {}
local CoverTweens = {}
local ActiveLocks = {}
local CameraFrozen = false
local SavedCameraType
local Lucide

local function SinkInput()
	return Enum.ContextActionResult.Sink
end

local function FreezeCamera()
	local Current = workspace.CurrentCamera
	if CameraFrozen or not Current or not UserInputService.TouchEnabled then return end
	CameraFrozen = true
	SavedCameraType = Current.CameraType
	Current.CameraType = Enum.CameraType.Scriptable
end

local function ThawCamera()
	if not CameraFrozen then return end
	CameraFrozen = false
	local Current = workspace.CurrentCamera
	if Current then
		Current.CameraType = SavedCameraType or Enum.CameraType.Custom
	end
end

local function LockCamera(Name)
	ActiveLocks[Name] = true
	pcall(function()
		ContextActionService:BindActionAtPriority(
			Name,
			SinkInput,
			false,
			3000,
			Enum.UserInputType.MouseMovement,
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseWheel,
			Enum.UserInputType.Touch
		)
	end)
	FreezeCamera()
end

local function UnlockCamera(Name)
	ActiveLocks[Name] = nil
	pcall(function()
		ContextActionService:UnbindAction(Name)
	end)
	if next(ActiveLocks) == nil then
		ThawCamera()
	end
end

pcall(function()
	Lucide = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"))()
end)

local function ResolveIcon(Icon)
	if type(Icon) == "number" then return "rbxassetid://" .. Icon end
	if type(Icon) == "string" then
		if string.match(Icon, "^rbxassetid://") then return Icon end
		if string.match(Icon, "^%d+$") then return "rbxassetid://" .. Icon end
		local Name = string.lower(Icon)
		if type(Lucide) == "function" then
			local ok, Data = pcall(Lucide, Name)
			if ok and type(Data) == "table" then
				local Id = Data.id or Data.Id or Data[1]
				local Size = Data.imageRectSize or Data.ImageRectSize or Data[2]
				local Offset = Data.imageRectOffset or Data.imageRectPosition or Data.ImageRectOffset or Data[3]
				if Id then return "rbxassetid://" .. tostring(Id), Offset, Size end
			end
		elseif type(Lucide) == "table" then
			for _, Set in { Lucide["48px"], Lucide["256px"], Lucide } do
				if type(Set) == "table" then
					local Data = Set[Name]
					if type(Data) == "table" and Data[1] then
						return "rbxassetid://" .. tostring(Data[1]), Data[3], Data[2]
					end
				end
			end
		end
	end
	return "rbxassetid://0"
end

local function ToVector2(Value)
	if typeof(Value) == "Vector2" then return Value end
	if type(Value) == "table" then return Vector2.new(Value[1] or Value.X or 0, Value[2] or Value.Y or 0) end
	return Vector2.new(0, 0)
end

local function ApplyIcon(Object, Icon)
	if not Icon then return end
	local Image, Offset, Size = ResolveIcon(Icon)
	Object.Image = Image
	if Offset then Object.ImageRectOffset = ToVector2(Offset) end
	if Size then Object.ImageRectSize = ToVector2(Size) end
end

local Theme = {
	Window = Color3.fromHex("#141415"),
	Border = Color3.fromHex("#242525"),
	Sidebar = Color3.fromHex("#0f0e0f"),
	Main = Color3.fromHex("#090808"),
	CardBody = Color3.fromHex("#100f10"),
	Control = Color3.fromHex("#141415"),
	ControlHover = Color3.fromHex("#19191b"),
	TabIdle = Color3.fromHex("#040406"),
	TabHover = Color3.fromHex("#0c0c0e"),
	ItemHover = Color3.fromHex("#1e1e21"),
	Text = Color3.fromHex("#cfcfcf"),
	TextHover = Color3.fromHex("#b4b4b6"),
	Muted = Color3.fromHex("#838384"),
	Footer = Color3.fromHex("#8a8a8a"),
	Icon = Color3.fromHex("#878787"),
	Chevron = Color3.fromHex("#a7a7a7"),
	White = Color3.new(1, 1, 1),
	Black = Color3.new(0, 0, 0),
	Accent = Color3.fromHex("#6e7db7"),
	AccentTop = Color3.fromHex("#8799e1"),
	AccentBottom = Color3.fromHex("#505b85"),
	TabTop = Color3.fromHex("#8190cc"),
	TabBottom = Color3.fromHex("#4f5a80"),
	OffTrack = Color3.fromHex("#1f1f22"),
	OffKnob = Color3.fromHex("#6b6b70"),
}

local FontFamily = "rbxasset://fonts/families/GothamSSm.json"

local function New(Class, Props, Children)
	local Object = Instance.new(Class)
	local Parent
	for Key, Value in pairs(Props or {}) do
		if Key == "Parent" then
			Parent = Value
		else
			Object[Key] = Value
		end
	end
	for _, Child in ipairs(Children or {}) do
		Child.Parent = Object
	end
	if Parent then Object.Parent = Parent end
	return Object
end

local function Tween(Object, Time, Props, Style, Direction)
	local Info = TweenInfo.new(Time, Style or Enum.EasingStyle.Quint, Direction or Enum.EasingDirection.Out)
	local Playing = TweenService:Create(Object, Info, Props)
	Playing:Play()
	return Playing
end

local function MakeFont(Weight)
	return Font.new(FontFamily, Weight)
end

local function Corner(Parent, Radius)
	return New("UICorner", { Parent = Parent, CornerRadius = UDim.new(0, Radius) })
end

local function Round(Parent)
	return New("UICorner", { Parent = Parent, CornerRadius = UDim.new(1, 0) })
end

local function Stroke(Parent, Color, Transparency)
	return New("UIStroke", {
		Parent = Parent,
		Color = Color,
		Thickness = 1,
		Transparency = Transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Gradient(Parent, Top, Bottom, Rotation)
	return New("UIGradient", {
		Parent = Parent,
		Color = ColorSequence.new(Top, Bottom),
		Rotation = Rotation,
	})
end

local function Panel(Parent, Color, Position, Size)
	return New("Frame", {
		Parent = Parent,
		BackgroundColor3 = Color,
		BorderSizePixel = 0,
		Position = Position,
		Size = Size,
	})
end

local function Label(Parent, Content, Size, Weight, Color, Position, BoxSize, Align)
	return New("TextLabel", {
		Parent = Parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = Content,
		TextSize = Size,
		FontFace = MakeFont(Weight),
		TextColor3 = Color,
		Position = Position,
		Size = BoxSize,
		TextXAlignment = Align or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

local function Icon(Parent, Name, Size, Color, Position, Anchor, Class)
	local Image = New(Class or "ImageLabel", {
		Parent = Parent,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(Size, Size),
		Position = Position,
		AnchorPoint = Anchor or Vector2.zero,
		ImageColor3 = Color,
	})
	ApplyIcon(Image, Name)
	return Image
end

local function IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

local function IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

local function Pointer(Input)
	if Input.UserInputType == Enum.UserInputType.Touch then
		local Inset = GuiService:GetGuiInset()
		return Vector2.new(Input.Position.X + Inset.X, Input.Position.Y + Inset.Y)
	end
	return UserInputService:GetMouseLocation()
end

local function Connect(Signal, Callback)
	local Connection = Signal:Connect(Callback)
	table.insert(Connections, Connection)
	return Connection
end

local function Drag(Scroller, Begin, Move, Finish)
	local Active
	Connect(UserInputService.InputChanged, function(Input)
		if not Active or not IsMove(Input) then return end
		if Active.UserInputType == Enum.UserInputType.Touch then
			if Input ~= Active then return end
		elseif Input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		Move(Input)
	end)
	Connect(UserInputService.InputEnded, function(Input)
		if not Active then return end
		if Input == Active or (Input.UserInputType == Enum.UserInputType.MouseButton1 and Active.UserInputType == Enum.UserInputType.MouseButton1) then
			Active = nil
			UnlockCamera("LibraryDrag")
			if Scroller then Scroller.ScrollingEnabled = true end
			if Finish then Finish() end
		end
	end)
	return function(Target)
		Target.InputBegan:Connect(function(Input)
			if Active or not IsPress(Input) then return end
			Active = Input
			LockCamera("LibraryDrag")
			if Scroller then Scroller.ScrollingEnabled = false end
			Begin(Input)
		end)
	end
end

local function ShowGroup(Group, Base, Shift, Instant, Delay)
	local Cover = Covers[Group]
	if GroupTweens[Group] then GroupTweens[Group]:Cancel() end
	if CoverTweens[Cover] then CoverTweens[Cover]:Cancel() end
	Group:SetAttribute("Shown", true)
	Group.Visible = true
	if Instant then
		Cover.Visible = false
		Group.Position = Base
		return
	end
	Cover.BackgroundTransparency = 0
	Cover.Visible = true
	Group.Position = Base + UDim2.fromOffset(0, Shift)
	task.delay(Delay or 0, function()
		if Group:GetAttribute("Shown") then
			GroupTweens[Group] = Tween(Group, 0.45, { Position = Base })
			local Reveal = Tween(Cover, 0.45, { BackgroundTransparency = 1 })
			CoverTweens[Cover] = Reveal
			Reveal.Completed:Connect(function(State)
				if State == Enum.PlaybackState.Completed and Group:GetAttribute("Shown") then
					Cover.Visible = false
				end
			end)
		end
	end)
end

local function HideGroup(Group)
	if not Group.Visible then return end
	Group:SetAttribute("Shown", false)
	if GroupTweens[Group] then GroupTweens[Group]:Cancel() end
	if Group:GetAttribute("Shared") then
		Group.Visible = false
		return
	end
	local Cover = Covers[Group]
	if CoverTweens[Cover] then CoverTweens[Cover]:Cancel() end
	Cover.Visible = true
	local Fade = Tween(Cover, 0.16, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
	CoverTweens[Cover] = Fade
	Fade.Completed:Connect(function(State)
		if State == Enum.PlaybackState.Completed and Group:GetAttribute("Shown") == false then
			Group.Visible = false
			Cover.Visible = false
		end
	end)
end

local function MakeButton(Parent, Text, Position, Width, Callback)
	local Button = New("TextButton", {
		Parent = Parent,
		Position = Position,
		Size = UDim2.fromOffset(Width, 24),
		BackgroundColor3 = Theme.Control,
		BorderSizePixel = 0,
		Text = Text,
		TextSize = 12,
		FontFace = MakeFont(Enum.FontWeight.Medium),
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
	})
	Corner(Button, 4)
	local Ring = Stroke(Button, Theme.Border)
	Button.MouseEnter:Connect(function()
		Tween(Button, 0.2, { BackgroundColor3 = Theme.ControlHover, TextColor3 = Theme.White })
		Tween(Ring, 0.2, { Color = Theme.Accent })
	end)
	Button.MouseLeave:Connect(function()
		Tween(Button, 0.2, { BackgroundColor3 = Theme.Control, TextColor3 = Theme.Text })
		Tween(Ring, 0.2, { Color = Theme.Border })
	end)
	Button.MouseButton1Down:Connect(function()
		Tween(Button, 0.1, { BackgroundColor3 = Theme.Accent })
	end)
	Button.MouseButton1Up:Connect(function()
		Tween(Button, 0.2, { BackgroundColor3 = Theme.ControlHover })
	end)
	Button.MouseButton1Click:Connect(Callback)
	return Button
end

local function MakeColumn(Page, X)
	return New("ScrollingFrame", {
		Parent = Page,
		Position = UDim2.fromOffset(X, 0),
		Size = UDim2.fromOffset(280, 384),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 11) }),
		New("UIPadding", { PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 11) }),
	})
end

local function MakeCard(Parent, Order, Title, IconName)
	local Card = New("Frame", {
		Parent = Parent,
		LayoutOrder = Order,
		Size = UDim2.fromOffset(274, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.CardBody,
		BorderSizePixel = 0,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	Corner(Card, 6)
	Stroke(Card, Theme.Border)

	local Header = New("Frame", {
		Parent = Card,
		LayoutOrder = 1,
		Size = UDim2.fromOffset(274, 35),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
	})
	Corner(Header, 6)
	Panel(Header, Theme.Window, UDim2.fromOffset(0, 29), UDim2.fromOffset(274, 6))
	if IconName then
		Icon(Header, IconName, 18, Theme.White, UDim2.fromOffset(8, 9))
	end
	Label(Header, Title, 13, Enum.FontWeight.Bold, Theme.White, UDim2.fromOffset(IconName and 32 or 10, 0), UDim2.fromOffset(200, 35))

	return New("Frame", {
		Parent = Card,
		LayoutOrder = 2,
		Size = UDim2.fromOffset(274, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 11),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
		}),
	})
end

local function MakeBlock(Section, Height, Name)
	Section.Order = Section.Order + 1
	local Frame = New("Frame", {
		Parent = Section.Body,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Height),
		LayoutOrder = Section.Order,
	})
	table.insert(Rows, { Frame = Frame, Name = string.lower(Name or "") })
	return Frame
end

local function Publish(Props, Value)
	if Props.Flag then
		Library.Flags[Props.Flag] = Value
	end
end

local function Expose(Props, Export, Import)
	if Props.Flag then
		Library.Elements[Props.Flag] = { Export = Export, Import = Import }
	end
end

local function Fire(Props, ...)
	if Props.Callback then
		task.spawn(Props.Callback, ...)
	end
end

local Section = {}
Section.__index = Section

function Section:Label(Props)
	if type(Props) == "string" then Props = { Name = Props } end
	local Block = MakeBlock(self, 22, Props.Name)
	local Text = Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.new(1, -1, 0, 14))
	local Object = {}
	function Object:Set(Value)
		Text.Text = tostring(Value)
	end
	return Object
end

function Section:Button(Props)
	local Block = MakeBlock(self, 34, Props.Name)
	local Button = MakeButton(Block, Props.Name, UDim2.fromOffset(0, 0), 254, function()
		Fire(Props)
	end)
	local Object = {}
	function Object:SetText(Value)
		Button.Text = Value
	end
	return Object
end

function Section:ButtonRow(Props)
	local Block = MakeBlock(self, 34, Props.Name or "")
	local Count = #Props.Buttons
	local Width = (254 - (Count - 1) * 4) / Count
	for Index, Data in ipairs(Props.Buttons) do
		MakeButton(Block, Data.Name, UDim2.fromOffset((Index - 1) * (Width + 4), 0), Width, function()
			if Data.Callback then task.spawn(Data.Callback) end
		end)
	end
end

function Section:Toggle(Props)
	local Block = MakeBlock(self, 25, Props.Name)
	local State = Props.Default == true
	local Track = New("Frame", {
		Parent = Block,
		Size = UDim2.fromOffset(28, 14),
		BackgroundColor3 = Theme.OffTrack,
		BorderSizePixel = 0,
	})
	Round(Track)
	local Fill = New("Frame", {
		Parent = Track,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
	})
	Round(Fill)
	Gradient(Fill, Theme.AccentTop, Theme.AccentBottom, 90)
	local Knob = New("Frame", {
		Parent = Track,
		ZIndex = 2,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 15, 0.5, 0),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Theme.Black,
		BorderSizePixel = 0,
	})
	Round(Knob)
	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(39, 0), UDim2.fromOffset(200, 14))
	local Hit = New("TextButton", {
		Parent = Block,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local Object = {}

	local function Apply(Value, Instant)
		State = Value
		local Time = Instant and 0 or 0.3
		Tween(Fill, Time, { BackgroundTransparency = State and 0 or 1 })
		Tween(Knob, Time, {
			Position = UDim2.new(0, State and 15 or 3, 0.5, 0),
			BackgroundColor3 = State and Theme.Black or Theme.OffKnob,
		})
		Publish(Props, State)
	end

	function Object:Set(Value)
		if Value == State then return end
		Apply(Value)
		Fire(Props, State)
	end

	function Object:Get()
		return State
	end

	Hit.MouseButton1Click:Connect(function()
		Object:Set(not State)
	end)

	Apply(State, true)
	Expose(Props, function()
		return State
	end, function(Value)
		Object:Set(Value == true)
	end)
	return Object
end

function Section:Slider(Props)
	local Min = Props.Min or 0
	local Max = Props.Max or 100
	local Step = Props.Increment or 1
	local Suffix = Props.Suffix or ""
	local Decimals = 0
	local StepText = tostring(Step)
	local Dot = string.find(StepText, ".", 1, true)
	if Dot then Decimals = #StepText - Dot end
	local Format = "%." .. Decimals .. "f"

	local Block = MakeBlock(self, 39, Props.Name)
	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.fromOffset(150, 13))
	local ValueLabel = Label(Block, "", 12, Enum.FontWeight.Bold, Theme.White, UDim2.new(1, 0, 0, 0), UDim2.fromOffset(80, 13), Enum.TextXAlignment.Right)
	ValueLabel.AnchorPoint = Vector2.new(1, 0)

	local Track = New("TextButton", {
		Parent = Block,
		Position = UDim2.fromOffset(0, 17),
		Size = UDim2.fromOffset(254, 12),
		BackgroundColor3 = Theme.Control,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	Corner(Track, 3)
	local Fill = New("Frame", {
		Parent = Track,
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
	})
	Corner(Fill, 3)
	Gradient(Fill, Theme.AccentTop, Theme.AccentBottom, 90)
	local Knob = New("Frame", {
		Parent = Track,
		ZIndex = 2,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Black,
		BorderSizePixel = 0,
	})
	Round(Knob)

	local Value = Min
	local Sliding = false
	local Hovering = false
	local Object = {}

	local function KnobSize()
		local Diameter = Sliding and 11 or (Hovering and 10 or 8)
		Tween(Knob, 0.2, { Size = UDim2.fromOffset(Diameter, Diameter) })
	end

	local function Apply(Raw, Instant)
		Raw = math.clamp(Raw, Min, Max)
		Raw = math.floor((Raw - Min) / Step + 0.5) * Step + Min
		Value = math.clamp(tonumber(string.format(Format, Raw)), Min, Max)
		local Ratio = Max > Min and (Value - Min) / (Max - Min) or 0
		local Width = Ratio * 254
		local KnobPosition = UDim2.new(0, math.max(Width - 7.5, 4.5), 0.5, 0)
		if Instant then
			Fill.Size = UDim2.new(0, Width, 1, 0)
			Knob.Position = KnobPosition
		else
			Tween(Fill, 0.2, { Size = UDim2.new(0, Width, 1, 0) })
			Tween(Knob, 0.2, { Position = KnobPosition })
		end
		ValueLabel.Text = string.format(Format, Value) .. Suffix
		Publish(Props, Value)
	end

	local function FromInput(Input)
		local Ratio = math.clamp((Pointer(Input).X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
		local Before = Value
		Apply(Min + (Max - Min) * Ratio, true)
		if Value ~= Before then Fire(Props, Value) end
	end

	Track.MouseEnter:Connect(function()
		Hovering = true
		KnobSize()
	end)
	Track.MouseLeave:Connect(function()
		Hovering = false
		KnobSize()
	end)

	Drag(self.Scroller, function(Input)
		Sliding = true
		KnobSize()
		FromInput(Input)
	end, FromInput, function()
		Sliding = false
		KnobSize()
	end)(Track)

	function Object:Set(Raw)
		if type(Raw) ~= "number" then return end
		local Before = Value
		Apply(Raw)
		if Value ~= Before then Fire(Props, Value) end
	end

	function Object:Get()
		return Value
	end

	Apply(Props.Default or Min, true)
	Expose(Props, function()
		return Value
	end, function(Raw)
		Object:Set(Raw)
	end)
	return Object
end

function Section:Dropdown(Props)
	local Multi = Props.Multi == true
	local Searchable = Props.Searchable == true
	local Options = Props.Options or {}
	local Block = MakeBlock(self, 51, Props.Name)
	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.fromOffset(150, 13))

	local Header = New("TextButton", {
		Parent = Block,
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.fromOffset(254, 24),
		BackgroundColor3 = Theme.Control,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	Corner(Header, 5)
	local HeaderStroke = Stroke(Header, Theme.Border)
	local HeaderLabel = Label(Header, "", 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(10, 0), UDim2.new(1, -40, 1, 0))
	HeaderLabel.TextTruncate = Enum.TextTruncate.AtEnd
	local Chevron = Icon(Header, "chevron-down", 18, Theme.Chevron, UDim2.fromOffset(237, 12), Vector2.new(0.5, 0.5))
	Header.MouseEnter:Connect(function()
		Tween(Header, 0.2, { BackgroundColor3 = Theme.ControlHover })
	end)
	Header.MouseLeave:Connect(function()
		Tween(Header, 0.2, { BackgroundColor3 = Theme.Control })
	end)

	local ListTop = Searchable and 32 or 0
	local MaxVisible = 5
	local Height = 0
	local Opened = false
	local Entries = {}
	local Selected = {}
	local Single
	local Object = {}

	if Multi then
		if type(Props.Default) == "table" then
			for _, Name in ipairs(Props.Default) do Selected[Name] = true end
		end
	else
		Single = Props.Default
	end

	local Holder = New("Frame", {
		Parent = Block,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.fromOffset(254, 0),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
	})
	Corner(Holder, 6)
	Stroke(Holder, Theme.Border)

	local SearchBox
	if Searchable then
		local SearchBack = Panel(Holder, Theme.Control, UDim2.fromOffset(4, 4), UDim2.fromOffset(246, 24))
		Corner(SearchBack, 4)
		local SearchRing = Stroke(SearchBack, Theme.Accent, 1)
		Icon(SearchBack, "search", 14, Theme.Muted, UDim2.fromOffset(7, 5))
		SearchBox = New("TextBox", {
			Parent = SearchBack,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(28, 0),
			Size = UDim2.new(1, -34, 1, 0),
			Text = "",
			PlaceholderText = "Search...",
			PlaceholderColor3 = Theme.Muted,
			ClearTextOnFocus = false,
			TextSize = 12,
			FontFace = MakeFont(Enum.FontWeight.Medium),
			TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClipsDescendants = true,
		})
		SearchBox.Focused:Connect(function()
			Tween(SearchRing, 0.25, { Transparency = 0.3 })
		end)
		SearchBox.FocusLost:Connect(function()
			Tween(SearchRing, 0.3, { Transparency = 1 })
		end)
	end

	local List = New("ScrollingFrame", {
		Parent = Holder,
		Position = UDim2.fromOffset(0, ListTop),
		Size = UDim2.fromOffset(254, 34),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	})

	local Empty = Label(Holder, "No results", 12, Enum.FontWeight.Medium, Theme.Muted, UDim2.fromOffset(0, ListTop), UDim2.fromOffset(254, 34), Enum.TextXAlignment.Center)
	Empty.Visible = false

	local function ListHeightFor(Visible)
		local Lines = math.min(math.max(Visible, 1), MaxVisible)
		return Lines * 26 + (Lines - 1) * 2 + 8
	end

	local function Snapshot()
		if not Multi then return Single end
		local Copy = {}
		for Name, On in pairs(Selected) do
			if On then Copy[Name] = true end
		end
		return Copy
	end

	local function Display()
		if Multi then
			local Names = {}
			for _, Option in ipairs(Options) do
				if Selected[Option] then table.insert(Names, Option) end
			end
			return #Names > 0 and table.concat(Names, ", ") or "None"
		end
		return Single or "None"
	end

	local function IsOn(Option)
		if Multi then return Selected[Option] == true end
		return Single == Option
	end

	local function Paint(Instant)
		local Time = Instant and 0 or 0.2
		HeaderLabel.Text = Display()
		HeaderLabel.TextColor3 = HeaderLabel.Text == "None" and Theme.Muted or Theme.Text
		for Option, Entry in pairs(Entries) do
			local On = IsOn(Option)
			Tween(Entry.Fill, Time, { BackgroundTransparency = (not Multi and On) and 0 or 1 })
			Tween(Entry.Label, Time, { TextColor3 = On and Theme.White or Theme.Text })
			Tween(Entry.Check, Time, { ImageTransparency = On and 0 or 1 })
		end
		Publish(Props, Snapshot())
	end

	local function Resize(Visible)
		local ListHeight = ListHeightFor(Visible)
		Height = ListTop + ListHeight
		List.Size = UDim2.fromOffset(254, ListHeight)
		Empty.Size = UDim2.fromOffset(254, ListHeightFor(1))
		if Opened then
			Tween(Holder, 0.2, { Size = UDim2.fromOffset(254, Height) })
			Tween(Block, 0.2, { Size = UDim2.new(1, 0, 0, 51 + Height) })
		end
	end

	local function Refilter()
		local Query = SearchBox and string.lower(SearchBox.Text) or ""
		local Visible = 0
		for Option, Entry in pairs(Entries) do
			local Match = Query == "" or string.find(string.lower(Option), Query, 1, true) ~= nil
			Entry.Item.Visible = Match
			if Match then Visible = Visible + 1 end
		end
		Empty.Visible = Visible == 0
		List.CanvasPosition = Vector2.zero
		Resize(Visible)
	end

	if SearchBox then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(Refilter)
	end

	local function SetOpen(State)
		if Opened == State then return end
		Opened = State
		Tween(Chevron, 0.35, { Rotation = State and 180 or 0 })
		Tween(HeaderStroke, 0.25, { Color = State and Theme.Accent or Theme.Border })
		if State then
			Holder.Visible = true
			Tween(Holder, 0.32, { Size = UDim2.fromOffset(254, Height) })
			Tween(Block, 0.32, { Size = UDim2.new(1, 0, 0, 51 + Height) })
		else
			local Closing = Tween(Holder, 0.22, { Size = UDim2.fromOffset(254, 0) })
			Tween(Block, 0.22, { Size = UDim2.new(1, 0, 0, 51) })
			Closing.Completed:Connect(function(Result)
				if Result == Enum.PlaybackState.Completed and not Opened then
					Holder.Visible = false
					if SearchBox and SearchBox.Text ~= "" then
						SearchBox.Text = ""
					end
				end
			end)
		end
	end

	local function Pick(Option)
		if Multi then
			Selected[Option] = Selected[Option] ~= true and true or nil
		else
			Single = Option
		end
		Paint()
		Fire(Props, Snapshot())
		if not Multi then SetOpen(false) end
	end

	local function Build()
		for _, Entry in pairs(Entries) do
			Entry.Item:Destroy()
		end
		Entries = {}
		MaxVisible = Searchable and 5 or math.min(math.max(#Options, 1), 6)
		for Index, Option in ipairs(Options) do
			local Item = New("TextButton", {
				Parent = List,
				LayoutOrder = Index,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundColor3 = Theme.ItemHover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
			})
			Corner(Item, 4)
			local Fill = New("Frame", {
				Parent = Item,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			})
			Corner(Fill, 4)
			Gradient(Fill, Theme.TabTop, Theme.TabBottom, 100)
			local ItemLabel = Label(Item, Option, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(10, 0), UDim2.new(1, -40, 1, 0))
			ItemLabel.ZIndex = 2
			local Check = Icon(Item, "check", 14, Multi and Theme.AccentTop or Theme.White, UDim2.new(1, -16, 0.5, 0), Vector2.new(0.5, 0.5))
			Check.ZIndex = 2
			Check.ImageTransparency = 1
			Entries[Option] = { Item = Item, Fill = Fill, Label = ItemLabel, Check = Check }
			Item.MouseEnter:Connect(function()
				Tween(Item, 0.15, { BackgroundTransparency = 0 })
			end)
			Item.MouseLeave:Connect(function()
				Tween(Item, 0.15, { BackgroundTransparency = 1 })
			end)
			Item.MouseButton1Click:Connect(function()
				Pick(Option)
			end)
		end
		Refilter()
		Paint(true)
	end

	Header.MouseButton1Click:Connect(function()
		SetOpen(not Opened)
	end)

	function Object:Set(Value)
		if Multi then
			if type(Value) ~= "table" then return end
			Selected = {}
			for Key, Name in pairs(Value) do
				if type(Key) == "number" then
					Selected[Name] = true
				elseif Name == true then
					Selected[Key] = true
				end
			end
		else
			Single = type(Value) == "string" and Value or nil
		end
		Paint()
		Fire(Props, Snapshot())
	end

	function Object:Get()
		return Snapshot()
	end

	function Object:SetOptions(NewOptions)
		Options = NewOptions
		if Multi then
			for Name in pairs(Selected) do
				if not table.find(Options, Name) then Selected[Name] = nil end
			end
		elseif Single and not table.find(Options, Single) then
			Single = nil
		end
		Build()
	end

	Build()
	Expose(Props, function()
		if not Multi then return Single end
		local Names = {}
		for _, Option in ipairs(Options) do
			if Selected[Option] then table.insert(Names, Option) end
		end
		return Names
	end, function(Value)
		Object:Set(Value)
	end)
	return Object
end

function Section:Input(Props)
	local Block = MakeBlock(self, 49, Props.Name)
	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.fromOffset(150, 13))
	local Frame = Panel(Block, Theme.Control, UDim2.fromOffset(0, 17), UDim2.fromOffset(254, 22))
	Corner(Frame, 4)
	local Ring = Stroke(Frame, Theme.Accent, 1)
	local Box = New("TextBox", {
		Parent = Frame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = Props.Default or "",
		PlaceholderText = Props.Placeholder or "",
		PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false,
		TextSize = 12,
		FontFace = MakeFont(Enum.FontWeight.Medium),
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	})
	local Pencil = Icon(Frame, "pencil", 16, Theme.Text, UDim2.fromOffset(229, 3), nil, "ImageButton")
	Pencil.MouseEnter:Connect(function()
		Tween(Pencil, 0.2, { ImageColor3 = Theme.White })
	end)
	Pencil.MouseLeave:Connect(function()
		Tween(Pencil, 0.2, { ImageColor3 = Theme.Text })
	end)
	Pencil.MouseButton1Click:Connect(function()
		Box:CaptureFocus()
	end)
	Box.Focused:Connect(function()
		Tween(Ring, 0.25, { Transparency = 0.3 })
		Tween(Frame, 0.25, { BackgroundColor3 = Theme.ControlHover })
	end)
	Box.FocusLost:Connect(function()
		Tween(Ring, 0.3, { Transparency = 1 })
		Tween(Frame, 0.3, { BackgroundColor3 = Theme.Control })
		Fire(Props, Box.Text)
	end)
	Box:GetPropertyChangedSignal("Text"):Connect(function()
		Publish(Props, Box.Text)
	end)

	local Object = {}
	function Object:Set(Value)
		Box.Text = tostring(Value)
	end
	function Object:Get()
		return Box.Text
	end

	Publish(Props, Box.Text)
	Expose(Props, function()
		return Box.Text
	end, function(Value)
		if type(Value) == "string" then
			Box.Text = Value
			Fire(Props, Value)
		end
	end)
	return Object
end

function Section:ColorPicker(Props)
	local Block = MakeBlock(self, 25, Props.Name)
	local Color = Props.Default or Color3.new(1, 1, 1)
	local Hue, Sat, Val = Color:ToHSV()
	local Opened = false
	local PickerHeight = 176

	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.fromOffset(180, 14))
	local Swatch = New("Frame", {
		Parent = Block,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(245, 7),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color,
		BorderSizePixel = 0,
	})
	Round(Swatch)
	local Hit = New("TextButton", {
		Parent = Block,
		Size = UDim2.new(1, 0, 0, 14),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})
	Hit.MouseEnter:Connect(function()
		Tween(Swatch, 0.2, { Size = UDim2.fromOffset(17, 17) })
	end)
	Hit.MouseLeave:Connect(function()
		Tween(Swatch, 0.2, { Size = UDim2.fromOffset(14, 14) })
	end)

	local Holder = New("Frame", {
		Parent = Block,
		Position = UDim2.fromOffset(0, 29),
		Size = UDim2.fromOffset(254, 0),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Visible = false,
		ClipsDescendants = true,
	})
	Corner(Holder, 5)
	Stroke(Holder, Theme.Border)

	local SV = New("Frame", {
		Parent = Holder,
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(238, 110),
		BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
		BorderSizePixel = 0,
	})
	Corner(SV, 4)
	local WhiteLayer = New("Frame", {
		Parent = SV,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
	})
	Corner(WhiteLayer, 4)
	New("UIGradient", { Parent = WhiteLayer, Transparency = NumberSequence.new(0, 1) })
	local BlackLayer = New("Frame", {
		Parent = SV,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Black,
		BorderSizePixel = 0,
	})
	Corner(BlackLayer, 4)
	New("UIGradient", { Parent = BlackLayer, Rotation = 90, Transparency = NumberSequence.new(1, 0) })
	local SVCursor = New("Frame", {
		Parent = SV,
		ZIndex = 3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = Color,
		BorderSizePixel = 0,
	})
	Round(SVCursor)
	New("UIStroke", {
		Parent = SVCursor,
		Color = Theme.White,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local SVHit = New("TextButton", {
		Parent = SV,
		ZIndex = 4,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local HueKeys = {}
	for Index = 0, 6 do
		table.insert(HueKeys, ColorSequenceKeypoint.new(Index / 6, Color3.fromHSV((Index / 6) % 1, 1, 1)))
	end
	local HueBar = New("Frame", {
		Parent = Holder,
		Position = UDim2.fromOffset(8, 126),
		Size = UDim2.fromOffset(238, 10),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
	})
	Round(HueBar)
	New("UIGradient", { Parent = HueBar, Color = ColorSequence.new(HueKeys) })
	local HueKnob = New("Frame", {
		Parent = HueBar,
		ZIndex = 3,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
		BorderSizePixel = 0,
	})
	Round(HueKnob)
	New("UIStroke", {
		Parent = HueKnob,
		Color = Theme.White,
		Thickness = 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
	local HueHit = New("TextButton", {
		Parent = HueBar,
		ZIndex = 4,
		Position = UDim2.fromOffset(0, -4),
		Size = UDim2.new(1, 0, 1, 8),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local Preview = New("Frame", {
		Parent = Holder,
		Position = UDim2.fromOffset(8, 144),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Color,
		BorderSizePixel = 0,
	})
	Corner(Preview, 4)
	local HexFrame = Panel(Holder, Theme.Main, UDim2.fromOffset(36, 144), UDim2.fromOffset(210, 22))
	Corner(HexFrame, 4)
	local HexStroke = Stroke(HexFrame, Theme.Accent, 1)
	local HexBox = New("TextBox", {
		Parent = HexFrame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(1, -16, 1, 0),
		Text = "",
		PlaceholderText = "#FFFFFF",
		PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false,
		TextSize = 12,
		FontFace = MakeFont(Enum.FontWeight.Medium),
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	})

	local Object = {}

	local function Apply(Silent)
		Color = Color3.fromHSV(Hue, Sat, Val)
		local Base = Color3.fromHSV(Hue, 1, 1)
		Swatch.BackgroundColor3 = Color
		Preview.BackgroundColor3 = Color
		SV.BackgroundColor3 = Base
		SVCursor.BackgroundColor3 = Color
		SVCursor.Position = UDim2.fromScale(Sat, 1 - Val)
		HueKnob.BackgroundColor3 = Base
		HueKnob.Position = UDim2.fromScale(Hue, 0.5)
		HexBox.Text = "#" .. string.upper(Color:ToHex())
		Publish(Props, Color)
		if not Silent then Fire(Props, Color) end
	end

	local function FromSV(Input)
		local Offset = Pointer(Input) - SV.AbsolutePosition
		Sat = math.clamp(Offset.X / SV.AbsoluteSize.X, 0, 1)
		Val = 1 - math.clamp(Offset.Y / SV.AbsoluteSize.Y, 0, 1)
		Apply()
	end

	local function FromHue(Input)
		Hue = math.clamp((Pointer(Input).X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
		Apply()
	end

	Drag(self.Scroller, FromSV, FromSV)(SVHit)
	Drag(self.Scroller, FromHue, FromHue)(HueHit)

	HexBox.Focused:Connect(function()
		Tween(HexStroke, 0.25, { Transparency = 0.3 })
	end)
	HexBox.FocusLost:Connect(function()
		Tween(HexStroke, 0.3, { Transparency = 1 })
		local Clean = string.gsub(HexBox.Text, "[#%s]", "")
		if #Clean == 6 and tonumber(Clean, 16) then
			Hue, Sat, Val = Color3.fromHex(Clean):ToHSV()
		end
		Apply()
	end)

	local function SetOpen(State)
		if Opened == State then return end
		Opened = State
		if State then
			Holder.Visible = true
			Tween(Holder, 0.3, { Size = UDim2.fromOffset(254, PickerHeight) })
			Tween(Block, 0.3, { Size = UDim2.new(1, 0, 0, 29 + PickerHeight + 6) })
		else
			local Closing = Tween(Holder, 0.2, { Size = UDim2.fromOffset(254, 0) })
			Tween(Block, 0.2, { Size = UDim2.new(1, 0, 0, 25) })
			Closing.Completed:Connect(function(Result)
				if Result == Enum.PlaybackState.Completed and not Opened then
					Holder.Visible = false
				end
			end)
		end
	end

	Hit.MouseButton1Click:Connect(function()
		SetOpen(not Opened)
	end)

	function Object:Set(Value)
		if type(Value) == "string" then
			local ok, Parsed = pcall(Color3.fromHex, Value)
			if not ok then return end
			Value = Parsed
		end
		if typeof(Value) ~= "Color3" then return end
		Hue, Sat, Val = Value:ToHSV()
		Apply()
	end

	function Object:Get()
		return Color
	end

	Apply(true)
	Expose(Props, function()
		return Color:ToHex()
	end, function(Value)
		Object:Set(Value)
	end)
	return Object
end

function Section:List(Props)
	local Height = Props.Height or 118
	local Block = MakeBlock(self, Height + 22, Props.Name)
	Label(Block, Props.Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(1, 0), UDim2.fromOffset(150, 13))
	local Frame = Panel(Block, Theme.Control, UDim2.fromOffset(0, 17), UDim2.fromOffset(254, Height))
	Corner(Frame, 4)
	Stroke(Frame, Theme.Border)
	local Scroll = New("ScrollingFrame", {
		Parent = Frame,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }),
		New("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
		}),
	})
	local Empty = Label(Frame, "Nothing here", 12, Enum.FontWeight.Medium, Theme.Muted, UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1), Enum.TextXAlignment.Center)

	local Entries = {}
	local Selected
	local Object = {}

	local function Paint(Instant)
		local Time = Instant and 0 or 0.2
		for Name, Entry in pairs(Entries) do
			local On = Name == Selected
			Tween(Entry.Fill, Time, { BackgroundTransparency = On and 0 or 1 })
			Tween(Entry.Label, Time, { TextColor3 = On and Theme.White or Theme.Text })
			Entry.Label.Text = Props.Format and Props.Format(Name) or Name
		end
	end

	function Object:SetItems(Names)
		for _, Entry in pairs(Entries) do
			Entry.Item:Destroy()
		end
		Entries = {}
		Empty.Visible = #Names == 0
		if Selected and not table.find(Names, Selected) then Selected = nil end
		for Index, Name in ipairs(Names) do
			local Item = New("TextButton", {
				Parent = Scroll,
				LayoutOrder = Index,
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundColor3 = Theme.ItemHover,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
			})
			Corner(Item, 4)
			local Fill = New("Frame", {
				Parent = Item,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			})
			Corner(Fill, 4)
			Gradient(Fill, Theme.TabTop, Theme.TabBottom, 100)
			local ItemLabel = Label(Item, Name, 12, Enum.FontWeight.Medium, Theme.Text, UDim2.fromOffset(10, 0), UDim2.new(1, -20, 1, 0))
			ItemLabel.ZIndex = 2
			ItemLabel.TextTruncate = Enum.TextTruncate.AtEnd
			Entries[Name] = { Item = Item, Fill = Fill, Label = ItemLabel }
			Item.MouseEnter:Connect(function()
				Tween(Item, 0.15, { BackgroundTransparency = 0 })
			end)
			Item.MouseLeave:Connect(function()
				Tween(Item, 0.15, { BackgroundTransparency = 1 })
			end)
			Item.MouseButton1Click:Connect(function()
				Selected = Name
				Paint()
				Fire(Props, Name)
			end)
		end
		Paint(true)
	end

	function Object:Select(Name)
		Selected = Name
		Paint()
	end

	function Object:Get()
		return Selected
	end

	function Object:Refresh()
		Paint(true)
	end

	Object:SetItems(Props.Items or {})
	return Object
end

function Library:Notify(Props)
	local Holder = Library.NotifyHolder
	if not Holder then return end
	Props = Props or {}
	local Duration = Props.Duration or 3
	Library.NotifyOrder = Library.NotifyOrder + 1

	local Slot = New("Frame", {
		Parent = Holder,
		LayoutOrder = Library.NotifyOrder,
		Size = UDim2.fromOffset(250, 58),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})
	local Card = New("Frame", {
		Parent = Slot,
		Position = UDim2.fromOffset(270, 0),
		Size = UDim2.fromOffset(250, 58),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
	})
	Corner(Card, 6)
	Stroke(Card, Theme.Border)
	Icon(Card, Props.Icon or "bell", 20, Theme.AccentTop, UDim2.fromOffset(12, 19))
	Label(Card, Props.Title or "Notification", 13, Enum.FontWeight.Bold, Theme.White, UDim2.fromOffset(42, 8), UDim2.fromOffset(196, 16))
	local Body = Label(Card, Props.Content or "", 12, Enum.FontWeight.Medium, Theme.Muted, UDim2.fromOffset(42, 26), UDim2.fromOffset(196, 16))
	Body.TextTruncate = Enum.TextTruncate.AtEnd
	local Bar = New("Frame", {
		Parent = Card,
		Position = UDim2.fromOffset(6, 53),
		Size = UDim2.fromOffset(238, 3),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
	})
	Round(Bar)
	Gradient(Bar, Theme.AccentTop, Theme.AccentBottom, 0)

	Tween(Card, 0.45, { Position = UDim2.fromOffset(0, 0) })
	Tween(Bar, Duration, { Size = UDim2.fromOffset(0, 3) }, Enum.EasingStyle.Linear)

	task.delay(Duration, function()
		local Leave = Tween(Card, 0.35, { Position = UDim2.fromOffset(270, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		Leave.Completed:Connect(function()
			local Collapse = Tween(Slot, 0.25, { Size = UDim2.fromOffset(250, 0) }, Enum.EasingStyle.Sine)
			Collapse.Completed:Connect(function()
				Slot:Destroy()
			end)
		end)
	end)
end

local function Serialize()
	local Data = {}
	for Flag, Element in pairs(Library.Elements) do
		local ok, Value = pcall(Element.Export)
		if ok then Data[Flag] = Value end
	end
	return HttpService:JSONEncode(Data)
end

local function Deserialize(Text)
	local ok, Data = pcall(function()
		return HttpService:JSONDecode(Text)
	end)
	if not ok or type(Data) ~= "table" then return false end
	for Flag, Value in pairs(Data) do
		local Element = Library.Elements[Flag]
		if Element then pcall(Element.Import, Value) end
	end
	return true
end

function Library:Window(Props)
	Props = Props or {}
	local Title = Props.Title or "Library"
	local FooterText = Props.Footer or ""
	local ConfigFolder = Props.ConfigFolder or Title

	local BaseWidth = 660
	local BaseHeight = 463
	local Multiplier = 1
	local Started = false
	local CurrentCategory = 1
	local Categories = {}
	local HolderBase = UDim2.fromOffset(10, 10)
	local Window = {}

	local Gui = New("ScreenGui", {
		Name = "Library",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 999,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	pcall(function()
		Gui.ScreenInsets = Enum.ScreenInsets.None
	end)
	local Mounted = pcall(function()
		Gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not Mounted or not Gui.Parent then
		Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
	Library.Gui = Gui

	local NotifyHolder = New("Frame", {
		Parent = Gui,
		ZIndex = 10,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.fromOffset(250, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, {
		New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0, 8),
		}),
	})
	local NotifyScale = New("UIScale", { Parent = NotifyHolder })
	Library.NotifyHolder = NotifyHolder

	local WindowFrame = New("Frame", {
		Parent = Gui,
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(658, 461),
		BackgroundColor3 = Theme.Window,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	})
	Corner(WindowFrame, 6)
	local WindowStroke = Stroke(WindowFrame, Theme.Border, 1)

	local Root = New("Frame", {
		Parent = WindowFrame,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	})

	local IntroCover = New("Frame", {
		Parent = Root,
		ZIndex = 200,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
	})
	Corner(IntroCover, 6)

	local Scale = New("UIScale", { Parent = WindowFrame })
	local IntroValue = New("NumberValue", { Value = 0.93 })
	local Camera = workspace.CurrentCamera

	local function Rescale()
		local Viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
		local Fit = math.min(Viewport.X * 0.92 / BaseWidth, Viewport.Y * 0.92 / BaseHeight, math.max(Viewport.Y / 1080, 1))
		Scale.Scale = math.max(Fit * Multiplier * IntroValue.Value, 0.25)
		NotifyScale.Scale = math.clamp(Viewport.Y / 700, 0.7, 1)
	end

	Rescale()
	Connect(IntroValue.Changed, Rescale)
	if Camera then
		Connect(Camera:GetPropertyChangedSignal("ViewportSize"), Rescale)
	end

	local Sidebar = Panel(Root, Theme.Sidebar, UDim2.fromOffset(0, 0), UDim2.fromOffset(75, 461))
	Corner(Sidebar, 6)
	Panel(Sidebar, Theme.Sidebar, UDim2.fromOffset(40, 0), UDim2.fromOffset(35, 461))
	Panel(Root, Theme.Border, UDim2.fromOffset(75, 0), UDim2.fromOffset(1, 461))

	local SidebarScroll = New("ScrollingFrame", {
		Parent = Sidebar,
		Size = UDim2.fromOffset(75, 461),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.fromOffset(0, 461),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	})

	local Topbar = Panel(Root, Theme.Window, UDim2.fromOffset(76, 0), UDim2.fromOffset(582, 50))
	Corner(Topbar, 6)
	Panel(Topbar, Theme.Window, UDim2.fromOffset(0, 0), UDim2.fromOffset(300, 50))
	Panel(Topbar, Theme.Window, UDim2.fromOffset(0, 25), UDim2.fromOffset(582, 25))
	Panel(Root, Theme.Border, UDim2.fromOffset(76, 50), UDim2.fromOffset(582, 1))

	local Content = Panel(Root, Theme.Main, UDim2.fromOffset(76, 51), UDim2.fromOffset(582, 384))

	Panel(Root, Theme.Border, UDim2.fromOffset(76, 435), UDim2.fromOffset(582, 1))
	local Footer = Panel(Root, Theme.Window, UDim2.fromOffset(76, 436), UDim2.fromOffset(582, 25))
	Corner(Footer, 6)
	Panel(Footer, Theme.Window, UDim2.fromOffset(0, 0), UDim2.fromOffset(300, 25))
	Panel(Footer, Theme.Window, UDim2.fromOffset(0, 0), UDim2.fromOffset(582, 12))
	Label(Footer, Title, 12, Enum.FontWeight.SemiBold, Theme.Footer, UDim2.fromOffset(12, 0), UDim2.fromOffset(200, 25))
	local FooterRight = Label(Footer, FooterText, 12, Enum.FontWeight.SemiBold, Theme.Footer, UDim2.new(1, -10, 0, 0), UDim2.fromOffset(200, 25), Enum.TextXAlignment.Right)
	FooterRight.AnchorPoint = Vector2.new(1, 0)

	local function ScreenSize()
		local Size = Gui.AbsoluteSize
		if Size.X > 0 and Size.Y > 0 then return Size end
		return Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	end

	local DragStart
	local StartScale

	local BindWindowDrag = Drag(nil, function(Input)
		DragStart = Pointer(Input)
		StartScale = Vector2.new(WindowFrame.Position.X.Scale, WindowFrame.Position.Y.Scale)
	end, function(Input)
		local Size = ScreenSize()
		local Half = WindowFrame.AbsoluteSize / 2
		local Delta = Pointer(Input) - DragStart
		local Center = Vector2.new(StartScale.X * Size.X, StartScale.Y * Size.Y) + Delta
		local MinX = 80 - Half.X
		local MaxX = math.max(Size.X - 80 + Half.X, MinX)
		local MinY = math.min(Half.Y, Size.Y / 2)
		local MaxY = math.max(Size.Y - 40 + Half.Y, MinY)
		Center = Vector2.new(math.clamp(Center.X, MinX, MaxX), math.clamp(Center.Y, MinY, MaxY))
		WindowFrame.Position = UDim2.fromScale(Center.X / Size.X, Center.Y / Size.Y)
	end)
	BindWindowDrag(Topbar)
	BindWindowDrag(Sidebar)
	BindWindowDrag(Footer)

	local function SidebarY(Index)
		local Total = #Categories * 44 + (#Categories - 1) * 7
		return math.max((461 - Total) / 2, 8) + (Index - 1) * 51
	end

	local Highlight = New("Frame", {
		Parent = SidebarScroll,
		ZIndex = 1,
		Position = UDim2.fromOffset(15.5, SidebarY(1)),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Theme.White,
		BorderSizePixel = 0,
		Visible = false,
	})
	Round(Highlight)
	Gradient(Highlight, Theme.TabTop, Theme.TabBottom, 100)

	local TopCover = New("Frame", {
		Parent = Topbar,
		ZIndex = 20,
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, -215, 1, 0),
		BackgroundColor3 = Theme.Window,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
	})

	local function Relayout()
		for Index, Category in ipairs(Categories) do
			Category.Side.Button.Position = UDim2.fromOffset(15.5, SidebarY(Index))
		end
		SidebarScroll.CanvasSize = UDim2.fromOffset(0, math.max(#Categories * 51 + 9, 461))
		Highlight.Position = UDim2.fromOffset(15.5, SidebarY(CurrentCategory))
	end

	local function StyleTab(Tab, Active, Instant)
		local Time = Instant and 0 or 0.3
		Tab.Active = Active
		Tween(Tab.Fill, Time, { BackgroundTransparency = Active and 0 or 1 })
		Tween(Tab.Frame, Time, { BackgroundColor3 = Theme.TabIdle })
		Tween(Tab.Label, Time, { TextColor3 = Active and Theme.White or Theme.Muted })
	end

	local function Refresh(Instant)
		local Time = Instant and 0 or 0.35
		Tween(Highlight, Time, { Position = UDim2.fromOffset(15.5, SidebarY(CurrentCategory)) })
		for CategoryIndex, Category in ipairs(Categories) do
			local Chosen = CategoryIndex == CurrentCategory
			Tween(Category.Side.Icon, Time, { ImageColor3 = Chosen and Theme.Black or Theme.Icon })
			local HolderShown = Category.Holder:GetAttribute("Shown") == true
			if Chosen and not HolderShown then
				ShowGroup(Category.Holder, HolderBase, 6, Instant, 0.12)
			elseif not Chosen and HolderShown then
				HideGroup(Category.Holder)
			end
			for TabIndex, Tab in ipairs(Category.TabList) do
				local Active = TabIndex == Category.Active
				StyleTab(Tab, Active, Instant)
				local Want = Chosen and Active
				local Shown = Tab.Page:GetAttribute("Shown") == true
				if Want and not Shown then
					ShowGroup(Tab.Page, UDim2.fromOffset(0, 0), 12, Instant, 0.14)
				elseif not Want and Shown then
					HideGroup(Tab.Page)
				end
			end
		end
	end

	function Window:Tab(TabProps)
		TabProps = TabProps or {}
		local Category = { TabList = {}, Active = 1 }
		local CategoryIndex = #Categories + 1
		Categories[CategoryIndex] = Category

		Category.Holder = New("ScrollingFrame", {
			Parent = Topbar,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = HolderBase,
			Size = UDim2.fromOffset(352, 36),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Accent,
			Visible = false,
		}, {
			New("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),
		})
		Category.Holder:SetAttribute("Shared", true)
		Covers[Category.Holder] = TopCover

		local Button = New("TextButton", {
			Parent = SidebarScroll,
			ZIndex = 2,
			Size = UDim2.fromOffset(44, 44),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		})
		local SideIcon = Icon(Button, TabProps.Icon or "circle", 24, Theme.Icon, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))
		Button.MouseEnter:Connect(function()
			if CurrentCategory ~= CategoryIndex then
				Tween(SideIcon, 0.2, { ImageColor3 = Theme.TextHover })
			end
		end)
		Button.MouseLeave:Connect(function()
			if CurrentCategory ~= CategoryIndex then
				Tween(SideIcon, 0.2, { ImageColor3 = Theme.Icon })
			end
		end)
		Button.MouseButton1Click:Connect(function()
			CurrentCategory = CategoryIndex
			Refresh()
		end)
		Category.Side = { Button = Button, Icon = SideIcon }

		Highlight.Visible = true
		Relayout()
		if Started then Refresh(true) end

		local Tab = {}

		function Tab:SubTab(SubProps)
			SubProps = SubProps or {}
			local TabIndex = #Category.TabList + 1

			local Page = New("Frame", {
				Parent = Content,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				Visible = false,
			})
			local Left = MakeColumn(Page, 11)
			local Right = MakeColumn(Page, 297)
			Covers[Page] = New("Frame", {
				Parent = Page,
				ZIndex = 100,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.Main,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
			})

			local Frame = New("Frame", {
				Parent = Category.Holder,
				LayoutOrder = TabIndex,
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Theme.TabIdle,
				BorderSizePixel = 0,
			})
			Corner(Frame, 5)
			local Fill = New("Frame", {
				Parent = Frame,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Theme.White,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			})
			Corner(Fill, 5)
			Gradient(Fill, Theme.TabTop, Theme.TabBottom, 100)
			local TabLabel = New("TextLabel", {
				Parent = Frame,
				ZIndex = 2,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(0, 30),
				AutomaticSize = Enum.AutomaticSize.X,
				Text = SubProps.Name or "Tab",
				TextSize = 13,
				FontFace = MakeFont(Enum.FontWeight.SemiBold),
				TextColor3 = Theme.Muted,
			}, {
				New("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
			})
			local Hit = New("TextButton", {
				Parent = Frame,
				ZIndex = 3,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = "",
			})
			local Entry = { Frame = Frame, Fill = Fill, Label = TabLabel, Page = Page, Active = false }
			Hit.MouseEnter:Connect(function()
				if not Entry.Active then
					Tween(Frame, 0.2, { BackgroundColor3 = Theme.TabHover })
					Tween(TabLabel, 0.2, { TextColor3 = Theme.TextHover })
				end
			end)
			Hit.MouseLeave:Connect(function()
				if not Entry.Active then
					Tween(Frame, 0.2, { BackgroundColor3 = Theme.TabIdle })
					Tween(TabLabel, 0.2, { TextColor3 = Theme.Muted })
				end
			end)
			Hit.MouseButton1Click:Connect(function()
				Category.Active = TabIndex
				Refresh()
			end)
			Category.TabList[TabIndex] = Entry
			if Started then Refresh(true) end

			local SubTab = { Orders = { Left = 0, Right = 0 } }

			function SubTab:Section(SectionProps)
				SectionProps = SectionProps or {}
				local Side = SectionProps.Side == "Right" and "Right" or "Left"
				local Column = Side == "Right" and Right or Left
				SubTab.Orders[Side] = SubTab.Orders[Side] + 1
				local Body = MakeCard(Column, SubTab.Orders[Side], SectionProps.Name or "Section", SectionProps.Icon)
				return setmetatable({ Body = Body, Scroller = Column, Order = 0 }, Section)
			end

			return SubTab
		end

		return Tab
	end

	function Window:ConfigTab(ConfigProps)
		ConfigProps = ConfigProps or {}
		local Name = ConfigProps.Name or "Configs"
		local Dir = ConfigFolder .. "/configs"
		local AutoFile = ConfigFolder .. "/autoload.txt"
		local CanFile = type(writefile) == "function"
			and type(readfile) == "function"
			and type(isfile) == "function"
			and type(isfolder) == "function"
			and type(makefolder) == "function"
			and type(listfiles) == "function"
		local Selected
		local AutoName = ""

		local function EnsureFolders()
			if not CanFile then return false end
			pcall(function()
				if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
				if not isfolder(Dir) then makefolder(Dir) end
			end)
			return true
		end

		local function CleanName(Text)
			Text = string.gsub(Text or "", "[^%w%-%_ ]", "")
			Text = string.gsub(Text, "^%s+", "")
			Text = string.gsub(Text, "%s+$", "")
			return Text
		end

		local function ConfigPath(Text)
			return Dir .. "/" .. Text .. ".json"
		end

		local function ListConfigs()
			local Names = {}
			if not EnsureFolders() then return Names end
			local ok, Files = pcall(listfiles, Dir)
			if not ok or type(Files) ~= "table" then return Names end
			for _, Path in ipairs(Files) do
				local Found = string.match(Path, "([^/\\]+)%.json$")
				if Found then table.insert(Names, Found) end
			end
			table.sort(Names, function(A, B)
				return string.lower(A) < string.lower(B)
			end)
			return Names
		end

		local function ReadAutoload()
			if not CanFile then return "" end
			local Found = ""
			pcall(function()
				if isfile(AutoFile) then
					Found = CleanName(readfile(AutoFile))
				end
			end)
			return Found
		end

		AutoName = ReadAutoload()

		local Tab = self:Tab({ Name = Name, Icon = ConfigProps.Icon or "folder" })
		local SubTab = Tab:SubTab({ Name = Name })
		local Files = SubTab:Section({ Name = "Configs", Icon = "folder", Side = "Left" })
		local Auto = SubTab:Section({ Name = "Autoload", Icon = "zap", Side = "Right" })

		local function Fail(Message)
			Library:Notify({ Title = "Config", Content = Message, Duration = 3, Icon = "x" })
		end

		local function Done(Message)
			Library:Notify({ Title = "Config", Content = Message, Duration = 3, Icon = "check" })
		end

		local function Ready()
			if not CanFile then
				Fail("Executor has no file support")
				return false
			end
			EnsureFolders()
			return true
		end

		local NameInput = Files:Input({ Name = "Config Name", Placeholder = "Enter config name" })
		local AutoLabel = Auto:Label({ Name = "" })

		local function PaintAuto()
			AutoLabel:Set("Autoload: " .. (AutoName ~= "" and AutoName or "None"))
		end

		local ConfigList = Files:List({
			Name = "Config List",
			Height = 118,
			Format = function(Item)
				return Item .. (Item == AutoName and "  (auto)" or "")
			end,
			Callback = function(Item)
				Selected = Item
				NameInput:Set(Item)
			end,
		})

		local function PaintList()
			ConfigList:SetItems(ListConfigs())
			if Selected then ConfigList:Select(Selected) end
		end

		Files:ButtonRow({
			Buttons = {
				{
					Name = "Create",
					Callback = function()
						if not Ready() then return end
						local Text = CleanName(NameInput:Get())
						if Text == "" then
							Fail("Enter a config name")
							return
						end
						if isfile(ConfigPath(Text)) then
							Fail("Config already exists")
							return
						end
						if not pcall(writefile, ConfigPath(Text), Serialize()) then
							Fail("Could not write config")
							return
						end
						Selected = Text
						PaintList()
						Done("Created " .. Text)
					end,
				},
				{
					Name = "Load",
					Callback = function()
						if not Ready() then return end
						if not Selected then
							Fail("Select a config first")
							return
						end
						local ok, Text = pcall(readfile, ConfigPath(Selected))
						if ok and Deserialize(Text) then
							Done("Loaded " .. Selected)
						else
							Fail("Could not load config")
						end
					end,
				},
			},
		})

		Files:ButtonRow({
			Buttons = {
				{
					Name = "Save",
					Callback = function()
						if not Ready() then return end
						if not Selected then
							Fail("Select a config first")
							return
						end
						if pcall(writefile, ConfigPath(Selected), Serialize()) then
							Done("Saved " .. Selected)
						else
							Fail("Could not write config")
						end
					end,
				},
				{
					Name = "Delete",
					Callback = function()
						if not Ready() then return end
						if not Selected then
							Fail("Select a config first")
							return
						end
						if type(delfile) ~= "function" then
							Fail("Executor cannot delete files")
							return
						end
						local Removed = Selected
						pcall(delfile, ConfigPath(Removed))
						if AutoName == Removed then
							AutoName = ""
							pcall(delfile, AutoFile)
							PaintAuto()
						end
						Selected = nil
						NameInput:Set("")
						PaintList()
						Done("Deleted " .. Removed)
					end,
				},
			},
		})

		Files:Button({
			Name = "Refresh",
			Callback = function()
				if not Ready() then return end
				PaintList()
			end,
		})

		Auto:ButtonRow({
			Buttons = {
				{
					Name = "Set",
					Callback = function()
						if not Ready() then return end
						if not Selected then
							Fail("Select a config first")
							return
						end
						if pcall(writefile, AutoFile, Selected) then
							AutoName = Selected
							PaintAuto()
							ConfigList:Refresh()
							Done("Autoload set to " .. Selected)
						else
							Fail("Could not write autoload")
						end
					end,
				},
				{
					Name = "Clear",
					Callback = function()
						if not Ready() then return end
						if type(delfile) == "function" then
							pcall(delfile, AutoFile)
						else
							pcall(writefile, AutoFile, "")
						end
						AutoName = ""
						PaintAuto()
						ConfigList:Refresh()
						Done("Autoload cleared")
					end,
				},
			},
		})

		PaintAuto()
		if CanFile then PaintList() end

		Window.OnStart = function()
			if not CanFile then return end
			local Found = ReadAutoload()
			if Found == "" then return end
			local ok, Text = pcall(readfile, ConfigPath(Found))
			if ok and Deserialize(Text) then
				Selected = Found
				NameInput:Set(Found)
				ConfigList:Select(Found)
				Done("Autoloaded " .. Found)
			end
		end

		return Tab
	end

	function Window:Notify(NotifyProps)
		Library:Notify(NotifyProps)
	end

	function Window:SetDPI(Value)
		if type(Value) ~= "number" then return end
		Multiplier = Value
		Rescale()
	end

	local SearchFrame = New("Frame", {
		Parent = Topbar,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(200, 30),
		BackgroundColor3 = Theme.Main,
		BorderSizePixel = 0,
	})
	Corner(SearchFrame, 5)
	local SearchStroke = Stroke(SearchFrame, Theme.Accent, 1)
	local SearchIcon = Icon(SearchFrame, "search", 16, Theme.Muted, UDim2.fromOffset(7, 7))
	local SearchBox = New("TextBox", {
		Parent = SearchFrame,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(29, 0),
		Size = UDim2.new(1, -37, 1, 0),
		Text = "",
		PlaceholderText = "Search function",
		PlaceholderColor3 = Theme.Muted,
		ClearTextOnFocus = false,
		TextSize = 13,
		FontFace = MakeFont(Enum.FontWeight.Medium),
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
	})
	SearchBox.Focused:Connect(function()
		Tween(SearchStroke, 0.25, { Transparency = 0.3 })
		Tween(SearchIcon, 0.25, { ImageColor3 = Theme.Text })
	end)
	SearchBox.FocusLost:Connect(function()
		Tween(SearchStroke, 0.3, { Transparency = 1 })
		Tween(SearchIcon, 0.3, { ImageColor3 = Theme.Muted })
	end)
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Query = string.lower(SearchBox.Text)
		for _, Row in ipairs(Rows) do
			if Row.Frame.Parent then
				Row.Frame.Visible = Query == "" or string.find(Row.Name, Query, 1, true) ~= nil
			end
		end
	end)

	local MenuOpen = true
	local MenuTween

	local function SetMenu(State)
		if MenuOpen == State then return end
		MenuOpen = State
		if MenuTween then MenuTween:Cancel() end
		IntroCover.Visible = true
		if State then
			WindowFrame.Visible = true
			IntroCover.BackgroundTransparency = 0
			Tween(IntroValue, 0.4, { Value = 1 })
			MenuTween = Tween(IntroCover, 0.35, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			MenuTween.Completed:Connect(function(Result)
				if Result == Enum.PlaybackState.Completed and MenuOpen then
					IntroCover.Visible = false
				end
			end)
		else
			Tween(IntroValue, 0.25, { Value = 0.93 })
			MenuTween = Tween(IntroCover, 0.2, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
			MenuTween.Completed:Connect(function(Result)
				if Result == Enum.PlaybackState.Completed and not MenuOpen then
					WindowFrame.Visible = false
				end
			end)
		end
	end

	function Window:Toggle(State)
		if State == nil then State = not MenuOpen end
		SetMenu(State)
	end

	local ToggleButton = New("TextButton", {
		Parent = Gui,
		Name = "Toggle",
		ZIndex = 20,
		Position = UDim2.new(0.5, -22, 0, 12),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Theme.Window,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	})
	Round(ToggleButton)
	Stroke(ToggleButton, Theme.Border)
	local ToggleIcon = Icon(ToggleButton, "menu", 22, Theme.AccentTop, UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5))

	local ButtonStart
	local ButtonOrigin
	local ButtonMoved = false

	Drag(nil, function(Input)
		ButtonStart = Pointer(Input)
		ButtonOrigin = ToggleButton.AbsolutePosition
		ButtonMoved = false
	end, function(Input)
		local Delta = Pointer(Input) - ButtonStart
		if Delta.Magnitude > 8 then ButtonMoved = true end
		if ButtonMoved then
			local Size = ScreenSize()
			local Target = ButtonOrigin + Delta
			ToggleButton.Position = UDim2.fromOffset(
				math.clamp(Target.X, 0, math.max(Size.X - 44, 0)),
				math.clamp(Target.Y, 0, math.max(Size.Y - 44, 0))
			)
		end
	end, function()
		if not ButtonMoved then
			SetMenu(not MenuOpen)
			Tween(ToggleIcon, 0.25, { ImageColor3 = MenuOpen and Theme.AccentTop or Theme.White })
		end
		ButtonMoved = false
	end)(ToggleButton)

	function Window:Destroy()
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
		Connections = {}
		UnlockCamera("LibraryDrag")
		IntroValue:Destroy()
		Gui:Destroy()
		Library.NotifyHolder = nil
		Library.Flags = {}
		Library.Elements = {}
		Rows = {}
	end

	task.defer(function()
		Started = true
		Refresh(false)
		Tween(IntroValue, 0.65, { Value = 1 })
		Tween(WindowFrame, 0.35, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
		Tween(WindowStroke, 0.35, { Transparency = 0 }, Enum.EasingStyle.Sine)
		task.delay(0.3, function()
			Root.Visible = true
			local Reveal = Tween(IntroCover, 0.45, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
			Reveal.Completed:Connect(function()
				IntroCover.Visible = false
			end)
		end)
		if Window.OnStart then Window.OnStart() end
	end)

	return Window
end

return Library
