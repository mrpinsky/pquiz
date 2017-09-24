module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css exposing (Color)
import Css.Colors
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Quiz.Kind as Kind
    exposing
        ( Kind
        , update
        , view
        , defaultKinds
        , encodeKind
        , kindDecoder
        )
import Util exposing ((=>), delta)
import Html exposing (..)
import Html.Events exposing (..)


type alias Settings =
    { kinds : Kind.KindSettings
    , tally : Bool
    , groupWidth : Css.Px
    }


default : Settings
default =
    { kinds = defaultKinds
    , tally = False
    , groupWidth = Css.px 100
    }


type Msg
    = KindMsg String Kind.Msg


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        KindMsg label kindMsg ->
            let
                updateHelper =
                     Kind.update kindMsg
                        |> Maybe.map

                newKinds =
                     Dict.update label updateHelper settings.kinds 
            in
                { settings | kinds = newKinds }


view : Settings -> Html Msg
view settings =
    viewKinds settings.kinds
        |> div []


viewKinds : Kind.KindSettings -> List (Html Msg)
viewKinds kindSettings =
    Dict.toList kindSettings
        |> List.map viewKindHelper  


viewKindHelper : (String, Kind) -> Html Msg
viewKindHelper (label, kind) =
    Kind.view kind
        |> Html.map (KindMsg label)


-- JSON


encode : Settings -> Encode.Value
encode settings =
    Encode.object
        [ "kinds" => encodeKinds settings.kinds
        , "tally" => Encode.bool settings.tally
        , "groupWidth" => Encode.float settings.groupWidth.numericValue
        ]


encodeKinds : Kind.KindSettings -> Encode.Value
encodeKinds kinds =
    let
        encodeHelper ( key, kind ) =
            ( key, encodeKind kind )
    in
        Dict.toList kinds
            |> List.map encodeHelper
            |> Encode.object


decoder : Decode.Decoder Settings
decoder =
    Decode.map3
        Settings
        (Decode.field "kinds" kindsDecoder)
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)


kindsDecoder : Decode.Decoder Kind.KindSettings
kindsDecoder =
    Decode.dict kindDecoder



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


removeKind : String -> Settings -> Settings
removeKind name settings =
    { settings | kinds = Dict.remove name settings.kinds }
