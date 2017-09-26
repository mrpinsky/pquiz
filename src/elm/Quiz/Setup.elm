module Quiz.Setup exposing (..)

import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyedList exposing (KeyedList, Key)
import Quiz.Settings as Settings exposing (Settings)

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
    = Proto String String


newProto : List String -> ProtoObservation
newProto kinds =
    let
        kind = List.head kinds
            |> Maybe.withDefault ""
    in
        Proto kind ""


relabel : String -> ProtoObservation -> ProtoObservation
relabel label (Proto kind _) =
    Proto kind label


rekind : String -> ProtoObservation -> ProtoObservation
rekind kind (Proto _ label) =
    Proto kind label


-- UPDATE


type Msg
    = AddObservation
    | Relabel Key String
    | Rekind Key String
    | RemoveObservation Key
    | UpdateSettings Settings.Msg


update : Msg -> Setup -> Setup
update msg setup =
    case msg of
        AddObservation ->
            { setup
                | observations =
                    KeyedList.push (newProto <| Dict.keys setup.settings.kinds) setup.observations
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
        [ viewObservations (Dict.keys settings.kinds) observations
        , Settings.view settings
            |> Html.map UpdateSettings
        ]


viewObservations : List String -> KeyedList ProtoObservation -> Html Msg
viewObservations kinds observations =
    div [] 
        [ ul [] <|
            KeyedList.keyedMap (viewObservation kinds) observations
        , button [ onClick AddObservation ] [ Html.text "+" ]
        ]


viewObservation : List String -> KeyedList.Key -> ProtoObservation -> Html Msg
viewObservation kinds key (Proto kind label) =
    li []
        [ viewKindSelector kinds key kind
        , input
            [ value label
            , onInput (Relabel key)
            ]
            []
        ]


viewKindSelector : List String -> KeyedList.Key -> String -> Html Msg
viewKindSelector kinds key kind =
    List.map (viewKindOption kind) kinds
        |> select [ onInput (Rekind key) ]


viewKindOption : String -> String -> Html Msg
viewKindOption current kind =
    option [ selected <| kind == current ] [ Html.text kind ]

