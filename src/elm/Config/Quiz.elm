module Config.Quiz exposing (..)

import Array exposing (Array)
import Css


type alias Kind =
    { symbol : Char
    , color : Css.Color
    , label : Maybe String
    }


type alias Config =
    { kinds : Array Kind }
