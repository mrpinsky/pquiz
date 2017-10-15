module Quiz.Observation.Options
    exposing
        ( Options
        , Option
        , Id
        , Msg
        , update
        , view
        , init
        , toList
        , idList
        , lookup
        , first
        , encode
        , decoder
        )

import Css exposing (Color)
import Css.Colors as Colors
import Html exposing (..)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Nonempty as NE exposing (Nonempty, (:::))
import Quiz.Observation.Style as Style exposing (Style)
import Tagged exposing (Tagged)
import Util exposing ((=>), encodeColor, colorDecoder, viewWithRemoveButton)


-- MODEL


type Options
    = Options Int (Nonempty Option)


type alias Option =
    { id : String
    , symbol : String
    , label : String
    , color : Css.Color
    , weight : Int
    }


type alias Id =
    String


init : Options
init =
    defaultOption
        |> NE.fromElement
        |> Options 1


initOption : String -> Option
initOption id =
    { id = id
    , symbol = ""
    , label = ""
    , color = Colors.green
    , weight = 1
    }


defaultOption : Option
defaultOption =
    { id = "default"
    , symbol = "+"
    , label = "+"
    , color = Colors.green
    , weight = 1
    }


first : Options -> Option
first (Options _ options) =
    NE.head options


toList : Options -> List Option
toList (Options _ options) =
    NE.toList options


idList : Options -> List Id
idList (Options _ options) =
    NE.map .id options
        |> NE.toList


lookup : Id -> Options -> Maybe Option
lookup target (Options _ options) =
    let
        lookupHelper { id } =
            id == target
    in
        NE.toList options
            |> List.filter lookupHelper
            |> List.head



-- UPDATE


type Msg
    = Add
    | Remove Id
    | UpdateStyle Id Style.Msg


update : Msg -> Options -> Options
update msg (Options nextId options) =
    case msg of
        Add ->
            toString nextId
                |> initOption
                |> NE.fromElement
                |> NE.append options
                |> Options (nextId + 1)

        Remove id ->
            let
                removeHelper option =
                    option.id /= id
            in
                options
                    |> NE.filter removeHelper (NE.head options)
                    |> Options nextId

        UpdateStyle target styleMsg ->
            let
                updateHelper option =
                    if option.id == target then
                        Style.update styleMsg option
                    else
                        option
            in
                Options nextId <| NE.map updateHelper options



-- VIEW


view : Options -> Html Msg
view (Options _ options) =
    div []
        [ options
            |> NE.toList
            |> List.map viewOption
            |> div []
        , button [ onClick Add ] [ text "+" ]
        ]


viewOption : Option -> Html Msg
viewOption option =
    Style.view option
        |> Html.map (UpdateStyle option.id)
        |> viewWithRemoveButton (Remove option.id)



-- JSON


encode : Options -> Encode.Value
encode (Options _ options) =
    options
        |> NE.map encodeOption
        |> NE.toList
        |> Encode.list


encodeOption : Option -> Encode.Value
encodeOption option =
    Encode.object
        [ "id" => Encode.string option.id
        , "symbol" => Encode.string option.symbol
        , "label" => Encode.string option.label
        , "color" => encodeColor option.color
        , "weight" => Encode.int option.weight
        ]


decoder : Decode.Decoder Options
decoder =
    Decode.list optionDecoder
        |> Decode.map NE.fromList
        |> Decode.map
            (Maybe.withDefault <|
                NE.fromElement (initOption "default")
            )
        |> Decode.andThen extractNextId


extractNextId : Nonempty Option -> Decode.Decoder Options
extractNextId options =
    let
        nextId =
            NE.get -1 options
                |> .id
                |> String.toInt
                |> Result.toMaybe
                |> Maybe.withDefault (NE.length options)
    in
        Decode.succeed <| Options nextId options


optionDecoder : Decode.Decoder Option
optionDecoder =
    Decode.map5
        Option
        (Decode.field "id" Decode.string)
        (Decode.field "symbol" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "color" colorDecoder)
        (Decode.field "weight" Decode.int)
