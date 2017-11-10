module Quiz.Group exposing (Group, Msg, init, update, view)

import Css
import Css.Colors
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Record as Record exposing (Record)
import Quiz.Settings as Settings exposing (..)
import Quiz.Theme as Theme exposing (Theme)
import Util exposing (..)


-- MODEL


type alias Group =
    { current : Maybe Theme.Id
    , label : String
    , records : KeyedList Record
    , defaults : Dict String Int
    }


init : String -> Group
init label =
    Group Nothing label KeyedList.empty Dict.empty


-- encode : Group -> Encode.Value
-- encode { label, records, defaults } =
--     Encode.object
--         [ "label" => Encode.string label
--         , "records" => encodeRecords records
--         , "defaults" => encodeDefaults defaults
--         ]
-- encodeRecords : KeyedList Record -> Encode.Value
-- encodeRecords records =
--     KeyedList.toList records
--         |> List.map Record.encode
--         |> Encode.list
-- encodeDefaults : Dict String Int -> Encode.Value
-- encodeDefaults defaults =
--     defaults
--         |> Dict.toList
--         |> List.map (Tuple.mapSecond Encode.int)
--         |> Encode.object
-- decoder : Decode.Decoder Group
-- decoder =
--     Decode.map3
--         (Group Nothing)
--         (Decode.field "label" Decode.string)
--         (Decode.field "records" <| recordsDecoder)
--         (Decode.field "defaults" <| defaultsDecoder)
-- recordsDecoder : Decode.Decoder (KeyedList Record)
-- recordsDecoder =
--     Decode.map KeyedList.fromList <| Decode.list Record.decoder
-- defaultsDecoder : Decode.Decoder (Dict String Int)
-- defaultsDecoder =
--     Decode.dict Decode.int
-- UPDATE


type Msg
    = StartNew Theme.Id
    | CommitCurrent Theme.Id String
    | CancelCurrent
    | IncrementDefault String
    | UpdateRecord Key Record.Msg
    | Delete Key
    | Relabel String


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
                Record.init 1 <| Observation style label
        in
            KeyedList.cons new existing

-- VIEW


view : Handlers Msg msg r -> Settings -> Group -> Html msg
view handlers { theme, observations, showTally } group =
    div
        [ class "group" ]
        [ lazy2 viewLabel handlers group.label
        , Html.map handlers.onUpdate <| div [ class "body" ] 
            [ lazy3 viewTally theme showTally group.records
            , lazy3 viewDefaults theme observations group.defaults
            , lazy2 viewRecords theme group.records
            , lazy2 viewDrawer theme group.current
            ]
        ]


viewLabel : Handlers Msg msg r -> String -> Html msg
viewLabel { onUpdate, remove } label =
    div
        [ class "title"
        , contenteditable True
        , onChange (onUpdate << Relabel)
        ]
        [ text label
        , button [ class "remove", onClick remove ] [ text "x" ]
        ]


viewTally : Theme -> Bool -> KeyedList Record -> Html Msg
viewTally theme showTally records =
    let
        total =
            KeyedList.toList records
                |> List.map (Record.value theme)
                |> List.sum
    in
        total
            |> toString
            |> text
            |> List.singleton
            |> h2
                [ classList
                    [ ( "points", True )
                    , ( "hidden", not showTally )
                    , ( "total-" ++ (toString <| clamp 0 10 <| abs total), True )
                    , ( "pos", total > 0 )
                    ]
                ]


viewDrawer : Theme -> Maybe Theme.Id -> Html Msg
viewDrawer theme current =
    let
        bgColor =
            case current of
                Just id ->
                    Theme.lookup id theme
                        |> .color
                        |> faded 

                Nothing ->
                    Css.hex "dddddd"
    in
        div [ class "drawer"
            , classList [ ("entering", current /= Nothing) ]
            , styles [ Css.backgroundColor bgColor ]
            ] 
            [ Theme.viewAsButtons StartNew current theme
            , viewCurrent theme current
            , button
                [ class "cancel"
                , onClick CancelCurrent
                ]
                [ text "x" ]
            ]


viewCurrent : Theme -> Maybe Theme.Id -> Html Msg
viewCurrent theme current =
    input
        [ onEnter <| CommitCurrent (Maybe.withDefault "default" current)
        , class "observation creating"
        , value ""
        ]
        []


viewDefaults : Theme -> List (String, Observation) -> Dict String Int -> Html Msg
viewDefaults theme defaults tallies =
    List.map (viewDefaultObservation theme tallies) defaults
        |> ul [ class "observations default" ]


viewDefaultObservation : Theme -> Dict String Int -> (String, Observation) -> Html Msg
viewDefaultObservation theme tallies (id, observation) =
    let
        tally =
            Dict.get id tallies
                |> Maybe.withDefault 0

        { color, symbol, textColor } =
            Theme.lookup observation.style theme
    in
        li
            [ styles [ Css.backgroundColor <| fade color tally ]
            , class "observation default"
            ]
            [ button [ onClick (IncrementDefault id), class "tally"]
                [ Html.text <| symbol ++ toString tally ]
            , span
                [ class "label"
                -- , styles [ Css.color textColor ]
                ]
                [ Html.text observation.label ]
            ]


viewRecords : Theme -> KeyedList Record -> Html Msg
viewRecords theme records =
    viewLocals theme records
        |> ul [ class "observations local" ]


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
