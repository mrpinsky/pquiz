module Quiz.Settings exposing (..)

import Css exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (value, selected)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Options as Options exposing (Options)
import Quiz.Observation.Style as Style exposing (Style)
import Util
    exposing
        ( (=>)
        , delta
        , encodeKeyedList
        , keyedListDecoder
        , encodeMaybe
        , viewWithRemoveButton
        , onChange
        )


-- MODEL


type alias Settings =
    { options : Options
    , observations : KeyedList ProtoObservation
    , tally : Bool
    , groupWidth : Css.Px
    }


type ProtoObservation
    = Proto (Maybe Options.Id) String


styleIds : Settings -> List Options.Id
styleIds { options } =
    Options.idList options


default : Settings
default =
    let
        options =
            Options.init
    in
        { options = options
        , observations = KeyedList.fromList []
        , tally = False
        , groupWidth = Css.px 200
        }


defaultProto : List Options.Id -> ProtoObservation
defaultProto options =
    Proto (List.head options) ""


relabel : String -> ProtoObservation -> ProtoObservation
relabel label (Proto kind _) =
    Proto kind label


rekind : Options.Id -> ProtoObservation -> ProtoObservation
rekind kind (Proto _ label) =
    Proto (Just kind) label


defaultObservations : Settings -> List Observation
defaultObservations { options, observations } =
    observations
        |> KeyedList.toList
        |> List.map (realizeProto <| .id <| Options.first options)


realizeProto : Options.Id -> ProtoObservation -> Observation
realizeProto defaultOption (Proto maybeOption label) =
    Observation.init
        (Maybe.withDefault defaultOption maybeOption)
        label
        0



-- UPDATE


type Msg
    = UpdateOptions Options.Msg
    | AddObservation
    | Relabel Key String
    | Rekind Key Options.Id
    | RemoveObservation Key
    | ToggleTally
    | SetGroupWidth Float


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        AddObservation ->
            let
                proto =
                    Options.idList settings.options
                        |> defaultProto
            in
                { settings
                    | observations =
                        KeyedList.push proto settings.observations
                }

        Relabel key label ->
            { settings
                | observations =
                    KeyedList.update key (relabel label) settings.observations
            }

        Rekind key kind ->
            { settings
                | observations =
                    KeyedList.update key (rekind kind) settings.observations
            }

        RemoveObservation key ->
            { settings | observations = KeyedList.remove key settings.observations }

        UpdateOptions optionsMsg ->
            { settings
                | options = Options.update optionsMsg settings.options
            }

        ToggleTally ->
            { settings | tally = not settings.tally }

        SetGroupWidth px ->
            { settings | groupWidth = Css.px px }



-- VIEW


view : Settings -> Html Msg
view { options, observations } =
    div []
        [ h1 [] [ text "Set up your Quiz" ]
        , h2 [] [ text "Default Observations" ]
        , viewObservations options observations
        , h2 [] [ text "Observation Categories" ]
        , Options.view options
            |> Html.map UpdateOptions
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



-- JSON


encode : Settings -> Encode.Value
encode { options, observations, tally, groupWidth } =
    Encode.object
        [ "options" => Options.encode options
        , "observations"
            => encodeKeyedList encodeProto observations
        , "tally" => Encode.bool tally
        , "groupWidth" => Encode.float groupWidth.numericValue
        ]


encodeProto : ProtoObservation -> Encode.Value
encodeProto (Proto optionId label) =
    Encode.object
        [ "optionId" => encodeMaybe Encode.string optionId
        , "label" => Encode.string label
        ]


decoder : Options.Option -> Decode.Decoder Settings
decoder defaultOption =
    Decode.map4 Settings
        (Decode.field "options" Options.decoder)
        (Decode.field "observations" <|
            keyedListDecoder protoObsDecoder
        )
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)


protoObsDecoder : Decode.Decoder ProtoObservation
protoObsDecoder =
    Decode.map2 Proto
        (Decode.field "optionId" <| Decode.nullable Decode.string)
        (Decode.field "label" Decode.string)
