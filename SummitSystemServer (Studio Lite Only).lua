local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Config = require(ReplicatedStorage:WaitForChild("CheckpointConfig"))

local checkpointStore = DataStoreService:GetDataStore(Config.DataStoreKeys.Checkpoints)
local summitStore = DataStoreService:GetDataStore(Config.DataStoreKeys.Records)
local globalLeaderboardStore = DataStoreService:GetDataStore(Config.DataStoreKeys.GlobalLeaderboard)

local remoteFolder = ReplicatedStorage:FindFirstChild("SummitRemotes") or Instance.new("Folder", ReplicatedStorage)
remoteFolder.Name = "SummitRemotes"

local checkpointEvent = remoteFolder:FindFirstChild("CheckpointReached") or Instance.new("RemoteEvent", remoteFolder)
checkpointEvent.Name = "CheckpointReached"

local summitEvent = remoteFolder:FindFirstChild("SummitReached") or Instance.new("RemoteEvent", remoteFolder)
summitEvent.Name = "SummitReached"

local notificationEvent = remoteFolder:FindFirstChild("ShowNotification") or Instance.new("RemoteEvent", remoteFolder)
notificationEvent.Name = "ShowNotification"

local adminCommandRemote = remoteFolder:FindFirstChild("AdminCommand") or Instance.new("RemoteEvent", remoteFolder)
adminCommandRemote.Name = "AdminCommand"

local gameRemoteFolder = ReplicatedStorage:FindFirstChild("GameRemotes") or Instance.new("Folder", ReplicatedStorage)
gameRemoteFolder.Name = "GameRemotes"

local resetRemote = gameRemoteFolder:FindFirstChild("ResetRemote") or Instance.new("RemoteEvent", gameRemoteFolder)
resetRemote.Name = "ResetRemote"

local updateLeaderboardsBindable = ServerStorage:FindFirstChild("UpdateSummitLeaderboards") or Instance.new("BindableEvent")
updateLeaderboardsBindable.Name = "UpdateSummitLeaderboards"
updateLeaderboardsBindable.Parent = ServerStorage

local playerData = {}
_G.SummitSystemPlayerData = playerData  
local dataLoadQueue = {}
local lastResetRequest = {}
local saveQueue = {}
local isSaving = false

-- FIX: Tambahan untuk Studio Lite - tracking spawn ready
local playerSpawnReady = {}

local ADMIN_USERNAMES = {
	["tropis_72"] = true,
}

local function getCheckpointCount()
	local folder = workspace:FindFirstChild(Config.Settings.CheckpointFolderName)
	if not folder then 
		warn("?? Checkpoint folder tidak ditemukan!")
		return 0 
	end
	local count = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then count = count + 1 end
	end
	return count
end

local function getCheckpointNumber(part)
	return tonumber(string.match(part.Name, "%d+")) or 0
end

local function isAdmin(player)
	return ADMIN_USERNAMES[string.lower(player.Name)] == true
end

local function updateGlobalLeaderboard(userId, username, count)
	task.spawn(function()
		local success, err = pcall(function()
			local currentData = globalLeaderboardStore:GetAsync("TopSummits") or {}

			local found = false
			for i, entry in ipairs(currentData) do
				if entry.userId == userId then
					entry.summitCount = count
					entry.username = username
					entry.lastUpdated = os.time()
					found = true
					break
				end
			end

			if not found then
				table.insert(currentData, {
					userId = userId, 
					username = username, 
					summitCount = count,
					lastUpdated = os.time()
				})
			end

			table.sort(currentData, function(a, b) 
				return a.summitCount > b.summitCount 
			end)

			if #currentData > 50 then
				for i = 51, #currentData do 
					currentData[i] = nil 
				end
			end

			globalLeaderboardStore:SetAsync("TopSummits", currentData)
			updateLeaderboardsBindable:Fire(currentData)

			print("? Global Leaderboard updated: "..username.." dengan "..count.." summits")
		end)

		if not success then
			warn("? Gagal update global leaderboard:", err)
		end
	end)
end

local function loadData(player)
	if not player or not player:IsDescendantOf(Players) then return nil end

	local userId = player.UserId

	if dataLoadQueue[userId] then
		local waitTime = 0
		while dataLoadQueue[userId] and waitTime < 10 do
			task.wait(0.1)
			waitTime = waitTime + 0.1
		end
		if playerData[userId] then
			return playerData[userId]
		end
	end

	dataLoadQueue[userId] = true

	local defaultData = {
		checkpoint = 0,
		summitCount = 0,
		lastTouch = 0,
		lastSave = 0
	}

	local cpData = nil
	local sumData = nil

	for attempt = 1, 3 do
		local success1, result1 = pcall(function()
			return checkpointStore:GetAsync("Player_" .. userId)
		end)

		if success1 then
			cpData = result1
			break
		else
			warn("?? Attempt "..attempt.."/3 - Gagal load checkpoint data untuk "..player.Name..": "..tostring(result1))
			if attempt < 3 then task.wait(1) end
		end
	end

	for attempt = 1, 3 do
		local success2, result2 = pcall(function()
			return summitStore:GetAsync("Player_" .. userId)
		end)

		if success2 then
			sumData = result2
			break
		else
			warn("?? Attempt "..attempt.."/3 - Gagal load summit data untuk "..player.Name..": "..tostring(result2))
			if attempt < 3 then task.wait(1) end
		end
	end

	playerData[userId] = {
		checkpoint = (cpData and cpData.checkpoint) or defaultData.checkpoint,
		summitCount = (sumData and sumData.summitCount) or defaultData.summitCount,
		lastTouch = defaultData.lastTouch,
		lastSave = defaultData.lastSave
	}

	dataLoadQueue[userId] = nil

	print("? Data loaded untuk "..player.Name..": CP="..playerData[userId].checkpoint..", Summits="..playerData[userId].summitCount)
	return playerData[userId]
end

local function getUserIdFromUsername(username)
	local success, userId = pcall(function()
		return Players:GetUserIdFromNameAsync(username)
	end)

	if success and userId then
		return userId
	end
	return nil
end

local function loadOfflinePlayerData(userId)
	local cpData = nil
	local sumData = nil

	local success1, result1 = pcall(function()
		return checkpointStore:GetAsync("Player_" .. userId)
	end)
	if success1 then
		cpData = result1
	end

	local success2, result2 = pcall(function()
		return summitStore:GetAsync("Player_" .. userId)
	end)
	if success2 then
		sumData = result2
	end

	return {
		checkpoint = (cpData and cpData.checkpoint) or 0,
		summitCount = (sumData and sumData.summitCount) or 0,
		lastTouch = 0,
		lastSave = tick()
	}
end

local function saveOfflinePlayerData(userId, data)
	local success = true

	pcall(function()
		checkpointStore:SetAsync("Player_" .. userId, {
			checkpoint = data.checkpoint,
			lastUpdated = os.time()
		})
	end)

	task.wait(0.5)

	pcall(function()
		summitStore:SetAsync("Player_" .. userId, {
			summitCount = data.summitCount,
			lastUpdated = os.time()
		})
	end)

	return success
end

local function saveData(player, forceSync)
	if not player or not player:IsDescendantOf(Players) then return end

	local userId = player.UserId
	local data = playerData[userId]
	if not data then return end

	if not forceSync and (tick() - data.lastSave < 10) then
		return
	end

	saveQueue[userId] = {
		player = player,
		data = {
			checkpoint = data.checkpoint,
			summitCount = data.summitCount,
			lastSave = data.lastSave
		},
		timestamp = tick()
	}
end

task.spawn(function()
	while true do
		task.wait(2)

		if isSaving then
			continue
		end

		local userId, queueData = next(saveQueue)
		if not userId then
			continue
		end

		isSaving = true
		saveQueue[userId] = nil

		local player = queueData.player
		local data = queueData.data

		if player and player:IsDescendantOf(Players) then
			local success = pcall(function()
				checkpointStore:SetAsync("Player_" .. userId, {
					checkpoint = data.checkpoint,
					lastUpdated = os.time()
				})
			end)

			task.wait(0.5)

			local success2 = pcall(function()
				summitStore:SetAsync("Player_" .. userId, {
					summitCount = data.summitCount,
					lastUpdated = os.time()
				})
			end)

			if success and success2 then
				if playerData[userId] then
					playerData[userId].lastSave = tick()
				end
				print("?? Data saved untuk "..player.Name)
			else
				warn("?? Save gagal untuk "..player.Name..", akan retry nanti")
				saveQueue[userId] = queueData
			end
		end

		isSaving = false
		task.wait(1)
	end
end)

local function updateLeaderstats(player)
	if not player or not player:IsDescendantOf(Players) then return end

	local data = playerData[player.UserId]
	if not data then return end

	local maxAttempts = 5
	for attempt = 1, maxAttempts do
		local ls = player:FindFirstChild(Config.Leaderstats.FolderName)

		if ls then
			local cpStat = ls:FindFirstChild(Config.Leaderstats.CheckpointStatName)
			local sumStat = ls:FindFirstChild(Config.Leaderstats.SummitStatName)

			if cpStat and sumStat then
				cpStat.Value = data.checkpoint
				sumStat.Value = data.summitCount
				return
			else
				if attempt < maxAttempts then
					task.wait(0.1)
				end
			end
		else
			if attempt < maxAttempts then
				task.wait(0.1)
			end
		end
	end

	warn("?? Gagal update leaderstats untuk "..player.Name.." setelah "..maxAttempts.." percobaan")
end

-- FIX: Teleport function yang lebih robust untuk Studio Lite
local function teleportToCheckpoint(character, checkpointNumber)
	if not character or not character:IsA("Model") then 
		warn("?? Character invalid")
		return false 
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp or not hrp:IsA("BasePart") then
		warn("?? HumanoidRootPart atau Humanoid tidak ditemukan")
		return false
	end

	local cpFolder = workspace:FindFirstChild(Config.Settings.CheckpointFolderName)
	if not cpFolder then
		warn("?? Checkpoint folder tidak ditemukan")
		return false
	end

	local cpPart = cpFolder:FindFirstChild("Checkpoint"..checkpointNumber) 
		or cpFolder:FindFirstChild(tostring(checkpointNumber))
		or cpFolder:FindFirstChild("CP"..checkpointNumber)

	if not cpPart or not cpPart:IsA("BasePart") then
		warn("?? Checkpoint part "..checkpointNumber.." tidak ditemukan")
		return false
	end

	local success = pcall(function()
		-- FIX 1: Reset physics lebih agresif untuk Studio Lite
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)

		-- FIX 2: Freeze character untuk prevent jitter
		hrp.Anchored = true

		-- FIX 3: Clear semua velocity
		for _, part in pairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Velocity = Vector3.zero
				part.RotVelocity = Vector3.zero
				part.AssemblyLinearVelocity = Vector3.zero
				part.AssemblyAngularVelocity = Vector3.zero
			end
		end

		-- FIX 4: Teleport dengan offset lebih tinggi
		local targetCFrame = cpPart.CFrame * CFrame.new(0, 7, 0)
		character:PivotTo(targetCFrame)
		hrp.CFrame = targetCFrame

		-- FIX 5: Wait sebelum unanchor (penting untuk Studio Lite)
		task.wait(0.1)

		-- FIX 6: Unanchor dan set state
		hrp.Anchored = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

		-- FIX 7: Double check velocity clear
		task.wait(0.05)
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero

		humanoid.AutoRotate = true
	end)

	if success then
		print("? Teleport berhasil ke checkpoint "..checkpointNumber)
	else
		warn("? Gagal teleport ke checkpoint "..checkpointNumber)
	end

	return success
end

local function sendAdminNotification(player, message, colorType)
	if player and player:IsDescendantOf(Players) then
		pcall(function()
			notificationEvent:FireClient(player, message, colorType or "info")
		end)
	end
end

local function handleAdminCommand(player, commandString)
	if not isAdmin(player) then
		warn("?? [SECURITY] "..player.Name.." mencoba admin command tanpa izin!")
		return
	end

	local args = {}
	for word in string.gmatch(commandString, "%S+") do
		table.insert(args, string.lower(word))
	end

	local cmd = args[1]
	print("?? Admin command dari "..player.Name..": "..commandString)

	if cmd == "add" then
		local username = args[2]
		local amount = tonumber(args[3])

		if not username or not amount then
			sendAdminNotification(player, "? Format: add <username> <amount>", "error")
			return
		end

		local targetPlayer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == username then
				targetPlayer = p
				break
			end
		end

		if targetPlayer then
			local userId = targetPlayer.UserId
			local data = playerData[userId]

			if not data then
				sendAdminNotification(player, "? Loading data "..targetPlayer.Name.."...", "info")
				data = loadData(targetPlayer)
				task.wait(0.5)
			end

			if not data then
				sendAdminNotification(player, "? Gagal load data "..targetPlayer.Name, "error")
				return
			end

			local totalCP = getCheckpointCount()
			local newCheckpoint = math.min(data.checkpoint + amount, totalCP)
			data.checkpoint = newCheckpoint
			data.lastTouch = tick()

			task.wait(0.2)
			updateLeaderstats(targetPlayer)
			saveData(targetPlayer, true)
			updateLeaderboardsBindable:Fire(nil)

			sendAdminNotification(player, "? "..targetPlayer.Name.." checkpoint: "..newCheckpoint.."/"..totalCP, "success")
			sendAdminNotification(targetPlayer, "? Admin menambahkan "..amount.." checkpoint", "info")

			print("? Admin "..player.Name.." menambahkan "..amount.." checkpoint untuk "..targetPlayer.Name.." (ONLINE)")

		else
			sendAdminNotification(player, "? Loading offline player '"..username.."'...", "info")

			local userId = getUserIdFromUsername(username)
			if not userId then
				sendAdminNotification(player, "? Player '"..username.."' tidak ditemukan", "error")
				return
			end

			local data = loadOfflinePlayerData(userId)
			local totalCP = getCheckpointCount()
			local newCheckpoint = math.min(data.checkpoint + amount, totalCP)
			data.checkpoint = newCheckpoint

			saveOfflinePlayerData(userId, data)
			updateLeaderboardsBindable:Fire(nil)

			sendAdminNotification(player, "? "..username.." (OFFLINE) checkpoint: "..newCheckpoint.."/"..totalCP, "success")
			print("? Admin "..player.Name.." menambahkan "..amount.." checkpoint untuk "..username.." (OFFLINE)")
		end

	elseif cmd == "addsummit" then
		local username = args[2]
		local amount = tonumber(args[3])

		if not username or not amount then
			sendAdminNotification(player, "? Format: addsummit <username> <amount>", "error")
			return
		end

		local targetPlayer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == username then
				targetPlayer = p
				break
			end
		end

		if targetPlayer then
			local userId = targetPlayer.UserId
			local data = playerData[userId]

			if not data then
				sendAdminNotification(player, "? Loading data "..targetPlayer.Name.."...", "info")
				data = loadData(targetPlayer)
				task.wait(0.5)
			end

			if not data then
				sendAdminNotification(player, "? Gagal load data "..targetPlayer.Name, "error")
				return
			end

			data.summitCount = data.summitCount + amount
			data.lastTouch = tick()

			task.wait(0.2)
			updateLeaderstats(targetPlayer)
			saveData(targetPlayer, true)
			updateGlobalLeaderboard(userId, targetPlayer.Name, data.summitCount)
			updateLeaderboardsBindable:Fire(nil)

			sendAdminNotification(player, "? "..targetPlayer.Name.." summit: "..data.summitCount, "success")
			sendAdminNotification(targetPlayer, "?? Admin menambahkan "..amount.." summit points", "summit")

			print("? Admin "..player.Name.." menambahkan "..amount.." summit untuk "..targetPlayer.Name.." (ONLINE)")

		else
			sendAdminNotification(player, "? Loading offline player '"..username.."'...", "info")

			local userId = getUserIdFromUsername(username)
			if not userId then
				sendAdminNotification(player, "? Player '"..username.."' tidak ditemukan", "error")
				return
			end

			local data = loadOfflinePlayerData(userId)
			data.summitCount = data.summitCount + amount

			saveOfflinePlayerData(userId, data)
			updateGlobalLeaderboard(userId, username, data.summitCount)
			updateLeaderboardsBindable:Fire(nil)

			sendAdminNotification(player, "? "..username.." (OFFLINE) summit: "..data.summitCount, "success")
			print("? Admin "..player.Name.." menambahkan "..amount.." summit untuk "..username.." (OFFLINE)")
		end

	elseif cmd == "remove" or cmd == "removeplayer" then
		local username = args[2]

		if not username then
			sendAdminNotification(player, "? Format: removeplayer <username>", "error")
			return
		end

		local targetPlayer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == username then
				targetPlayer = p
				break
			end
		end

		if targetPlayer then
			local userId = targetPlayer.UserId

			playerData[userId] = {
				checkpoint = 0,
				summitCount = 0,
				lastTouch = 0,
				lastSave = 0
			}

			local deleteSuccess = true
			for attempt = 1, 3 do
				local s1, e1 = pcall(function()
					checkpointStore:RemoveAsync("Player_" .. userId)
				end)
				local s2, e2 = pcall(function()
					summitStore:RemoveAsync("Player_" .. userId)
				end)
				local s3, e3 = pcall(function()
					local currentData = globalLeaderboardStore:GetAsync("TopSummits") or {}
					for i = #currentData, 1, -1 do
						if currentData[i].userId == userId then
							table.remove(currentData, i)
						end
					end
					globalLeaderboardStore:SetAsync("TopSummits", currentData)
				end)

				if s1 and s2 and s3 then
					deleteSuccess = true
					break
				else
					warn("?? Attempt "..attempt.."/3 - Gagal delete data")
					deleteSuccess = false
					if attempt < 3 then task.wait(1) end
				end
			end

			local ls = targetPlayer:FindFirstChild(Config.Leaderstats.FolderName)
			if ls then
				local cpStat = ls:FindFirstChild(Config.Leaderstats.CheckpointStatName)
				local sumStat = ls:FindFirstChild(Config.Leaderstats.SummitStatName)
				if cpStat then cpStat.Value = 0 end
				if sumStat then sumStat.Value = 0 end
			end

			updateLeaderboardsBindable:Fire(nil)

			if deleteSuccess then
				sendAdminNotification(player, "? "..targetPlayer.Name.." dihapus dari leaderboard (ONLINE)", "success")
				sendAdminNotification(targetPlayer, "?? Data Anda telah direset oleh admin", "warning")
				print("? Admin "..player.Name.." menghapus data "..targetPlayer.Name.." (ONLINE)")
			else
				sendAdminNotification(player, "?? Player dihapus tapi ada error di DataStore", "warning")
			end

		else
			sendAdminNotification(player, "? Removing offline player '"..username.."'...", "info")

			local userId = getUserIdFromUsername(username)
			if not userId then
				sendAdminNotification(player, "? Player '"..username.."' tidak ditemukan", "error")
				return
			end

			local deleteSuccess = pcall(function()
				checkpointStore:RemoveAsync("Player_" .. userId)
			end)

			task.wait(0.5)

			pcall(function()
				summitStore:RemoveAsync("Player_" .. userId)
			end)

			task.wait(0.5)

			pcall(function()
				local currentData = globalLeaderboardStore:GetAsync("TopSummits") or {}
				for i = #currentData, 1, -1 do
					if currentData[i].userId == userId then
						table.remove(currentData, i)
					end
				end
				globalLeaderboardStore:SetAsync("TopSummits", currentData)
			end)

			updateLeaderboardsBindable:Fire(nil)

			sendAdminNotification(player, "? "..username.." (OFFLINE) dihapus dari leaderboard", "success")
			print("? Admin "..player.Name.." menghapus "..username.." (OFFLINE)")
		end

	elseif cmd == "resetprogress" then
		local username = args[2]

		if not username then
			sendAdminNotification(player, "? Format: resetprogress <username>", "error")
			return
		end

		local targetPlayer = nil
		for _, p in ipairs(Players:GetPlayers()) do
			if string.lower(p.Name) == username then
				targetPlayer = p
				break
			end
		end

		if targetPlayer then
			local data = playerData[targetPlayer.UserId]
			if data then
				data.checkpoint = 0
				data.summitCount = 0
				data.lastTouch = 0

				updateLeaderstats(targetPlayer)
				saveData(targetPlayer, true)

				sendAdminNotification(player, "? Progress "..targetPlayer.Name.." direset (ONLINE)", "success")
				sendAdminNotification(targetPlayer, "?? Progress Anda direset oleh admin", "warning")

				print("? Admin "..player.Name.." mereset progress "..targetPlayer.Name.." (ONLINE)")
			end

		else
			sendAdminNotification(player, "? Resetting offline player '"..username.."'...", "info")

			local userId = getUserIdFromUsername(username)
			if not userId then
				sendAdminNotification(player, "? Player '"..username.."' tidak ditemukan", "error")
				return
			end

			local data = {
				checkpoint = 0,
				summitCount = 0,
				lastTouch = 0,
				lastSave = tick()
			}

			saveOfflinePlayerData(userId, data)

			sendAdminNotification(player, "? Progress "..username.." (OFFLINE) direset", "success")
			print("? Admin "..player.Name.." mereset progress "..username.." (OFFLINE)")
		end

	elseif cmd == "resetall" then
		local count = 0
		for _, p in ipairs(Players:GetPlayers()) do
			local data = playerData[p.UserId]
			if data then
				data.checkpoint = 0
				data.summitCount = 0
				data.lastTouch = 0

				updateLeaderstats(p)
				saveData(p, true)

				sendAdminNotification(p, "?? Semua progress direset oleh admin", "warning")
				count = count + 1
			end
		end

		sendAdminNotification(player, "? "..count.." player direset", "success")
		print("? Admin "..player.Name.." mereset semua player")

	elseif cmd == "refreshdisplay" then
		updateLeaderboardsBindable:Fire(nil)
		sendAdminNotification(player, "? Display leaderboard direfresh", "success")
		print("? Admin "..player.Name.." refresh leaderboard")

	else
		sendAdminNotification(player, "? Command tidak dikenali: "..tostring(cmd), "error")
	end

	updateLeaderboardsBindable:Fire(nil)
end

adminCommandRemote.OnServerEvent:Connect(handleAdminCommand)

resetRemote.OnServerEvent:Connect(function(player)
	if not player or not player:IsDescendantOf(Players) then return end
	local userId = player.UserId

	local last = lastResetRequest[userId] or 0
	if tick() - last < 5 then
		pcall(function()
			notificationEvent:FireClient(player, "?? Tunggu beberapa detik sebelum mereset lagi.", "warning")
		end)
		return
	end
	lastResetRequest[userId] = tick()

	if not playerData[userId] then
		loadData(player)
	end

	if not playerData[userId] then
		playerData[userId] = {
			checkpoint = 0,
			summitCount = 0,
			lastTouch = 0,
			lastSave = tick()
		}
	else
		playerData[userId].checkpoint = 0
		playerData[userId].lastTouch = 0
		playerData[userId].lastSave = tick()
	end

	local ok1, err1 = pcall(function()
		checkpointStore:SetAsync("Player_" .. userId, {
			checkpoint = 0,
			lastUpdated = os.time()
		})
	end)
	if not ok1 then
		warn("?? Gagal SetAsync checkpoint untuk "..player.Name..": "..tostring(err1))
	end

	updateLeaderstats(player)
	saveData(player, true)

	pcall(function()
		notificationEvent:FireClient(player, "? Checkpoint Anda telah direset.", "success")
	end)

	updateLeaderboardsBindable:Fire(nil)
	print("?? Player "..player.Name.." melakukan reset CHECKPOINT (server-side).")
end)

local function onCheckpointTouched(player, part)
	if not player or not player:IsDescendantOf(Players) then return end

	local userId = player.UserId
	local data = playerData[userId]
	if not data then return end

	local touchedNum = getCheckpointNumber(part)
	local expectedNum = data.checkpoint + 1
	local totalCP = getCheckpointCount()

	if touchedNum ~= expectedNum then
		return
	end

	if touchedNum < 1 or touchedNum > totalCP then
		return
	end

	if tick() - data.lastTouch < Config.Settings.CheckpointCooldown then
		return
	end

	data.checkpoint = touchedNum
	data.lastTouch = tick()

	updateLeaderstats(player)
	saveData(player, false)

	if player and player:IsDescendantOf(Players) then
		local success1 = pcall(function()
			checkpointEvent:FireClient(player, touchedNum, totalCP)
		end)

		local success2 = pcall(function()
			notificationEvent:FireClient(player, "? Checkpoint " .. touchedNum .. "/" .. totalCP, "checkpoint")
		end)

		if not success1 or not success2 then
			warn("?? Gagal fire event ke "..player.Name)
		end
	end

	print("? "..player.Name.." mencapai checkpoint "..touchedNum.."/"..totalCP)
	updateLeaderboardsBindable:Fire(nil)
end

local function onSummitTouched(player)
	if not player or not player:IsDescendantOf(Players) then return end

	local userId = player.UserId
	local data = playerData[userId]
	if not data then return end

	if tick() - data.lastTouch < Config.Settings.SummitCooldown then 
		return 
	end

	local totalCP = getCheckpointCount()

	if data.checkpoint < totalCP then
		if player and player:IsDescendantOf(Players) then
			pcall(function()
				notificationEvent:FireClient(player, "? Selesaikan semua checkpoint dulu! ("..data.checkpoint.."/"..totalCP..")", "error")
			end)
		end
		return
	end

	data.summitCount = data.summitCount + Config.Settings.SummitPointReward
	data.checkpoint = 0
	data.lastTouch = tick()

	updateLeaderstats(player)
	saveData(player, true)

	if player and player:IsDescendantOf(Players) then
		pcall(function()
			summitEvent:FireClient(player, data.summitCount)
		end)

		pcall(function()
			notificationEvent:FireClient(player, "?? SUMMIT TERCAPAI! +"..Config.Settings.SummitPointReward.." Points", "summit")
		end)
	end

	print("?? "..player.Name.." mencapai SUMMIT! Total: "..data.summitCount)
	updateGlobalLeaderboard(userId, player.Name, data.summitCount)
	updateLeaderboardsBindable:Fire(nil)
end

local function setupTouchEvents()
	local cpFolder = workspace:WaitForChild(Config.Settings.CheckpointFolderName, 10)
	if not cpFolder then
		error("? Checkpoint folder tidak ditemukan!")
	end

	local checkpointCount = 0
	for _, part in ipairs(cpFolder:GetChildren()) do
		if part:IsA("BasePart") then
			checkpointCount = checkpointCount + 1

			local debounce = {}

			part.Touched:Connect(function(hit)
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player and not debounce[player.UserId] then
					debounce[player.UserId] = true
					onCheckpointTouched(player, part)
					task.wait(0.5)
					debounce[player.UserId] = nil
				end
			end)
		end
	end
	print("? "..checkpointCount.." checkpoints loaded")

	local summitPart = workspace:WaitForChild(Config.Settings.SummitPartName, 10)
	if not summitPart then
		error("? Summit part tidak ditemukan!")
	end

	local summitDebounce = {}

	summitPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = Players:GetPlayerFromCharacter(character)
		if player and not summitDebounce[player.UserId] then
			summitDebounce[player.UserId] = true
			onSummitTouched(player)
			task.wait(1)
			summitDebounce[player.UserId] = nil
		end
	end)
	print("? Summit part loaded")
end

-- FIX: Handler untuk spawn yang lebih robust (Studio Lite compatible)
local function handleCharacterSpawn(player, character)
	local userId = player.UserId

	-- Mark spawn not ready
	playerSpawnReady[userId] = false

	print("?? "..player.Name.." character spawning...")

	local pdata = playerData[userId]
	if not pdata then
		pdata = loadData(player)
		-- Wait untuk data load
		local maxWait = 0
		while not pdata and maxWait < 30 do
			task.wait(0.1)
			maxWait = maxWait + 1
			pdata = playerData[userId]
		end
	end

	-- Wait untuk humanoid dan HRP ready
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)

	if not humanoid or not hrp then
		warn("?? Character tidak lengkap untuk "..player.Name)
		playerSpawnReady[userId] = true
		return
	end

	-- FIX: Wait sampai character benar-benar ada di workspace
	task.wait(0.2)

	-- FIX: Reset state untuk Studio Lite
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true

	-- Teleport jika ada checkpoint tersimpan
	if pdata and pdata.checkpoint and pdata.checkpoint > 0 then
		-- FIX: Tambahan delay untuk Studio Lite
		task.wait(0.3)

		local cpFolder = workspace:FindFirstChild(Config.Settings.CheckpointFolderName)
		if cpFolder then
			local cpPart =
				cpFolder:FindFirstChild("Checkpoint"..pdata.checkpoint)
				or cpFolder:FindFirstChild("CP"..pdata.checkpoint)
				or cpFolder:FindFirstChild(tostring(pdata.checkpoint))

			if cpPart and cpPart:IsA("BasePart") then
				-- FIX: Freeze untuk prevent movement
				hrp.Anchored = true

				-- Clear velocity
				for _, part in pairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Velocity = Vector3.zero
						part.RotVelocity = Vector3.zero
						part.AssemblyLinearVelocity = Vector3.zero
						part.AssemblyAngularVelocity = Vector3.zero
					end
				end

				-- Teleport dengan offset lebih tinggi
				local targetPos = cpPart.Position + Vector3.new(0, 7, 0)
				local targetCFrame = CFrame.new(targetPos)

				character:PivotTo(targetCFrame)
				hrp.CFrame = targetCFrame

				-- FIX: Critical delay untuk Studio Lite
				task.wait(0.15)

				-- Unanchor
				hrp.Anchored = false

				-- Set freefall state
				humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

				-- Double check velocity
				task.wait(0.05)
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero

				print("?? "..player.Name.." spawned at checkpoint "..pdata.checkpoint)
			end
		end
	end

	updateLeaderstats(player)

	-- Mark spawn ready
	task.wait(0.1)
	playerSpawnReady[userId] = true
end

Players.PlayerAdded:Connect(function(player)
	print("?? "..player.Name.." joining...")

	-- Initialize spawn ready tracker
	playerSpawnReady[player.UserId] = false

	-- Buat leaderstats DULU
	local ls = Instance.new("Folder")
	ls.Name = Config.Leaderstats.FolderName
	ls.Parent = player

	local cp = Instance.new("IntValue")
	cp.Name = Config.Leaderstats.CheckpointStatName
	cp.Value = 0
	cp.Parent = ls

	local sm = Instance.new("IntValue")
	sm.Name = Config.Leaderstats.SummitStatName
	sm.Value = 0
	sm.Parent = ls

	local data = loadData(player)

	if data then
		cp.Value = data.checkpoint
		sm.Value = data.summitCount
		print("? Leaderstats updated untuk "..player.Name..": CP="..data.checkpoint..", Summits="..data.summitCount)
	end

	-- Connect CharacterAdded dengan handler baru
	player.CharacterAdded:Connect(function(char)
		handleCharacterSpawn(player, char)
	end)

	updateLeaderboardsBindable:Fire(nil)
	print("? "..player.Name.." joined successfully")
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	local data = playerData[userId]

	if data then
		pcall(function()
			checkpointStore:SetAsync("Player_" .. userId, {
				checkpoint = data.checkpoint,
				lastUpdated = os.time()
			})
		end)

		task.wait(0.5)

		pcall(function()
			summitStore:SetAsync("Player_" .. userId, {
				summitCount = data.summitCount,
				lastUpdated = os.time()
			})
		end)

		print("?? Force save for leaving player: "..player.Name.." (CP: "..data.checkpoint..", Summits: "..data.summitCount..")")
	end

	playerData[userId] = nil
	dataLoadQueue[userId] = nil
	saveQueue[userId] = nil
	playerSpawnReady[userId] = nil

	task.wait(0.5)
	updateLeaderboardsBindable:Fire(nil)

	print("?? "..player.Name.." left")
end)

task.spawn(function()
	while true do
		task.wait(300)

		local playerCount = #Players:GetPlayers()
		print("?? Auto-save starting for "..playerCount.." players...")

		for i, player in ipairs(Players:GetPlayers()) do
			if player:IsDescendantOf(Players) then
				saveData(player, false)
				task.wait(2)
			end
		end

		print("?? Auto-save completed")
	end
end)

setupTouchEvents()
print("?? Summit System Loaded! (Studio Lite Compatible)")
print("?? Total Checkpoints: "..getCheckpointCount())
print("?? Admin Commands: Ready")
print("? FIXED: Studio Lite Respawn & Rejoin Teleport")