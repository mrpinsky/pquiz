module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css exposing (Color)
import Css.Colors
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Util exposing ((=>), delta)


type alias Settings =
    { kinds : KindSettings
    , tally : Bool
    , groupWidth : Css.Px
    }


type alias KindSettings =
    Dict String Kind


type alias Kind =
    { symbol : String
    , color : Color
    , weight : Int
    }


default : Settings
default =
    { kinds = defaultKinds
    , tally = False
    , groupWidth = Css.px 100
    }


defaultKinds : KindSettings
defaultKinds =
    let
        green =
            { symbol = "+"
            , color = Css.Colors.green
            , weight = 1
            }

        white =
            { symbol = "*"
            , color = (Css.hex "ffffff")
            , weight = 0
            }

        red =
            { symbol = delta
            , color = Css.Colors.red
            , weight = -1
            }
    in
        Dict.fromList
            [ "green" => green
            , "white" => white
            , "red" => red
            ]



-- JSON


encode : Settings -> Encode.Value
encode settings =
    Encode.object
        [ "kinds" => encodeKinds settings.kinds
        , "tally" => Encode.bool settings.tally
        , "groupWidth" => Encode.float settings.groupWidth.numericValue
        ]


encodeKinds : KindSettings -> Encode.Value
encodeKinds kinds =
    let
        encodeHelper ( key, kind ) =
            ( key, encodeKind kind )
    in
        Dict.toList kinds
            |> List.map encodeHelper
            |> Encode.object


encodeKind : Kind -> Encode.Value
encodeKind kind =
    Encode.object
        [ "symbol" => Encode.string kind.symbol
        , "color" => encodeColor kind.color
        , "weight" => Encode.int kind.weight
        ]


encodeColor : Color -> Encode.Value
encodeColor color =
    Encode.object
        [ "red" => Encode.int color.red
        , "green" => Encode.int color.green
        , "blue" => Encode.int color.blue
        , "alpha" => Encode.float color.alpha
        ]


decoder : Decode.Decoder Settings
decoder =
    Decode.map3
        Settings
        (Decode.field "kinds" kindsDecoder)
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)


kindsDecoder : Decode.Decoder KindSettings
kindsDecoder =
    Decode.dict kindDecoder


kindDecoder : Decode.Decoder Kind
kindDecoder =
    Decode.map3
        Kind
        (Decode.field "symbol" Decode.string)
        (Decode.field "color" colorDecoder)
        (Decode.field "weight" Decode.int)


colorDecoder : Decode.Decoder Color
colorDecoder =
    Decode.map4
        Css.rgba
        (Decode.field "red" Decode.int)
        (Decode.field "green" Decode.int)
        (Decode.field "blue" Decode.int)
        (Decode.field "alpha" Decode.float)



{-
   type alias Settings =
       { kinds : KindSettings
       , tally : Bool
       , groupWidth : Css.Em
       }
-}
-- UPDATE


setGroupWidth : Css.Px -> Settings -> Settings
setGroupWidth pixels settings =
    { settings | groupWidth = pixels }


toggleTally : Settings -> Settings
toggleTally settings =
    { settings | tally = not settings.tally }


insertKind : String -> Kind -> Settings -> Settings
insertKind name kind settings =
    let
        newKinds =
            Dict.insert name kind settings.kinds
    in
        { settings | kinds = newKinds }


updateKind : String -> (Maybe Kind -> Maybe Kind) -> Settings -> Settings
updateKind name updater settings =
    -- TODO: Implement this
    settings


removeKind : String -> Settings -> Settings
removeKind name settings =
    { settings | kinds = Dict.remove name settings.kinds }
