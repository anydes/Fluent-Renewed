local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Keybind"

-- All supported Gamepad button KeyCodes for display and detection
local GAMEPAD_KEYCODES = {
	[Enum.KeyCode.ButtonA]          = "ButtonA",
	[Enum.KeyCode.ButtonB]          = "ButtonB",
	[Enum.KeyCode.ButtonX]          = "ButtonX",
	[Enum.KeyCode.ButtonY]          = "ButtonY",
	[Enum.KeyCode.ButtonL1]         = "ButtonL1",
	[Enum.KeyCode.ButtonL2]         = "ButtonL2",
	[Enum.KeyCode.ButtonL3]         = "ButtonL3",
	[Enum.KeyCode.ButtonR1]         = "ButtonR1",
	[Enum.KeyCode.ButtonR2]         = "ButtonR2",
	[Enum.KeyCode.ButtonR3]         = "ButtonR3",
	[Enum.KeyCode.ButtonStart]      = "ButtonStart",
	[Enum.KeyCode.ButtonSelect]     = "ButtonSelect",
	[Enum.KeyCode.DPadUp]           = "DPadUp",
	[Enum.KeyCode.DPadDown]         = "DPadDown",
	[Enum.KeyCode.DPadLeft]         = "DPadLeft",
	[Enum.KeyCode.DPadRight]        = "DPadRight",
}

local GAMEPAD_INPUT_TYPES = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
}

local function isGamepadInput(Input)
	return GAMEPAD_INPUT_TYPES[Input.UserInputType] == true
end

local function getKeyName(Input)
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		return Input.KeyCode.Name
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
		return "LeftMousebutton"
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "RightMousebutton"
	elseif isGamepadInput(Input) then
		return GAMEPAD_KEYCODES[Input.KeyCode]
	end
	return nil
end

local function keyMatchesInput(Key, Input)
	if Key == "LeftMousebutton" then
		return Input.UserInputType == Enum.UserInputType.MouseButton1
	elseif Key == "RightMousebutton" then
		return Input.UserInputType == Enum.UserInputType.MouseButton2
	elseif isGamepadInput(Input) then
		return GAMEPAD_KEYCODES[Input.KeyCode] == Key
	else
		return Input.UserInputType == Enum.UserInputType.Keyboard
			and (Input.KeyCode.Name == Key or tostring(Input.KeyCode) == Key)
	end
end

function Element:New(Idx, Config)
	local Library = self.Library

	local Keybind = {
		Value = Config.Default or Config.Value or Enum.KeyCode.Unknown,
		Toggled = false,
		Mode = Config.Mode or "Toggle",
		Type = "Keybind",
		Callback = Config.Callback or function(Value) end,
		ChangedCallback = Config.ChangedCallback or function(New) end,
	}

	local Picking = false

	local KeybindFrame = require(Components.Element)(Config.Title or "Keybind", Config.Description, self.Container, true)

	Keybind.SetTitle = KeybindFrame.SetTitle
	Keybind.SetDesc = KeybindFrame.SetDesc

	local KeybindDisplayLabel = New("TextLabel", {
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal),
		Text = Library.Utilities:Prettify(Keybind.Value),
		TextColor3 = Color3.fromRGB(240, 240, 240),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(0, 0, 0, 14),
		Position = UDim2.new(0, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ThemeTag = {
			TextColor3 = "Text",
		},
	})

	local KeybindDisplayFrame = New("TextButton", {
		Size = UDim2.fromOffset(0, 30),
		Position = UDim2.new(1, -10, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 0.9,
		Parent = KeybindFrame.Frame,
		AutomaticSize = Enum.AutomaticSize.X,
		ThemeTag = {
			BackgroundColor3 = "Keybind",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 5),
		}),
		New("UIPadding", {
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
		}),
		New("UIStroke", {
			Transparency = 0.5,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag = {
				Color = "InElementBorder",
			},
		}),
		KeybindDisplayLabel,
	}) :: TextButton

	function Keybind:GetState()
		if UserInputService:GetFocusedTextBox() and Keybind.Mode ~= "Always" then
			return false
		end

		if Keybind.Mode == "Always" then
			return true
		elseif Keybind.Mode == "Hold" then
			if Keybind.Value == "None" then
				return false
			end

			local Key = Keybind.Value

			if Key == "LeftMousebutton" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			elseif Key == "RightMousebutton" then
				return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			else
				-- Try as KeyCode (covers both keyboard and gamepad buttons)
				local ok, kc = pcall(function()
					return Enum.KeyCode[Key]
				end)
				if ok and kc then
					return UserInputService:IsKeyDown(kc)
				end
				return false
			end
		else
			return Keybind.Toggled
		end
	end

	function Keybind:SetValue(Key, Mode)
		Key = Key or Keybind.Value
		Mode = Mode or Keybind.Mode

		rawset(Keybind, "Value", Key)
		Keybind.Mode = Mode

		KeybindDisplayLabel.Text = Library.Utilities:Prettify(Keybind.Value)

		if typeof(Keybind.ChangedCallback) == "function" then
			Library:SafeCallback(Keybind.ChangedCallback, Key)
		end
		if typeof(Keybind.Changed) == "function" then
			Library:SafeCallback(Keybind.Changed, Key)
		end
	end

	function Keybind:OnClick(Callback)
		Keybind.Clicked = Callback
	end

	function Keybind:OnChanged(Callback)
		Keybind.Changed = Callback
		Library:SafeCallback(Callback, Keybind.Value, Keybind.Value)
	end

	function Keybind:DoClick()
		if typeof(Keybind.Callback) == "function" then
			Library:SafeCallback(Keybind.Callback, Keybind.Toggled)
		end
		if typeof(Keybind.Clicked) == "function" then
			Library:SafeCallback(Keybind.Clicked, Keybind.Toggled)
		end
	end

	function Keybind:Destroy()
		KeybindFrame:Destroy()
		Library.Options[Idx] = nil
	end

	-- Click on the keybind button to start picking a new key
	Creator.AddSignal(KeybindDisplayFrame.InputBegan, function(Input)
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
			or (isGamepadInput(Input) and Input.KeyCode == Enum.KeyCode.ButtonA)
		then
			Picking = true
			KeybindDisplayLabel.Text = "..."

			task.wait(0.2)

			local connection
			connection = UserInputService.InputBegan:Connect(function(BindInput)
				local Key = getKeyName(BindInput)
				if not Key then return end -- Ignore thumbsticks/invalid inputs

				connection:Disconnect()

				if isGamepadInput(BindInput) then
					-- For gamepads, bind immediately on InputBegan (InputEnded can be swallowed by UI navigation)
					if not Library.Unloaded then
						Picking = false
						Keybind.Value = Key
						KeybindDisplayLabel.Text = Library.Utilities:Prettify(Keybind.Value)
						if typeof(Keybind.ChangedCallback) == "function" then
							Library:SafeCallback(Keybind.ChangedCallback, BindInput.KeyCode)
						end
						if typeof(Keybind.Changed) == "function" then
							Library:SafeCallback(Keybind.Changed, BindInput.KeyCode)
						end
					end
				else
					-- Wait for the key/button to be released before confirming for KBM
					local endConnection
					endConnection = UserInputService.InputEnded:Connect(function(EndInput)
						if getKeyName(EndInput) == Key then
							endConnection:Disconnect()
							if not Library.Unloaded then
								Picking = false
								Keybind.Value = Key
								KeybindDisplayLabel.Text = Library.Utilities:Prettify(Keybind.Value)
								
								local outVal = EndInput.KeyCode ~= Enum.KeyCode.Unknown and EndInput.KeyCode or EndInput.UserInputType
								if typeof(Keybind.ChangedCallback) == "function" then
									Library:SafeCallback(Keybind.ChangedCallback, outVal)
								end
								if typeof(Keybind.Changed) == "function" then
									Library:SafeCallback(Keybind.Changed, outVal)
								end
							end
						end
					end)
				end
			end)
		end
	end)

	-- Global input listener: fires Toggle/Hold/Always logic for any bound key
	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if Picking or UserInputService:GetFocusedTextBox() then return end

		local Key = Keybind.Value
		if not Key or Key == "None" then return end

		if keyMatchesInput(Key, Input) then
			if Keybind.Mode == "Toggle" then
				Keybind.Toggled = not Keybind.Toggled
				Keybind:DoClick()
			elseif Keybind.Mode == "Hold" then
				Keybind.Toggled = true
				Keybind:DoClick()
			end
		end
	end)

	-- Release for Hold mode
	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if Picking then return end

		local Key = Keybind.Value
		if not Key or Key == "None" then return end

		if Keybind.Mode == "Hold" and keyMatchesInput(Key, Input) then
			Keybind.Toggled = false
			Keybind:DoClick()
		end
	end)

	Keybind:SetValue(Keybind.Value)

	Library.Options[Idx] = Keybind

	Keybind.Instance = KeybindFrame

	return setmetatable(Keybind, {
		__newindex = function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Keybind.SetValue, Keybind, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
