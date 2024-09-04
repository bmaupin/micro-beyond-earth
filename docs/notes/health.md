# Health

Problem: enabling `GAMEOPTION_NO_HEALTH` in the game seems to just not show health, while the underlying health systems don't seem to actually be disabled.

## Idea 1: Give free health policies

This might be easiest as it could be a one-time thing. Grant all players all health policies, if possible.

Seems like it should be feasible? Civ 5 has `DoAdoptPolicy`

## Idea 2: Set health and unhealth to 0

Every turn, set health and unhealth to 0. I think it might need to be done per player, per turn, since it seems like it may not persist.

## Interesting code

#### Health

```
$ strings ../Sid\ Meier\'s\ Civilization\ Beyond\ Earth/libCvGameCoreDLL_Expansion1.so | grep ^CvLua | grep Health | egrep -v Get | sort
CvLuaArgs::pushValue<HealthLevelTypes>
CvLuaMethodWrapper<CvLuaPlayer, CvPlayer>::BasicLuaMethod<HealthLevelTypes>
CvLuaPlayer::lChangeExtraHealthPerCity
CvLuaPlayer::lChangeHealthPerGarrisonedUnit
CvLuaPlayer::lChangeHealthPerTradeRoute
CvLuaPlayer::lIsAffectedByHealthLevel
CvLuaPlayer::lSetHealth
CvLuaPlayer::lSetHealthPerGarrisonedUnit
CvLuaPlayer::lSetHealthPerTradeRoute
```

Equivalates to:

pPlayer:ChangeExtraHealthPerCity()
pPlayer:ChangeHealthPerGarrisonedUnit()
pPlayer:ChangeHealthPerTradeRoute()
pPlayer:SetHealth()
pPlayer:SetHealthPerGarrisonedUnit()
pPlayer:SetHealthPerTradeRoute()

#### Policies

```
$ strings ../Sid\ Meier\'s\ Civilization\ Beyond\ Earth/libCvGameCoreDLL_Expansion1.so | grep ^CvLua | egrep -v "CvLuaArgs|CvLuaMethodWrapper" | grep Polic | egrep -v Get | sort
CvLuaCity::lChangeCulturePerTurnFromPolicies
CvLuaGame::lHasMadeAgreementWithPolicy
CvLuaGame::lIsKickerPolicy
CvLuaGame::lIsPlayerReceivingPolicyFromAgreement
CvLuaPlayer::lAddForeignPolicy
CvLuaPlayer::lCanAdoptAnyPolicy
CvLuaPlayer::lCanAdoptPolicy
CvLuaPlayer::lCanUnlockPolicyBranch
CvLuaPlayer::lChangeNumFreePolicies
CvLuaPlayer::lChangeScoreFromFuturePolicies
CvLuaPlayer::lDoAdoptPolicy
CvLuaPlayer::lHasPolicy
CvLuaPlayer::lIsPolicyBlocked
CvLuaPlayer::lIsPolicyBranchBlocked
CvLuaPlayer::lIsPolicyBranchFinished
CvLuaPlayer::lIsPolicyBranchUnlocked
CvLuaPlayer::lRemoveForeignPolicy
CvLuaPlayer::lSetHasPolicy
CvLuaPlayer::lSetNumFreePolicies
CvLuaPlayer::lSetPolicyBranchUnlocked
CvLuaQuestObjective::lSetExtraPolicyAIWeight
```

## Testing

- pPlayer:ChangeExtraHealthPerCity()
  - Persists between turns?: yes, changes pPlayer:GetExtraHealthPerCity()
- pPlayer:ChangeHealthPerGarrisonedUnit()
  - Persists between turns?: no?
- pPlayer:ChangeHealthPerTradeRoute()
  - Persists between turns?: unsure (no trade routes in test game)
- pPlayer:SetHealth()
  - Persists between turns?: no
- pPlayer:SetHealthPerGarrisonedUnit()
  - Persists between turns?: no?
- pPlayer:SetHealthPerTradeRoute()
  - Persists between turns?: unsure

#### Algorithm idea

1. Get total health

   ```
   player:GetExcessHealth()
   ```

1. Get extra health per city

   ```
   player:GetExtraHealthPerCity()
   ```

1. Get number of cities

   ```
   player:GetNumCities()
   ```

1. Adjust health each turn to get total health in the range 0-5

   - baseline health = excess health - (extra health per city \* number of cities)
   - if baseline health < 0:
     - adjustment = round up to nearest integer(absolute value (baseline health) / number of cities)
     - player:ChangeExtraHealthPerCity(adjustment)
   - or if baseline health > 5:
     - adjustment = round down to nearest integer(absolute value (baseline health) / number of cities)
     - player:ChangeExtraHealthPerCity(adjustment)
