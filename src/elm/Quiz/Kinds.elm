module Quiz.Kinds exposing (Kinds, Style, Msg, update, view, encode, decoder)

import Css exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Util exposing (Tagged, (=>), delta, encodeColor, colorDecoder)


type alias Kinds =
    List Kind


type alias Kind =
    Tagged Id Style


type Id
    = Id Int


type alias Style =
    { symbol : String
    , label : String
    , color : Color
    , weight : Int
    }


-- UPDATE


type Msg
    = Update Id StyleMsg


type StyleMsg
    = UpdateSymbol String
    | UpdateLabel String
    | UpdateColor Color
    | UpdateWeight Int


update : Msg -> Kinds -> Kinds
update (Update target subMsg) kinds =
    let
        updateHelper : Kind -> Kind
        updateHelper kind =
            if kind.tag == target then
                updateStyle subMsg kind
            else
                kind
    in
        List.map updateHelper kinds


updateStyle : StyleMsg -> Style -> Style
updateStyle msg style =
    case msg of
        UpdateSymbol symbol ->
            { style | symbol = symbol }

        UpdateLabel label ->
            { style | label = label }

        UpdateColor color ->
            { style | color = color }

        UpdateWeight weight ->
            { style | weight = weight }



view : Kinds -> Html Msg
view kinds =
    div [] <| List.map viewKind kinds


viewKind : Kind -> Html Msg
viewKind kind =
    Html.map (Update kind.tag) <| viewStyle kind


viewStyle : Style -> Html StyleMsg
viewStyle style =
    Html.form
        []
        [ Html.label []
            [ text "Symbol"
            , input
                [ onEnter UpdateSymbol
                , type_ "text"
                , maxlength 1
                , value style.symbol
                ]
                []
            ]
        , Html.label []
            [ text "Label"
            , input
                [ onEnter UpdateLabel
                , type_ "text"
                , value style.label
                ]
                []
            ]
        , Html.label []
            [ text "Color"
            , input
                [ onInput (UpdateColor << Css.hex)
                , type_ "color"
                , value style.color.value
                ]
                []
            ]
        , Html.label []
            [ text "Weight"
            , input
                [ onEnter (UpdateWeight << parseWeight style.weight)
                , type_ "number"
                , value <| toString style.weight
                ]
                []
            ]
        ]


encode : Style -> Encode.Value
encode style =
    Encode.object
        [ "symbol" => Encode.string style.symbol
        , "label" => Encode.string style.label
        , "color" => encodeColor style.color
        , "weight" => Encode.int style.weight
        ]


decoder : Decode.Decoder Style
decoder =
    Decode.map4
        Style
        (Decode.field "symbol" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "color" colorDecoder)
        (Decode.field "weight" Decode.int)



-- UTIL


parseWeight : Int -> String -> Int
parseWeight default input =
    String.toInt input
        |> Result.toMaybe
        |> Maybe.withDefault default


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
