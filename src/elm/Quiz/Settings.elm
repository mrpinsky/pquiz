module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css exposing (Color)
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Util exposing ((=>))


type alias Settings =
    { kinds : KindSettings
    , tally : Bool
    , groupWidth : Int
    }


type alias KindSettings =
    Dict String Kind


type alias Kind =
    { symbol : String
    , color : Color
    , weight : Int
    }


encode : Settings -> Encode.Value
encode settings =
    Encode.object
        [ "kinds" => encodeKinds settings.kinds
        , "tally" => Encode.bool settings.tally
        , "groupWidth" => Encode.int settings.groupWidth
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
        (Decode.field "groupWidth" Decode.int)


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
