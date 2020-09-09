module Quiz.Observation exposing
    ( MenuContent
    , Msg
    , Observation
    , decoder
    , encode
    , init
    , update
    , view
    , viewAsProto
    , viewStatic
    )

import Css
import Html.Styled as Html exposing (..)
import Html.Styled.Attributes as Attributes exposing (..)
import Html.Styled.Events as Events exposing (..)
import Html.Styled.Lazy as Lazy exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Quiz.Theme as Theme exposing (Theme, Topic)
import Util
    exposing
        ( checkmark
        , emdash
        , onChange
        , onEnter
        , onKeyPress
        , viewField
        )
import Util.Handlers as Handlers exposing (Handlers)



-- MODEL


type alias Observation =
    { editState : EditState
    , style : Theme.Id
    , label : String
    }


type alias Id =
    String


type EditState
    = Editing
    | NotEditing


type alias Style r =
    { r
        | symbol : String
        , label : String
        , color : Css.Color
        , weight : Int
    }


init : Theme.Id -> String -> Observation
init =
    Observation NotEditing



-- UPDATE


type Msg
    = UpdateLabel String
    | UpdateStyle Theme.Id
    | StartEditing
    | StopEditing


update : Msg -> Observation -> Observation
update msg observation =
    case msg of
        UpdateLabel newLabel ->
            { observation | label = newLabel }

        UpdateStyle newStyle ->
            { observation | style = newStyle }

        StartEditing ->
            { observation | editState = Editing }

        StopEditing ->
            { observation | editState = NotEditing }



-- VIEW


view : Handlers Msg msg r -> MenuContent msg -> Observation -> Html msg
view { onUpdate } { color, startContent, endContent } observation =
    div [ class "container" ]
        [ lazy viewStartMenu startContent
        , lazy viewLabel observation
            |> Html.map onUpdate
        , lazy2 viewEndMenu color endContent
        ]


viewStatic : MenuContent msg -> Observation -> Html msg
viewStatic { color, startContent } { label } =
    div [ class "container" ]
        [ lazy viewStartMenu startContent
        , span [ class "label" ] [ Html.text label ]
        ]


viewStartMenu : List (Html msg) -> Html msg
viewStartMenu content =
    div [ class "buttons start" ] content


viewEndMenu : Css.Color -> List (Html msg) -> Html msg
viewEndMenu color content =
    div
        [ class "buttons end unobtrusive"
        , css [ Css.backgroundColor color ]
        ]
        content


type alias MenuContent msg =
    { color : Css.Color
    , startContent : List (Html msg)
    , endContent : List (Html msg)
    }


viewLabel : Observation -> Html Msg
viewLabel { label, editState } =
    case editState of
        Editing ->
            textarea
                [ class "label editing"
                , onInput UpdateLabel
                , onBlur StopEditing
                , value label
                ]
                []

        NotEditing ->
            span [ class "label", onClick StartEditing ] [ Html.text label ]


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
        , button [ class "fas fa-trash inverted delete-btn", onClick remove ] []
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
    Decode.map3
        Observation
        (Decode.succeed NotEditing)
        (Decode.field "style" Theme.idDecoder)
        (Decode.field "label" Decode.string)


encode : Observation -> Encode.Value
encode { style, label } =
    Encode.object
        [ ( "style", Theme.encodeId style )
        , ( "label", Encode.string label )
        ]
