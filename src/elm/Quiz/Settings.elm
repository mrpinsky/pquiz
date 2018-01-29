module Quiz.Settings exposing (..)

import Html exposing (..)
import Html.Attributes exposing (value, selected, class, classList)
import Html.Events exposing (onClick, onWithOptions)
import Json.Decode as Decode
import Json.Encode as Encode
import List.Nonempty as NE exposing (Nonempty)
import Quiz.Observation as Observation exposing (Observation)
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
    , format : Format
    }


type alias ObservationId =
    String


type Format
    = Grid
    | Column


default : Settings
default =
    let
        theme =
            Theme.default
    in
        { theme = theme
        , showTally = False
        , observations = []
        , nextId = 1
        , format = Grid
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
    | SetFormat Format


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

        SetFormat format ->
            { settings | format = format }



-- VIEW


view : { updateMsg : Msg -> msg, doneMsg : msg, cancelMsg : msg } -> Settings -> Html msg
view { updateMsg, doneMsg, cancelMsg } { theme, observations, format } =
    div [ class "settings" ]
        [ h1 [ class "title" ] [ text "Settings" ]
        , div [ class "content" ]
            [ viewFormatToggle format
                |> Html.map updateMsg
            , Theme.viewAsEditable theme
                |> Html.map UpdateTheme
                |> Html.map updateMsg
            , viewObservations theme observations
                |> Html.map updateMsg
            ]
        , div [ class "buttons" ]
            [ button [ class "cancel", onClick cancelMsg ]
                [ text "Cancel changes" ]
            , div [ class "spacer" ] []
            , button [ class "submit", onClick doneMsg ]
                [ text "Save and return" ]
            ]
        ]


viewFormatToggle : Format -> Html Msg
viewFormatToggle format =
    section [ class "format" ]
        [ h2 [] [ text "Group Display" ]
        , div [ class "options" ]
            [ div
                [ onClick (SetFormat Grid)
                , class "option"
                , classList
                    [ "selected" => (format == Grid)
                    ]
                ]
                [ p [ class "title" ] [ text "Grid" ]
                , span [ class "description" ]
                    [ text """
                        Arrange groups in two rows. Wider groups allow for
                        larger text, but display fewer observations at a time.
                      """
                    ]
                ]
            , div
                [ onClick (SetFormat Column)
                , class "option"
                , classList
                    [ "selected" => (format == Column)
                    ]
                ]
                [ p [ class "title" ] [ text "Columns" ]
                , span [ class "description" ]
                    [ text """
                        Arrange groups in one row. Taller, narrower groups
                        display many observations, but require smaller text.
                      """
                    ]
                ]
            ]

        -- [ label [ onClick (SetFormat Grid) ]
        --     [ input
        --         [ type_ "radio"
        --         , name "format"
        --         , checked (format == Grid)
        --         ]
        --         []
        --     , span [ class "label-text" ] [ text "Grid" ]
        --     ]
        -- , label [ onClick (SetFormat Column) ]
        --     [ input
        --         [ type_ "radio"
        --         , name "format"
        --         , checked (format == Column)
        --         ]
        --         []
        --     , span [ class "label-text" ] [ text "Columns" ]
        --     ]
        -- ]
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
encode { theme, observations, showTally, nextId, format } =
    Encode.object
        [ "theme" => Theme.encode theme
        , "showTally" => Encode.bool showTally
        , "observations" => encodeObservations observations
        , "nextId" => Encode.int nextId
        , "format" => encodeFormat format
        ]


encodeObservations : List ( String, Observation ) -> Encode.Value
encodeObservations observations =
    observations
        |> List.map (Tuple.mapSecond Observation.encode)
        |> Encode.object


encodeFormat : Format -> Encode.Value
encodeFormat format =
    case format of
        Grid ->
            Encode.string "grid"

        Column ->
            Encode.string "column"


decoder : Decode.Decoder Settings
decoder =
    Decode.map5 Settings
        (Decode.field "theme" Theme.decoder)
        (Decode.field "showTally" Decode.bool)
        (Decode.field "observations" <| Decode.keyValuePairs Observation.decoder)
        (Decode.field "nextId" Decode.int)
        (Decode.field "format" formatDecoder)


formatDecoder : Decode.Decoder Format
formatDecoder =
    let
        formatFromString string =
            case string of
                "column" ->
                    Column

                "grid" ->
                    Grid

                _ ->
                    Grid
    in
        Decode.map formatFromString Decode.string
