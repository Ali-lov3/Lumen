local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ali-lov3/Repo/main/Source.lua"))()

local Window = Library:Window({
	Title = "Example",
	Footer = "Example",
	ConfigFolder = "Example",
})

local Tab = Window:Tab({ Name = "Example", Icon = "crosshair" })
local SubTab = Tab:SubTab({ Name = "Example" })

local Left = SubTab:Section({ Name = "Example", Icon = "crosshair", Side = "Left" })
local Right = SubTab:Section({ Name = "Example", Icon = "layers", Side = "Right" })

Left:Label({ Name = "Example Label" })

Left:Button({
	Name = "Example Button",
	Callback = function()
		Library:Notify({ Title = "Example", Content = "Button was clicked", Duration = 3, Icon = "mouse-pointer-click" })
	end,
})

Left:ButtonRow({
	Buttons = {
		{
			Name = "Example One",
			Callback = function()
				Library:Notify({ Title = "Example", Content = "One", Duration = 2, Icon = "check" })
			end,
		},
		{
			Name = "Example Two",
			Callback = function()
				Library:Notify({ Title = "Example", Content = "Two", Duration = 2, Icon = "check" })
			end,
		},
	},
})

Left:Toggle({
	Name = "Example Toggle",
	Default = true,
	Flag = "ExampleToggle",
	Callback = function(Value)
		Library:Notify({ Title = "Example", Content = Value and "Enabled" or "Disabled", Duration = 2, Icon = "crosshair" })
	end,
})

Left:Slider({
	Name = "Example Slider",
	Min = 0,
	Max = 10,
	Default = 5,
	Increment = 0.5,
	Suffix = "°",
	Flag = "ExampleSlider",
})

Left:ColorPicker({
	Name = "Example Color",
	Default = Color3.fromHex("#c90a0a"),
	Flag = "ExampleColor",
})

Left:Input({
	Name = "Example Input",
	Default = "",
	Placeholder = "Example",
	Flag = "ExampleInput",
})

Right:Dropdown({
	Name = "Example Dropdown",
	Options = { "Head", "Chest", "Arms", "Legs" },
	Default = "Head",
	Flag = "ExampleDropdown",
})

Right:Dropdown({
	Name = "Example Multi Dropdown",
	Options = { "Head", "Chest", "Arms", "Legs" },
	Default = { "Head" },
	Multi = true,
	Flag = "ExampleMulti",
})

Right:Dropdown({
	Name = "Example Search Dropdown",
	Options = { "Head", "Neck", "Chest", "Stomach", "Left Arm", "Right Arm", "Left Leg", "Right Leg" },
	Default = "Head",
	Searchable = true,
	Flag = "ExampleSearch",
})

Right:Dropdown({
	Name = "Example Menu DPI",
	Options = { "1x", "1.5x", "2x" },
	Default = "2x",
	Flag = "ExampleDPI",
	Callback = function(Value)
		Window:SetDPI(tonumber((string.gsub(Value, "x", ""))) / 2)
	end,
})

Right:List({
	Name = "Example List",
	Height = 90,
	Items = { "Example One", "Example Two", "Example Three", "Example Four" },
	Callback = function(Value)
		Library:Notify({ Title = "Example", Content = Value, Duration = 2, Icon = "check" })
	end,
})

Window:ConfigTab()
