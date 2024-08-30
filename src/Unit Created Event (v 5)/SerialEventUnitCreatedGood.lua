-- Unit_CreatedFunctions.lua
-- Author: Machiavelli
-- DateCreated: 6/1/2012 9:02:22 AM
--------------------------------------------------------------
-- Version 5
--
-- Purpose:
-- Events.SerialEventUnitCreated fires when a unit is created but also
-- fires at other times.  This function marks every unit with "PROMOTION_CREATED"
-- to ensure it only calls LuaEvents.SerialEventUnitCreatedGood when a unit is
-- actually created.
--
-- Functions that hook into LuaEvents.SerialEventUnitCreatedGood should not kill()
-- the unit because it could cause problems for other hooked in functions.  Instead
-- give the unit the "PROMOTION_MARKED_FOR_DEATH" which will have this code kill the
-- unit after all hooked functions finish executing.
--------------------------------------------------------------
function CallSerialEventUnitCreatedGood(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible)
	if(Players[playerID] == nil or
		Players[playerID]:GetUnitByID(unitID) == nil or
		Players[playerID]:GetUnitByID(unitID):IsDead() or
		Players[playerID]:GetUnitByID(unitID):IsHasPromotion(GameInfoTypes["PROMOTION_CREATED"])) then
		return;
	end

	local unit = Players[playerID]:GetUnitByID(unitID);

	-- Always mark the unit with the created promotion
	unit:SetHasPromotion(GameInfoTypes["PROMOTION_CREATED"], true);

	-- Call the good event
	LuaEvents.SerialEventUnitCreatedGood(playerID, unitID, hexVec, unitType, cultureType, civID, primaryColor, secondaryColor, unitFlagIndex, fogState, selected, military, notInvisible);

	-- Kill the unit if some code hooked into the event has indicated the unit should be deleted
	if(unit:IsHasPromotion(GameInfoTypes["PROMOTION_MARKED_FOR_DEATH"])) then
		unit:Kill();
	end
end

--------------
-- Initialization check.  Ensures this code isn't loaded twice
--------------
local retVal = {};
LuaEvents.SerialEventUnitCreatedGood_IsInitialized(retVal);

-- If retVal isn't changed, no other mod has initialized this code.
if (retVal.isInitialized == nil) then
	LuaEvents.SerialEventUnitCreatedGood_IsInitialized.Add(function (retVal) retVal.isInitialized = true; end);
	-- Initialize the code
	Events.SerialEventUnitCreated.Add(CallSerialEventUnitCreatedGood);
end