module Quiz.Group exposing (Group, Msg, init, update, view, encode, decoder)

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
import Quiz.Observation.Options as Options
import Quiz.Settings as Settings exposing (..)
import Util exposing (..)


main : Program Never Group Msg
main =
    Html.beginnerProgram
        { model = init "Test Group" []
        , view = view Settings.default
        , update = update
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


view : Settings -> Group -> Html Msg
view settings (Group label observations state) =
    div
        [ class "group"
        , styles [ Css.width settings.groupWidth ]
        ]
        [ lazy viewLabel label
        , lazy2 viewTally settings observations
        , lazy2 viewInput settings state
        , lazy2 viewObservations settings.options observations
        ]


viewLabel : String -> Html Msg
viewLabel label =
    div
        [ class "title"
        , contenteditable True
        , onChange Relabel
        ]
        [ text label ]


viewTally : Settings.Settings -> KeyedList Observation -> Html Msg
viewTally settings observations =
    let
        total =
            KeyedList.toList observations
                |> List.map (Observation.value settings.options)
                |> List.sum
    in
        total
            |> toString
            |> text
            |> List.singleton
            |> h2
                [ classList
                    [ ( "points", True )
                    , ( "hidden", not settings.tally )
                    , ( "total-" ++ (toString <| clamp 0 10 <| abs total), True )
                    , ( "pos", total > 0 )
                    ]
                ]


viewButtons : Options.Options -> List (Html Msg)
viewButtons options =
    Options.toList options
        |> List.map viewButton


viewButton : Options.Option -> Html Msg
viewButton option =
    button
        [ onClick <| StartNew option.id
        , class "input-button"
        , styles [ Css.backgroundColor option.color ]
        ]
        [ text option.label ]


viewInput : Settings -> State -> Html Msg
viewInput settings state =
    case state of
        Waiting ->
            viewButtons settings.options
                |> div [ class "group-input buttons" ]

        Entering kind description ->
            div
                [ class "group-input editing" ]
                [ input
                    [ placeholder "Observation"
                    , value description
                    , onEnter SaveCurrent
                    , onInput UpdateCurrent

                    -- , Html.Attributes.id <| "input-group-" ++ (toString id)
                    ]
                    []
                ]


viewObservations : Options.Options -> KeyedList Observation -> Html Msg
viewObservations options observations =
    KeyedList.keyedMap (viewKeyedObservation options) observations
        |> ul []


viewKeyedObservation : Options.Options -> Key -> Observation -> Html Msg
viewKeyedObservation options key observation =
    Observation.view options observation
        |> Html.map (UpdateExisting key)
        |> viewWithRemoveButton (Delete key)
