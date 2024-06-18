# Covert Ops

## Idea 1: disable covert ops altogether?

It seems like the way this works, this requires disabling anything that gives agents. Even if just one agent is given as part of a quest, covert ops will be enabled.

#### Buildings

This is pretty easy:

- Spy Agency
- CEL Cradle
- Feedsite Hub
- Command Center

(Look for `<FreeSpies>1</FreeSpies>` in CivBEPlayerPerks.xml)

Also probably should disable Surveillance Web since it's only for covert ops.

#### Virtues

There is one virtue that gives a free agent:

(Look for `<NumFreeCovertAgents>1</NumFreeCovertAgents>` in CivBEPolicies.xml)

- _Information Warfare_
  - `TXT_KEY_POLICY_KNOWLEDGE_13` in CivBEPolicies.xml

As well as a bonus:

- Synergy Bonus
  - (`POLICY_DEVOTED_KICKER_1`)

Ideas:

- `Player.SetHasPolicy`
- Ignore these; they likely won't happen until later in the game
- Disable them altogether somehow? I'm not sure that's dynamically possible at runtime
- Hook into the event for when an agent is recruited and kill it right away?
- Or override CovertOperationsSystem.lua, but then that would introduce compatibility issues with other mods ...
- A separate mod to disable Covert Ops? but that feels like a big pain ...

#### Interesting code

- `GameEvents.CovertAgentRecruited.Add(CovertOpsQuestManager.OnCovertAgentRecruited)`
- `GameEvents.PlayerDoTurn.Add(CovertOpsQuestManager.OnPlayerDoTurn)`

## Idea 2: disable covert ops missions

Instead of disabling covert ops altogether (which would be tricky to do since some agents are given as a result of virtues, not just buildings), it would be even nicer to just prevent covert ops missions. That would still allow sending agents throughout the map to spy on other Civs, which is nice since there's no way to see the whole map like there is in other Civ games.

Ideas:

- First, try `SetFailMode`
- Abort operations???

  ```
  function AbortCovertOperations(playerType)
    local agent = Players[playerType]:GetCovertAgentByIndex(agentID);

    local agent = city:GetCovertAgent(playerType)
  end
  GameEvents.PlayerDoTurn()
  ```

  - `agent:AbortOperation()`

- Keep city intrigue low?
  - `city:SetIntrigue(value)`
- Kill agents :P
- Fail objectives? ... I'm not sure we can :/

  - Add something like this to `GameEvents.PlayerDoTurn`:

    ```
    for operationInfo in GameInfo.CovertOperations() do
      if (operationInfo.ID ~= GameInfo.CovertOperations["COVERT_OPERATION_ESTABLISH_NETWORK"].ID) then
      end
    end
    `objective:Fail()`
    ```

- Prevent intrigue from ever going above 0? This would prevent all but the steal energy mission ...
- Override `.CanDo` for all operations?

#### Interesting code

- `agent:AbortOperation()`
- `agent:DoOperation(operationID?? or operationType)`
- `agent:SetHasEstablishedNetwork(true)`
- `CovertOperationsSystem.CanDoOperation`

Probably not helpful (read-only?):

- `CovertOperationsSystem.GetOperationTable`
- `g_Operations[operationInfo.ID] = operationTable;`

## Game events

```
Events.SerialEventGameInitFinished
Events.SerialEventStartGame
```

```
GameEvents.BuildFinished
GameEvents.BuildingProcessed
GameEvents.CityCreated
GameEvents.CityIntrigueLevelChanged
GameEvents.CovertAgentArrivedInCity
GameEvents.CovertAgentCompletedOperation
GameEvents.CovertAgentRecruited
GameEvents.PlayerCityFounded
GameEvents.PlayerDoTurn
GameEvents.ProjectProcessed
```

#### Undocumented APIs

1. Inspect CvGameCore DLL
1. Filter functions on `CvLua`
