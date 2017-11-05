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
    , columns : Int
    , observations : List (ObservationId, Observation)
    , nextId : Int
    }


type alias ObservationId = String


default : Settings
default =
    let
        theme =
            Theme.default
    in
        { theme = theme
        , showTally = False
        , columns = 4
        , observations = []
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
    | SetColumns Int


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
                        (toString settings.nextId, Observation style "")
                            |> List.singleton
                            |> (++) settings.observations
                    , nextId = settings.nextId + 1
                }

        UpdateObservation target subMsg ->
            let
                updateHelper (id, observation) =
                    if id == target then
                        (id, Observation.update subMsg observation)
                    else
                        (id, observation)
            in
                { settings
                    | observations = List.map updateHelper settings.observations
                }

        RemoveObservation target ->
            let
                removeHelper : (String, a) -> Bool
                removeHelper (id, _) =
                    id /= target
            in
                { settings | observations = List.filter removeHelper settings.observations }

        UpdateTheme themeMsg ->
            { settings
                | theme = Theme.update themeMsg settings.theme
            }

        ToggleTally ->
            { settings | showTally = not settings.showTally }

        SetColumns cols ->
            { settings | columns = cols }



-- VIEW


view : Settings -> Html Msg
view { theme, observations } =
    div [ class "content" ]
        [ h1 [] [ text "Set up your Quiz" ]
        , div [ class "body" ] 
            [ section []
                [ h2 [] [ text "Observation Categories" ]
                , Theme.viewAsEditable theme
                    |> Html.map UpdateTheme
                ]
            , section []
                [ h2 [] [ text "Default Observations" ]
                , viewObservations theme observations
                ]
            ]
        ]


viewObservations : Theme -> List (String, Observation) -> Html Msg
viewObservations theme observations =
    div [ class "default-observations" ]
        [ observations
            |> List.map (viewRemovableObservation theme) 
            |> ul [ class "observations" ]
        , button [ onClick AddObservation, class "add-button" ] [ Html.text "+" ]
        ]


viewRemovableObservation : Theme -> (String, Observation) -> Html Msg
viewRemovableObservation theme (id, observation) =
    Observation.viewAsProto theme observation
        |> Html.map (UpdateObservation id)
        |> viewWithRemoveButton (RemoveObservation id)


-- JSON


-- encode : Settings -> Encode.Value
-- encode { theme, observations, showTally, columns } =
--     Encode.object
--         [ "theme" => Theme.encode theme
--         , "observations" => encodeObservations observations
--         , "showTally" => Encode.bool showTally
--         , "columns" => Encode.int columns
--         ]


-- encodeObservations : List (String, Observation) -> Encode.Value
-- encodeObservations observations =
--     observations
--         |> List.map (Tuple.mapSecond Observation.encode)
--         |> Encode.object


-- decoder : Topic -> Decode.Decoder Settings
-- decoder defaultTopic =
--     Decode.map4 Settings
--         (Decode.field "theme" Theme.decoder)
--         (Decode.field "showTally" Decode.bool)
--         (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)
--         (Decode.field "observations" <| Decode.keyValuePairs Observation.decoder)
