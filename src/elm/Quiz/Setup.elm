module Quiz.Setup exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import KeyedList exposing (KeyedList, Key)
import Quiz.Kind as Kind exposing (Kind)
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
    = Proto (Maybe Kind.Id) String


newProto : List Kind.Id -> ProtoObservation
newProto kinds =
    Proto (List.head kinds) ""


relabel : String -> ProtoObservation -> ProtoObservation
relabel label (Proto kind _) =
    Proto kind label


rekind : Kind.Id -> ProtoObservation -> ProtoObservation
rekind kind (Proto _ label) =
    Proto (Just kind) label


-- UPDATE


type Msg
    = AddObservation
    | Relabel Key String
    | Rekind Key Kind.Id
    | RemoveObservation Key
    | UpdateSettings Settings.Msg


update : Msg -> Setup -> Setup
update msg setup =
    case msg of
        AddObservation ->
            let
                proto =
                    Settings.listKinds setup.settings
                        |> newProto
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
        [ viewObservations settings.kinds observations
        , Settings.view settings
            |> Html.map UpdateSettings
        ]


viewObservations : List Kind -> KeyedList ProtoObservation -> Html Msg
viewObservations kinds observations =
    div [] 
        [ ul [] <|
            KeyedList.keyedMap (viewObservation kinds) observations
        , button [ onClick AddObservation ] [ Html.text "+" ]
        ]


viewObservation : List Kind -> KeyedList.Key -> ProtoObservation -> Html Msg
viewObservation kinds key (Proto kind label) =
    li []
        [ select [ onInput (Rekind key) ] <| viewKindOptions kind kinds
        , input
            [ value label
            , onInput (Relabel key)
            ]
            []
        ]


viewKindOptions : Maybe Kind.Id -> List Kind -> List (Html Msg)
viewKindOptions current kinds =
    List.map (viewKindOption current) kinds


viewKindOption : Maybe Kind.Id -> Kind -> Html Msg
viewKindOption selected kind =
    option
        [ selected <| selected == (Just kind.tag) ]
        [ Html.text kind.label ]

