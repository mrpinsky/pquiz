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
    Style (Tagged Id)

type Id
    = Id Int


type alias Style r =
    { r | symbol : String
    , label : String
    , color : Color
    , weight : Int
    }


buildKind : Int -> String -> String -> Color -> Int -> Kind
buildKind id symbol label color weight =
    { tag = Id id
    , symbol = symbol
    , label = label
    , color = color
    , weight = weight
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


updateStyle : StyleMsg -> Style r -> Style r 
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


viewStyle : Style r -> Html StyleMsg
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


encode : Kind -> Encode.Value
encode kind =
    Encode.object
        [ "id" => encodeId kind.tag
        , "symbol" => Encode.string kind.symbol
        , "label" => Encode.string kind.label
        , "color" => encodeColor kind.color
        , "weight" => Encode.int kind.weight
        ]


encodeId : Id -> Encode.Value
encodeId (Id id) =
    Encode.int id


decoder : Decode.Decoder Kind
decoder =
    Decode.map5
        buildKind
        (Decode.field "id" Decode.int)
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
