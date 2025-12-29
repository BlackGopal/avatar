--// Boombox Client UI (by kuli komis)

local tool = script.Parent
local remote = tool:WaitForChild("Remote")
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local marketplace = game:GetService("MarketplaceService")

-- buat UI hanya sekali
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BoomboxUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = gui

-- frame utama
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 240)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.45, 0) -- tengah sedikit ke atas
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Visible = true
frame.Parent = screenGui

-- rounded corner
Instance.new("UICorner", frame)

-- judul
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "Boombox Player"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- tombol close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 90, 90)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 26
closeBtn.Parent = frame

-- input ID
local input = Instance.new("TextBox")
input.PlaceholderText = "Masukkan ID Musik..."
input.Size = UDim2.new(1, -20, 0, 30)
input.Position = UDim2.new(0, 10, 0, 45)
input.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.Font = Enum.Font.Gotham
input.TextSize = 16
input.ClearTextOnFocus = false
Instance.new("UICorner", input)
input.Parent = frame

-- tombol play manual
local playBtn = Instance.new("TextButton")
playBtn.Text = "▶️ Play"
playBtn.Size = UDim2.new(1, -20, 0, 30)
playBtn.Position = UDim2.new(0, 10, 0, 80)
playBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
playBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
playBtn.Font = Enum.Font.GothamBold
playBtn.TextSize = 16
Instance.new("UICorner", playBtn)
playBtn.Parent = frame

-- daftar lagu otomatis (bisa kamu ganti id-nya)
local songs = {
	-- dari list lama
	"114669676583992",
	"98844151317369",
	"108633691126542",
	"71882835188517",
	"75868550437395",
	"102226752843361",
	"71194734259803",
	"136460486693864",

	-- tambahan (tanpa duplikat)
	"91936459020996",
	"137771074649953",
	"113786223042435",
	"95764755468444",
	"83596428711098",
	"106640427522329",
	"103455474348459",
	"136834864966642",
	"137280724241225",
	"133255229639519",
	"81489966591916",
	"75035768683544",
	"88442309168459",
	"139287963613241",
	"94033787163834",
	"129728977330414",
	"108027633492475",

	-- bawaan sebelumnya
	"116255319981650",
	"88691296316236",
	"116647235474599",
	"74932161532936",
	"79298130320884",
	"112930367758222",
	"91859155312932",
	"139590201617508",
	"130721206402716",
	"101456813429584",
	"129988226070628",
	"119254319180287",
	"118538313029983",
	"82162714102729",
	"126397167396751",
	"83817418053316",
	"109184193897016",
}

-- wadah list
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 0, 100)
scroll.Position = UDim2.new(0, 10, 0, 120)
scroll.CanvasSize = UDim2.new(0, 0, 0, #songs * 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 6
scroll.Parent = frame

-- isi daftar lagu
task.spawn(function()
    for i, id in ipairs(songs) do
        local titleName = "Audio ID: " .. id
        pcall(function()
            local info = marketplace:GetProductInfo(id)
            if info and info.Name then
                titleName = info.Name
            end
        end)
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Position = UDim2.new(0, 0, 0, (i - 1) * 35)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 14
        btn.Text = titleName
        btn.Parent = scroll
        Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            remote:FireServer("PlaySong", id)
        end)
    end
end)

-- play dari input manual
playBtn.MouseButton1Click:Connect(function()
    local id = input.Text:match("%d+")
    if id then
        remote:FireServer("PlaySong", id)
    else
        input.PlaceholderText = "⚠️ Masukkan angka ID valid"
    end
end)

-- close UI
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

-- tampil UI saat equip
tool.Equipped:Connect(function()
    screenGui.Enabled = true
end)

tool.Unequipped:Connect(function()
    screenGui.Enabled = false
end)


