--[[

	Apologies for the terrible coding style,
	I started this a long time ago and my modern styling looks very different.

	Notes:
		-This is ran as a sandboxed script (sub-script) created by the main module that Trace.lua is from, the effects of which are:
			-inputData is a dictionary that is shared by the main module and this sub-script.
				-inputData contains one key-value pair, the key is "tracedAlerts", the value is a table

]]

local Plrs = game:GetService("Players")
local Debris = game:GetService("Debris")
local HttpService = game:GetService("HttpService")
local Content = game:GetService("ContentProvider")
local DataStore = game:GetService("DataStoreService"):GetDataStore("GameLeaveData")
local NotificationID = "rbxassetid://180877191"
local DataTab = {}
local max = math.max 

local inputData = { -- Would be defined in module containing Trace.lua, remove this table unless testing separately to Trace.lua
	tracedAlerts = {}
}

local numSounds = 9
local traceRad = 100

Content:Preload(NotificationID)

local Things = {"c/", "s/", "do/", "x/", "l/", "script/", "local/", "nl/", "runl/", "rename/", "newlocal/", "g/", "get/", "create/", "edit/", "clear/", "exit/", "runlocal/", "run/", "r/", "rn/", "runnew/", "createsource/", "creates/", "share/", "rl/", "stop/", "remove/", "nl/", "runlocalto/", "rlt/"}
local Things2 = {"h/", "rh/", "rsh/", "runh/", "hl/", "rlh/", "http/", "httpl/", "httplocal/"}
local Things3 = {"httpnewlocal/", "hnl/", "insert/", "i/", "createh/", "createhttp/", "edith/", "edithttp/", "rlth/", "hlt/", "httplocalto/", "createhs/", "createhttpsource/", "sbban/", "sbunban/", "sb/", "ch/", "eh/"}
local AllThings = {}

local twoDash = {
	["createh"] = true;
	["rlth"] = true;
	["nl"] = true;
	["httplocalto"] = true;
	["hlt"] = true;
	["rlt"] = true;
	["share"] = true;
	["createhs"] = true;
	["createhttpsource"] = true;
	["createhttp"] = true;
	["creates"] = true;
	["createsource"] = true;
	["newlocal"] = true;
	["sbban"] = true;
	["sbunban"] = true;
	["ch"] = true;
	["edith"] = true;
	["edithttp"] = true;
	["eh"] = true;
	["rename"] = true;
	["runlocalto"] = true;
	["httpnewlocal"] = true;
	["hnl"] = true;
}

local pingWords = {
	"vaeb",
	"vae",
	"beav",
	"kick",
	"ban",
	"shutdown",
	"fweld",
	"fap",
	"administratorgui",
	"/bn",
	"/bh",
	"/cr",
	"aerx",
	"cmdbar",
	"loopkill",
	"/ps",
}

for _,v in pairs(Things) do
	AllThings[v:lower()] = true
end
for _,v in pairs(Things2) do
	AllThings[v:lower()] = true
end
for _,v in pairs(Things3) do
	AllThings[v:lower()] = true
end

local ignoreTexts = {
	[""] = true;
	["Click here or press (') to run a command"] = true;
}

local tinsert = table.insert 
local tremove = table.remove  

local QueTab = {}
local DataRequests = 0
local PrevPrint = print
local CanPrint = true

local print = nil
local removeRequest = nil
local getRealData = nil
local getCmd = nil
local getChanges = nil
local handleData = nil
local controlData = nil
local connectChat = nil
local connectBar = nil
local connectCheck = nil
local findBoxes = nil

print = function(...)
	if CanPrint == true then
		PrevPrint(...)
	end
end

local function Run(func, ...)
	local ok, err = coroutine.resume(coroutine.create(func), unpack{...})
	if not ok then
		print("[Run] ERROR:", err)
	end
end

removeRequest = function()
	DataRequests = DataRequests - 1
end

getRealData = function(Msg)
	local OkGet, returnedVal = pcall(function() return HttpService:GetAsync(Msg, true) end)
	if OkGet and returnedVal ~= nil and returnedVal ~= "" then 
		return returnedVal
	end
	return Msg
end

getChanges = function(str1, str2)
	local len1 = string.len(str1)
	local len2 = string.len(str2)
	local matrix = {}
	local cost = 0
	if (len1 == 0) then
		return len2
	elseif (len2 == 0) then
		return len1
	elseif (str1 == str2) then
		return 0
	end
	for i = 0, len1, 1 do
		matrix[i] = {}
		matrix[i][0] = i
	end
	for j = 0, len2, 1 do
		matrix[0][j] = j
	end
	for i = 1, len1, 1 do
		for j = 1, len2, 1 do
			if (str1:byte(i) == str2:byte(j)) then
				cost = 0
			else
				cost = 1
			end
			
			matrix[i][j] = math.min(matrix[i-1][j] + 1, matrix[i][j-1] + 1, matrix[i-1][j-1] + cost)
		end
	end
	return matrix[len1][len2]
end

getCmd = function(Msg)
	local returnVal = "None"
	local endMsg = Msg
	local LMsg = Msg:lower()
	for v,_ in pairs(AllThings) do --When validating HTTP: Things | Else: AllThings
		if #LMsg > #v and LMsg:sub(1, #v) == v then
			returnVal = "Completed"
			return returnVal, endMsg
		end
	end
	return returnVal, endMsg, Msg
end

handleData = function(preData, origData, trueData, realData, Plr, Sign, extraSign)
	local Sign2 = "[" .. preData
	if Sign2 == "[g" or Sign2 == "[get" then
		Sign2 = "[CMD"
		realData = "g/" .. realData
	end
	Sign = Sign .. " " .. Sign2 .. (extraSign or "") .. "]"
	tinsert(inputData.tracedAlerts, {PlrName = Plr.Name, Symbol = Sign, msgTime = os.time(), origMsg = trueData, Msg = realData})
	local origDataL = origData:lower()
	local realDataL = realData:lower()
	local dontUse = {}
	for i,v in pairs(pingWords) do
		local findPos2a, findPos2b = realDataL:find(v)
		local findPos1a, findPos1b = origDataL:find(v)
		local pingText
		if findPos2a then
			pingText = realData:sub(max(findPos2a-traceRad, 1), findPos2b+traceRad)
		elseif findPos1a then
			pingText = origData:sub(max(findPos1a-traceRad, 1), findPos1a+traceRad)
		end
		if pingText and not dontUse[v] then
			local realResult = ("[" .. Plr.Name .. "] " .. Sign .. " [" .. #realData .. "] " .. pingText)
			print("[" .. v:upper() .. "] Ping:", realResult)
			if v == "vaeb" or v == "vae" or v == "beav" or v == "/bn" then
				if Plrs:findFirstChild("Vaeb") and Plrs["Vaeb"]:findFirstChild("PlayerGui") then
					for i = 1, numSounds do
						local NotiSound = Instance.new("Sound", Plrs["Vaeb"]["PlayerGui"])
						NotiSound.Name = "NotiSound1428"
						NotiSound.Volume = 1
						NotiSound.SoundId = NotificationID
						NotiSound:Play()
						Debris:AddItem(NotiSound, 1)
					end
				end
				if v == "vaeb" then
					dontUse["vae"] = true
				end
			end
		end
	end
end

controlData = function(Msg, Plr, Sign)
	local Result = (Sign .. " [" .. Plr.Name .. "] " .. Msg)
	tinsert(DataTab, Result)
	if #DataTab > 20 then
		tremove(DataTab, 1)
	end
	local Value, Data = getCmd(Msg)
	local LMsg = Msg:lower()
	local didPrint = false
	local dontUse = {}
	if Value == "Completed" or Sign == "[E]" then
		local preData, trueData, realData
		preData, trueData = Msg:match("(.-)/(.+)")
		local Sign2 = nil
		if preData and twoDash[preData] then
			local dashTwoNum = trueData:match("()/")
			local preDashTwo = dashTwoNum and trueData:sub(1, dashTwoNum-1) or "N/A"
			trueData = dashTwoNum and trueData:sub(dashTwoNum+1) or trueData
			Sign2 = "/" .. preDashTwo
		end
		if Msg:lower():find("http") then
			realData = getRealData(trueData)
		else
			realData = trueData
		end
		preData = preData or "/e"
		trueData = trueData or Msg
		realData = realData or trueData
		handleData(preData, Msg, trueData, realData, Plr, Sign, Sign2)
	else
		for i,v in pairs(pingWords) do
			local findPos1a, findPos1b = LMsg:find(v)
			local pingText
			if findPos1a then
				pingText = Msg:sub(max(findPos1a-traceRad, 1), findPos1b+traceRad)
			end
			if pingText and not dontUse[v] then
				local realResult = ("[" .. Plr.Name .. "] " .. "[MC] [" .. #Msg .. "] " .. pingText)
				print("[" .. v:upper() .. "] Ping:", realResult)
				if not didPrint then
					tinsert(inputData.tracedAlerts, {PlrName = Plr.Name, Symbol = "[MC]", msgTime = os.time(), origMsg = Msg, Msg = Msg})
					didPrint = true
				end
				if v == "vaeb" or v == "vae" or v == "beav" or v == "/bn" then
					if Plrs:findFirstChild("Vaeb") and Plrs["Vaeb"]:findFirstChild("PlayerGui") then
						for i = 1, numSounds do
							local NotiSound = Instance.new("Sound", Plrs["Vaeb"]["PlayerGui"])
							NotiSound.Name = "NotiSound1428"
							NotiSound.Volume = 1
							NotiSound.SoundId = NotificationID
							NotiSound:Play()
							Debris:AddItem(NotiSound, 1)
						end
					end
					if v == "vaeb" then
						dontUse["vae"] = true
					end
				end
			end
		end
	end
end

connectChat = function(Plr)
	local PlrChattedCon; PlrChattedCon = Plr.Chatted:connect(function(Msg)
		local origMsg = Msg
		if Msg:sub(1, 3) == "/e " then
			Msg = Msg:sub(4)
		end
		if origMsg == Msg then
			controlData(Msg, Plr, "[C]")
		else
			controlData(Msg, Plr, "[E]")
		end
	end)
end

connectBar = function(Plr, Bar)
	local LastText = ""
	local BarChangedCon; BarChangedCon = Bar.Changed:connect(function(P)
		local NewText = Bar.Text
		if P == "Text" then
			local CodeText = LastText
			LastText = NewText
			if not ignoreTexts[CodeText] and not tonumber(CodeText) and not AllThings[CodeText:lower()] and (((NewText == "" or ignoreTexts[NewText]) and #CodeText > 1) or getChanges(NewText, CodeText) > 2) then
				local Sign = "[B]"
				local Result = (Sign .. " [" .. Plr.Name .. "] " .. CodeText)
				tinsert(DataTab, Result)
				if #DataTab > 20 then
					tremove(DataTab, 1)
				end
				local preData, trueData, realData
				local Sign2 = nil
				preData, trueData = CodeText:match("(.-/)(.+)")
				local didPrint = false
				if preData and twoDash[preData] then
					local dashTwoNum = trueData:match("()/")
					local preDashTwo = dashTwoNum and trueData:sub(1, dashTwoNum-1) or ""
					local endData = trueData:sub(dashTwoNum+1)
					if not dashTwoNum or not endData or #endData < 1 then
						return
					end
					trueData = endData
					Sign2 = "/" .. preDashTwo
				end
				if CodeText:lower():find("http") then
					realData = getRealData(trueData)
				else
					realData = trueData
				end
				preData = preData or "CUSTOM"
				trueData = trueData or CodeText
				realData = realData or trueData
				handleData(preData, CodeText, trueData, realData, Plr, Sign, Sign2)
			end
		end
	end)
end

findBoxes = function(Obj, Tab)
	if Obj.ClassName == "TextBox" and Obj.Name ~= "VOutTextBox" then
		Tab[#Tab+1] = Obj
	end
	if #Obj:GetChildren() > 0 then
		for _,v in pairs(Obj:GetChildren()) do 
			findBoxes(v, Tab)
		end
	end
end

local HasGotBar = {}

connectCheck = function(Plr)
	local TextBoxes = {}
	local PlrGui = Plr:findFirstChild("PlayerGui")
	if PlrGui then
		findBoxes(PlrGui, TextBoxes)
		if #TextBoxes > 0 then
			for _,InputBar in pairs(TextBoxes) do
				if HasGotBar[InputBar] == nil then
					HasGotBar[InputBar] = true
					connectBar(Plr, InputBar)
				end
			end
		end
	end
	wait(1.5)
	if Plr and Plr.Parent then
		connectCheck(Plr)
	end
end

local PlrRemoveCon; PlrRemoveCon = Plrs.PlayerRemoving:connect(function(v)
	if #Plrs:GetPlayers() == 0 then
		DataStore:SetAsync("ShutDownData", DataTab)
	else
		spawn(function()
			if v.Name == "Vaeb" then
				local newTab = {}
				local SetOk, SetErr = pcall(function()
					DataStore:SetAsync("LeaveData", DataTab)
				end)
				wait(.2)
				pcall(function() DataStore:SetAsync("LeaveData", DataTab) end)
			end
		end)
		wait(.1)
		if #Plrs:GetPlayers() == 0 then
			DataStore:SetAsync("ShutDownData", DataTab)
		end
	end
end)

game:BindToClose(function()
	DataStore:SetAsync("ShutDownData", DataTab)
	wait(1)
	DataStore:SetAsync("ShutDownData", DataTab)
end)

print("Tracer Ran")

for _,v in pairs(Plrs:GetPlayers()) do
	coroutine.resume(coroutine.create(function()
		--connectChat(v)
	end))
	coroutine.resume(coroutine.create(function()
		connectCheck(v)
	end))
	print("ConnectedR", v.Name)
end

local PlrAddedCon; PlrAddedCon = Plrs.PlayerAdded:connect(function(v)
	coroutine.resume(coroutine.create(function()
		--connectChat(v)
	end))
	coroutine.resume(coroutine.create(function()
		connectCheck(v)
	end))
	print("ConnectedR", v.Name)
end)
