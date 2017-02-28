module Observation exposing (Model, Msg, init, update, viewWithRemoveButton, obsValue, toJSON, fromJSON, decoder)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import Result exposing (Result(Ok, Err))
import Util


-- MODEL


type alias Model =
    { description : String
    , count : Int
    , kind : Kind
    , struck : Bool
    , id : Int
    }


toJSON : Model -> Encode.Value
toJSON model =
    Encode.object
        [ ( "description", Encode.string model.description )
        , ( "count", Encode.int model.count )
        , ( "kind", Encode.int <| kindToInt model.kind )
        , ( "struck", Encode.bool model.struck )
        , ( "id", Encode.int model.id )
        ]


decoder : Decode.Decoder Model
decoder =
    Decode.map5
        Model
        (Decode.field "description" Decode.string)
        (Decode.field "count" Decode.int)
        (Decode.field "kind" <| Decode.map kindFromInt Decode.int)
        (Decode.field "editing" Decode.bool)
        (Decode.field "id" Decode.int)


fromJSON : Decode.Value -> Int -> Model
fromJSON value nextId =
    let
        result =
            Decode.decodeValue decoder value
    in
        case result of
            Ok model ->
                model

            Err _ ->
                baseModel nextId


type Kind
    = FirstKind
    | SecondKind
    | ThirdKind


kindFromInt : Int -> Kind
kindFromInt n =
    case n of
        1 ->
            FirstKind

        2 ->
            SecondKind

        3 ->
            ThirdKind

        _ ->
            SecondKind


kindToInt : Kind -> Int
kindToInt k =
    case k of
        FirstKind ->
            1

        SecondKind ->
            2

        ThirdKind ->
            3


baseModel : Int -> Model
baseModel id =
    Model "" 0 FirstKind False id


init : String -> Int -> Int -> Model
init desc kNum id =
    let
        k =
            kindFromInt kNum
    in
        { description = desc
        , count = 1
        , kind = k
        , struck = False
        , id = id
        }



-- MESSAGING


type Msg
    = Update String
    | Increment
    | ToggleStrikethrough
    | Delete



-- UPDATE


update : Msg -> Model -> ( Model, Maybe Int )
update msg model =
    case msg of
        Update newDescription ->
            ( { model | description = newDescription }, Nothing )

        Increment ->
            ( { model | count = model.count + 1, struck = False }, Nothing )

        ToggleStrikethrough ->
            ( { model | struck = not model.struck, count = 0 }, Nothing )

        Delete ->
            ( model, Just model.id )



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ viewCounter model
        , div []
            [ button
                [ onClick ToggleStrikethrough ]
                [ text "--" ]
            ]
        , div [] [ viewDesc model ]
        ]


viewWithRemoveButton : Model -> Html Msg
viewWithRemoveButton model =
    li
        []
        [ viewCounter model
        , viewDesc model
        , span
            []
            [ button
                [ onClick Delete ]
                [ text "×" ]
            , button
                [ onClick ToggleStrikethrough ]
                [ text "--" ]
            ]
        ]


viewDesc : Model -> Html Msg
viewDesc model =
    span
        [ contenteditable True ]
        [ span
            [ onInput Update ]
            [ text model.description ]
        ]


viewCounter : Model -> Html Msg
viewCounter model =
    span []
        [ button
            [ onClick Increment ]
            [ case model.kind of
                FirstKind ->
                    text "+"

                SecondKind ->
                    text "*"

                ThirdKind ->
                    text Util.delta
            ]
        , div [] [ text (toString model.count) ]
        ]



-- UTILITIES


hue : Kind -> String
hue kind =
    case kind of
        FirstKind ->
            "115"

        ThirdKind ->
            "0"

        _ ->
            "55"


lightness : Int -> String
lightness counter =
    let
        scaled =
            clamp 0 5 counter
    in
        100 - 10 * scaled |> toString


obsValue : Model -> Int
obsValue behavior =
    case behavior.kind of
        FirstKind ->
            behavior.count

        ThirdKind ->
            behavior.count * -1

        _ ->
            0
