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
        , styles
        , viewField
        , faded
        )
import Util.Handlers as Handlers exposing (Handlers)


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
                |> viewField "Label" 8
                |> Html.map onUpdate
            , input
                [ onChange UpdateSymbol
                , maxlength 2
                , value style.symbol
                , class "symbol"
                ]
                []
                |> viewField "Symbol" 1
                |> Html.map onUpdate
            , input
                [ onInput (UpdateColor << Css.hex)
                , type_ "color"
                , value style.color.value
                , class "background"
                ]
                []
                |> viewField "Color" 1
                |> Html.map onUpdate
            , button
                [ onClick remove
                , class "fas fa-trash inverted delete-btn"
                ]
                []
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
