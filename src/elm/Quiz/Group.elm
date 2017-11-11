module Quiz.Group exposing (Group, Msg, init, reset, update, view)

import Css
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Lazy exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Record as Record exposing (Record)
import Quiz.Observation.Style exposing (Style)
import Quiz.Settings as Settings exposing (..)
import Quiz.Theme as Theme exposing (Theme)
import Util exposing (..)


-- MODEL


type alias Group =
    { id : Int
    , current : Maybe Theme.Id
    , label : String
    , records : KeyedList Record
    , defaults : Dict String Int
    }


init : Int -> String -> Group
init id label =
    Group id Nothing label KeyedList.empty Dict.empty


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
        [ class "group"
        , id <| "group-" ++ toString group.id
        ]
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
    div [ class "title" ]
        [ input
            [ onInput (onUpdate << Relabel)
            , value label
            ]
            []
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
        contents =
            case current of
                Nothing ->
                    Theme.viewAsButtons StartNew current theme

                Just id ->
                    viewInput theme id
    in
        div [ class "drawer"
            , classList [ ("open", current /= Nothing) ]
            ] 
            [ contents ]


viewInput : Theme -> Theme.Id -> Html Msg
viewInput theme id =
    let
        { symbol, color } =
            Theme.lookup id theme
    in
        div [ class "input-container"
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

        tallyBgColor =
            if tally == 0 then
                Css.hex "eeeeee"
            else
                color
    in
        li
            [ styles [ Css.backgroundColor <| fade color tally ]
            , class "observation default"
            ]
            [ div
                [ class "buttons start"
                , styles [ Css.backgroundColor tallyBgColor ]
                ]
                [ button
                    [ onClick (IncrementDefault id)
                    , class "tally"
                    ]
                    [ Html.text <| toString tally ++ symbol ]
                ]
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
