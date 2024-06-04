function CanCityConstructBuilding(playerID, cityID, buildingID)
    local player = Players[playerID]
    local city = player:GetCityByID(cityID)

    if (PreGame.GetGameOption("GAMEOPTION_NO_ESPIONAGE") == 1) then
        if buildingID == GameInfoTypes.BUILDING_SPY_AGENCY then
            return false
        end
    end

    return true
end

GameEvents.CityCanConstruct.Add(CanCityConstructBuilding)
