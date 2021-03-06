module Stories.CryoSleep where

import GameState
import Color
import Data.Map.Strict as Map
import Types
import Stories.Types


initState :: GameState
initState =
  let roomCryoPod = Room
        { rShortDescription = "You see the inside of a CryoPod 3001 that you are lieing down in. You should take a " ++ action "look" ++ " around."
        , rDescription = "In the tight space around you, you see lots of frost. You're lieing on a metal bed, with a cracked " ++
        "glass window in front of you. The window is covered in frost, so you can't see anything beyond it. " ++
        "You don't remember how you got here, and trying seems to hurt your head."
        , rInventory = Map.fromList [(tLabel thingButton, thingButton)]
        }
      thingButton = Thing
        { tDescription = "A large glowing button that says \"Open\", and is covered with a thin layer of frost"
        , tInteraction = TravelRoom (
        "Pushing the button causes the glass to slide off the side, opening your Pod. " ++
        "You sit up, and immediately wich you hadn't as you try to avoid vomiting. You try to think back to what you " ++
        "were told about waking up from cryosleep, though only faint memories greet you, you're certain this is not " ++
        "what it's supposed to be like. Slowly, you coax your stiff joints into motion, and get out of your pod.\n\n" ++
        "Now that you're upright, and your vision is no longer obscured by the frosted glass, you begin to take in the " ++
        "room you in which you find yourself.") roomCryoStorage
        , tLabel = Label "button"
        , tRoomDescription = Just $ "To your right is a " ++ thing "button" ++ ". If you " ++ action "interact" ++ " with it the CryoPod should open."
        , tCombinations = Map.empty
        }
      roomCryoStorage = Room
        { rShortDescription = "You are in a small room with the " ++ thing "CryoPod" ++ " that you woke up from. " ++
        "You should " ++ action "look" ++ " around some more to see if you can find anything else in this room."
         , rDescription = "You " ++ action "look" ++ " around the Cryo Storage room. You notice a bloody, dismemebered, " ++
         thing "body" ++ " in a heap. There is also a glowing blue card " ++ thing "scanner" ++ " next to the door."
         , rInventory = Map.fromList
         [ (tLabel thingCryoPod, thingCryoPod)
         , (tLabel thingCryoBody, thingCryoBody)
         , (tLabel thingCryoStorageExitClosed, thingCryoStorageExitClosed)
         , (tLabel thingCryoScanner, thingCryoScanner)
         ]
         }
      thingCryoPod = Thing
        { tDescription = "The CryoPod 3001 that you woke up from."
        , tInteraction = Inspect "The CryoPod seems familiar, but there doesn't seem to be anything left to discover here."
        , tLabel = Label "CryoPod"
        , tRoomDescription = Nothing
        , tCombinations = Map.empty
        }
      thingCryoBody = Thing
        { tDescription = "A smelly, blood covered pile of body parts."
        , tInteraction = GrabThings ("You carefully dig through the body, avoiding touching more than you have to. You find a "
        ++ thing "keycard" ++ " in the pockets of the body. If you " ++ action "use" ++ " " ++ thing "keycard" ++ " " ++
        action "on" ++ " " ++ thing "scanner" ++ " the door should open.") [thingCryoKeyCard]
        , tLabel = Label "body"
        , tRoomDescription = Nothing
        , tCombinations = Map.empty
        }
      thingCryoScanner = Thing
        { tDescription = "You see a pedestal next to the " ++ thing "door" ++ ". In the center of it's face, there " ++
        "is a slight indentation which is likely where a keycard would go.  Above the indentation, in bold, red " ++
        "lettering, you see the message \"Authorized Personelle only\""
        , tInteraction = Inspect "You look around for any buttons, or barring that, a panel you can remove to try and short circuit the scanner, to no avail."
        , tLabel = Label "scanner"
        , tRoomDescription = Nothing
        , tCombinations = Map.empty
        }
      thingCryoKeyCard = Thing
        { tDescription = "A " ++ thing "keycard" ++ " with a magnetic strip. Perhaps you could " ++ action "use" ++ " it " ++ action "on" ++ " the " ++ thing "scanner" ++ "."
        , tInteraction = Describe
        , tLabel = Label "keycard"
        , tRoomDescription = Nothing
        , tCombinations = Map.fromList
          [ (tLabel thingCryoScanner, ActOnThing2 $ TriggerActionOn thingCryoStorageExitClosed $ ReplaceSelfWithThings "You place the keycard into the indentation in the scanner. You hear a faint ding\a, a light on the scanner goes green and the door slides open." [thingCryoStorageExitOpened] )
          , (tLabel thingCryoStorageExitClosed, ActOnNothing $ "Try using the " ++ thing "keycard" ++ " on the " ++ thing "scanner" ++ " instead.")
          ]
        }
      thingCryoStorageExitClosed = Thing
        { tDescription = "An automatic sliding metal door that is closed."
        , tInteraction = Inspect $ "It doesn't seem like you'll be able to force it open. You'll have to gain access through the card " ++ thing "scanner" ++ "."
        , tLabel = Label "door"
        , tRoomDescription = Just $ "At the far end of the room, you see a large, metal " ++ thing "door" ++ ", firmly shut"
        , tCombinations = Map.empty
        }
      thingCryoStorageExitOpened = Thing
        { tDescription = "An automatic sliding metal door that is open."
        , tInteraction = TravelRoom "You step through the open door." roomHallway
        , tLabel = Label "door"
        , tRoomDescription = Just $ "At the far end of the room, you see a large, open space, where the " ++ thing "door" ++ " slid open."
        , tCombinations = Map.empty
        }
      roomHallway = Room
        { rShortDescription = "A small hallway."
         , rDescription = "A small hallway adjoining your Cryopod Storage room, and the room ahead."
         , rInventory = Map.fromList
            [ (tLabel thingCryoStorageEntrance, thingCryoStorageEntrance)]
         }
      thingCryoStorageEntrance = Thing
        { tDescription = "An automatic sliding metal door that is open."
        , tInteraction = TravelRoom "You step through the open door." roomCryoStorage
        , tLabel = Label "entrance"
        , tRoomDescription = Just "You also see the open automatic door that will take you back into the Cryopod Storage."
        , tCombinations = Map.empty
        }

  in GameState
     { gRoom = roomCryoPod
     , gYou = Map.empty
     , gTimeLeft = Time 10
     , gEvents = Map.fromList
     [ (Time 5, "Your head spins, you don't remember how you know, but you're sure you are feeling the effects of extended Cryo sleep. You know you don't have long, but might be able to be saved if you can find a functioning MediTable 2001.")
     ]
     }

story :: Story
story = Story "CryoSleep" (
  "Welcome to CryoSleep! Take a look around the world, and try to survive. It is not possible to win on " ++
  "your first try, so take your time and explore. Using the " ++ action "look" ++ " command will tell you about the " ++
  "room you are in, and typing " ++ action "look" ++ " and then a " ++ thing "blue" ++ " label will describe that " ++
   thing "thing" ++ ". Looking is always free (it will never take time). Typing " ++ action "interact" ++ " and then a " ++
   thing "label" ++ " will often cost time, but also tell you more about the labeled thing, or even cause something " ++
   "to happen. The last thing you can do is to " ++ action "use" ++ " " ++ thing "something" ++  " on " ++ thing "something" ++
   " else. Note that the first thing must be in your " ++ action "inventory" ++ ". Good luck!"
   ) initState
