# Unit upgrades

## Automate unit upgrades

### Idea 1: automate upgrades up to a certain level

The lower-level upgrades seem pretty minor to me. By automating them, it would make the early game go faster. Then we could disable auto upgrades for later tier units.

The implementation depends on the different classes of units:

- regular units
  - tier 2 and tier 3 upgrades seem minor
  - tier 4 upgrades should not be automated
    - these start at affinity 11, or hybrid 6-6
- affinity-specific units
  - lowest class (Xeno Swarm, Battlesuit, CNDR) upgrades are minor
  - next class (Xeno Calvary, Aegis, CARVR) upgrades are minor
  - higher than that, upgrades are meaningful
- hybrid units
  - these are mixed, but I think it's probably best to just not auto upgrade them at all

Based on this, this could be implemented a number of ways:

- Auto-upgrade all units up to last tier
  - This would get us most of the way there, except for the affinity-specific units. Might be a good place to start
- Auto-upgrade all units up to last tier
- Auto-upgrade based on affinity level
  - This might work, but would be complicated
    - We'd have to know for which affinity the upgrade was for, and take hybrid affinities into account as well
- Auto-upgrade all units up to last tier, except affinity-specific units; auto-upgrade only the first two classes of units
  - But how do we determine this? Maybe based on their affinity cost at tier 1, e.g. 7 and lower?

#### Implementation

1. At start of each turn, only for human players, check if there are upgrades
   - `Player:HasAnyPendingUpgrades`
1. Go through each unit to see if it has upgrades
   - `Player:DoesUnitHavePendingUpgrades`
   - or `Unit:CanUpgradeRightNow`? All the other methods use `Player`, so I think that's probably better
1. If a unit has upgrades, apply logic to see if we should auto-upgrade
   - TODO
1. Auto-upgrade as needed
   1. Get available unit perks; one of these? (For perk choices, see UnitUpgradePerkChoices)
      - `Player:GetPerksForUnit`
      - `Player:GetPerksForUpgrade`
      - `Player:GetUnitPerkList`
   1. Pick a random one
   1. Upgrade
      - `Player:AssignUnitUpgrade`

### ~~Idea 2: auto upgrade all units randomly~~

I don't think random upgrades will make anyone happy, including myself

### ~~Idea 3: auto upgrade randomly except for specific upgrades~~

The idea would be to randomly do most upgrades but pre-select some upgrades. But then this becomes much less useful to others and doesn't allow me to change my own mind on what upgrade I want.

### ~~Idea: 4: pre-select all upgrades~~

This would be a ton of work and similarly to idea 3, I don't think it would really be that useful.

## Useful code

#### Upgrades

Potentially useful:

- `Player:AssignUnitUpgrade`
- `Player:DoesUnitHavePendingUpgrades`
- `Player:HasAnyPendingUpgrades`
- `Unit:CanUpgradeRightNow`

All:

```
$ strings libCvGameCoreDLL_Expansion1.so | grep ^CvLua | grep "::" | grep Upgrade | sort -u | cut -c 6- | sed 's/::l/:/'
City:AllUpgradesAvailable
City:GetSpecialistUpgradeThreshold
Game:GetImprovementUpgradeTime
Game:GetUnitUpgradesTo
Player:AssignUnitUpgrade
Player:DoesUnitHavePendingUpgrades
Player:DoesUnitHaveUpgrade
Player:GetAssignedUpgradeAtLevel
Player:GetBestUnitUpgrade
Player:GetBestUnitUpgradeTier
Player:GetFirstAvailableUpgrade
Player:GetImprovementUpgradeRate
Player:GetImprovementUpgradeRateModifier
Player:GetPerksForUpgrade
Player:GetUpgradesForUnit
Player:GetUpgradesForUnitClassLevel
Player:GetUpgradeStatsForUnit
Player:HasAnyPendingUpgrades
Player:IgnoreUnitUpgrade
Player:IsUnitUpgradeIgnored
Player:IsUnitUpgradeTierReady
Player:IsUpgradeUnlocked
Player:RemoveUnitUpgrade
Plot:ChangeUpgradeProgress
Plot:GetUpgradeProgress
Plot:GetUpgradeTimeLeft
Plot:SetUpgradeProgress
Unit:CanUpgradeRightNow
Unit:GetNumResourceNeededToUpgrade
Unit:GetUpgradeDiscount
Unit:GetUpgradeUnitType
Unit:UpgradePrice
```

#### Perks

I think a "perk" is the choice we need to make when upgrading

Potentially useful:

- `Player:GetPerksForUnit`
- `Player:GetPerksForUpgrade`
- `Player:GetUnitPerkList`

All:

```
$ strings libCvGameCoreDLL_Expansion1.so | grep ^CvLua | grep "::" | grep Perk | sort -u | cut -c 6- | sed 's/::l/:/'
City:GetHealthFromPerks
City:IsPerkActive
Game:GetPlayerPerkBuildingClassAquaticCityMoveCostMod
Game:GetPlayerPerkBuildingClassCityHPChange
Game:GetPlayerPerkBuildingClassCityStrengthChange
Game:GetPlayerPerkBuildingClassCityStrikeMod
Game:GetPlayerPerkBuildingClassEnergyMaintenanceChange
Game:GetPlayerPerkBuildingClassFlatHealthChange
Game:GetPlayerPerkBuildingClassFlatYieldChange
Game:GetPlayerPerkBuildingClassGrowthCarryoverChange
Game:GetPlayerPerkBuildingClassMilitaryProductionMod
Game:GetPlayerPerkBuildingClassNavalProductionMod
Game:GetPlayerPerkBuildingClassOrbitalCoverageChange
Game:GetPlayerPerkBuildingClassPercentHealthChange
Game:GetPlayerPerkBuildingClassPercentYieldChange
Player:AddPerk
Player:DoesUnitHavePerk
Player:GetAllActivePlayerPerks
Player:GetAllActivePlayerPerkTypes
Player:GetBaseCombatStrengthWithPerks
Player:GetBaseMovesWithPerks
Player:GetBaseRangedCombatStrengthWithPerks
Player:GetBaseRangeWithPerks
Player:GetFreePerksForUnit
Player:GetNavalMovementChangeFromPlayerPerks
Player:GetPerksForUnit
Player:GetPerksForUpgrade
Player:GetPopulationUnhealthModFromPerks
Player:GetUnitPerkList
Player:HasPerk
Player:RemovePerk
```

#### Affinities

Potentially useful:

- `Player:GetAffinityLevel`
- `Player:GetDominantAffinityType`

All:

```
$ strings libCvGameCoreDLL_Expansion1.so | grep ^CvLua | grep "::" | grep Affinity | sort -u | cut -c 6- | sed 's/::l/:/'
Game:GetAverageDominantAffinityProgress
Game:GetTechAffinityValue
Player:CalculateAffinityScoreNeededForNextLevel
Player:ChangeAffinityScore
Player:ChangeNumFreeAffinityLevels
Player:GetAffinityLevel
Player:GetAffinityPercentTowardsMaxLevel
Player:GetAffinityPercentTowardsNextLevel
Player:GetAffinityScoreFromTech
Player:GetAffinityScoreTowardsNextLevel
Player:GetAIAffinityChoice
Player:GetBuildingAffinityRequirementDiscount
Player:GetDominantAffinityType
Player:GetNumFreeAffinityLevels
Player:GetUnitAffinityRequirementDiscount
Player:GetYieldPerTurnFromAffinityLevel
```
