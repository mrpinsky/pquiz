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


main : Program Never Group Msg
main =
    Html.beginnerProgram
        { model = init "Test Group" []
        , view = view Settings.default
        , update = update
        }



-- MODEL


type alias Group =
    { current : Maybe Observation
    , label : String
    , records : KeyedList Record
    , defaults : Dict String Int
    }


init : String -> List String -> Group
init label defaultKeys =
    defaultKeys
        |> List.map initDefaultRecord
        |> Dict.fromList
        |> Group Nothing label KeyedList.empty


initDefaultRecord : String -> ( String, Int )
initDefaultRecord key =
    ( key, 0 )



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
    | UpdateCurrent Observation.Msg
    | Commit
    | IncrementDefault String
    | UpdateRecord Key Record.Msg
    | Delete Key
    | Relabel String


update : Msg -> Group -> Group
update msg group =
    case msg of
        StartNew topicId ->
            { group | current = Just <| Observation.init topicId }

        UpdateCurrent subMsg ->
            { group
                | current =
                    Maybe.map (Observation.update subMsg) group.current
            }

        Commit ->
            { group
                | current = Nothing
                , records = commit group.current group.records
            }

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


commit : Maybe Observation -> KeyedList Record -> KeyedList Record
commit current existing =
    case current of
        Nothing ->
            existing

        Just observation ->
            KeyedList.push (Record.init observation 1) existing



-- VIEW


view : Settings -> Group -> Html Msg
view { theme, observations, groupWidth, showTally } group =
    div
        [ class "group"
        , styles [ Css.width groupWidth ]
        ]
        [ lazy viewLabel group.label
        , lazy3 viewTally theme showTally group.records
        , lazy2 viewInput theme group.current
        , lazy3 viewDefaults theme observations group.defaults
        , lazy2 viewRecords theme group.records
        ]


viewLabel : String -> Html Msg
viewLabel label =
    div
        [ class "title"
        , contenteditable True
        , onChange Relabel
        ]
        [ text label ]


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


viewInput : Theme -> Maybe Observation -> Html Msg
viewInput theme current =
    case current of
        Nothing ->
            Theme.viewAsButtons StartNew theme

        Just observation ->
            Observation.viewCreating UpdateCurrent Commit observation
              


viewDefaults : Theme -> List (String, Observation) -> Dict String Int -> Html Msg
viewDefaults theme defaults tallies =
    List.map (viewDefaultObservation theme tallies) defaults
        |> ul []


viewDefaultObservation : Theme -> Dict String Int -> (String, Observation) -> Html Msg
viewDefaultObservation theme tallies (id, observation) =
    let
        tally =
            Dict.get id tallies
                |> Maybe.withDefault 0

        style =
            Theme.lookup observation.style theme
    in
        li [ styles [ Css.backgroundColor style.color ] ]
            [ button [ onClick (IncrementDefault id) ]
                [ Html.text style.symbol
                , Html.text <| toString tally
                ]
            , Html.text observation.label
            ]


viewRecords : Theme -> KeyedList Record -> Html Msg
viewRecords theme records =
    viewLocals theme records
        |> ul []


viewLocals : Theme -> KeyedList Record -> List (Html Msg)
viewLocals theme records =
    KeyedList.keyedMap (viewKeyedRecord theme) records


viewKeyedRecord : Theme -> Key -> Record -> Html Msg
viewKeyedRecord theme key record =
    Record.view theme record
        |> Html.map (UpdateRecord key)
        |> viewWithRemoveButton (Delete key)
