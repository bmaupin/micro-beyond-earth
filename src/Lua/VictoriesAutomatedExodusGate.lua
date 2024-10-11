print("This is the 'Victories - Automated Exodus Gate' mod script.")

-- Set this to bring more earthlings than needed through the gate,
-- useful if your earthlings are being captured by aliens/enemies before they get to their settlements 
local iEarthlingsExtra = 0

-- This array is only populated for human players
local g_ExodusGates = {}

-- Some database values we'll be using a lot
local iEarthlingsNeeded = GameDefines.PROMISED_LAND_EARTHLINGS_SETTLED_REQUIREMENT
local iEarthlingSettler = GameInfoTypes.UNIT_EARTHLING_SETTLER
local iExodusGate = GameInfoTypes.IMPROVEMENT_PURITY_GATE
local iSpawnEarthlingAction = GameInfoTypes.LANDMARK_ACTION_SPAWN_EARTHLING_UNIT

-- Given an Exodus Gate at pPlot, find which player(s) can use it
function FindPlayerForGate(pPlot)
  local iGatePlayer = -1

  for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
    local pPlayer = Players[iPlayer]
	
    if (pPlayer:IsEverAlive() and pPlayer:IsHuman() and pPlayer:CanHandleLandmarkAction(iSpawnEarthlingAction, pPlot)) then
      g_ExodusGates[iPlayer] = pPlot:GetPlotIndex()
	  iGatePlayer = iPlayer
    end
  end

  return iGatePlayer
end

-- Scan the map for all (completed) Exodus Gates
function FindGates()
  for iPlotIndex = 0, Map.GetNumPlots()-1, 1 do
    local pPlot = Map.GetPlotByIndex(iPlotIndex)

    if (pPlot:GetImprovementType() == iExodusGate) then
	  FindPlayerForGate(pPlot)
    end
  end
end

-- Catch Exodus Gates being built during the game session
function OnImprovementCreated(iHexX, iHexY)
  local iX, iY = ToGridFromHex(iHexX, iHexY)
  local pPlot = Map.GetPlot(iX, iY)
  
  if (pPlot:GetImprovementType() == iExodusGate) then
    AutoSpawnEarthlings(FindPlayerForGate(pPlot))
  end
end
Events.SerialEventImprovementCreated.Add(OnImprovementCreated)

-- Catch Exodus Gates being destroyed during the game session
function OnImprovementDestroyed(iHexX, iHexY)
  local iX, iY = ToGridFromHex(iHexX, iHexY)
  local pPlotIndex = Map.GetPlot(iX, iY):GetPlotIndex()
  
  for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
    pPlayer = Players[iPlayer]
	
    if (pPlayer:IsHuman() and g_ExodusGates[iPlayer] == iPlotIndex) then
      g_ExodusGates[iPlayer] = nil
    end
  end
end
Events.SerialEventImprovementDestroyed.Add(OnImprovementDestroyed)

-- Bring another Earthling Settler (if necessary) throuh the player's Exodus Gate (if any)
function AutoSpawnEarthlings(iPlayer)
  if (g_ExodusGates[iPlayer]) then
    local pPlayer = Players[iPlayer]
  
    local iEarthlingsCalled = pPlayer:GetNumEarthlingsSettled()
    for pUnit in pPlayer:Units() do
      if (pUnit:GetUnitType() == iEarthlingSettler) then
	    iEarthlingsCalled = iEarthlingsCalled + 1
      end
    end

    if (iEarthlingsCalled < (iEarthlingsNeeded + iEarthlingsExtra)) then
	  local iPlotIndex = g_ExodusGates[iPlayer]
      local pPlot = Map.GetPlotByIndex(iPlotIndex)

      if (pPlot:GetImprovementType() == iExodusGate) then
        if (pPlayer:CanHandleLandmarkAction(iSpawnEarthlingAction, pPlot)) then
          pPlayer:HandleLandmarkAction(iSpawnEarthlingAction, iPlotIndex)
		end
	  else
	    g_ExodusGates[iPlayer] = nil
      end
    end
  end
end
GameEvents.PlayerDoTurn.Add(AutoSpawnEarthlings)

-- Find any Exodus Gates already built (needed when loading a saved game)
FindGates()
