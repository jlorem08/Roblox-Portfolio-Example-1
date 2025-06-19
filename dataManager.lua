--!strict

--[[
	DATA MANAGER:
	- Allows for collection of data from data stores
	- Allows for serialized data management of folders with values
	- Typically takes 2/3 arguments:
		- Data store name
		- Key
		- (Sometimes) Folder to serialize/update
]]

--------------
-- SERVICES --
--------------
local DataStoreService = game:GetService("DataStoreService")

-----------
-- TYPES --
-----------

---------------
-- CONSTANTS --
---------------
local DataManager = {}

---------------
-- VARIABLES --
---------------

---------------
-- FUNCTIONS --
---------------

-- Safely assigns .Value to any ValueBase subclass
local function assignValueBaseValue(target: ValueBase, newValue: any): boolean
	if target:IsA("IntValue") and type(newValue) == "number" then
		(target :: IntValue).Value = newValue
	elseif target:IsA("NumberValue") and type(newValue) == "number" then
		(target :: NumberValue).Value = newValue
	elseif target:IsA("StringValue") and type(newValue) == "string" then
		(target :: StringValue).Value = newValue
	elseif target:IsA("BoolValue") and type(newValue) == "boolean" then
		(target :: BoolValue).Value = newValue
	elseif target:IsA("Vector3Value") and typeof(newValue) == "Vector3" then
		(target :: Vector3Value).Value = newValue
	elseif target:IsA("CFrameValue") and typeof(newValue) == "CFrame" then
		(target :: CFrameValue).Value = newValue
	elseif target:IsA("Color3Value") and typeof(newValue) == "Color3" then
		(target :: Color3Value).Value = newValue
	elseif target:IsA("BrickColorValue") and typeof(newValue) == "BrickColor" then
		(target :: BrickColorValue).Value = newValue
	elseif target:IsA("ObjectValue") and typeof(newValue) == "Instance" then
		(target :: ObjectValue).Value = newValue
	else
		return false
	end

	return true
end

-- Returns the .Value of a ValueBase if it's a supported type, otherwise returns nil
local function getValueBaseValue(source: ValueBase): any?
	if source:IsA("IntValue") then
		return (source :: IntValue).Value
	elseif source:IsA("NumberValue") then
		return (source :: NumberValue).Value
	elseif source:IsA("StringValue") then
		return (source :: StringValue).Value
	elseif source:IsA("BoolValue") then
		return (source :: BoolValue).Value
	elseif source:IsA("Vector3Value") then
		return (source :: Vector3Value).Value
	elseif source:IsA("CFrameValue") then
		return (source :: CFrameValue).Value
	elseif source:IsA("Color3Value") then
		return (source :: Color3Value).Value
	elseif source:IsA("BrickColorValue") then
		return (source :: BrickColorValue).Value
	elseif source:IsA("ObjectValue") then
		return (source :: ObjectValue).Value
	else
		return nil
	end
end

-- Used to retrieve data from a given DataStore and key.
function DataManager.retrieveDataFromKey(dataStoreName: string, key: string): any?
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(dataStoreName):GetAsync(key)
	end)

	if success then
		return result
	else
		warn(
			`[{string.upper(script.Name)}]: Data at key {key} in DataStore {dataStoreName} could not be retrieved: {result}.`
		)
		return nil
	end
end

-- Used to retrieve data from a given datastore name and key, and apply it to all values inside a folder.
function DataManager.retrieveFolderData(dataStoreName: string, key: string, folder: Folder): Folder?
	local dataStructureToRequest = {} :: { [string]: ValueBase }

	for _, valueObject: ValueBase in ipairs(folder:GetChildren()) do -- get every value and set up expected value tree as dictionary
		if not valueObject:IsA("ValueBase") then
			continue
		end

		dataStructureToRequest[valueObject.Name] = valueObject
	end

	local success, result = pcall(function()
		return DataStoreService:GetDataStore(dataStoreName):GetAsync(key)
	end)

	if success then
		print(`[{string.upper(script.Name)}]: Successfully grabbed data at key {key} in DataStore {dataStoreName}.`)
	else
		warn(
			`[{string.upper(script.Name)}]: Data at key {key} in DataStore {dataStoreName} could not be retrieved: {result}`
		)
		return nil
	end

	if not result then
		print(`[{string.upper(script.Name)}]: No data found in DataStore {dataStoreName} at key {key}`)
		return nil
	end

	if typeof(result) ~= "table" then
		warn(`[{string.upper(script.Name)}]: Expected table as DataStore result, instead got {typeof(result)}.`)
		return nil
	end

	result = result :: { [string]: any }

	local foundFolder = result[folder.Name] :: { [string]: any }

	if not foundFolder then
		warn(`[{string.upper(script.Name)}]: Could not find retrieved data with key: {folder.Name}.`)
		return nil
	end

	for valueName: string, requestedValue: ValueBase in pairs(dataStructureToRequest) do
		local foundValue = foundFolder[valueName]

		if foundValue then
			if not assignValueBaseValue(requestedValue, foundValue) then
				warn(
					`[{string.upper(script.Name)}]: Could not assign value to {requestedValue.Name}. Expected {requestedValue.ClassName}, got {typeof(
						foundValue
					)}.`
				)
			end
		else
			warn(`[{string.upper(script.Name)}]: Could not find retrieved data with key: {valueName}.`)
			continue
		end
	end

	return folder
end

-- Used to update data to a given datastore with its name and key, applying data from all values inside a folder.
function DataManager.setFolderData(dataStoreName: string, key: string, folder: Folder)
	local retrievedData = DataManager.retrieveDataFromKey(dataStoreName, key)

	if not retrievedData then
		warn(
			`[{string.upper(script.Name)}]: There was an issue finding data to update at key {key} in DataStore {dataStoreName}.`
		)
		retrievedData = {}
	end

	local folderKey = retrievedData[folder.Name]

	if not folderKey then
		retrievedData[folder.Name] = {}
		folderKey = retrievedData[folder.Name]
	end

	for _, value: ValueBase in ipairs(folder:GetChildren()) do
		if not value:IsA("ValueBase") then
			continue
		end

		local serializableValue = getValueBaseValue(value)

		if serializableValue ~= nil then
			folderKey[value.Name] = serializableValue
		else
			warn(`[{string.upper(script.Name)}]: Could not serialize value: {value.Name} of class {value.ClassName}`)
		end
	end

	local success = pcall(function()
		DataStoreService:GetDataStore(dataStoreName):SetAsync(key, retrievedData)
	end)

	if success then
		print(`[{string.upper(script.Name)}]: Successfully updated data for key {key} in DataStore {dataStoreName}.`)
	else
		warn(`[{string.upper(script.Name)}]: Could not set data for key {key} in DataStore {dataStoreName}.`)
	end
end

-- Used to connect events to functions
function DataManager.init()
	return true
end

-- Used to start any automatic module logic post-initialization
function DataManager.start()
	return true
end

-------------
-- BINDING --
-------------

-------------
-- RUNNING --
-------------

-------------
-- CLOSING --
-------------
return DataManager
