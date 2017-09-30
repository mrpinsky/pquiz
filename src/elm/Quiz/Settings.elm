module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css exposing (Color)
import Css.Colors
import Dict exposing (Dict)
import Html exposing (..)
import Html.Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Quiz.Kind as Kind exposing (Kind, Style)
import Tagged exposing (Tagged)
import Util exposing ((=>), delta)


type alias Settings =
    { kinds : Kinds
    , tally : Bool
    , groupWidth : Css.Px
    }


type alias Kinds =
    List Kind


listKinds : Settings -> List Kind.Id
listKinds { kinds } =
    List.map .tag kinds


lookupKind : Kind.Id -> Kinds -> Maybe Kind
lookupKind target kinds =
    kinds
        |> List.filter (Tagged.match target)
        |> List.head


default : Settings
default =
    { kinds = []
    , tally = False
    , groupWidth = Css.px 200
    }


type Msg
    = KindMsg Kind.Msg


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        KindMsg kindMsg ->
            { settings | kinds = List.map (Kind.update kindMsg) settings.kinds }


view : Settings -> Html Msg
view settings =
    div [] <| List.map viewHelper settings.kinds


viewHelper : Kind -> Html Msg
viewHelper kind =
    Html.map KindMsg <| Kind.view kind


-- JSON


encode : Settings -> Encode.Value
encode { kinds, tally, groupWidth } =
    Encode.object
        [ "kinds" => Encode.list (List.map Kind.encode kinds) 
        , "tally" => Encode.bool tally
        , "groupWidth" => Encode.float groupWidth.numericValue
        ]


decoder : Decode.Decoder Settings
decoder =
    Decode.map3
        Settings
        (Decode.field "kinds" (Decode.list Kind.decoder))
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)


-- UPDATE


setGroupWidth : Css.Px -> Settings -> Settings
setGroupWidth pixels settings =
    { settings | groupWidth = pixels }


toggleTally : Settings -> Settings
toggleTally settings =
    { settings | tally = not settings.tally }


insertKind : Kind.Id -> Kind -> Settings -> Settings
insertKind name kind settings =
    { settings | kinds = settings.kinds ++ List.singleton kind }


removeKind : Kind.Id -> Settings -> Settings
removeKind target settings =
    { settings | kinds = List.filter (not << Tagged.match target) settings.kinds }
