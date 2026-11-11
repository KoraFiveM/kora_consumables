# Converted from the communitybot legacy tests by kora-qa-panel/scripts/convert-legacy.mjs.
# The """ block under each Scenario is the original test text, verbatim. Review before applying.
Feature: kora_consumables — Activities

  @kora_consumables @checklist @checklist:kora_consumables:eat-food @cat:activities
  Scenario: Eat food items
    """
    Checklist test: Use sandwich, hot_dog, chips, bread, chocolate_bar from inventory; progress bar + prop; hunger rises after finishing.
    """
    Given I have 1 "sandwich"
    And I have 1 "hot_dog"
    And I have 1 "chips"
    And I have 1 "bread"
    And I have 1 "chocolate_bar"
    When I open my inventory
    And I use a "sandwich"
    Then a progress bar should run
    And I confirm: a food prop appears in my hands while eating
    And I confirm: my hunger rises after the progress bar finishes
    And my "sandwich" count should have changed by -1
    When I use a "hot_dog"
    Then a progress bar should run
    And I confirm: a food prop appears and my hunger rises after finishing
    When I use a "chips"
    Then a progress bar should run
    And I confirm: a food prop appears and my hunger rises after finishing
    When I use a "bread"
    Then a progress bar should run
    And I confirm: a food prop appears and my hunger rises after finishing
    When I use a "chocolate_bar"
    Then a progress bar should run
    And I confirm: a food prop appears and my hunger rises after finishing

  @kora_consumables @checklist @checklist:kora_consumables:drink-items @cat:activities
  Scenario: Drink water, soda, coffee
    """
    Checklist test: Use water, water_bottle, soda, coffee; thirst rises; soda also lowers stress; coffee uses right-hand cup prop.
    """
    Given I have 1 "water"
    And I have 1 "water_bottle"
    And I have 1 "soda"
    And I have 1 "coffee"
    When I use a "water"
    Then a progress bar should run
    And I confirm: my thirst rises after finishing
    When I use a "water_bottle"
    Then a progress bar should run
    And I confirm: my thirst rises after finishing
    When I use a "soda"
    Then a progress bar should run
    And I confirm: my thirst rises after finishing
    And I confirm: my stress is lowered
    When I use a "coffee"
    Then a progress bar should run
    And I confirm: my thirst rises after finishing
    And I confirm: the coffee cup prop is in my right hand

  @kora_consumables @checklist @checklist:kora_consumables:liquor-items @cat:activities
  Scenario: Drink beer, whiskey, vodka, wine
    """
    Checklist test: Use any beer/whiskey/vodka/wine item; thirst +10 and buzzed visual effect for ~15s.
    """
    Given I have 1 "beer"
    And I have 1 "whiskey"
    And I have 1 "vodka"
    And I have 1 "wine"
    When I use a "beer"
    Then a progress bar should run
    And my metadata "thirst" should have changed by 10
    And I confirm: a buzzed visual effect lasts for about 15 seconds
    When I use a "whiskey"
    Then my metadata "thirst" should have changed by 10
    And I confirm: the buzzed effect shows for about 15 seconds
    When I use a "vodka"
    Then my metadata "thirst" should have changed by 10
    And I confirm: the buzzed effect shows for about 15 seconds
    When I use a "wine"
    Then my metadata "thirst" should have changed by 10
    And I confirm: the buzzed effect shows for about 15 seconds

  @kora_consumables @checklist @checklist:kora_consumables:smoke-items @cat:activities
  Scenario: Smoke cigarettes and joints
    """
    Checklist test: Use cigarette or a *_joint item; stress drops, health -5, alien visual effect (cigarette has none).
    """
    Given I have 1 "cigarette"
    And I have 1 "joint"
    And I am at full health
    When I use a "cigarette"
    Then my metadata "stress" should have decreased
    And I confirm: my health drops by 5
    And I confirm: no visual effect appears for the cigarette
    When I use a "joint"
    Then my metadata "stress" should have decreased
    And I confirm: my health drops by 5
    And I confirm: an alien visual effect appears

  @kora_consumables @checklist @checklist:kora_consumables:item-consumed-on-finish @cat:activities
  Scenario: Item removed only after completion
    """
    Checklist test: Start using an item then cancel the progress bar; item stays and no status changes. Finish it: item removed once.
    """
    Given I have 1 "soda"
    When I use a "soda"
    And I cancel the progress bar
    Then I should have 1 "soda"
    And I confirm: my hunger, thirst and stress did not change
    When I use a "soda"
    And I wait 10 seconds
    Then I should have no "soda"
    And my "soda" count should have changed by -1

  @kora_consumables @checklist @checklist:kora_consumables:cancel-progress @cat:activities
  Scenario: Cancel use mid-animation
    """
    Checklist test: Use an item and cancel the progress bar; animation and prop are cleaned up, nothing applied.
    """
    Given I have 1 "soda"
    When I use a "soda"
    And I cancel the progress bar
    Then I confirm: the animation stops and the prop is removed
    And I confirm: no status effect was applied
    And I should have 1 "soda"

  @kora_consumables @checklist @checklist:kora_consumables:walk-while-using @cat:activities
  Scenario: Move while eating/drinking
    """
    Checklist test: Use food/drink and walk; upper-body animation plays while moving (Config.allowMovement); combat and vehicle entry blocked.
    """
    Given I have 1 "sandwich"
    And I have 1 "water"
    When I use a "sandwich"
    And I manually: walk around while the progress bar runs
    Then I confirm: an upper-body animation plays while I move (only applies when Config.allowMovement is enabled; otherwise mark Pass if movement is blocked)
    When I manually: try to shoot or punch while the progress bar runs
    Then I confirm: combat actions are blocked
    When I manually: try to enter a vehicle while the progress bar runs
    Then I confirm: vehicle entry is blocked

  @kora_consumables @checklist @checklist:kora_consumables:double-use-blocked @cat:activities
  Scenario: Cannot use two items at once
    """
    Checklist test: Spam-use an item or use a second one while the first bar is running; second use is ignored.
    """
    Given I have 3 "soda"
    And I have 1 "water"
    When I use a "soda"
    And I use a "soda"
    And I use a "water"
    And I wait 10 seconds
    Then my "soda" count should have changed by -1
    And I should have 1 "water"
    And I confirm: only one progress bar ran and the second use was ignored

  @kora_consumables @checklist @checklist:kora_consumables:uses-counter @cat:activities @manual
  Scenario: Items with limited uses
    """
    Checklist test: Use an item whose info.uses is set; uses decrement and item is removed only at 0.
    """
    When I manually: obtain a consumable item whose info.uses is set, for example by asking a Mod to give one
    And I manually: use the item once
    Then I confirm: the item's uses decrement by 1 and the item stays in my inventory
    When I manually: keep using the item until its uses reach 0
    Then I confirm: the item is removed only when uses reach 0

  @kora_consumables @checklist @checklist:kora_consumables:status-clamped @cat:activities
  Scenario: Status clamped 0-100
    """
    Checklist test: Use food at 100 hunger; value stays at 100 with no error.
    """
    Given my metadata "hunger" is "100"
    And I have 1 "sandwich"
    When I use a "sandwich"
    And I wait 10 seconds
    Then my metadata "hunger" should be "100"
    And there should be no script errors

  @kora_consumables @checklist @checklist:kora_consumables:qb-compat-exports @cat:activities @needs:admin @manual
  Scenario: AddFood/AddDrink/AddAlcohol/AddCustom exports
    """
    Checklist test: From another server resource call exports.kora_consumables:AddFood(name, 20); item becomes usable, bad/duplicate names return false.
    """
    When I manually: in the server console, run a Lua snippet from another resource that calls exports.kora_consumables:AddFood(name, 20) with an existing item name that is not yet configured as a consumable
    And I manually: give myself 1 of that item and note my current hunger
    And I manually: use that item from my inventory
    Then I confirm: the item is usable and my hunger increases by about 20 after the progress bar finishes
    When I manually: in the server console, call exports.kora_consumables:AddFood with a nonexistent item name and print the result
    Then I confirm: the call returns false (reason 'item does not exist')
    When I manually: in the server console, call AddFood again with the same item name that was already added and print the result
    Then I confirm: the call returns false (reason 'already added')

  @kora_consumables @checklist @checklist:kora_consumables:late-join-sync @cat:activities @needs:admin @manual
  Scenario: Added items sync to joining players
    """
    Checklist test: Add a consumable via export, then join/reconnect a client; the new item is usable there without restart.
    """
    When I manually: in the server console, run a Lua snippet that calls exports.kora_consumables:AddFood(name, 20) with an existing item name that is not yet configured as a consumable
    And I manually: give myself 1 of that item
    And I manually: disconnect from the server and reconnect
    And I manually: use the newly added item from my inventory
    Then I confirm: the item is usable and its progress bar runs, without any resource restart
