{-# LANGUAGE OverloadedStrings #-}

module Game
    ( runGame
    ) where

import Types
import Actions
import GameState
import Color
import Util (firstJust, maybeHead, prompt, (|>))
import InputParser (parseInput)
import Stories.Types (StoryParseResult(..), beginStory, loadStory)
-- import InitState (story)

import Control.Applicative ((<|>))
import Data.Foldable (forM_)
import Data.Maybe (mapMaybe, fromMaybe)
import qualified Data.Map.Strict as Map
import Data.Text (Text, pack, unpack)
import qualified Data.Text as T
import System.Console.Haskeline
import System.Environment


data UpdateResult
  = NoChangeWithMessage Text
  | ChangedState GameState Text
  | Terminate String


-- |Decrement the time left of the game by one
tickState :: GameState -> GameState
tickState oldState =
  let (Time t) = gTimeLeft oldState
  in oldState { gTimeLeft = Time (t - 1) }


updateStateWith2Things :: GameState -> Thing -> Thing -> MultiThingAction -> UpdateResult
updateStateWith2Things oldState thing1 thing2 action =
  case action of
    ActOnThing1 thingAction ->
      updateStateWithThing oldState thing1 thingAction
    ActOnThing2 thingAction ->
      updateStateWithThing oldState thing2 thingAction
    ActOnNothing msg ->
      NoChangeWithMessage msg


updateStateWithThing :: GameState -> Thing -> ThingAction -> UpdateResult
updateStateWithThing oldState thing action =
  case action of
    Grab msg ->
      let newState =
            oldState
            |> addToYou thing
            |> removeFromRoom thing
      in ChangedState newState msg
    Inspect msg ->
      ChangedState oldState msg
    ReplaceSelfWithThings msg things ->
      let newState =
            oldState
            |> removeFromRoom thing
            |> \gameState -> foldl (flip addToRoom) gameState things
      in ChangedState newState msg
    TravelRoom msg room ->
      let newState = oldState { gRoom = room }
      in ChangedState newState msg
    Describe ->
      NoChangeWithMessage $ tDescription thing
    GrabThings msg things ->
      let newState =
            oldState
            |> \gameState -> foldl (flip addToYou) gameState things
      in ChangedState newState msg
    TriggerActionOn triggeredThing thingAction ->
      updateStateWithThing oldState triggeredThing thingAction


-- |Tries to find the first thing from your inventory, the second from your inventory or the current
-- room, and lastly tries to find the interaction between the things if they've been found.
findCombinableThings :: GameState -> Label -> Label -> Maybe (Thing, Thing, MultiThingAction)
findCombinableThings gameState l1 l2 = do
  thing1 <- findInInventory l1 (gYou gameState)
  thing2 <- findInInventory l2 (roomInventory gameState) <|> findInInventory l2 (gYou gameState)
  thingAction <- Map.lookup l2 $ tCombinations thing1
  return (thing1, thing2, thingAction)


updateState :: GameState -> UpdatingAction -> UpdateResult
updateState oldState action =
  case action of
    NoOp ->
      ChangedState oldState "you do nothing for a bit"
    Interact l ->
      case findInInventory l (roomInventory oldState) of
        Nothing ->
          NoChangeWithMessage $ red "couldn't find that here"
        Just thing ->
          updateStateWithThing oldState thing (tInteraction thing)
    Combine l1@(Label s1) l2@(Label s2) ->
      case findCombinableThings oldState l1 l2 of
        Just (thing1, thing2, thingAction) ->
          updateStateWith2Things oldState thing1 thing2 thingAction
        Nothing ->
          NoChangeWithMessage $ red $ T.concat ["You can't use ", s1, " on ", s2, " (maybe you can't find one of them or they can't be combined)"]


lookAt :: Label -> [Inventory] -> String
lookAt thingLabel i =
  let found = firstJust (findInInventory thingLabel) i
  in maybe ("couldn't find " ++ unpack (blue (pack (show thingLabel))) ++ " here.") show found


lookAtRoom :: Room -> String
lookAtRoom room =
  let things = rInventory room
      descriptions :: [Text]
      descriptions =
        things
        |> Map.elems
        |> mapMaybe tRoomDescription
  in unpack (rDescription room) ++ "\n" ++ unlines (map unpack descriptions)


dispatchAction :: GameState -> Action -> UpdateResult
dispatchAction oldState action =
  case action of
    Look ->
      NoChangeWithMessage $ pack $ lookAtRoom (gRoom oldState)
    LookAt label ->
      NoChangeWithMessage $ pack $ lookAt label [roomInventory oldState, gYou oldState]
    Inventory ->
      NoChangeWithMessage $ pack $ "you have: " ++ show (Map.keys (gYou oldState))
    Panic ->
      Terminate "you flip the fluff out"
    Update updatingAction ->
      updateState oldState updatingAction
    Help ->
      NoChangeWithMessage $ pack $ "commands: " ++ unpack (green "look") ++ ", interact, wait, help, panic"
    BadInput msg ->
      NoChangeWithMessage $ pack $ fromMaybe "huh?" msg


timesUp :: GameState -> Bool
timesUp = (<= Time 0) . gTimeLeft


loop :: GameState -> InputT IO ()
loop oldState
  | timesUp oldState = outputStrLn "Times up! You died."
  | otherwise = do
      outputStrLn ""
      action <- parseInput <$> prompt (unpack $ green "What do you want to do? ")
      case dispatchAction oldState action of
        NoChangeWithMessage msg -> do
          outputStrLn $ unpack msg
          loop oldState
        ChangedState newState message -> do
          let newState' = tickState newState
          forM_ (currentEvent newState') outputStrLn
          outputStrLn $ unpack message
          loop newState'
        Terminate msg ->
          outputStrLn msg


runGame :: IO ()
runGame = do
  args <- getArgs
  let mStoryFile = maybeHead args
  case mStoryFile of
    Nothing ->
      putStrLn "usage: dod stories/test.yml"
    Just path -> do
      result <- loadStory path
      case result of
        FailedToParseStory msg ->
          putStrLn msg
        Parsed story ->
          runInputT defaultSettings $ beginStory story loop
