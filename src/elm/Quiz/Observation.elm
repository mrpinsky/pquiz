module Quiz.Observation exposing (Observation, Msg, decoder, encode, init, relabel, update, view)

-- import AllDict

import Dict
import Quiz.Config as Config exposing (..)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Util exposing ((=>), checkmark, emdash)


-- MODEL


type Observation
    = Observation String String State


type State
    = Struck
    | Active Int


init : String -> String -> Int -> Observation
init kind label tally =
    Observation kind label (Active tally)


relabel : String -> Observation -> Observation
relabel newLabel (Observation kind label tally) =
    Observation kind newLabel tally



-- kindDecoder : Decoder Kind
-- kindDecoder =
--     Decode.map Kind Decode.string


stateDecoder : Decoder State
stateDecoder =
    Decode.map stateFromInt Decode.int


decoder : Decoder Observation
decoder =
    Decode.map3
        Observation
        (Decode.field "kind" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "state" stateDecoder)


encode : Observation -> Encode.Value
encode (Observation kind label state) =
    Encode.object
        [ "kind" => Encode.string kind
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
update msg (Observation kind label state) =
    case msg of
        Relabel newLabel ->
            Observation kind newLabel state

        Increment ->
            case state of
                Struck ->
                    Observation kind label Struck

                Active tally ->
                    tally
                        + 1
                        |> Active
                        |> Observation kind label

        Strike ->
            Observation kind label Struck



-- VIEW


view : Config.Config -> Observation -> Html Msg
view config (Observation kind label state) =
    let
        kindConfig =
            Dict.get kind config.kinds

        symbol =
            kindConfig
                |> Maybe.map (.symbol >> String.fromChar)
                |> Maybe.withDefault checkmark
    in
        case state of
            Struck ->
                div [ Attributes.class "struck" ]
                    [ s [] [ Html.text label ] ]

            Active tally ->
                div []
                    [ button [ onClick Increment ]
                        [ Html.text symbol
                        , Html.text <| toString tally
                        ]
                    , span
                        [ contenteditable True, onInput Relabel ]
                        [ Html.text label ]
                    , button [ onClick Strike ] [ Html.text emdash ]
                    ]
