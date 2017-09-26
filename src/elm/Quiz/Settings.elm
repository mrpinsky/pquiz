module Quiz.Settings exposing (..)

-- import AllDict exposing (AllDict)

import Css exposing (Color)
import Css.Colors
import Dict exposing (Dict)
import Json.Decode as Decode
import Json.Encode as Encode
import Quiz.Kind as Kind exposing (Kind)
import Util exposing ((=>), delta)
import Html exposing (..)
import Html.Events exposing (..)


type alias Settings =
    { kinds : Kinds
    , tally : Bool
    , groupWidth : Css.Px
    }


type alias Kinds
    = List (KindId, Kind)


type alias KindId = String


getKind : KindId -> Kinds -> Maybe Kind
getKind target kinds =
    kinds
        |> List.filter (\(id, _) -> id == target) 
        |> List.head
        |> Maybe.map Tuple.second


default : Settings
default =
    { kinds = []
    , tally = False
    , groupWidth = Css.px 200
    }


type Msg
    = KindMsg KindId Kind.Msg


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        KindMsg target kindMsg ->
            let
                updateHelper (id, kind) =
                    if id == target then (id, Kind.update kindMsg kind) else
                        (id, kind)
            in
                { settings | kinds = List.map updateHelper settings.kinds }


view : Settings -> Html Msg
view settings =
    div [] <| viewKinds settings.kinds


viewKinds : Kinds -> List (Html Msg)
viewKinds kinds =
    List.map viewKindHelper kinds


viewKindHelper : (KindId, Kind) -> Html Msg
viewKindHelper (id, kind) =
    Kind.view kind
        |> Html.map (KindMsg id)


-- JSON


encode : Settings -> Encode.Value
encode settings =
    Encode.object
        [ "kinds" => encodeKinds settings.kinds
        , "tally" => Encode.bool settings.tally
        , "groupWidth" => Encode.float settings.groupWidth.numericValue
        ]


encodeKinds : Kinds -> Encode.Value
encodeKinds kinds =
    let
        encodeHelper ( id, kind ) =
            ( id, Kind.encode kind )
    in
        kinds
            |> List.map encodeHelper
            |> Encode.object


decoder : Decode.Decoder Settings
decoder =
    Decode.map3
        Settings
        (Decode.field "kinds" kindsDecoder)
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)


kindsDecoder : Decode.Decoder Kinds
kindsDecoder =
    Decode.keyValuePairs Kind.decoder



-- UPDATE


setGroupWidth : Css.Px -> Settings -> Settings
setGroupWidth pixels settings =
    { settings | groupWidth = pixels }


toggleTally : Settings -> Settings
toggleTally settings =
    { settings | tally = not settings.tally }


insertKind : KindId -> Kind -> Settings -> Settings
insertKind name kind settings =
    { settings | kinds = settings.kinds ++ List.singleton (name, kind) }


removeKind : KindId -> Settings -> Settings
removeKind target settings =
    let
        removeHelper (id, _) =
            id == target
    in
        { settings | kinds = List.filter removeHelper settings.kinds }
