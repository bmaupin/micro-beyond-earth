-- Abort all covert operations for all of the player's agents except for establish network
function AbortCovertOperations(playerType)
    if (PreGame.GetGameOption("GAMEOPTION_NO_COVERT_OPERATIONS") == 1) then
        for i, agent in ipairs(Players[playerType]:GetCovertAgents()) do
            if (agent:IsDoingOperation()) then
                local operation = agent:GetOperation();
                if (operation ~= nil) then
                    if (operation.Type ~= GameInfo.CovertOperations["COVERT_OPERATION_ESTABLISH_NETWORK"].ID) then
                        agent:AbortOperation();
                    end
                end
            end
        end
    end
end
GameEvents.PlayerDoTurn.Add(AbortCovertOperations);

function CanCityConstructBuilding(playerID, cityID, buildingID)
    if (PreGame.GetGameOption("GAMEOPTION_NO_COVERT_OPERATIONS") == 1) then
        -- -1 intrigue per turn in all cities
        if buildingID == GameInfoTypes.BUILDING_RELATIVISTIC_DATA_BANK then
            return false;
        -- Reduces cities max intrigue level by 2
        elseif buildingID == GameInfoTypes.BUILDING_SURVEILLANCE_WEB then
            return false;
        end
    end

    if (PreGame.GetGameOption("GAMEOPTION_NO_HEALTH") == 1) then
        -- -50% unhealth from population in city
        if buildingID == GameInfoTypes.BUILDING_AKKOROKAMUI then
            return false;
        -- +3 health
        elseif buildingID == GameInfoTypes.BUILDING_GENE_SMELTER then
            return false;
        -- +4 health, +1 health from silica
        elseif buildingID == GameInfoTypes.BUILDING_OPTICAL_SURGERY then
            return false;
        -- +2 health
        elseif buildingID == GameInfoTypes.BUILDING_PHARMALAB then
            return false;
        -- +20% health
        elseif buildingID == GameInfoTypes.BUILDING_PROGENITOR_GARDEN then
            return false;
        -- No unhealth from buildings or worked tiles
        elseif buildingID == GameInfoTypes.BUILDING_PROMETHEAN then
            return false;
        -- +50% global benefits from health
        elseif buildingID == GameInfoTypes.BUILDING_RESURRECTION_DEVICE then
            return false;
        -- +4 health
        elseif buildingID == GameInfoTypes.BUILDING_SOMA_DISTILLERY then
            return false;
        -- -50% negative health
        elseif buildingID == GameInfoTypes.BUILDING_XENONOVA then
            return false;
        end
    end

    return true;
end
GameEvents.CityCanConstruct.Add(CanCityConstructBuilding);

function OnUnitCreated(playerID, unitID)
    local player = Players[playerID];
    local unit = player:GetUnitByID(unitID);

    if (PreGame.GetGameOption("GAMEOPTION_EXPLORERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_EXPLORER"].ID then
            -- The last parameter has to be set to 1 for some reason; 0 didn't work
            unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 1);
        end
    end

    if (PreGame.GetGameOption("GAMEOPTION_WORKERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_WORKER"].ID then
            unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 0);
        end
    end
end
LuaEvents.SerialEventUnitCreatedGood.Add(OnUnitCreated);
