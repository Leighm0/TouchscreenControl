-------------
-- Globals --
-------------
do
	EC = {}
	OPC = {}
	g_debugMode = 0
	g_DbgPrint = nil
end

----------------------------------------------------------------------------
--Function Name : OnDriverInit
--Description   : Function invoked when a driver is loaded or being updated.
----------------------------------------------------------------------------
function OnDriverInit()
	C4:UpdateProperty("Driver Name", C4:GetDriverConfigInfo("name"))
	C4:UpdateProperty("Driver Version", C4:GetDriverConfigInfo("version"))
	C4:AllowExecute(true)
end

------------------------------------------------------------------------------------------------
--Function Name : OnDriverLateInit
--Description   : Function that serves as a callback into a project after the project is loaded.
------------------------------------------------------------------------------------------------
function OnDriverLateInit()
	for k,v in pairs(Properties) do OnPropertyChanged(k) end
end

-----------------------------------------------------------------------------------------------------------------------------
--Function Name : OnDriverDestroyed
--Description   : Function called when a driver is deleted from a project, updated within a project or Director is shut down.
-----------------------------------------------------------------------------------------------------------------------------
function OnDriverDestroyed()
	if (g_DbgPrint ~= nil) then g_DbgPrint:Cancel() end
end

----------------------------------------------------------------------------
--Function Name : OnPropertyChanged
--Parameters    : strProperty(str)
--Description   : Function called by Director when a property changes value.
----------------------------------------------------------------------------
function OnPropertyChanged(strProperty)
	Dbg("OnPropertyChanged: " .. strProperty .. " (" .. Properties[strProperty] .. ")")
	local propertyValue = Properties[strProperty]
	if (propertyValue == nil) then propertyValue = '' end
	local strProperty = string.upper(strProperty)
	strProperty = string.gsub(strProperty, "%s+", "_")
	local success, ret
	if (OPC and OPC[strProperty] and type(OPC[strProperty]) == "function") then
		success, ret = pcall(OPC[strProperty], propertyValue)
	end
	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ("OnPropertyChanged Lua error: ", strProperty, ret)
	end
end

-------------------------------------------------------------------------
--Function Name : OPC.DEBUG_MODE
--Parameters    : strProperty(str)
--Description   : Function called when Debug Mode property changes value.
-------------------------------------------------------------------------
function OPC.DEBUG_MODE(strProperty)
	if (strProperty == "Off") then
		if (g_DbgPrint ~= nil) then g_DbgPrint:Cancel() end
		g_debugMode = 0
		print ("Debug Mode: Off")
	else
		g_debugMode = 1
		print ("Debug Mode: On for 8 hours")
		g_DbgPrint = C4:SetTimer(28800000, function(timer)
			C4:UpdateProperty("Debug Mode", "Off")
			timer:Cancel()
		end, false)
	end
end

-----------------------------------------------------------------------------------------------------
--Function Name : ExecuteCommand
--Parameters    : strCommand(str), tParams(table)
--Description   : Function called by Director when a command is received for this DriverWorks driver.
-----------------------------------------------------------------------------------------------------
function ExecuteCommand(strCommand, tParams)
	tParams = tParams or {}
	Dbg("ExecuteCommand: " .. strCommand .. " (" ..  formatParams(tParams) .. ")")
	if (strCommand == 'LUA_ACTION') then
		if (tParams.ACTION) then
			strCommand = tParams.ACTION
			tParams.ACTION = nil
		end
	end
	local strCommand = string.upper(strCommand)
	strCommand = string.gsub(strCommand, "%s+", "_")
	local success, ret
	if (EC and EC[strCommand] and type(EC[strCommand]) == "function") then
		success, ret = pcall(EC[strCommand], tParams)
	end
	if (success == true) then
		return (ret)
	elseif (success == false) then
		print ("ExecuteCommand Lua error: ", strCommand, ret)
	end
end

----------------------------------------------------------------------------------
--Function Name : EC.CHANGE_ROOM
--Parameters    : tParams(table)
--Description   : Function called when "Change Room" ExecuteCommand is received.
----------------------------------------------------------------------------------
function EC.CHANGE_ROOM(tParams)
	local touchscreen = tParams["Touchscreen Device"] or ""
	local room = tParams["Room Selection"] or ""
	if (room == "") or (touchscreen == "") then return end
	C4:SendToDevice (touchscreen, "SEND_URI", {URI = "navigator://" .. touchscreen .. "/v1/rooms/" .. room})
end

---------------------------------------------------------------------------------------------
--Function Name : Dbg
--Parameters    : strDebugText(str)
--Description   : Function called when debug information is to be printed/logged (if enabled)
---------------------------------------------------------------------------------------------
function Dbg(strDebugText)
    if (g_debugMode == 1) then print(strDebugText) end
end

----------------------------------------------------------------
--Function Name : trim
--Parameters    : s(str)
--Description   : Function called to trim whitespace in a string
----------------------------------------------------------------
function trim(s)
	return s:gsub("^%s*(.-)%s*$", "%1")
end

---------------------------------------------------------
--Function Name : formatParams
--Parameters    : tParams(table)
--Description   : Function called to format table params.
---------------------------------------------------------
function formatParams(tParams)
	tParams = tParams or {}
	local out = {}
	for k,v in pairs(tParams) do
		if (type(v) == "string") then
			table.insert(out, k .. " = \"" .. v .. "\"")
		else
			table.insert(out, k .. " = " .. tostring(v))
		end
	end
	return "{" .. table.concat(out, ", ") .. "}"
end
