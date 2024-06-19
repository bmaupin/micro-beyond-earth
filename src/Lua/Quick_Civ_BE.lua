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
        -- Reduces cities max intrigue level by 2
        if buildingID == GameInfoTypes.BUILDING_SURVEILLANCE_WEB then
            return false;
        end
    end

    return true;
end
GameEvents.CityCanConstruct.Add(CanCityConstructBuilding);

function GiveFreeUltrasonicFence(playerID, cityX, cityY)
    if (PreGame.GetGameOption("GAMEOPTION_FREE_ULTRASONIC_FENCE") == 1) then
        local city = Map.GetPlot(cityX, cityY):GetPlotCity();
        if (city ~= nil) then
            city:SetNumRealBuilding(GameInfoTypes["BUILDING_ULTRASONIC_FENCE"], 1);
        end
    end
end
GameEvents.PlayerCityFounded.Add(GiveFreeUltrasonicFence);
