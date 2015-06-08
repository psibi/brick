module Brick.Edit
  ( Editor
  , editor
  , drawEditor
  )
where

import Data.Monoid ((<>))
import Graphics.Vty (Event(..), Key(..), Modifier(..))

import Brick.Core (Name, Location(..), HandleEvent(..))
import Brick.Render
import Brick.Util (clamp)

data Editor =
    Editor { editStr :: !String
           , editCursorPos :: !Int
           , editorName :: Name
           }

instance HandleEvent Editor where
    handleEvent e =
        case e of
            EvKey (KChar 'a') [MCtrl] -> gotoBOL
            EvKey (KChar 'e') [MCtrl] -> gotoEOL
            EvKey (KChar 'd') [MCtrl] -> deleteChar
            EvKey (KChar c) [] | c /= '\t' -> insertChar c
            EvKey KDel [] -> deleteChar
            EvKey KLeft [] -> moveLeft
            EvKey KRight [] -> moveRight
            EvKey KBS [] -> deletePreviousChar
            _ -> id

editSetCursorPos :: Int -> Editor -> Editor
editSetCursorPos pos e =
    let newCP = clamp 0 (length $ editStr e) pos
    in e { editCursorPos = newCP
         }

moveLeft :: Editor -> Editor
moveLeft e = editSetCursorPos (editCursorPos e - 1) e

moveRight :: Editor -> Editor
moveRight e = editSetCursorPos (editCursorPos e + 1) e

deletePreviousChar :: Editor -> Editor
deletePreviousChar e
  | editCursorPos e == 0 = e
  | otherwise = deleteChar $ moveLeft e

gotoBOL :: Editor -> Editor
gotoBOL = editSetCursorPos 0

gotoEOL :: Editor -> Editor
gotoEOL e = editSetCursorPos (length $ editStr e) e

deleteChar :: Editor -> Editor
deleteChar e = e { editStr = s'
                 }
    where
        n = editCursorPos e
        s = editStr e
        s' = take n s <> drop (n+1) s

insertChar :: Char -> Editor -> Editor
insertChar c theEdit =
    theEdit { editStr = s
            , editCursorPos = newCursorPos
            }
    where
        s = take n oldStr ++ [c] ++ drop n oldStr
        n = editCursorPos theEdit
        newCursorPos = n + 1
        oldStr = editStr theEdit

editor :: Name -> String -> Editor
editor name s = Editor s (length s) name

drawEditor :: Editor -> Render
drawEditor e =
    let cursorLoc = Location (cp, 0)
        cp = editCursorPos e
        s = editStr e
        beforeCursor = take cp s
        onCursor' = take 1 $ drop cp s
        onCursor = if null onCursor' then " " else onCursor'
        afterCursor = drop (cp + 1) s
    in viewport (editorName e) Horizontal $
       showCursor (editorName e) cursorLoc $
       (txt beforeCursor)
       <+> (visible $ txt onCursor)
       <+> (txt afterCursor)
