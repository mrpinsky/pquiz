module Quiz.Observation.Style
    exposing
        ( Style
        , Msg
        , update
        , view
        , viewAsButton
        )

import Css exposing (Color)
import Css.Colors as Colors
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Tagged exposing (Tagged)
import Util exposing ((=>), onChange, delta, encodeColor, colorDecoder, Handlers, styles)


type alias Style r =
    { r
        | symbol : String
        , label : String
        , color : Color
        , weight : Int
        , textColor : Color
    }



-- UPDATE


type Msg
    = UpdateSymbol String
    | UpdateLabel String
    | UpdateColor Color
    | UpdateWeight Int
    | UpdateTextColor Color


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

        UpdateTextColor color ->
            { style | textColor = color }


view : Handlers Msg msg p -> Style r -> Html msg
view {onUpdate, remove } style =
    div []
        [ div [ class "row" ]
            [ viewField "Label"
                [ onChange UpdateLabel
                , value style.label
                , class "label"
                ]
                |> Html.map onUpdate
            , button [ onClick remove, class "remove" ] [ text "x" ]
            ]
        , Html.map onUpdate <| div [ class "row small-fields" ]
            [ viewField "Symbol"
                [ onChange UpdateSymbol
                , maxlength 1
                , value style.symbol
                , class "symbol"
                ]
            , viewField "Background"
                [ onInput (UpdateColor << Css.hex)
                , type_ "color"
                , value style.color.value
                , class "background"
                ]
            -- , viewField "Text Color"
            --     [ type_ "color"
            --     , class "color"
            --     , onInput (UpdateTextColor << Css.hex)
            --     , value style.textColor.value
            --     ]
            , viewField "Weight"
                [ onChange (UpdateWeight << parseWeight style.weight)
                , type_ "number"
                , value <| toString style.weight
                , class "weight"
                ]
            ]
        ]


viewAsButton : List (Attribute msg) -> Style r -> Html msg
viewAsButton attrs { color, label } =
    let
        attributes =
            [ class "topic button"
            , styles [ Css.backgroundColor color ]
            ]
                ++ attrs
    in
        button attributes [ text label ]


viewField : String -> List (Attribute Msg) -> Html Msg
viewField label attributes =
    Html.label [ class "field" ]
        [ div [] [ text label ]
        , input attributes []
        ]



-- UTIL


parseWeight : Int -> String -> Int
parseWeight default input =
    String.toInt input
        |> Result.toMaybe
        |> Maybe.withDefault default
