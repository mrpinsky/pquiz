module Config.Quiz exposing (..)

import Dict exposing (Dict)
import Css


type alias Kind =
    { symbol : Char
    , color : Css.Color
    , label : Maybe String
    }


type alias Config =
    { kinds : Dict String Kind }
