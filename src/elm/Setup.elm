module Setup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import KeyedList exposing (KeyedList, Key)
import Quiz.App as PQuiz
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Options as Options exposing (Options)
import Quiz.Observation.Style as Style exposing (Style)
import Quiz.Quiz as Quiz exposing (Quiz)
import Quiz.Settings as Settings exposing (Settings)
import Util exposing (onChange, viewWithRemoveButton)


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


toQuiz : Setup -> PQuiz.Model
toQuiz { observations, settings } =
    observations
        |> KeyedList.toList
        |> List.map (realizeProto <| .id <| Options.first settings.options)
        |> Quiz.init "Participation Quiz"
        |> PQuiz.init settings


realizeProto : Options.Id -> ProtoObservation -> Observation
realizeProto defaultOption (Proto maybeOption label) =
    Observation.init
        (Maybe.withDefault defaultOption maybeOption)
        label
        0


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
            { setup | settings = Settings.update subMsg setup.settings }



-- VIEW


view : Setup -> Html Msg
view { settings, observations } =
    div []
        [ h1 [] [ text "Set up your Quiz" ]
        , h2 [] [ text "Default Observations" ]
        , viewObservations settings.options observations
        , h2 [] [ text "Observation Categories" ]
        , Settings.view settings
            |> Html.map UpdateSettings
        ]


viewObservations : Options -> KeyedList ProtoObservation -> Html Msg
viewObservations options observations =
    div []
        [ ul [] <| KeyedList.keyedMap (viewRemovableObservation options) observations
        , button [ onClick AddObservation ] [ Html.text "+" ]
        ]


viewRemovableObservation : Options -> KeyedList.Key -> ProtoObservation -> Html Msg
viewRemovableObservation options key proto =
    viewObservation options key proto
        |> viewWithRemoveButton (RemoveObservation key)


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
        [ selected <| currentlySelected == Just id
        , value id
        ]
        [ Html.text label ]
