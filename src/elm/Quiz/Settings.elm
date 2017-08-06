module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Util exposing ((=>))


type alias Settings =
    { kinds : KindSettings
    , tally : Bool
    }


type alias KindSettings =
    Dict String Kind


type alias Kind =
    { symbol : Char
    , color : Css.Color
    , weight : Int
    }


encode : Settings -> Encode.Value
encode config =
    Encode.object
        [ "kinds" => encodeKinds config.kinds
        , "tally" => Encode.bool config.tally
        ]


encodeKinds : KindSettings -> Encode.Value
encodeKinds kinds =
    Encode.null


encodeKind : Kind -> Encode.Value
encodeKind kind =
    Encode.object
        [ "symbol" => (Encode.string <| toString kind.symbol)
        , "color" => Encode.null
        , "weight" => Encode.int kind.weight
        ]



{--
decoder : Decode.Decoder Settings
decoder =
    Decode.map2
        Settings
        (Decode.field "kinds" kindsDecoder)
        (Decode.field "tally" Decode.bool)


kindsDecoder : Decode.Decoder (Dict String KindSettings)
kindsDecoder =
    Decode.always Dict.empty
--}
