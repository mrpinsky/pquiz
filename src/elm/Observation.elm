module Observation exposing (..)

import Array
import Config.Quiz exposing (Config, Kind)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Util exposing ((=>), checkmark, emdash)


-- MODEL


type Observation
    = Observation Int String State


type State
    = Struck
    | Active Int


init : Int -> String -> Observation
init kindIndex label =
    Observation kindIndex label (Active 1)


stateDecoder : Decoder State
stateDecoder =
    Decode.map stateFromInt Decode.int


decoder : Decoder Observation
decoder =
    Decode.map3
        Observation
        (Decode.field "kind" Decode.int)
        (Decode.field "label" Decode.string)
        (Decode.field "state" stateDecoder)


encode : Observation -> Encode.Value
encode (Observation kind label state) =
    Encode.object
        [ "kind" => Encode.int kind
        , "label" => Encode.string label
        , "state" => Encode.int (stateToInt state)
        ]


encodeState : State -> Encode.Value
encodeState state =
    case state of
        Struck ->
            Encode.int 0

        Active tally ->
            Encode.int tally


stateToInt : State -> Int
stateToInt state =
    case state of
        Struck ->
            0

        Active tally ->
            tally


stateFromInt : Int -> State
stateFromInt tally =
    if tally > 0 then
        Active tally
    else
        Struck



-- UPDATE


type Msg
    = Relabel String
    | Increment
    | Strike


update : Msg -> Observation -> Observation
update msg (Observation kindIndex label state) =
    case msg of
        Relabel newLabel ->
            Observation kindIndex newLabel state

        Increment ->
            case state of
                Struck ->
                    Observation kindIndex label Struck

                Active tally ->
                    tally
                        + 1
                        |> Active
                        |> Observation kindIndex label

        Strike ->
            Observation kindIndex label Struck



-- VIEW


view : Config -> Observation -> Html Msg
view config (Observation kindIndex label state) =
    let
        kind =
            Array.get kindIndex config.kinds

        symbol =
            kind
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
