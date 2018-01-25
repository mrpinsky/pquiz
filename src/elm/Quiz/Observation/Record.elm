module Quiz.Observation.Record
    exposing
        ( Record
        , Msg
        , init
        , value
        , update
        , view
        , encode
        , decoder
        )

import Css
import Html exposing (Html, li, s, button, div, text)
import Html.Attributes as Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Json.Decode as Decode
import Quiz.Observation as Observation exposing (Observation)
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


init : Int -> Observation -> Record
init tally observation =
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
view { onUpdate, remove } theme { observation, state } =
    let
        { color, symbol } =
            Theme.lookup observation.style theme

        ( bgColor, stateClass, tallyText, label ) =
            case state of
                Struck ->
                    ( Css.hex "eeeeee"
                    , "struck"
                    , "0"
                    , s [ class "label" ] [ text observation.label ]
                    )

                Active tally ->
                    ( fade color tally
                    , "active"
                    , toString tally
                    , Observation.view observation
                        |> Html.map UpdateObservation
                        |> Html.map onUpdate
                    )
    in
        li
            [ styles [ Css.backgroundColor bgColor ]
            , class "observation local"
            , class stateClass
            ]
            [ div
                [ class "buttons start"
                , styles [ Css.backgroundColor color ]
                ]
                [ button
                    [ onClick (onUpdate Increment)
                    , class "tally"
                    ]
                    [ Html.text <| tallyText ++ symbol ]
                ]
            , label
            , div [ class "buttons end" ]
                [ button
                    [ onClick remove
                    , class "remove"
                    ]
                    [ Html.text "x" ]
                , button
                    [ onClick (onUpdate Strike), class "strike" ]
                    [ Html.text emdash ]
                ]
            ]



-- JSON


encode : Record -> Encode.Value
encode { observation, state } =
    Encode.object
        [ "observation" => Observation.encode observation
        , "state" => encodeState state
        ]


encodeState : State -> Encode.Value
encodeState state =
    case state of
        Struck ->
            Encode.null

        Active tally ->
            Encode.int tally


decoder : Decode.Decoder Record
decoder =
    Decode.map2 Record
        (Decode.field "observation" Observation.decoder)
        (Decode.field "state" stateDecoder)


stateDecoder : Decode.Decoder State
stateDecoder =
    Decode.oneOf
        [ Decode.null Struck
        , Decode.map Active Decode.int
        ]
