-- Abort all covert operations for all of the player's agents except for establish network
function AbortCovertOperations(playerID)
    if (PreGame.GetGameOption("GAMEOPTION_NO_COVERT_OPERATIONS") ~= 1) then
        return;
    end

    local player = Players[playerID];

    -- Apply the logic to human and computer players alike
    if (not player:IsMajorCiv() or not player:IsAlive()) then
        return;
    end

    for _, agent in ipairs(player:GetCovertAgents()) do
        if (agent:IsDoingOperation()) then
            local operation = agent:GetOperation();
            if (operation ~= nil) then
                if (operation.Type ~= GameInfo.CovertOperations["COVERT_OPERATION_ESTABLISH_NETWORK"].ID) then
                    local operationInfo = GameInfo.CovertOperations[operation.Type]
                    print("(Micro Beyond Earth) Aborting covert operation " .. operationInfo.Type .. " for player " .. playerID);
                    agent:AbortOperation();
                end
            end
        end
    end
end
GameEvents.PlayerDoTurn.Add(AbortCovertOperations);

function CanCityConstructBuilding(playerID, _, buildingID)
    local player = Players[playerID];

    -- Apply the logic to human and computer players alike
    if (not player:IsMajorCiv() or not player:IsAlive()) then
        return;
    end

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

    if not player:IsHuman() or not player:IsAlive() then
        return;
    end

    -- Explorers seem to stay automated until there's nothing left to explore
    if (PreGame.GetGameOption("GAMEOPTION_EXPLORERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_EXPLORER"].ID then
            -- If the unit isn't in the table we're using to track automated units
            if not automatedUnits[unitID] then
                -- If the unit is already automated (e.g. after loading a save)
                if unit:IsAutomated() then
                    -- Mark the unit as automated by adding its ID to the table
                    automatedUnits[unitID] = true;

                -- If the unit isn't automated, first check that we can automated it
                elseif unit:CanDoCommand(CommandTypes.COMMAND_AUTOMATE, 1) then
                    print("(Micro Beyond Earth) Automating explorer");
                    -- 1 = AutomateTypes.AUTOMATE_EXPLORE in CvEnums.h (from Civ 5 SDK)
                    unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 1);

                    automatedUnits[unitID] = true;
                end
            end
        end
    end

    -- Every once in a while a worker seems to get ... un-automated, maybe because an
    -- alien or another unit is occupying a tile it was going to move to? I'm not sure
    -- it's worth worrying about since the workaround is as simple as clicking automate
    -- again
    if (PreGame.GetGameOption("GAMEOPTION_WORKERS_START_AUTO") == 1) then
        if unit ~= nil and unit:GetUnitType() == GameInfo.Units["UNIT_WORKER"].ID then
            if not automatedUnits[unitID] then
                if unit:IsAutomated() then
                    automatedUnits[unitID] = true;

                elseif unit:CanDoCommand(CommandTypes.COMMAND_AUTOMATE, 0) then
                    print("(Micro Beyond Earth) Automating worker");
                    -- 0 = AutomateTypes.AUTOMATE_BUILD in CvEnums.h (from Civ 5 SDK)
                    unit:DoCommand(CommandTypes.COMMAND_AUTOMATE, 0);

                    automatedUnits[unitID] = true;
                end
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

    -- Apply the logic to human and computer players alike
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

        -- Apply the logic to human and computer players alike
        if player:IsMajorCiv() and player:IsAlive() then
            -- Profiteering
            -- NOTE: We're explitly not using player:CanAdoptPolicy() here because it will
            -- only return true for the first policy in each branch because the
            -- prerequisite policies haven't been unlocked yet
            if not player:HasPolicy(GameInfo.Policies["POLICY_INDUSTRY_8"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_INDUSTRY_8"].ID, true);
            end

            -- Magnasanti
            if not player:HasPolicy(GameInfo.Policies["POLICY_INDUSTRY_15"].ID) then
                player:SetHasPolicy(GameInfo.Policies["POLICY_INDUSTRY_15"].ID, true);
            end

            -- Foresight
            if not player:HasPolicy(GameInfo.Policies["POLICY_KNOWLEDGE_1"].ID) then
                -- For some reason we have to unlock the policy branch first but only for the first policy in a branch
                if not player:IsPolicyBranchUnlocked(GameInfo.PolicyBranchTypes["POLICY_BRANCH_KNOWLEDGE"].ID) then
                    player:SetPolicyBranchUnlocked(GameInfo.PolicyBranchTypes["POLICY_BRANCH_KNOWLEDGE"].ID, true)
                end
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
-- Run this once at the start of the game
Events.SequenceGameInitComplete.Add(GiveFreeHealthPolicies);

-- If the Auto Upgrade Units option is checked, automatically upgrade units up to but not
-- including the final tier for each unit
-- NOTE: much of this code is from unitupgradepopup.lua
function AutoUpgradeUnits(playerID)
    if (PreGame.GetGameOption("GAMEOPTION_AUTO_UPGRADE_UNITS") ~= 1) then
        return;
    end

    local player = Players[playerID];

    if not player:IsHuman() or not player:IsAlive() then
        return;
    end

    local MAX_UPGRADE_LEVELS = 3;
	local purityAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_PURITY"].ID);
	local harmonyAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_HARMONY"].ID);
	local supremacyAmt = player:GetAffinityLevel(GameInfo.Affinity_Types["AFFINITY_TYPE_SUPREMACY"].ID);
	local anyAmt = (purityAmt + harmonyAmt + supremacyAmt);

	if (player:HasAnyPendingUpgrades()) then
	    for unitInfo in GameInfo.Units() do
            local hasPendingUpgrade = player:DoesUnitHavePendingUpgrades(unitInfo.ID, -1, true);

            if hasPendingUpgrade then
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
                    if player:IsUnitUpgradeTierReady(unitInfo.ID, iLevel) then
                        nextLevel = iLevel;
                    end
                end

                -- Only auto upgrade if this is not the last upgrade tier for the unit
                if nextLevel < numLevels then
                    -- Get available upgrades for the pending upgrade tier
                    local upgradeTypes = player:GetUpgradesForUnitClassLevel(unitInfo.ID, nextLevel);

                    -- Track the number of purchasable upgrades at the pending upgrade tier
                    local numPurchasableUpgrades = 0;
                    local availableUpgradeId = 0;
                    -- Figure out which upgrades the unit is eligible for
                    for _, iType in ipairs(upgradeTypes) do
                        local upgrade = GameInfo.UnitUpgrades[iType];

                        local isPurchasable =
                            upgrade.AnyAffinityLevel <= anyAmt and
                            upgrade.PurityLevel		<= purityAmt and
                            upgrade.HarmonyLevel	<= harmonyAmt and
                            upgrade.SupremacyLevel	<= supremacyAmt;

                        if isPurchasable then
                            numPurchasableUpgrades = numPurchasableUpgrades + 1;
                            availableUpgradeId = iType;
                        end
                    end

                    -- Only auto upgrade if there's exactly one available upgrade tier
                    if numPurchasableUpgrades == 1 then
                        -- Get the available perks for the upgrade and pick a random one
                        local perkTypes	= player:GetPerksForUpgrade(availableUpgradeId);
                        local randomIndex = math.random(#perkTypes);
                        local randomPerkId = perkTypes[randomIndex];

                        -- Apply the upgrade and random perk
                        local hasUpgrade = player:DoesUnitHaveUpgrade(unitInfo.ID, availableUpgradeId);
                        local hasPerk = player:DoesUnitHavePerk(unitInfo.ID, randomPerkId);
                        if not hasUpgrade and not hasPerk then
                            local upgrade = GameInfo.UnitUpgrades[availableUpgradeId];
                            local perk = GameInfo.UnitPerks[randomPerkId];
                            print("(Micro Beyond Earth) Auto upgrading unit " .. unitInfo.Type .. " with upgrade " .. upgrade.Type .. " and perk " .. perk.Type);
                            player:AssignUnitUpgrade(unitInfo.ID, availableUpgradeId, randomPerkId);
                        end
                    end
                end
            end
	    end
	end
end
GameEvents.PlayerDoTurn.Add(AutoUpgradeUnits);
