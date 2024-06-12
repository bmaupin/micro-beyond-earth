function CanCityConstructBuilding(playerID, cityID, buildingID)
    local player = Players[playerID]
    local city = player:GetCityByID(cityID)

    if (PreGame.GetGameOption("GAMEOPTION_NO_ESPIONAGE") == 1) then
        -- Gives 3 agents
        if buildingID == GameInfoTypes.BUILDING_SPY_AGENCY then
            return false

        -- Reduces cities max intrigue level by 2
        elseif buildingID == GameInfoTypes.BUILDING_SURVEILLANCE_WEB then
            return false

        -- Disable buildings that grant extra agents
        elseif buildingID == GameInfoTypes.BUILDING_CEL_CRADLE then
            return false
        elseif buildingID == GameInfoTypes.BUILDING_FEEDSITE_HUB then
            return false
        elseif buildingID == GameInfoTypes.BUILDING_COMMAND_CENTER then
            return false
        end
    end

    return true
end

GameEvents.CityCanConstruct.Add(CanCityConstructBuilding)
