local UserInputService = game:GetService("UserInputService")

local Root = script.Parent.Parent
local Creator = require(Root.Modules.Creator)

local New = Creator.New
local Components = Root.Components

local Element = {}
Element.__index = Element
Element.__type = "Keybind"

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
			if Keybind.Value == "None" or not Keybind.Value then
				return false
			end

			local Key = Keybind.Value

			if Key == "LeftMousebutton" or Key == "RightMousebutton" then
				return Key == "LeftMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
					or Key == "RightMousebutton" and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			else
				local Success, IsDown = pcall(function()
					return UserInputService:IsKeyDown(Enum.KeyCode[Keybind.Value])
				end)
				return Success and IsDown
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
			or (Input.UserInputType.Name:find("Gamepad") and Input.KeyCode == Enum.KeyCode.ButtonA)
		then
			Picking = true
			KeybindDisplayLabel.Text = "..."

			task.wait(0.2)

			local Listener
			Listener = UserInputService.InputBegan:Connect(function(InputObj)
				local Key
				
				if InputObj.UserInputType == Enum.UserInputType.Keyboard then
					Key = InputObj.KeyCode.Name
				elseif InputObj.UserInputType == Enum.UserInputType.MouseButton1 then
					Key = "LeftMousebutton"
				elseif InputObj.UserInputType == Enum.UserInputType.MouseButton2 then
					Key = "RightMousebutton"
				elseif InputObj.UserInputType.Name:find("Gamepad") then
					-- Extract valid controller buttons and strictly ignore thumbstick movement
					if InputObj.KeyCode.Name:match("Button") or InputObj.KeyCode.Name:match("DPad") then
						Key = InputObj.KeyCode.Name
					end
				end

				if Key then
					Listener:Disconnect()
					
					-- Immediately update the UI to show the selected key
					Keybind.Value = Key
					KeybindDisplayLabel.Text = Library.Utilities:Prettify(Keybind.Value)

					-- Wait for the user to physically release the button before closing the picker,
					-- so that they don't immediately trigger their own keybind.
					local endListener
					endListener = UserInputService.InputEnded:Connect(function(EndInput)
						if EndInput.KeyCode == InputObj.KeyCode and EndInput.UserInputType == InputObj.UserInputType then
							endListener:Disconnect()
							Picking = false
							
							if not Library.Unloaded then
								if typeof(Keybind.ChangedCallback) == "function" then
									Library:SafeCallback(Keybind.ChangedCallback, InputObj.KeyCode)
								end
								if typeof(Keybind.Changed) == "function" then
									Library:SafeCallback(Keybind.Changed, InputObj.KeyCode)
								end
							end
						end
					end)
				end
			end)
		end
	end)

	-- Global input listener
	Creator.AddSignal(UserInputService.InputBegan, function(Input)
		if not Picking and not UserInputService:GetFocusedTextBox() then
			if Keybind.Mode == "Toggle" then
				local Key = Keybind.Value
				if not Key or Key == "None" then return end

				if Key == "LeftMousebutton" or Key == "RightMousebutton" then
					if
						Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
						or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
					then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				elseif Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType.Name:find("Gamepad") then
					if Input.KeyCode.Name == Key then
						Keybind.Toggled = not Keybind.Toggled
						Keybind:DoClick()
					end
				end
			elseif Keybind.Mode == "Hold" then
				local Key = Keybind.Value
				if not Key or Key == "None" then return end

				if Key == "LeftMousebutton" or Key == "RightMousebutton" then
					if
						Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
						or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
					then
						Keybind.Toggled = true
						Keybind:DoClick()
					end
				elseif Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType.Name:find("Gamepad") then
					if Input.KeyCode.Name == Key then
						Keybind.Toggled = true
						Keybind:DoClick()
					end
				end
			end
		end
	end)

	-- Release for Hold Mode
	Creator.AddSignal(UserInputService.InputEnded, function(Input)
		if not Picking and not UserInputService:GetFocusedTextBox() then
			if Keybind.Mode == "Hold" then
				local Key = Keybind.Value
				if not Key or Key == "None" then return end

				if Key == "LeftMousebutton" or Key == "RightMousebutton" then
					if
						Key == "LeftMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton1
						or Key == "RightMousebutton" and Input.UserInputType == Enum.UserInputType.MouseButton2
					then
						Keybind.Toggled = false
						Keybind:DoClick()
					end
				elseif Input.UserInputType == Enum.UserInputType.Keyboard or Input.UserInputType.Name:find("Gamepad") then
					if Input.KeyCode.Name == Key then
						Keybind.Toggled = false
						Keybind:DoClick()
					end
				end
			end
		end
	end)

	Keybind:SetValue(Keybind.Value)

	Library.Options[Idx] = Keybind

	Keybind.Instance = KeybindFrame

	return setmetatable(Keybind, {
		__newindex =  function(self, index, newvalue)
			if index == "Value" then
				task.spawn(Keybind.SetValue, Keybind, newvalue)
			end
			rawset(self, index, newvalue)
		end
	})
end

return Element
