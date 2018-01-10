module Quiz.Observation.Style
    exposing
        ( Style
        , Msg
        , update
        , view
        , viewAsButton
        )

import Css exposing (Color)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Util
    exposing
        ( (=>)
        , onChange
        , delta
        , encodeColor
        , colorDecoder
        , Handlers
        , styles
        , viewField
        , faded
        )


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


view : Handlers Msg msg p -> Style r -> Html msg
view { onUpdate, remove } style =
    div []
        [ div [ class "row" ]
            [ input
                [ onChange UpdateLabel
                , value style.label
                , class "label"
                ]
                []
                |> viewField "Label"
                |> Html.map onUpdate
            , button [ onClick remove, class "remove" ] [ text "x" ]
            ]
        , Html.map onUpdate <|
            div [ class "row small-fields" ]
                [ input
                    [ onChange UpdateSymbol
                    , maxlength 1
                    , value style.symbol
                    , class "symbol"
                    ]
                    []
                    |> viewField "Symbol"
                , input
                    [ onInput (UpdateColor << Css.hex)
                    , type_ "color"
                    , value style.color.value
                    , class "background"
                    ]
                    []
                    |> viewField "Background"

                -- , input
                --     [ onChange (UpdateWeight << parseWeight style.weight)
                --     , type_ "number"
                --     , value <| toString style.weight
                --     , class "weight"
                --     ]
                --     []
                --     |> viewField "Weight"
                ]
        ]


viewAsButton : List (Attribute msg) -> Style r -> Html msg
viewAsButton attrs { color, label } =
    let
        attributes =
            [ class "topic button"
            , styles [ Css.backgroundColor <| faded color ]
            ]
                ++ attrs
    in
        button attributes [ text label ]



-- UTIL


parseWeight : Int -> String -> Int
parseWeight default input =
    String.toInt input
        |> Result.toMaybe
        |> Maybe.withDefault default
