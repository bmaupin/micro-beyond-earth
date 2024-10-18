-- Adapted from Victories - Automated Exodus Gate (https://www.picknmixmods.com/mods/CivBE/Victories/Automated%20Exodus%20Gate.html) from whoward69](https://forums.civfanatics.com/members/whoward69.210828/)

-- This array is only populated for human players
local g_WarpGates = {}

-- Some database values we'll be using a lot
local iWarpGate = GameInfoTypes.IMPROVEMENT_SUPREMACY_GATE
local iWarpGateAction = GameInfoTypes.LANDMARK_ACTION_WARP_GATE_CONSUME_UNIT

-- Given a Warp Gate at pPlot, find which player(s) can use it
function FindPlayerForGate(pPlot)
  local iGatePlayer = pPlot:GetOwner()

  if (iGatePlayer >= 0) then
    local pPlayer = Players[iGatePlayer]
    if (pPlayer:IsEverAlive() and pPlayer:IsHuman()) then
      g_WarpGates[iGatePlayer] = pPlot:GetPlotIndex()
      return iGatePlayer
    end
  end

  return -1
end

-- Scan the map for all (completed) Warp Gates
function FindGates()
  for iPlotIndex = 0, Map.GetNumPlots()-1, 1 do
    local pPlot = Map.GetPlotByIndex(iPlotIndex)

    if (pPlot:GetImprovementType() == iWarpGate) then
      FindPlayerForGate(pPlot)
    end
  end
end

-- Catch Warp Gates being built during the game session
function OnImprovementCreated(iHexX, iHexY)
  local iX, iY = ToGridFromHex(iHexX, iHexY)
  local pPlot = Map.GetPlot(iX, iY)

  if (pPlot:GetImprovementType() == iWarpGate) then
    AutoSendMilitaryUnit(FindPlayerForGate(pPlot))
  end
end
Events.SerialEventImprovementCreated.Add(OnImprovementCreated)

-- Catch Warp Gates being destroyed during the game session
function OnImprovementDestroyed(iHexX, iHexY)
  local iX, iY = ToGridFromHex(iHexX, iHexY)
  local iPlotIndex = Map.GetPlot(iX, iY):GetPlotIndex()

  for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS-1, 1 do
    local pPlayer = Players[iPlayer]

    if (pPlayer:IsHuman() and g_WarpGates[iPlayer] == iPlotIndex) then
      g_WarpGates[iPlayer] = nil
    end
  end
end
Events.SerialEventImprovementDestroyed.Add(OnImprovementDestroyed)

-- Send a military unit through the Warp Gate (if one is available)
function AutoSendMilitaryUnit(iPlayer)
  if (g_WarpGates[iPlayer]) then
    local pPlayer = Players[iPlayer]
    local iPlotIndex = g_WarpGates[iPlayer]
    local pPlot = Map.GetPlotByIndex(iPlotIndex)

    if (pPlot:GetImprovementType() == iWarpGate) then
      if (pPlayer:CanHandleLandmarkAction(iWarpGateAction, pPlot)) then
        -- Find the first military unit belonging to the player on the Warp Gate plot
        for i = 0, pPlot:GetNumUnits() - 1 do
          local pUnit = pPlot:GetUnit(i)

          if (pUnit:IsCombatUnit() and pUnit:GetOwner() == iPlayer) then
            print("(Micro Beyond Earth) Automatically sending unit " ..  pUnit:GetName() .. " through warp gate for player " .. pPlayer:GetName())
            -- Send the player's unit through the Warp Gate
            pPlayer:HandleLandmarkAction(iWarpGateAction, iPlotIndex)
            -- We can only send one unit through per turn
            break
          end
        end
      end
    else
      g_WarpGates[iPlayer] = nil
    end
  end
end
GameEvents.PlayerDoTurn.Add(AutoSendMilitaryUnit)

-- Find any Warp Gates already built (needed when loading a saved game)
FindGates()
