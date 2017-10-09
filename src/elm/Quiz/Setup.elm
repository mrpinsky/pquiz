module Quiz.Setup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation.Options as Options exposing (Options)
import Quiz.Observation.Style as Style exposing (Style)
import Quiz.Settings as Settings exposing (Settings)
import Util exposing (onChange)


main =
    Html.beginnerProgram
        { model = init
        , update = update
        , view = view
        }



-- MODEL


type alias Setup =
    { observations : KeyedList ProtoObservation
    , settings : Settings
    }


init : Setup
init =
    { observations = KeyedList.empty
    , settings = Settings.default
    }


type ProtoObservation
    = Proto (Maybe Options.Id) String


defaultProto : List Options.Id -> ProtoObservation
defaultProto options =
    Proto (List.head options) ""


relabel : String -> ProtoObservation -> ProtoObservation
relabel label (Proto kind _) =
    Proto kind label


rekind : Options.Id -> ProtoObservation -> ProtoObservation
rekind kind (Proto _ label) =
    Proto (Just kind) label



-- UPDATE


type Msg
    = AddObservation
    | Relabel Key String
    | Rekind Key Options.Id
    | RemoveObservation Key
    | UpdateSettings Settings.Msg


update : Msg -> Setup -> Setup
update msg setup =
    case msg of
        AddObservation ->
            let
                proto =
                    Options.idList setup.settings.options
                        |> defaultProto
            in
                { setup
                    | observations =
                        KeyedList.push proto setup.observations
                }

        Relabel key label ->
            { setup
                | observations =
                    KeyedList.update key (relabel label) setup.observations
            }

        Rekind key kind ->
            { setup
                | observations =
                    KeyedList.update key (rekind kind) setup.observations
            }

        RemoveObservation key ->
            { setup | observations = KeyedList.remove key setup.observations }

        UpdateSettings subMsg ->
            { setup
                | settings = Settings.update subMsg setup.settings
                , observations = 
            }



-- VIEW


view : Setup -> Html Msg
view { settings, observations } =
    div []
        [ viewObservations settings.options observations
        , Settings.view settings
            |> Html.map UpdateSettings
        ]


viewObservations : Options -> KeyedList ProtoObservation -> Html Msg
viewObservations options observations =
    div []
        [ ul [] <|
            KeyedList.keyedMap (viewObservation options) observations
        , button [ onClick AddObservation ] [ Html.text "+" ]
        ]


viewObservation : Options -> KeyedList.Key -> ProtoObservation -> Html Msg
viewObservation options key (Proto kind label) =
    li []
        [ options
            |> Options.toList
            |> List.map (viewStyleOption kind)
            |> select [ onChange (Rekind key) ]
        , input
            [ value label
            , onInput (Relabel key)
            ]
            []
        ]


viewStyleOption : Maybe Options.Id -> Options.Option -> Html Msg
viewStyleOption currentlySelected { id, label } =
    option
        [ selected <| currentlySelected == Just id ]
        [ Html.text label ]
