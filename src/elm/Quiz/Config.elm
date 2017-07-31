module Quiz.Config exposing (..)

-- import AllDict exposing (AllDict)

import Css
import Dict exposing (Dict)


type alias Config =
    { kinds : Dict String KindSettings
    , tally : Bool
    }



-- type Kind
--     = Kind String


type alias KindSettings =
    { symbol : Char
    , color : Css.Color
    , weight : Int
    }
