module Observation exposing (Observation, Kind, Msg, decoder, encode, init, update, view)

import Dict
import Config.Quiz as Config
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Util exposing ((=>), checkmark, emdash)


-- MODEL


type Observation
    = Observation Kind String State


type Kind
    = Kind String


type State
    = Struck
    | Active Int


init : Kind -> String -> Int -> Observation
init kind label tally =
    Observation kind label (Active tally)


kindDecoder : Decoder Kind
kindDecoder =
    Decode.map Kind Decode.string


stateDecoder : Decoder State
stateDecoder =
    Decode.map stateFromInt Decode.int


decoder : Decoder Observation
decoder =
    Decode.map3
        Observation
        (Decode.field "kind" kindDecoder)
        (Decode.field "label" Decode.string)
        (Decode.field "state" stateDecoder)


encode : Observation -> Encode.Value
encode (Observation (Kind kind) label state) =
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
view config (Observation (Kind kindName) label state) =
    let
        kind =
            Dict.get kindName config.kinds

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
