module Quiz.Observation exposing (Observation, Msg, decoder, encode, init, relabel, value, update, view)

import Css
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Quiz.Observation.Options as Options exposing (Options)
import Util exposing ((=>), checkmark, emdash, styles)


-- MODEL


type Observation
    = Observation Options.Id Label State


type Label
    = Label String


type State
    = Struck
    | Active Int


init : Options.Id -> String -> Int -> Observation
init optionId label tally =
    Observation optionId (Label label) (Active tally)


relabel : String -> Observation -> Observation
relabel newLabel (Observation optionId label tally) =
    Observation optionId (Label newLabel) tally


value : Options.Options -> Observation -> Int
value options (Observation optionId _ state) =
    case state of
        Struck ->
            0

        Active tally ->
            let
                weight =
                    Options.lookup optionId options
                        |> Maybe.map .weight
                        |> Maybe.withDefault 1
            in
                tally * weight


stateDecoder : Decoder State
stateDecoder =
    Decode.map stateFromInt Decode.int


decoder : Decoder Observation
decoder =
    Decode.map3
        Observation
        (Decode.field "optionId" Decode.string)
        (Decode.field "label" labelDecoder)
        (Decode.field "state" stateDecoder)


labelDecoder : Decoder Label
labelDecoder =
    Decode.map Label Decode.string


encode : Observation -> Encode.Value
encode (Observation optionId (Label label) state) =
    Encode.object
        [ "optionId" => Encode.string optionId
        , "state" => Encode.int (stateToInt state)
        , "label" => Encode.string label
        ]


encodeState : State -> Encode.Value
encodeState state =
    stateToInt state |> Encode.int


stateToInt : State -> Int
stateToInt state =
    case state of
        Struck ->
            -1

        Active tally ->
            tally


stateFromInt : Int -> State
stateFromInt tally =
    if tally < 0 then
        Struck
    else
        Active tally



-- UPDATE


type Msg
    = Relabel String
    | Increment
    | Strike


update : Msg -> Observation -> Observation
update msg (Observation optionId label state) =
    case msg of
        Relabel newLabel ->
            Observation optionId (Label newLabel) state

        Increment ->
            case state of
                Struck ->
                    Observation optionId label Struck

                Active tally ->
                    tally
                        + 1
                        |> Active
                        |> Observation optionId label

        Strike ->
            Observation optionId label Struck



-- VIEW


view : Options.Options -> Observation -> Html Msg
view options (Observation optionId (Label label) state) =
    let
        option =
            Options.lookup optionId options

        symbol =
            option
                |> Maybe.map .symbol
                |> Maybe.withDefault checkmark

        bgColor =
            option
                |> Maybe.map .color
                |> Maybe.withDefault (Css.hex "ffffff")
    in
        case state of
            Struck ->
                div [ Attributes.class "struck" ]
                    [ s [] [ Html.text label ] ]

            Active tally ->
                div
                    [ styles [ Css.backgroundColor bgColor ]
                    ]
                    [ button [ onClick Increment ]
                        [ Html.text symbol
                        , Html.text <| toString tally
                        ]
                    , span
                        [ contenteditable True, onInput Relabel ]
                        [ Html.text label ]
                    , button [ onClick Strike ] [ Html.text emdash ]
                    ]
