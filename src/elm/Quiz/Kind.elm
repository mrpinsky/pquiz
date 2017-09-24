module Quiz.Kind
    exposing
        ( Kind
        , KindSettings
        , defaultKinds
        , update
        , Msg
        , view
        , encodeKind
        , kindDecoder
        )

import Css exposing (Color)
import Css.Colors
import Dict exposing (Dict)
import Html exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Util exposing ((=>), delta )


type alias Kind =
    { symbol : String
    , color : Color
    , weight : Int
    }


type alias KindSettings =
    Dict String Kind


type Msg
    = ChangeSymbol String
    | ChangeColor String
    | ChangeWeight Int


update : Msg -> Kind -> Kind
update msg kind =
    case msg of
        ChangeSymbol newSymbol ->
            { kind | symbol = newSymbol }

        ChangeColor colorString ->
            { kind | color = Css.hex colorString }

        ChangeWeight newWeight ->
            { kind | weight = newWeight }


view : Kind -> Html Msg
view kind =
    Html.form
        []
        [ Html.label []
            [ text "Symbol"
            , input [ onEnter ChangeSymbol ] []
            ]
        , Html.label []
            [ text "Color"
            , input [ onEnter ChangeColor ] []
            ]
        , Html.label []
            [ text "Weight"
            , input [ onEnter (ChangeWeight << parseWeight) ] []
            ]
        ]


parseWeight : String -> Int
parseWeight input =
    case (String.toInt input) of
        Ok weight ->
            weight

        Err _ ->
            0


defaultKinds : KindSettings
defaultKinds =
    let
        green =
            { symbol = "^", color = Css.Colors.aqua, weight = 2 }

        white =
            { symbol = "&", color = Css.Colors.teal, weight = 5 }

        red =
            { symbol = "%", color = Css.Colors.lime, weight = 3 }
    in
        Dict.fromList
            [ "green" => green
            , "white" => white
            , "red" => red
            ]


encodeKind : Kind -> Encode.Value
encodeKind kind =
    Encode.object
        [ "symbol" => Encode.string kind.symbol
        , "color" => encodeColor kind.color
        , "weight" => Encode.int kind.weight
        ]


encodeColor : Color -> Encode.Value
encodeColor color =
    Encode.object
        [ "red" => Encode.int color.red
        , "green" => Encode.int color.green
        , "blue" => Encode.int color.blue
        , "alpha" => Encode.float color.alpha
        ]


kindDecoder : Decode.Decoder Kind
kindDecoder =
    Decode.map3
        Kind
        (Decode.field "symbol" Decode.string)
        (Decode.field "color" colorDecoder)
        (Decode.field "weight" Decode.int)


colorDecoder : Decode.Decoder Color
colorDecoder =
    Decode.map4
        Css.rgba
        (Decode.field "red" Decode.int)
        (Decode.field "green" Decode.int)
        (Decode.field "blue" Decode.int)
        (Decode.field "alpha" Decode.float)


-- UTIL

onEnter : (String -> msg) -> Attribute msg
onEnter tagger =
    keyCode
        |> Decode.andThen (onEnterHelper tagger)
        |> on "keydown"


onEnterHelper : (String -> msg) -> Int -> Decode.Decoder msg
onEnterHelper tagger code =
    if code == 13 then
        Html.Events.targetValue
            |> Decode.map tagger
    else
        Decode.fail "not ENTER"


