module Quiz.Observation exposing (Observation, Msg, decoder, encode, init, relabel, value, update, view)

-- import AllDict

import Css
import Dict exposing (Dict)
import Quiz.Settings as Settings exposing (..)
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Quiz.Kind as Kind exposing (KindSettings)
import Util exposing ((=>), checkmark, emdash, styles)


-- MODEL


type Observation
    = Observation Kind Label State


type Kind
    = Kind String


type Label
    = Label String


type State
    = Struck
    | Active Int


init : String -> String -> Int -> Observation
init kind label tally =
    Observation (Kind kind) (Label label) (Active tally)


relabel : String -> Observation -> Observation
relabel newLabel (Observation kind label tally) =
    Observation kind newLabel tally


value : KindSettings -> Observation -> Int
value kinds (Observation kind _ state) =
    case state of
        Struck ->
            0

        Active tally ->
            let
                weight =
                    Dict.get kind kinds
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


view : Settings.Settings -> Observation -> Html Msg
view settings (Observation kind label state) =
    let
        kindSettings =
            Dict.get kind settings.kinds

        symbol =
            kindSettings
                |> Maybe.map .symbol
                |> Maybe.withDefault checkmark

        bgColor =
            kindSettings
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
