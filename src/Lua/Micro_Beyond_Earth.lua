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

-- Unfortunately Events.SerialEventUnitCreated is called more than just when a unit is
-- created: "SerialEventUnitCreated works for this. It triggers for all players, whever a
-- unit is created. Unfortunately, it ALSO triggers whenever a unit embarks, disembarks,
-- rebases, etc." (https://forums.civfanatics.com/threads/any-way-to-get-the-unit-create-event-to-work-as-expected.434826/#post-10764768)
-- A workaround is to use this Unit Event Created mod: https://forums.civfanatics.com/resources/unit-created-event-mod-maker-snippet.23175/
-- However, that seems to trigger a bug in Beyond Earth where unit panel UI has bugs
-- (https://forums.civfanatics.com/threads/unit-promotion-unitpanel-mod-bug.540867/). In
-- this case, units simply weren't showing in the UI at all. So in the end, we opt to
-- track which units we've automated ourselves with this variable.
local automatedUnits = {};

function OnUnitCreated(playerID, unitID)
    local player = Players[playerID];
    local unit = player:GetUnitByID(unitID);

    if (PreGame.GetGameOption("GAMEOPTION_EXPLORERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_EXPLORER"].ID then
            -- Check if the unit has already been automated
            if not automatedUnits[unitID] then
                -- The last parameter has to be set to 1 for some reason; 0 didn't work
                unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 1);

                -- Mark the unit as automated by adding its ID to the table
                automatedUnits[unitID] = true;
            end
        end
    end

    if (PreGame.GetGameOption("GAMEOPTION_WORKERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_WORKER"].ID then
            if not automatedUnits[unitID] then
                unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 0);
                automatedUnits[unitID] = true;
            end
        end
    end
end
Events.SerialEventUnitCreated.Add(OnUnitCreated);

function ResetHealth(playerID)
    local player = Players[playerID];

    if (not player:IsMajorCiv() or not player:IsAlive() or player:GetNumCities() == 0) then
        return;
    end

    local excessHealth = player:GetExcessHealth();
    local numCities = player:GetNumCities();
    local baselineHealth = excessHealth - (player:GetExtraHealthPerCity() * numCities);

    print("(ResetHealth) playerID=", playerID)
    print("(ResetHealth) player:GetExcessHealth()=", player:GetExcessHealth())
    print("(ResetHealth) player:GetExtraHealthPerCity()=", player:GetExtraHealthPerCity())
    print("(ResetHealth) player:GetNumCities()=", player:GetNumCities())
    print("(ResetHealth) baselineHealth=", baselineHealth)

    if excessHealth < 0 then
        local adjustment = math.ceil(math.abs(baselineHealth) / numCities);
        player:ChangeExtraHealthPerCity(adjustment);
        local newExcessHealth = excessHealth + (adjustment * numCities);

        print("(Micro Beyond Earth) Adjusting health for player " .. playerID .. ", was: " .. excessHealth .. ", now: " .. newExcessHealth);

        print("(ResetHealth) adjustment=", adjustment);
        print("(ResetHealth) player:GetExcessHealth()=", player:GetExcessHealth())
        print("(ResetHealth) player:GetExtraHealthPerCity()=", player:GetExtraHealthPerCity())

    elseif excessHealth > 5 then
        local adjustment = math.floor(baselineHealth / numCities) * -1;
        player:ChangeExtraHealthPerCity(adjustment);
        local newExcessHealth = excessHealth + (adjustment * numCities);

        print("(Micro Beyond Earth) Adjusting health for player " .. playerID .. ", was: " .. excessHealth .. ", now: " .. newExcessHealth);

        print("(ResetHealth) adjustment=", adjustment);
        print("(ResetHealth) player:GetExcessHealth()=", player:GetExcessHealth())
        print("(ResetHealth) player:GetExtraHealthPerCity()=", player:GetExtraHealthPerCity())

    end
end
GameEvents.PlayerDoTurn.Add(ResetHealth);