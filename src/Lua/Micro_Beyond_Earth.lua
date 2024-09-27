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

-- If the Disable Health game option is checked, unfortunately this doesn't actually
-- disable bonuses or maluses from health, so extra logic is added here to effectively set
-- each player's health to 0 (give or take).
function ResetHealth(playerID)
    if (PreGame.GetGameOption("GAMEOPTION_NO_HEALTH") ~= 1) then
        return;
    end

    local player = Players[playerID];

    if (not player:IsMajorCiv() or not player:IsAlive() or player:GetNumCities() == 0) then
        return;
    end

    local totalHealth = player:GetExcessHealth();
    local numCities = player:GetNumCities();

    -- A health of 0 - 5 in game has no bonuses or maluses. This range allows for up to 6
    -- cities. Beyond that, we need to adjust the maximum health to avoid constantly
    -- triggering the health adjustment logic.
    local maxTotalHealth = 5;
    if numCities > 6 then
        maxTotalHealth = numCities - 1;
    end

    if totalHealth < 0 then
        local adjustment = math.ceil(math.abs(totalHealth) / numCities);
        -- This does not set extra health per city but increases or decreases it by this amount
        -- NOTE: As best as I can tell, impact on overall health takes effect at the end of the turn when total (excess) health is recalculated
        player:ChangeExtraHealthPerCity(adjustment);
        local newExcessHealth = totalHealth + (adjustment * numCities);

        print("(Micro Beyond Earth) Adjusting health for player " .. playerID .. ", was: " .. totalHealth .. ", now: " .. newExcessHealth);

    elseif totalHealth > maxTotalHealth then
        local adjustment = math.floor(totalHealth / numCities) * -1;
        player:ChangeExtraHealthPerCity(adjustment);
        local newExcessHealth = totalHealth + (adjustment * numCities);

        print("(Micro Beyond Earth) Adjusting health for player " .. playerID .. ", was: " .. totalHealth .. ", now: " .. newExcessHealth);
    end
end
GameEvents.PlayerDoTurn.Add(ResetHealth);

-- If the Disable Health game option is checked, give all health-related policies to all
-- players to avoid them wasting a free policy on something that will have little to no
-- impact as well as to speed up gameplay
function GiveFreeHealthPolicies()
    if (PreGame.GetGameOption("GAMEOPTION_NO_HEALTH") ~= 1) then
        return;
    end

    for playerID = 0, GameDefines.MAX_CIV_PLAYERS - 1 do
        local player = Players[playerID];

        if player:IsMajorCiv() and player:IsAlive() then
            -- Profiteering
            if not player:HasPolicy(GameInfo.Policies["POLICY_INDUSTRY_8"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_INDUSTRY_8"].ID, true);
            end

            -- Magnasanti
            if not player:HasPolicy(GameInfo.Policies["POLICY_INDUSTRY_15"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_INDUSTRY_15"].ID, true);
            end

            -- Foresight
            if not player:HasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_1"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_1"].ID, true);
            end

            -- Creative Class
            if not player:HasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_5"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_5"].ID, true);
            end

            -- Community Medicine
            if not player:HasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_8"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_8"].ID, true);
            end

            -- Public Security
            if not player:HasPolicy(GameInfo.Policies["POLICY_MIGHT_6"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_MIGHT_6"].ID, true);
            end

            -- Mind Over Matter
            if not player:HasPolicy(GameInfo.Policies["POLICY_PROSPERITY_10"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_PROSPERITY_10"].ID, true);
            end

            -- Joy From Variety
            if not player:HasPolicy(GameInfo.Policies["POLICY_PROSPERITY_12"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_PROSPERITY_12"].ID, true);
            end

            -- Eudaimonia
            if not player:HasPolicy(GameInfo.Policies["POLICY_PROSPERITY_15"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_PROSPERITY_15"].ID, true);
            end
        end
    end
end
Events.SequenceGameInitComplete.Add(GiveFreeHealthPolicies);

-- NOTE: much of this code is from unitupgradepopup.lua
function DebugUpgrades(playerID)
    -- TODO: only apply logic if game option is enabled

    local player = Players[playerID];

    if not player:IsHuman() or not player:IsAlive() then
        return;
    end

    local MAX_UPGRADE_LEVELS = 3;
	local purityAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_PURITY"].ID);
	local harmonyAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_HARMONY"].ID);
	local supremacyAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_SUPREMACY"].ID);
	local anyAmt = (purityAmt + harmonyAmt + supremacyAmt);

    print("(DebugUpgrades) player:HasAnyPendingUpgrades()=", player:HasAnyPendingUpgrades());
	if (player:HasAnyPendingUpgrades()) then
	    for unitInfo in GameInfo.Units() do
            local hasPendingUpgrade = player:DoesUnitHavePendingUpgrades(unitInfo.ID, -1, true);

            if hasPendingUpgrade then
                print("(DebugUpgrades) unitInfo.Type=", unitInfo.Type)
                print("(DebugUpgrades) hasPendingUpgrade=", hasPendingUpgrade)

                -- Store which upgrade tier is next (the one pending for upgrade)
                local nextLevel	= 0;
                -- Total number of upgrade tiers for the unit
                local numLevels = 0;
                for iLevel = 1, MAX_UPGRADE_LEVELS do
                    -- Figure out how many total upgrade levels the unit has
                    local upgradeTypes = player:GetUpgradesForUnitClassLevel(unitInfo.ID, iLevel);
                    ---@diagnostic disable-next-line: undefined-field
                    if table.count(upgradeTypes) > 0 then
                        numLevels = numLevels + 1;
                    end

                    -- Figure out which upgrade tier is next (the one pending for upgrade)
                    print("(DebugUpgrades) iLevel=", iLevel)
                    print("(DebugUpgrades) table.count(upgradeTypes)=", table.count(upgradeTypes))
                    print("(DebugUpgrades) nextLevel=", nextLevel)
                    print("(DebugUpgrades) numLevels=", numLevels)
                    print("(DebugUpgrades) player:IsUnitUpgradeTierReady(unitInfo.ID, iLevel)=", player:IsUnitUpgradeTierReady(unitInfo.ID, iLevel))
                    if player:IsUnitUpgradeTierReady(unitInfo.ID, iLevel) then
                        nextLevel = iLevel;
                    end
                end

                print("(DebugUpgrades) nextLevel=", nextLevel)
                print("(DebugUpgrades) numLevels=", numLevels)

                -- Only auto upgrade if this is not the last upgrade tier for the unit
                if nextLevel < numLevels then
                    -- Get available upgrades for the pending upgrade tier
                    local upgradeTypes = player:GetUpgradesForUnitClassLevel(unitInfo.ID, nextLevel);

                    -- Track the number of purchasable upgrades at the pending upgrade tier
                    local numPurchasableUpgrades = 0;
                    local purchasableUpgradeType = 0;
                    -- Figure out which upgrades the unit is eligible for
                    for _,iType in ipairs(upgradeTypes) do
                        print("(DebugUpgrades) iType=", iType)
                        local upgrade = GameInfo.UnitUpgrades[iType];

                        local isPurchasable =
                            upgrade.AnyAffinityLevel <= anyAmt and
                            upgrade.PurityLevel		<= purityAmt and
                            upgrade.HarmonyLevel	<= harmonyAmt and
                            upgrade.SupremacyLevel	<= supremacyAmt;

                        print("(DebugUpgrades) isPurchasable=", isPurchasable)

                        if isPurchasable then
                            numPurchasableUpgrades = numPurchasableUpgrades + 1;
                            purchasableUpgradeType = iType;
                        end
                    end

                    print("(DebugUpgrades) numPurchasableUpgrades=", numPurchasableUpgrades)

                    -- Only auto upgrade if there's exactly one available upgrade tier
                    if numPurchasableUpgrades == 1 then
                        -- Get the available perks for the upgrade and pick a random one
                        local perkTypes	= player:GetPerksForUpgrade(purchasableUpgradeType);
                        local randomIndex = math.random(#perkTypes);
                        local randomPerkType = perkTypes[randomIndex];

                        print("(DebugUpgrades) randomIndex=", randomIndex)
                        print("(DebugUpgrades) randomPerkType=", randomPerkType)


                        local hasUpgrade = player:DoesUnitHaveUpgrade(unitInfo.ID, purchasableUpgradeType);
                        local hasPerk = player:DoesUnitHavePerk(unitInfo.ID, randomPerkType);
                        print("(DebugUpgrades) hasUpgrade=", hasUpgrade)
                        print("(DebugUpgrades) hasPerk=", hasPerk)

                        -- local perkTypes			: table = m_player:GetPerksForUnit(unit.ID);

                        -- local perkInfo : table = GameInfo.UnitPerks[perkType];

                        -- for iLevel,upgradeInstances in ipairs(unit.Upgrades) do
                        --     for i,upgradeData in pairs(upgradeInstances) do
                        --         m_selectedUpgrade = upgradeData;
                        --         for _,perk in ipairs(m_selectedUpgrade.Perks) do


                        -- Apply the upgrade and random perk
                        if not hasUpgrade and not hasPerk then
                            -- TODO: Get unit, upgrade, perk for better logging
                            print("(Micro Beyond Earth) Auto upgrading unit", unitInfo.ID, "with upgrade", purchasableUpgradeType, "and perk", randomPerkType);
                            player:AssignUnitUpgrade(unitInfo.ID, purchasableUpgradeType, randomPerkType);
                        end
                    end
                end
            end
	    end
	end
end
GameEvents.PlayerDoTurn.Add(DebugUpgrades);