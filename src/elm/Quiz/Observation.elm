module Quiz.Observation
    exposing
        ( Observation
        , Msg
        , init
        , update
        , view
        , viewStatic
        , viewAsProto
        , encode
        , decoder
        )

import Css
import Html exposing (..)
import Html.Attributes as Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Quiz.Theme as Theme exposing (Theme, Topic)
import Util
    exposing
        ( (=>)
        , checkmark
        , emdash
        , styles
        , onChange
        , onEnter
        , Handlers
        , viewField
        )


-- MODEL


type alias Observation =
    { style : Theme.Id
    , label : String
    }


type alias Id =
    String


type alias Style r =
    { r
        | symbol : String
        , label : String
        , color : Css.Color
        , weight : Int
    }


init : Theme.Id -> Observation
init style =
    Observation style ""



-- UPDATE


type Msg
    = UpdateLabel String
    | UpdateStyle Theme.Id


update : Msg -> Observation -> Observation
update msg observation =
    case msg of
        UpdateLabel newLabel ->
            { observation | label = newLabel }

        UpdateStyle newStyle ->
            { observation | style = newStyle }



-- VIEW


view : Observation -> Html Msg
view observation =
    viewGeneral (Just UpdateLabel) observation


viewStatic : Observation -> Html msg
viewStatic observation =
    viewGeneral Nothing observation


viewGeneral : Maybe (String -> msg) -> Observation -> Html msg
viewGeneral maybeInputTagger { label } =
    let
        inputAttributes =
            case maybeInputTagger of
                Nothing ->
                    [ class "static" ]

                Just tagger ->
                    [ contenteditable True
                    , onInput tagger
                    ]

        attributes =
            inputAttributes ++ [ class "label" ]
    in
        span attributes [ Html.text label ]


viewAsProto : Handlers Msg msg r -> Theme -> Observation -> Html msg
viewAsProto { onUpdate, remove } theme observation =
    li [ class "observation" ]
        [ theme
            |> Theme.toList
            |> List.map (viewSelectableStyle observation.style)
            |> select [ onChange UpdateStyle, class "topic" ]
            |> viewField "Category" 1
            |> Html.map onUpdate
        , viewToRelabel observation
            |> viewField "Description" 3
            |> Html.map onUpdate
        , button [ class "inline-remove inverted large", onClick remove ] [ text "×" ]
        ]


viewToRelabel : Observation -> Html Msg
viewToRelabel { label } =
    input
        [ value label
        , onChange UpdateLabel
        , class "label editable"
        ]
        []


viewSelectableStyle : Theme.Id -> Topic -> Html Msg
viewSelectableStyle currentlySelected { id, label } =
    Html.option
        [ selected <| currentlySelected == id
        , value id
        , class "topic"
        ]
        [ Html.text label ]



-- JSON


decoder : Decoder Observation
decoder =
    Decode.map2
        Observation
        (Decode.field "style" Theme.idDecoder)
        (Decode.field "label" Decode.string)


encode : Observation -> Encode.Value
encode { style, label } =
    Encode.object
        [ "style" => Theme.encodeId style
        , "label" => Encode.string label
        ]
