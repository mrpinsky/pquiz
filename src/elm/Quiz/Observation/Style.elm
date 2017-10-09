module Quiz.Observation.Style
    exposing
        ( Style
        , Msg
        , update
        , view
        )

import Css exposing (Color)
import Css.Colors as Colors
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Tagged exposing (Tagged)
import Util exposing ((=>), onChange, delta, encodeColor, colorDecoder)


type alias Style r =
    { r
        | symbol : String
        , label : String
        , color : Color
        , weight : Int
    }


-- UPDATE


type Msg
    = UpdateSymbol String
    | UpdateLabel String
    | UpdateColor Color
    | UpdateWeight Int


update : Msg -> Style r -> Style r
update msg style =
    case msg of
        UpdateSymbol symbol ->
            { style | symbol = symbol }

        UpdateLabel label ->
            { style | label = label }

        UpdateColor color ->
            { style | color = color }

        UpdateWeight weight ->
            { style | weight = weight }


view : Style r -> Html Msg
view { symbol, label, color, weight } =
    Html.form
        []
        [ Html.label []
            [ text "Symbol"
            , input
                [ onChange UpdateSymbol
                , type_ "text"
                , maxlength 1
                , value symbol
                ]
                []
            ]
        , Html.label []
            [ text "Label"
            , input
                [ onChange UpdateLabel
                , type_ "text"
                , value label
                ]
                []
            ]
        , Html.label []
            [ text "Color"
            , input
                [ onInput (UpdateColor << Css.hex)
                , type_ "color"
                , value color.value
                ]
                []
            ]
        , Html.label []
            [ text "Weight"
            , input
                [ onChange (UpdateWeight << parseWeight weight)
                , type_ "number"
                , value <| toString weight
                ]
                []
            ]
        ]


-- UTIL


parseWeight : Int -> String -> Int
parseWeight default input =
    String.toInt input
        |> Result.toMaybe
        |> Maybe.withDefault default
