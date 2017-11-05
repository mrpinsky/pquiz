module Quiz.Observation.Record exposing (Record, Msg, init, value, update, view, viewActive)

import Css
import Html exposing (Html, li, s, button, div)
import Html.Attributes as Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Json.Decode as Decode
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Observation.Style as Style exposing (Style)
import Quiz.Theme as Theme exposing (Theme, Topic)
import Util exposing (..)


-- MODEL


type alias Record =
    { observation : Observation
    , state : State
    }


type State
    = Struck
    | Active Int


init : Observation -> Int -> Record
init observation tally =
    Record observation <| Active tally


value : Theme -> Record -> Int
value theme { observation, state } =
    case state of
        Struck ->
            0

        Active tally ->
            let
                weight =
                    theme
                        |> Theme.lookup observation.style
                        |> .weight
            in
                tally * weight



-- UPDATE


type Msg
    = Increment
    | Strike
    | UpdateObservation Observation.Msg


update : Msg -> Record -> Record
update msg record =
    case msg of
        Increment ->
            { record | state = increment record.state }

        Strike ->
            { record | state = Struck }

        UpdateObservation subMsg ->
            { record | observation = Observation.update subMsg record.observation }


increment : State -> State
increment state =
    case state of
        Active n ->
            Active <| n + 1

        _ ->
            state



-- VIEW


view : Handlers Msg msg r -> Theme -> Record -> Html msg
view handlers theme { observation, state } =
    case state of
        Struck ->
            li [ class "observation local struck" ]
                [ s [] [ Html.text observation.label ] ]

        Active tally ->
            Theme.lookup observation.style theme
                |> viewActive handlers observation tally


viewActive : Handlers Msg msg q -> Observation -> Int -> Style r -> Html msg
viewActive { onUpdate, remove } observation tally { color, symbol } =
    li
        [ styles [ Css.backgroundColor <| fade color tally ]
        , class "observation local active"
        ]
        [ div
            [ class "buttons start" ]
            [ button
                [ onClick (onUpdate Increment)
                , class "tally"
                ]
                [ Html.text <| symbol ++ toString tally ]
            ]
        , Observation.view observation
            |> Html.map UpdateObservation
            |> Html.map onUpdate
        , div [ class "buttons end" ]
            [ button
                [ onClick (onUpdate Strike), class "strike" ]
                [ Html.text emdash ]
            , button
                [ onClick remove
                , class "remove"
                ]
                [ Html.text "x" ]
            ]
        ]



-- JSON


encodeState : State -> Encode.Value
encodeState state =
    case state of
        Struck ->
            Encode.null

        Active tally ->
            Encode.int tally


stateDecoder : Decode.Decoder State
stateDecoder =
    Decode.oneOf
        [ Decode.null Struck
        , Decode.map Active Decode.int
        ]
