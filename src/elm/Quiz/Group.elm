module Quiz.Group exposing (Group, Msg, init, update, encode, decoder)

import Css
import Css.Colors
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Util exposing (..)
import Quiz.Config as Config exposing (..)


-- APP TESTING


main : Program Never Group Msg
main =
    Html.beginnerProgram
        { model = init "Test Group" []
        , update = update
        , view = view 1 testConfig
        }


testConfig : Config
testConfig =
    let
        kinds =
            Dict.fromList
                [ "+" => { symbol = '+', color = Css.Colors.green, weight = 1 }
                , "-" => { symbol = '-', color = Css.Colors.red, weight = -1 }
                ]
    in
        { kinds = kinds
        , tally = True
        }



-- MODEL


type Group
    = Group String (KeyedList Observation) State


type State
    = Waiting
    | Entering String String


init : String -> List Observation -> Group
init label observations =
    Group label (KeyedList.fromList observations) Waiting


encode : Group -> Encode.Value
encode (Group label observations state) =
    Encode.object
        [ "label" => Encode.string label
        , "observations"
            => (KeyedList.toList observations
                    |> List.map Observation.encode
                    |> Encode.list
               )
        ]


decoder : Decode.Decoder Group
decoder =
    Decode.map2
        init
        (Decode.field "label" Decode.string)
        (Decode.field "observations" <| Decode.list Observation.decoder)



-- UPDATE


type Msg
    = StartNew String
    | UpdateCurrent String
    | SaveCurrent
    | UpdateExisting Key Observation.Msg
    | Delete Key
    | Relabel String


update : Msg -> Group -> Group
update msg (Group label observations state) =
    case msg of
        StartNew kind ->
            Group label observations (Entering kind "")

        UpdateCurrent newDescription ->
            case state of
                Waiting ->
                    Group label observations Waiting

                Entering kind description ->
                    Group label observations (Entering kind newDescription)

        SaveCurrent ->
            case state of
                Waiting ->
                    Group label observations Waiting

                Entering kind description ->
                    let
                        newObservations =
                            KeyedList.cons (Observation.init kind description 1) observations
                    in
                        Group label newObservations Waiting

        UpdateExisting key submsg ->
            let
                newObservations =
                    KeyedList.update key (Observation.update submsg) observations
            in
                Group label newObservations state

        Delete key ->
            let
                newObservations =
                    KeyedList.remove key observations
            in
                Group label newObservations state

        Relabel newLabel ->
            Group newLabel observations state



-- VIEW


view : Int -> Config -> Group -> Html Msg
view id config (Group label observations state) =
    div [ class "group" ]
        [ lazy viewLabel label
        , lazy2 viewTally config observations
        , lazy3 viewInput id config state
        , lazy2 viewObservations config observations
        ]


viewLabel : String -> Html Msg
viewLabel label =
    div
        [ class "title"
        , contenteditable True
        , onContentEdit Relabel
        ]
        [ text label ]


viewTally : Config.Config -> KeyedList Observation -> Html Msg
viewTally config observations =
    let
        total =
            KeyedList.toList observations
                |> List.map (Observation.value config.kinds)
                |> List.sum
    in
        total
            |> toString
            |> text
            |> List.singleton
            |> h2
                [ classList
                    [ ( "points", True )
                    , ( "hidden", not config.tally )

                    --     , ( "total-" ++ (toString <| clamp 0 10 <| abs total), True )
                    --     , ( "pos", total > 0 )
                    ]
                ]


viewButton : ( String, KindSettings ) -> Html Msg
viewButton ( label, settings ) =
    button
        [ onClick <| StartNew label
        , class "input-button"
        , styles [ Css.backgroundColor settings.color ]
        ]
        [ text label ]


viewButtons : Config -> List (Html Msg)
viewButtons config =
    Dict.toList config.kinds
        |> List.map viewButton


viewInput : Int -> Config -> State -> Html Msg
viewInput id config state =
    case state of
        Waiting ->
            viewButtons config
                |> div [ class "group-input buttons" ]

        Entering kind description ->
            div
                [ class "group-input editing" ]
                [ input
                    [ placeholder "Observation"
                    , value description
                    , onEnter SaveCurrent
                    , onInput UpdateCurrent
                    , Html.Attributes.id <| "input-group-" ++ (toString id)
                    ]
                    []
                ]


viewObservations : Config -> KeyedList Observation -> Html Msg
viewObservations config observations =
    KeyedList.keyedMap (viewKeyedObservation config) observations
        |> ul []


viewKeyedObservation : Config -> Key -> Observation -> Html Msg
viewKeyedObservation config key observation =
    let
        inner =
            Observation.view config observation
                |> Html.map (UpdateExisting key)
    in
        li []
            [ inner
            , button [ onClick (Delete key) ] [ text "x" ]
            ]
