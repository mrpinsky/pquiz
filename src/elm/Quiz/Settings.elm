module Quiz.Settings exposing (..)

import Css exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (value, selected, class)
import Html.Events exposing (onClick, onInput)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import List.Nonempty as NE exposing (Nonempty)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Style as Style exposing (Style)
import Quiz.Theme as Theme exposing (Theme, Topic)
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
    { theme : Theme
    , showTally : Bool
    , observations : List ( ObservationId, Observation )
    , nextId : Int
    }


type alias ObservationId =
    String


default : Settings
default =
    let
        theme =
            Theme.default
    in
        { theme = theme
        , showTally = False
        , observations = [] -- [ ( "demo", defaultProto <| Theme.idList theme ) ]
        , nextId = 1
        }


defaultProto : Nonempty Theme.Id -> Observation
defaultProto theme =
    Observation (NE.head theme) ""


defaultKeys : Settings -> List String
defaultKeys { observations } =
    List.map Tuple.first observations



-- UPDATE


type Msg
    = UpdateTheme Theme.Msg
    | AddObservation
    | UpdateObservation String Observation.Msg
    | RemoveObservation String
    | ToggleTally


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        AddObservation ->
            let
                style =
                    Theme.idList settings.theme
                        |> NE.head
            in
                { settings
                    | observations =
                        ( toString settings.nextId, Observation style "" )
                            |> List.singleton
                            |> (++) settings.observations
                    , nextId = settings.nextId + 1
                }

        UpdateObservation target subMsg ->
            let
                updateHelper ( id, observation ) =
                    if id == target then
                        ( id, Observation.update subMsg observation )
                    else
                        ( id, observation )
            in
                { settings
                    | observations = List.map updateHelper settings.observations
                }

        RemoveObservation target ->
            let
                removeHelper : ( String, a ) -> Bool
                removeHelper ( id, _ ) =
                    id /= target
            in
                { settings | observations = List.filter removeHelper settings.observations }

        UpdateTheme themeMsg ->
            { settings
                | theme = Theme.update themeMsg settings.theme
            }

        ToggleTally ->
            { settings | showTally = not settings.showTally }

-- VIEW


view : { updateMsg : Msg -> msg, doneMsg : msg } -> Settings -> Html msg
view { updateMsg, doneMsg } { theme, observations } =
    div [ class "content" ]
        [ h1 [] [ text "Settings" ]
        , div [ class "body" ]
            [ Theme.viewAsEditable theme
                |> Html.map UpdateTheme
                |> Html.map updateMsg
            , viewObservations theme observations
                |> Html.map updateMsg
            , button [ class "submit", onClick doneMsg ]
                [ text "Save and return" ]
            ]
        ]


viewObservations : Theme -> List ( String, Observation ) -> Html Msg
viewObservations theme observations =
    section [ class "default-observations" ]
        [ h2 []
            [ text "Default Observations"
            , button
                [ onClick AddObservation, class "add-button" ]
                [ Html.text "+" ]
            ]
        , p [ class "hint" ]
            [ text
                """
                Behaviors you know you want to track in every group. These
                observations will display in every group with a starting tally
                of 0.  They cannot be struck out and can only be deleted from
                this menu.
                """
            ]
        , observations
            |> List.map (viewRemovableObservation theme)
            |> ul [ class "observations" ]
        ]


viewRemovableObservation : Theme -> ( String, Observation ) -> Html Msg
viewRemovableObservation theme ( id, observation ) =
    Observation.viewAsProto
        { onUpdate = UpdateObservation id
        , remove = RemoveObservation id
        }
        theme
        observation



-- JSON

encode : Settings -> Encode.Value
encode { theme, observations, showTally, nextId } =
    Encode.object
        [ "theme" => Theme.encode theme
        , "showTally" => Encode.bool showTally
        , "observations" => encodeObservations observations
        , "nextId" => Encode.int nextId
        ]

encodeObservations : List (String, Observation) -> Encode.Value
encodeObservations observations =
    observations
        |> List.map (Tuple.mapSecond Observation.encode)
        |> Encode.object

decoder : Decode.Decoder Settings
decoder =
    Decode.map4 Settings
        (Decode.field "theme" Theme.decoder)
        (Decode.field "showTally" Decode.bool)
        (Decode.field "observations" <| Decode.keyValuePairs Observation.decoder)
        (Decode.field "nextId" Decode.int)
