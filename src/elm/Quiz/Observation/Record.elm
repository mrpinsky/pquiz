module Quiz.Observation.Record
    exposing (Record, Msg, init, value, update, view, viewActive)

import Css
import Html exposing (Html, li, s, button)
import Html.Attributes as Attributes
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

view : Theme -> Record -> Html Msg
view theme { observation, state } =
    case state of
        Struck ->
            li [ Attributes.class "struck" ]
                [ s [] [ Html.text observation.label ] ]

        Active tally ->
            Theme.lookup observation.style theme
                |> viewActive observation tally


viewActive : Observation -> Int -> Style r -> Html Msg
viewActive observation tally style =
    li [ styles [ Css.backgroundColor style.color ] ]
        [ button [ onClick Increment ]
            [ Html.text style.symbol
            , Html.text <| toString tally
            ]
        , Observation.view observation
            |> Html.map UpdateObservation
        , button [ onClick Strike ] [ Html.text emdash ]
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


