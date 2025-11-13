-- Avatar Catalog - With Accessories Shop
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Import Topbar+
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

-- RemoteEvents
local changeAvatarEvent = ReplicatedStorage:WaitForChild("ChangeAvatarEvent")
local resetAvatarEvent = ReplicatedStorage:WaitForChild("ResetAvatarEvent")
local addAccessoryEvent = ReplicatedStorage:WaitForChild("AddAccessoryEvent")
local removeAccessoryEvent = ReplicatedStorage:WaitForChild("RemoveAccessoryEvent")

-- ============================================
-- AVATAR DATA
-- ============================================
local AVATARS = {
	Boys = {
		{name = "Boys 1", id = 9101259798},
		{name = "Boys 2", id = 8912185225},
		{name = "Boys 3", id = 8935877365},
		{name = "Boys 4", id = 8352609716},
		{name = "Boys 5", id = 8976748119},
		{name = "Boys 6", id = 8968308984},
		{name = "Boys 7", id = 4832303740},
		{name = "Boys 8", id = 9220382005},
		{name = "Boys 9", id = 9046030552},
		{name = "Boys 10", id = 9000844254},
		{name = "Boys 11", id = 8966687266},
		{name = "Boys 12", id = 9112933446}
	},
	Girls = {
		{name = "Girls 1", id = 9181935703},
		{name = "Girls 2", id = 7843828496},
		{name = "Girls 3", id = 3226668321},
		{name = "Girls 4", id = 7260068521},
		{name = "Girls 5", id = 8592887007},
		{name = "Girls 6", id = 9093398365},
		{name = "Girls 7", id = 8918025774},
		{name = "Girls 8", id = 8935328065},
		{name = "Girls 9", id = 8891975253},
		{name = "Girls 10", id = 8486540814},
		{name = "Girls 11", id = 9101275612},
		{name = "Girls 12", id = 9084296513}
	}
}
-- ============================================
-- ACCESSORIES DATA
-- ============================================
local ACCESSORIES = {
	{name = "Crown 8 Bit", id = 10159600649},
	{name = "8-Bit Extra Life", id = 10159606132},
	{name = "8-Bit HP Bar", id = 10159610478},
	{name = "8-Bit Roblox Coin", id = 10159622004},
	{name = "8-Bit Tabby Cat", id = 10159617728},
	{name = "8-Bit Exstra Life", id = 10159606132}
}

-- Topbar Icon
local avatarIcon = Icon.new()
avatarIcon:setLabel("Avatars")
avatarIcon:setOrder(1)

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AvatarCatalog"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

-- Overlay
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.Visible = false
overlay.Parent = gui

-- Main Frame
local main = Instance.new("Frame")
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.Size = UDim2.new(0, 650, 0, 380)
main.Position = UDim2.new(0.5, 0, 0.5, 0)
main.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 50)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(26, 26, 29)
header.BorderSizePixel = 0
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 14)
headerCorner.Parent = header

local headerFix = Instance.new("Frame")
headerFix.Size = UDim2.new(1, 0, 0, 15)
headerFix.Position = UDim2.new(0, 0, 1, -15)
headerFix.BackgroundColor3 = Color3.fromRGB(26, 26, 29)
headerFix.BorderSizePixel = 0
headerFix.Parent = header

-- Title with gradient
local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 150, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Avatar Catalog"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close
local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 35, 0, 35)
close.Position = UDim2.new(1, -43, 0, 8)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
close.Text = "X"
close.TextColor3 = Color3.fromRGB(200, 200, 205)
close.TextSize = 18
close.Font = Enum.Font.GothamBold
close.AutoButtonColor = false
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = close

-- Tabs Container
local tabs = Instance.new("Frame")
tabs.Size = UDim2.new(0, 200, 0, 36)
tabs.Position = UDim2.new(0, 20, 0, 62)
tabs.BackgroundTransparency = 1
tabs.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabs

-- LEFT SIDE - Content Container
local leftSide = Instance.new("Frame")
leftSide.Size = UDim2.new(0, 300, 1, -155)
leftSide.Position = UDim2.new(0, 20, 0, 105)
leftSide.BackgroundTransparency = 1
leftSide.Parent = main

-- Avatar Grid
local avatarContent = Instance.new("ScrollingFrame")
avatarContent.Name = "AvatarContent"
avatarContent.Size = UDim2.new(1, 0, 1, 0)
avatarContent.BackgroundTransparency = 1
avatarContent.BorderSizePixel = 0
avatarContent.ScrollBarThickness = 4
avatarContent.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 80)
avatarContent.CanvasSize = UDim2.new(0, 0, 0, 0)
avatarContent.Visible = true
avatarContent.Parent = leftSide

local avatarGrid = Instance.new("UIGridLayout")
avatarGrid.CellSize = UDim2.new(0, 68, 0, 88)
avatarGrid.CellPadding = UDim2.new(0, 6, 0, 6)
avatarGrid.Parent = avatarContent

local avatarPad = Instance.new("UIPadding")
avatarPad.PaddingTop = UDim.new(0, 3)
avatarPad.PaddingLeft = UDim.new(0, 3)
avatarPad.PaddingRight = UDim.new(0, 3)
avatarPad.Parent = avatarContent

-- Accessories Grid
local accessoryContent = Instance.new("ScrollingFrame")
accessoryContent.Name = "AccessoryContent"
accessoryContent.Size = UDim2.new(1, 0, 1, 0)
accessoryContent.BackgroundTransparency = 1
accessoryContent.BorderSizePixel = 0
accessoryContent.ScrollBarThickness = 4
accessoryContent.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 80)
accessoryContent.CanvasSize = UDim2.new(0, 0, 0, 0)
accessoryContent.Visible = false
accessoryContent.Parent = leftSide

local accessoryGrid = Instance.new("UIGridLayout")
accessoryGrid.CellSize = UDim2.new(0, 68, 0, 88)
accessoryGrid.CellPadding = UDim2.new(0, 6, 0, 6)
accessoryGrid.Parent = accessoryContent

local accessoryPad = Instance.new("UIPadding")
accessoryPad.PaddingTop = UDim.new(0, 3)
accessoryPad.PaddingLeft = UDim.new(0, 3)
accessoryPad.PaddingRight = UDim.new(0, 3)
accessoryPad.Parent = accessoryContent

-- RIGHT SIDE - 3D PREVIEW
local rightSide = Instance.new("Frame")
rightSide.Size = UDim2.new(0, 295, 1, -155)
rightSide.Position = UDim2.new(1, -315, 0, 105)
rightSide.BackgroundColor3 = Color3.fromRGB(26, 26, 29)
rightSide.BorderSizePixel = 0
rightSide.Parent = main

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 12)
rightCorner.Parent = rightSide

local rightStroke = Instance.new("UIStroke")
rightStroke.Color = Color3.fromRGB(40, 40, 45)
rightStroke.Thickness = 1
rightStroke.Parent = rightSide

-- Preview Title
local previewTitle = Instance.new("TextLabel")
previewTitle.Size = UDim2.new(1, 0, 0, 24)
previewTitle.BackgroundTransparency = 1
previewTitle.Text = "PREVIEW"
previewTitle.TextColor3 = Color3.fromRGB(150, 150, 160)
previewTitle.TextSize = 11
previewTitle.Font = Enum.Font.GothamBold
previewTitle.Parent = rightSide

-- ViewportFrame
local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(1, -8, 1, -28)
viewport.Position = UDim2.new(0, 4, 0, 26)
viewport.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
viewport.BorderSizePixel = 0
viewport.Parent = rightSide

local viewportCorner = Instance.new("UICorner")
viewportCorner.CornerRadius = UDim.new(0, 10)
viewportCorner.Parent = viewport

local camera = Instance.new("Camera")
camera.Parent = viewport
viewport.CurrentCamera = camera

local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport

local previewCharacter = nil
local rotationConnection = nil

-- Bottom Bar
local bottom = Instance.new("Frame")
bottom.Size = UDim2.new(1, -40, 0, 45)
bottom.Position = UDim2.new(0, 20, 1, -55)
bottom.BackgroundColor3 = Color3.fromRGB(26, 26, 29)
bottom.BorderSizePixel = 0
bottom.Parent = main

local bottomCorner = Instance.new("UICorner")
bottomCorner.CornerRadius = UDim.new(0, 10)
bottomCorner.Parent = bottom

local bottomStroke = Instance.new("UIStroke")
bottomStroke.Color = Color3.fromRGB(40, 40, 45)
bottomStroke.Thickness = 1
bottomStroke.Parent = bottom

-- Selected Name
local selectedName = Instance.new("TextLabel")
selectedName.Size = UDim2.new(0, 280, 1, 0)
selectedName.Position = UDim2.new(0, 15, 0, 0)
selectedName.BackgroundTransparency = 1
selectedName.Text = "Select an avatar"
selectedName.TextColor3 = Color3.fromRGB(180, 180, 190)
selectedName.TextSize = 12
selectedName.Font = Enum.Font.GothamMedium
selectedName.TextXAlignment = Enum.TextXAlignment.Left
selectedName.TextTruncate = Enum.TextTruncate.AtEnd
selectedName.Parent = bottom

-- Use/Add Button
local actionBtn = Instance.new("TextButton")
actionBtn.Size = UDim2.new(0, 90, 0, 32)
actionBtn.Position = UDim2.new(1, -195, 0.5, -16)
actionBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
actionBtn.BorderSizePixel = 0
actionBtn.Text = "Use"
actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
actionBtn.TextSize = 13
actionBtn.Font = Enum.Font.GothamBold
actionBtn.AutoButtonColor = false
actionBtn.Parent = bottom

local actionBtnCorner = Instance.new("UICorner")
actionBtnCorner.CornerRadius = UDim.new(0, 8)
actionBtnCorner.Parent = actionBtn

-- Reset Button
local resetBtn = Instance.new("TextButton")
resetBtn.Size = UDim2.new(0, 90, 0, 32)
resetBtn.Position = UDim2.new(1, -95, 0.5, -16)
resetBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
resetBtn.BorderSizePixel = 0
resetBtn.Text = "Reset"
resetBtn.TextColor3 = Color3.fromRGB(200, 200, 205)
resetBtn.TextSize = 13
resetBtn.Font = Enum.Font.GothamMedium
resetBtn.AutoButtonColor = false
resetBtn.Parent = bottom

local resetBtnCorner = Instance.new("UICorner")
resetBtnCorner.CornerRadius = UDim.new(0, 8)
resetBtnCorner.Parent = resetBtn

-- Variables
local currentMainTab = "Avatars"
local currentCategory = "Boys"
local selected = nil
local selectedAccessory = nil
local tabButtons = {}
local equippedAccessories = {}

-- Tween
local function tween(obj, props, time)
	TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad), props):Play()
end

-- Clear Preview
local function clearPreview()
	if rotationConnection then
		rotationConnection:Disconnect()
		rotationConnection = nil
	end

	if previewCharacter then
		previewCharacter:Destroy()
		previewCharacter = nil
	end

	worldModel:ClearAllChildren()
end

-- Load Preview (FIXED VERSION)
local function loadPreviewCharacter(userId)
	clearPreview()
	selectedName.Text = "Loading preview..."

	task.spawn(function()
		local success, character = pcall(function()
			return Players:CreateHumanoidModelFromUserId(userId)
		end)

		if success and character then
			character.Parent = worldModel
			previewCharacter = character

			-- Apply description
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				local descSuccess, description = pcall(function()
					return Players:GetHumanoidDescriptionFromUserId(userId)
				end)

				if descSuccess and description then
					pcall(function()
						humanoid:ApplyDescription(description)
					end)
				end
			end

			-- Wait for character to fully load
			task.wait(0.5)

			-- Setup camera
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Parent then
				hrp.Anchored = true

				local charSize = character:GetExtentsSize()
				local distance = math.max(charSize.X, charSize.Y, charSize.Z) * 1.2

				camera.CFrame = CFrame.new(
					Vector3.new(0, charSize.Y / 2.5, distance),
					Vector3.new(0, charSize.Y / 2.5, 0)
				)

				-- Rotation animation
				local angle = 0
				rotationConnection = RunService.RenderStepped:Connect(function(dt)
					if previewCharacter and previewCharacter.Parent and hrp and hrp.Parent then
						angle = angle + (dt * 40)
						hrp.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(angle), 0)
					else
						if rotationConnection then
							rotationConnection:Disconnect()
							rotationConnection = nil
						end
					end
				end)

				selectedName.Text = "Preview loaded!"
			else
				selectedName.Text = "Preview loaded"
			end
		else
			selectedName.Text = "Failed to load preview"
			warn("Failed to create character model for userId:", userId)
		end
	end)
end

-- Create Main Tab
local function createMainTab(name, icon)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 92, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	btn.BorderSizePixel = 0
	btn.Text = icon .. " " .. name
	btn.TextColor3 = Color3.fromRGB(140, 140, 150)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.AutoButtonColor = false
	btn.Parent = tabs

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	tabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		switchMainTab(name)
	end)

	return btn
end

-- Create Category Tab (Boys/Girls)
local categoryTabs = Instance.new("Frame")
categoryTabs.Size = UDim2.new(0, 150, 0, 34)
categoryTabs.Position = UDim2.new(0, 220, 0, 62)
categoryTabs.BackgroundTransparency = 1
categoryTabs.Visible = false
categoryTabs.Parent = main

local categoryLayout = Instance.new("UIListLayout")
categoryLayout.FillDirection = Enum.FillDirection.Horizontal
categoryLayout.Padding = UDim.new(0, 8)
categoryLayout.Parent = categoryTabs

local categoryButtons = {}

local function createCategoryTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 70, 0, 34)
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	btn.BorderSizePixel = 0
	btn.Text = name
	btn.TextColor3 = Color3.fromRGB(140, 140, 150)
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.AutoButtonColor = false
	btn.Parent = categoryTabs

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = btn

	categoryButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		loadCategory(name)
	end)

	return btn
end

-- Switch Main Tab
function switchMainTab(tab)
	currentMainTab = tab

	for name, btn in pairs(tabButtons) do
		if name == tab then
			tween(btn, {BackgroundColor3 = Color3.fromRGB(114, 137, 218), TextColor3 = Color3.fromRGB(255, 255, 255)})
		else
			tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(140, 140, 150)})
		end
	end

	if tab == "Avatars" then
		avatarContent.Visible = true
		accessoryContent.Visible = false
		categoryTabs.Visible = true
		actionBtn.Text = "Use"
		selectedName.Text = "Select an avatar"
	elseif tab == "Items" then
		avatarContent.Visible = false
		accessoryContent.Visible = true
		categoryTabs.Visible = false
		actionBtn.Text = "Add"
		selectedName.Text = "Select an item"
		loadAccessories()
	end

	clearPreview()
	selected = nil
	selectedAccessory = nil
end

-- Create Avatar Card
local function createAvatarCard(data)
	local card = Instance.new("TextButton")
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.Parent = avatarContent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 45)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = card

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, -8, 0, 58)
	img.Position = UDim2.new(0, 4, 0, 4)
	img.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	img.BorderSizePixel = 0
	img.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. data.id .. "&width=150&height=150&format=png"
	img.ScaleType = Enum.ScaleType.Crop
	img.Parent = card

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 8)
	imgCorner.Parent = img

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -6, 0, 24)
	name.Position = UDim2.new(0, 3, 0, 64)
	name.BackgroundTransparency = 1
	name.Text = data.name
	name.TextColor3 = Color3.fromRGB(210, 210, 220)
	name.TextSize = 10
	name.Font = Enum.Font.GothamMedium
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextWrapped = true
	name.Parent = card

	card.MouseEnter:Connect(function()
		if selected ~= data then
			tween(card, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)})
			tween(stroke, {Transparency = 0})
		end
	end)

	card.MouseLeave:Connect(function()
		if selected ~= data then
			tween(card, {BackgroundColor3 = Color3.fromRGB(28, 28, 32)})
			tween(stroke, {Transparency = 0.5})
		end
	end)

	card.MouseButton1Click:Connect(function()
		selected = data
		selectedAccessory = nil
		selectedName.Text = data.name

		loadPreviewCharacter(data.id)

		for _, c in pairs(avatarContent:GetChildren()) do
			if c:IsA("TextButton") then
				local s = c:FindFirstChildOfClass("UIStroke")
				tween(c, {BackgroundColor3 = Color3.fromRGB(28, 28, 32)})
				if s then s.Color = Color3.fromRGB(40, 40, 45) end
			end
		end
		tween(card, {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})
		stroke.Color = Color3.fromRGB(114, 137, 218)
	end)
end

-- Create Accessory Card
local function createAccessoryCard(data)
	local card = Instance.new("TextButton")
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.Parent = accessoryContent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(40, 40, 45)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = card

	local img = Instance.new("ImageLabel")
	img.Size = UDim2.new(1, -8, 0, 58)
	img.Position = UDim2.new(0, 4, 0, 4)
	img.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	img.BorderSizePixel = 0
	img.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	img.ScaleType = Enum.ScaleType.Fit
	img.Parent = card

	task.spawn(function()
		local success, result = pcall(function()
			return "https://www.roblox.com/asset-thumbnail/image?assetId=" .. data.id .. "&width=150&height=150&format=png"
		end)
		if success then img.Image = result end
	end)

	local imgCorner = Instance.new("UICorner")
	imgCorner.CornerRadius = UDim.new(0, 8)
	imgCorner.Parent = img

	local equipped = Instance.new("TextLabel")
	equipped.Size = UDim2.new(1, -8, 0, 16)
	equipped.Position = UDim2.new(0, 4, 0, 4)
	equipped.BackgroundColor3 = Color3.fromRGB(67, 181, 129)
	equipped.BorderSizePixel = 0
	equipped.Text = "✓ EQUIPPED"
	equipped.TextColor3 = Color3.fromRGB(255, 255, 255)
	equipped.TextSize = 9
	equipped.Font = Enum.Font.GothamBold
	equipped.Visible = false
	equipped.Parent = card

	local equippedCorner = Instance.new("UICorner")
	equippedCorner.CornerRadius = UDim.new(0, 8)
	equippedCorner.Parent = equipped

	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -6, 0, 24)
	name.Position = UDim2.new(0, 3, 0, 64)
	name.BackgroundTransparency = 1
	name.Text = data.name
	name.TextColor3 = Color3.fromRGB(210, 210, 220)
	name.TextSize = 9
	name.Font = Enum.Font.GothamMedium
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextWrapped = true
	name.Parent = card

	if equippedAccessories[data.id] then
		equipped.Visible = true
	end

	card.MouseEnter:Connect(function()
		if selectedAccessory ~= data then
			tween(card, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)})
			tween(stroke, {Transparency = 0})
		end
	end)

	card.MouseLeave:Connect(function()
		if selectedAccessory ~= data then
			tween(card, {BackgroundColor3 = Color3.fromRGB(28, 28, 32)})
			tween(stroke, {Transparency = 0.5})
		end
	end)

	card.MouseButton1Click:Connect(function()
		selectedAccessory = data
		selected = nil
		selectedName.Text = data.name

		for _, c in pairs(accessoryContent:GetChildren()) do
			if c:IsA("TextButton") then
				local s = c:FindFirstChildOfClass("UIStroke")
				tween(c, {BackgroundColor3 = Color3.fromRGB(28, 28, 32)})
				if s then s.Color = Color3.fromRGB(40, 40, 45) end
			end
		end
		tween(card, {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})
		stroke.Color = Color3.fromRGB(114, 137, 218)

		if equippedAccessories[data.id] then
			actionBtn.Text = "Remove"
			actionBtn.BackgroundColor3 = Color3.fromRGB(237, 66, 69)
		else
			actionBtn.Text = "Add"
			actionBtn.BackgroundColor3 = Color3.fromRGB(114, 137, 218)
		end
	end)

	return card
end

-- Load Category
function loadCategory(cat)
	currentCategory = cat

	for name, btn in pairs(categoryButtons) do
		if name == cat then
			tween(btn, {BackgroundColor3 = Color3.fromRGB(114, 137, 218), TextColor3 = Color3.fromRGB(255, 255, 255)})
		else
			tween(btn, {BackgroundColor3 = Color3.fromRGB(30, 30, 35), TextColor3 = Color3.fromRGB(140, 140, 150)})
		end
	end

	for _, c in pairs(avatarContent:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for _, data in ipairs(AVATARS[cat] or {}) do
		createAvatarCard(data)
	end

	avatarContent.CanvasSize = UDim2.new(0, 0, 0, avatarGrid.AbsoluteContentSize.Y + 6)
	selected = nil
	selectedName.Text = "Select an avatar"
	clearPreview()
end

-- Load Accessories
function loadAccessories()
	for _, c in pairs(accessoryContent:GetChildren()) do
		if c:IsA("TextButton") then c:Destroy() end
	end

	for _, data in ipairs(ACCESSORIES) do
		createAccessoryCard(data)
	end

	accessoryContent.CanvasSize = UDim2.new(0, 0, 0, accessoryGrid.AbsoluteContentSize.Y + 6)
end

-- Init
createMainTab("Avatars", "👤")
createMainTab("Items", "🎩")

createCategoryTab("Boys")
createCategoryTab("Girls")

categoryTabs.Visible = true
loadCategory("Boys")
switchMainTab("Avatars")

-- Canvas update
avatarGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	avatarContent.CanvasSize = UDim2.new(0, 0, 0, avatarGrid.AbsoluteContentSize.Y + 6)
end)

accessoryGrid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	accessoryContent.CanvasSize = UDim2.new(0, 0, 0, accessoryGrid.AbsoluteContentSize.Y + 6)
end)

-- Open/Close (TANPA ANIMASI)
avatarIcon:bindEvent("selected", function()
	overlay.Visible = true
	overlay.BackgroundTransparency = 0.55
	main.Visible = true
end)

avatarIcon:bindEvent("deselected", function()
	overlay.Visible = false
	main.Visible = false
	clearPreview()
end)

close.MouseButton1Click:Connect(function()
	avatarIcon:deselect()
end)

close.MouseEnter:Connect(function()
	tween(close, {BackgroundColor3 = Color3.fromRGB(237, 66, 69), TextColor3 = Color3.fromRGB(255, 255, 255)})
end)

close.MouseLeave:Connect(function()
	tween(close, {BackgroundColor3 = Color3.fromRGB(35, 35, 40), TextColor3 = Color3.fromRGB(200, 200, 205)})
end)

-- Action Button
actionBtn.MouseButton1Click:Connect(function()
	if currentMainTab == "Avatars" and selected then
		changeAvatarEvent:FireServer(selected.id)
		actionBtn.Text = "✓"
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(67, 181, 129)})

		task.wait(0.5)
		avatarIcon:deselect()

		task.wait(0.3)
		actionBtn.Text = "Use"
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})

	elseif currentMainTab == "Items" and selectedAccessory then
		if equippedAccessories[selectedAccessory.id] then
			removeAccessoryEvent:FireServer(selectedAccessory.id)
			equippedAccessories[selectedAccessory.id] = nil
			actionBtn.Text = "Add"
			tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})
		else
			addAccessoryEvent:FireServer(selectedAccessory.id)
			equippedAccessories[selectedAccessory.id] = true
			actionBtn.Text = "Remove"
			tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(237, 66, 69)})
		end
		loadAccessories()
	end
end)

actionBtn.MouseEnter:Connect(function()
	if actionBtn.Text == "Use" or actionBtn.Text == "Add" then
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(124, 147, 228)})
	elseif actionBtn.Text == "Remove" then
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(247, 76, 79)})
	end
end)

actionBtn.MouseLeave:Connect(function()
	if actionBtn.Text == "Use" or actionBtn.Text == "Add" then
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})
	elseif actionBtn.Text == "Remove" then
		tween(actionBtn, {BackgroundColor3 = Color3.fromRGB(237, 66, 69)})
	end
end)

-- Reset Button
resetBtn.MouseButton1Click:Connect(function()
	resetAvatarEvent:FireServer()
	equippedAccessories = {}
	selected = nil
	selectedAccessory = nil
	selectedName.Text = "Avatar reset!"

	for _, c in pairs(avatarContent:GetChildren()) do
		if c:IsA("TextButton") then
			local s = c:FindFirstChildOfClass("UIStroke")
			tween(c, {BackgroundColor3 = Color3.fromRGB(28, 28, 32)})
			if s then s.Color = Color3.fromRGB(40, 40, 45) end
		end
	end

	if currentMainTab == "Items" then loadAccessories() end
	clearPreview()

	task.wait(0.8)
	selectedName.Text = "Select an avatar"
end)

resetBtn.MouseEnter:Connect(function()
	tween(resetBtn, {BackgroundColor3 = Color3.fromRGB(45, 45, 52)})
end)

resetBtn.MouseLeave:Connect(function()
	tween(resetBtn, {BackgroundColor3 = Color3.fromRGB(35, 35, 40)})
end)

print("✨ Avatar Catalog - Ready!")
