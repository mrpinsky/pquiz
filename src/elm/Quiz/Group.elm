module Quiz.Group
    exposing
        ( Group
        , Msg
        , init
        , reset
        , update
        , view
        , viewStatic
        , encode
        , decoder
        )

import Css
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Lazy exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Record as Record exposing (Record)
import Quiz.Settings as Settings exposing (..)
import Quiz.Theme as Theme exposing (Theme)
import Util exposing (..)
import Util.Handlers as Handlers exposing (Handlers)


-- MODEL


type alias Group =
    { current : Maybe Theme.Id
    , id : Int
    , label : String
    , records : KeyedList Record
    , defaults : Dict String Int
    }


init : Int -> String -> Group
init id label =
    Group Nothing id label KeyedList.empty Dict.empty


defaultAsRecord : Dict String Int -> ( String, Observation ) -> Record
defaultAsRecord tallies ( uid, observation ) =
    Dict.get uid tallies
        |> Maybe.withDefault 0
        |> (flip Record.init) observation


reset : Group -> Group
reset group =
    { group
        | current = Nothing
        , records = KeyedList.empty
        , defaults = Dict.empty
    }



-- UPDATE


type Msg
    = StartNew Theme.Id
    | CommitCurrent Theme.Id String
    | CancelCurrent
    | IncrementDefault String
    | UpdateRecord Key Record.Msg
    | Delete Key
    | Relabel String
    | NoOp


update : Msg -> Group -> Group
update msg group =
    case msg of
        StartNew topicId ->
            { group | current = Just topicId }

        CommitCurrent style label ->
            { group
                | current = Nothing
                , records = commit group.records style label
            }

        CancelCurrent ->
            { group | current = Nothing }

        IncrementDefault defaultId ->
            { group | defaults = Dict.update defaultId incrementDefault group.defaults }

        UpdateRecord key submsg ->
            { group
                | records =
                    KeyedList.update key
                        (Record.update submsg)
                        group.records
            }

        Delete key ->
            { group | records = KeyedList.remove key group.records }

        Relabel newLabel ->
            { group | label = newLabel }

        NoOp ->
            group


incrementDefault : Maybe Int -> Maybe Int
incrementDefault tally =
    tally
        |> Maybe.withDefault 0
        |> (+) 1
        |> Just


commit : KeyedList Record -> Theme.Id -> String -> KeyedList Record
commit existing style label =
    if String.isEmpty label then
        existing
    else
        let
            new =
                Record.init 1 <| Observation.init style label
        in
            KeyedList.cons new existing



-- VIEW


view : Handlers Msg msg { highlightMsg : msg } -> Settings -> Group -> Html msg
view handlers { theme, observations, showTally } { id, label, defaults, records, current } =
    div
        [ class "group"
        , Attributes.id <| "group-" ++ toString id
        ]
        [ viewBanner
            [ button
                [ class "magnify unobtrusive left banner-btn"
                , class "fas fa-star"
                , onClick handlers.highlightMsg
                ]
                []
            , lazy viewLabel label
                |> Html.map handlers.onUpdate
            , button
                [ class "unobtrusive right banner-btn"
                , class "fas fa-trash"
                , onClick handlers.remove
                ]
                []
            ]
        , Html.map handlers.onUpdate <|
            div [ class "body" ]
                [ lazy3 viewDefaults theme observations defaults
                , lazy2 viewRecords theme records
                ]
        , lazy3 viewDrawer handlers theme current
        ]


viewBanner : List (Html msg) -> Html msg
viewBanner contents =
    div [ class "banner-container" ]
        [ div
            [ class "banner" ]
            contents
        ]


viewStatic : Settings -> Group -> Html Msg
viewStatic { theme, observations, showTally } { label, defaults, records } =
    let
        defaultRecords =
            List.map (defaultAsRecord defaults) observations

        localRecords =
            KeyedList.toList records

        allRecords =
            defaultRecords ++ localRecords
    in
        div
            [ class "group" ]
            [ viewBanner [ lazy viewLabel label ]
            , div [ class "body" ] [ viewAllRecords theme allRecords ]
            ]


viewLabel : String -> Html Msg
viewLabel label =
    input
        [ onInput Relabel
        , class "title"
        , value label
        ]
        []


viewDrawer : Handlers Msg msg r -> Theme -> Maybe Theme.Id -> Html msg
viewDrawer { onUpdate } theme current =
    let
        contents =
            case current of
                Nothing ->
                    Theme.viewAsButtons StartNew current theme

                Just id ->
                    viewInput theme id
    in
        div
            [ class "drawer"
            , classList [ ( "open", current /= Nothing ) ]
            ]
            [ Html.map onUpdate contents ]


viewInput : Theme -> Theme.Id -> Html Msg
viewInput theme id =
    let
        { symbol, color } =
            Theme.lookup id theme
    in
        div
            [ class "input-container"
            , styles [ Css.backgroundColor <| faded color ]
            ]
            [ div
                [ class "symbol"
                , styles [ Css.backgroundColor color ]
                ]
                [ text symbol ]
            , textarea
                [ onEnter <| CommitCurrent id
                , class "observation creating"
                , value ""
                ]
                []
            , button
                [ class "cancel"
                , onClick CancelCurrent
                ]
                [ text "x" ]
            ]


viewDefaults : Theme -> List ( String, Observation ) -> Dict String Int -> Html Msg
viewDefaults theme defaults tallies =
    List.map (viewDefaultObservation tallies theme) defaults
        |> ul [ class "observations default" ]


viewDefaultObservation : Dict String Int -> Theme -> ( String, Observation ) -> Html Msg
viewDefaultObservation tallies theme ( id, observation ) =
    defaultAsRecord tallies ( id, observation )
        |> Record.viewOnlyIncrementable { onUpdate = (\_ -> IncrementDefault id), remove = NoOp } theme


viewRecords : Theme -> KeyedList Record -> Html Msg
viewRecords theme records =
    viewLocals theme records
        |> ul [ class "observations local" ]


viewAllRecords : Theme -> List Record -> Html Msg
viewAllRecords theme records =
    List.map (Record.viewStatic theme) records
        |> ul [ class "observations" ]


viewLocals : Theme -> KeyedList Record -> List (Html Msg)
viewLocals theme records =
    KeyedList.keyedMap (viewKeyedRecord theme) records


viewKeyedRecord : Theme -> Key -> Record -> Html Msg
viewKeyedRecord theme key record =
    Record.view
        { onUpdate = UpdateRecord key
        , remove = Delete key
        }
        theme
        record



-- JSON


encode : Group -> Encode.Value
encode { id, label, records, defaults } =
    Encode.object
        [ "id" => Encode.int id
        , "label" => Encode.string label
        , "records" => encodeRecords records
        , "defaults" => encodeDefaults defaults
        ]


encodeRecords : KeyedList Record -> Encode.Value
encodeRecords records =
    records
        |> KeyedList.toList
        |> List.map Record.encode
        |> Encode.list


encodeDefaults : Dict String Int -> Encode.Value
encodeDefaults defaults =
    defaults
        |> Dict.toList
        |> List.map (Tuple.mapSecond Encode.int)
        |> Encode.object


decoder : Decoder Group
decoder =
    Decode.map4 (Group Nothing)
        (Decode.field "id" Decode.int)
        (Decode.field "label" Decode.string)
        (Decode.field "records" recordsDecoder)
        (Decode.field "defaults" defaultsDecoder)


recordsDecoder : Decoder (KeyedList Record)
recordsDecoder =
    Decode.list Record.decoder
        |> Decode.map (KeyedList.fromList)


defaultsDecoder : Decoder (Dict String Int)
defaultsDecoder =
    Decode.dict Decode.int
