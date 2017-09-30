module Quiz.Kind
    exposing
        ( Kind
        , Style
        , Id
        , Msg
        , update
        , view
        , encode
        , decoder
        , encodeId
        , idDecoder
        )

import Css exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Tagged exposing (Tagged)
import Util exposing ((=>), delta, encodeColor, colorDecoder)


type alias Kind =
    { tag : Id
    , symbol : String
    , label : String
    , color : Color
    , weight : Int
    }


type Id
    = Id String


type alias Style r =
    { r
        | symbol : String
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


update : Msg -> Kind -> Kind
update (Update target subMsg) kind =
    Tagged.update (updateStyle subMsg) target kind


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


view : Kind -> Html Msg
view kind =
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
    Encode.string id


decoder : Decode.Decoder Kind
decoder =
    Decode.map5
        Kind
        (Decode.field "id" idDecoder)
        (Decode.field "symbol" Decode.string)
        (Decode.field "label" Decode.string)
        (Decode.field "color" colorDecoder)
        (Decode.field "weight" Decode.int)


idDecoder : Decode.Decoder Id
idDecoder =
    Decode.map Id Decode.string



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
