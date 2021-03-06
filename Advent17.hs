
-- You're trying to access a secure vault protected by a 4x4 grid of small rooms connected by doors. You start in the top-left room (marked S), and you can access the vault (marked V) once you reach the bottom-right room:

-- #########
-- #S| | | #
-- #-#-#-#-#
-- # | | | #
-- #-#-#-#-#
-- # | | | #
-- #-#-#-#-#
-- # | | |  
-- ####### V
-- Fixed walls are marked with #, and doors are marked with - or |.

-- The doors in your current room are either open or closed (and locked) 
-- based on the hexadecimal MD5 hash of a passcode (your puzzle input) followed by a 
-- sequence of uppercase characters representing the path you have taken so far 
-- (U for up, D for down, L for left, and R for right).

-- Only the first four characters of the hash are used; they represent, respectively, 
-- the doors up, down, left, and right from your current position. 
-- Any b, c, d, e, or f means that the corresponding door is open; any 
-- other character (any number or a) means that the corresponding door is closed and locked.

-- To access the vault, all you need to do is reach the bottom-right room; reaching 
-- this room opens the vault and all doors in the maze.

-- For example, suppose the passcode is hijkl. Initially, you 
-- have taken no steps, and so your path is empty: you simply find the MD5 hash of hijkl alone. 
-- The first four characters of this hash are ced9, which indicate that up is open (c),
-- down is open (e), left is open (d), and right is closed and locked (9).
-- Because you start in the top-left corner, there are no "up" or "left" doors to be open, 
-- so your only choice is down.

-- Next, having gone only one step (down, or D), you find the hash of hijklD. 
-- This produces f2bc, which indicates that you can go back up, left (but that's a wall), 
-- or right. Going right means hashing hijklDR to get 5745 - all doors closed and locked. 
-- However, going up instead is worthwhile: even though it returns you to the room you started in, 
-- your path would then be DU, opening a different set of doors.

-- After going DU (and then hashing hijklDU to get 528e), only the right door is open; 
-- after going DUR, all doors lock. (Fortunately, your actual passcode is not hijkl).

-- Passcodes actually used by Easter Bunny Vault Security do allow access to the vault if 
-- you know the right path. For example:

-- If your passcode were ihgpwlah, the shortest path would be DDRRRD.
-- With kglvqrro, the shortest path would be DDUDRLRRUDRD.

-- With ulqzkmiv, the shortest would be DRURDRUDDLLDLUURRDULRLDUUDDDRR.


-- Given your vault's passcode, what is the shortest path (the actual path, not just the length) 
-- to reach the vault?

-- Your puzzle input is njfxhljp.

{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS -Wall -fwarn-tabs -fno-warn-type-defaults -fno-warn-unused-do-bind #-}

import Data.Digest.Pure.MD5
import Data.ByteString.Lazy.Char8 hiding (map, length, take, drop, elem, foldr, zipWith, filter, repeat, concat)

type Room = (Int, Int) 
type Pos = (String, Room)

-- +/- on a bounded grid
infixl 5 @+
(@+) :: Int -> Int -> Int
(@+) = gridPlus 3

infixl 5 @-
(@-) :: Int -> Int -> Int
(@-) = gridMinus 

gridPlus :: Int -> Int -> Int -> Int
gridPlus b x y 
    | x + y <= b = x + y
    | otherwise = x

gridMinus :: Int -> Int -> Int
gridMinus x y 
    | x - y >= 0 = x - y 
    | otherwise = 0
-- -------------------------------------


md5Hash :: String -> String
md5Hash  = show . md5 . pack  


posEq :: Pos -> Pos -> Bool
posEq (_, (x1, y1)) (_, (x2, y2)) = x1 == x2 && y1 == y2

move :: Char -> Room -> Room
move 'U' (x, y) = (x, y @- 1)
move 'D' (x, y) = (x, y @+ 1)
move 'L' (x, y) = (x @- 1, y)
move 'R' (x, y) = (x @+ 1, y)
move _   (x, y) = (x, y)

openDoorsInRoom :: (String, Room) -> [(String, Room)]
openDoorsInRoom (str, rm)  = 
    map (\(_, str', rm') -> (str', rm'))
    . validMoveFilter 
    . zipWith (\a b -> (b, str ++ [a] , move a rm) ) ['U', 'D', 'L', 'R'] 
    . foldr checkDoors [] 
    . take 4 
    . md5Hash $ str where
    --  doors - 1 open, 0 closed
    checkDoors = \x ac -> if (x `elem` ['b', 'c', 'd', 'e', 'f']) then 1:ac else 0:ac 
    -- only want open (1) and also be able to move into it - i.e. not edge
    validMoveFilter = filter   (\(x, _, rm') -> x == 1 && rm' /= rm )

keepOpening :: Pos -> [(String, Room)] -> [Pos]
keepOpening target rooms 
    | foundTarget target rooms = rooms
    | otherwise = keepOpening target $ concat . map openDoorsInRoom $ rooms
    where 
        foundTarget _ [] = False
        foundTarget t (x:xs)
            | posEq t x = True
            | otherwise = foundTarget t xs


posEqTarget :: Pos -> Bool
posEqTarget = posEq ("", (3,3))

main :: IO ()
main = do
    print $ filter  posEqTarget .   keepOpening ("", (3,3)) .  openDoorsInRoom $ ("kglvqrro", (0,0))
   
