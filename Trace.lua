--[[

    Apologies for the terrible coding style,
    I started this a long time ago and my modern styling looks very different.

    Notes:
        -This is part of the main module that I run every SB session, and thus was not intended to be used as a standalone script.

]]

local inputData = { -- Should be accessible by InputHook.lua (e.g. passing it via module or hardwiring it into a sandbox)
	tracedAlerts = {}
}

local Plrs = game:GetService("Players")
local DSS = game:GetService("DataStoreService")

local Plr = Plrs["tinke219"]

local Prefix, Suffix = ";", " "

local Commands = {}

local traceLinked = {
	["kill"] = {"kill", "breakjoints()", "health = 0", "destroy()"};
	["kick"] = {"kick", "destroy()", "remove()", "parent = nil", ":rep", "string.rep"};
}

local function GetTimeDist(OldTick)
	local NewTick = os.time() --os.time() or tick()
	local timeNum = nil
	local Symbol = ""
	local Seconds = NewTick - OldTick + 0.5
	local Minutes = Seconds / 60
	local Hour = Minutes / 60
	local Day = Hour / 24
	local Year = Day / 365

	if Seconds < 60 then
		timeNum = math.floor(Seconds)
		Symbol = "s"
	elseif Minutes < 60 then
		timeNum = math.floor(Minutes)
		Symbol = "m"
	elseif Hour < 24 then
		timeNum = math.floor(Hour)
		Symbol = "h"
	elseif Day < 365 then
		timeNum = math.floor(Day)
		Symbol = "d"
	else
		timeNum = math.floor(Year)
		Symbol = "y"
	end

	return tostring(timeNum) .. Symbol
end

local function addCmd(Name, Func)
	Commands[Name] = Func
end

function RunCommand(Message)
    if Message:sub(1, #Prefix) == Prefix then
        local Message = Message:sub(1 + #Prefix)
        for Names,Func in pairs(Commands) do
            for _,Name in pairs(Names) do
                if Message:lower():sub(1, #Name) == Name:lower() and Message:sub(1 + #Name, #Name + #Suffix):match("^"..Suffix.."?$") then
                    local Message = Message:sub(1 + #Name + #Suffix)
                    local newFunc, newErr = pcall(Func, Message)
                    if newErr then
                        print("[COMMAND] Error:", newErr)
                    end
                end
            end
        end
    end
end

local function traceMain(Msg)
	local TraceTab = inputData.tracedAlerts
	local nowPat = nil
	local tempPat = "%w"
	local hasWord = (Msg:match("%w+") == Msg)
	if hasWord then
		nowPat = "(%w+)"
	else
		if Msg:find(".", 1, true) then
			tempPat = tempPat .. "."
		end
		if Msg:find("(", 1, true) or Msg:find(")", 1, true) then
			tempPat = tempPat .. "%(%)"
		end
		if Msg:find(":", 1, true) then
			tempPat = tempPat .. ":"
		end
		if Msg:find("\"", 1, true) or Msg:find("'", 1, true) then
			tempPat = tempPat .. "\"'"
		end
		if Msg:find(" ", 1, true) then
			tempPat = tempPat .. " "
		end
		if Msg:find("=", 1, true) then
			tempPat = tempPat .. "="
		end
		if Msg:find("-", 1, true) then
			tempPat = tempPat .. "-"
		end
		if Msg:find("+", 1, true) then
			tempPat = tempPat .. "+"
		end
		if Msg:find("{", 1, true) or Msg:find("}", 1, true) then
			tempPat = tempPat .. "{}"
		end
		if Msg:find("[", 1, true) or Msg:find("]", 1, true) then
			tempPat = tempPat .. "%[%]"
		end
		if Msg:find("/", 1, true) then
			tempPat = tempPat .. "/"
		end
		if Msg:find("*", 1, true) then
			tempPat = tempPat .. "*"
		end
		if Msg:find("?", 1, true) then
			tempPat = tempPat .. "?"
		end
		if Msg:find("%", 1, true) then
			tempPat = tempPat .. "%%"
		end
		if Msg:find("\\n", 1, true) then
			print(1)
			tempPat = tempPat .. "%s"
			Msg = Msg:gsub("\\n", "\n")
		end
		tempPat = "([" .. tempPat .. "]+)"
		if Msg:match(tempPat) == Msg then
			nowPat = tempPat
		else
			nowPat = "([^%s;]+)"
		end
	end
	print("Pattern:", nowPat)
	local printTab = {}
	local LMsg = Msg:gsub(" ", ""):lower()
	for i = #TraceTab, 1, -1 do
		local nowTab = TraceTab[i]
		local nowMsg = nowTab.Msg
		local nowSymb = nowTab.Symbol
		local hasFound = false
		for sNum, keyWord, eNum in nowMsg:gmatch("()" .. nowPat .. "()") do
			if keyWord:gsub(" ", ""):lower():find(LMsg, 1, true) then
				local nowPlrName = nowTab.PlrName
				local nowOrigMsg = nowTab.origMsg
				local timeSymb = "[" .. GetTimeDist(nowTab.msgTime) .. "]"
				local nowText
				if #nowMsg < 1200 then
					nowText = "[" .. nowPlrName .. "] " .. timeSymb .. " " .. nowSymb .. " " .. (nowMsg)
				else
					local contextMsg = nowMsg:sub(max(sNum-traceRad, 1), eNum+traceRad)
					nowText = "[" .. nowPlrName .. "] " .. timeSymb .. " " .. nowSymb .. " [INC] " .. (contextMsg)
				end
				table.insert(printTab, 1, "Data: " .. nowText)
				hasFound = true
				break
			end
		end
		if #printTab >= traceNum then
			break
		end
		if not hasFound then
			for sNum, keyWord, eNum in nowSymb:gmatch("()" .. nowPat .. "()") do
				if keyWord:gsub(" ", ""):lower():find(LMsg, 1, true) then
					local nowPlrName = nowTab.PlrName
					local nowSymb = nowTab.Symbol
					local nowOrigMsg = nowTab.origMsg
					local timeSymb = "[" .. GetTimeDist(nowTab.msgTime) .. "]"
					local nowText
					if #nowMsg < 1200 then
						nowText = "[" .. nowPlrName .. "] " .. timeSymb .. " " .. nowSymb .. " " .. (nowMsg)
					else
						local contextMsg = nowMsg:sub(max(sNum-traceRad, 1), eNum+traceRad)
						nowText = "[" .. nowPlrName .. "] " .. timeSymb .. " " .. nowSymb .. " [INC] " .. (contextMsg)
					end
					table.insert(printTab, 1, "Data: " .. nowText)
					break
				end
			end
			if #printTab >= traceNum then
				break
			end
		end
	end
	for _,v in pairs(printTab) do
		run(v)
	end
end

addCmd({"tracesd", "post"}, function(Msg)
	if tonumber(Msg) then
		local Findings = tonumber(Msg) - 1
		local FromEvent = DSS:GetDataStore("GameLeaveData")
		local TraceTab = FromEvent:GetAsync("ShutDownData")
		print("--FINDING--")
		for i = math.max(#TraceTab-Findings, 1), #TraceTab, 1 do
			local nowText = TraceTab[i]
			--local ModResult = TraceTab[i]:gsub("", "\127")
			run("Data: " .. nowText)
		end
	end
end)

addCmd({"leave", "prev"}, function(Msg)
	if tonumber(Msg) then
		local Findings = tonumber(Msg) - 1
		local FromEvent = DSS:GetDataStore("GameLeaveData")
		local TraceTab = FromEvent:GetAsync("LeaveData")
		print("--FINDING--")
		for i = math.max(#TraceTab-Findings, 1), #TraceTab, 1 do
			local nowText = TraceTab[i]
			--local ModResult = TraceTab[i]:gsub("", "\127")
			run("Data: " .. nowText)
		end
	end
end)

addCmd({"trace"}, function(Msg)
	traceMain(Msg)
	print("TRACE COMPLETE")
end)

addCmd({"tracek"}, function(Msg)
	if traceLinked[Msg:lower()] then
		for _,v in pairs(traceLinked[Msg:lower()]) do
			traceMain(v, false)
			wait(1/30)
		end
		print("KEYWORD TRACE COMPLETE")
	else
		print("No keyword found")
	end
end)

Plr.Chatted:connect(RunCommand)
