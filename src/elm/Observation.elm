module Observation exposing (Model, InternalMsg(Increment), init, Translator, translator, update, view, viewWithRemoveButton, obsValue)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Json
import Char
import String


-- MODEL


type alias Model =
    { description : String
    , count : Int
    , kind : Kind
    , editing : Bool
    , isActive : Bool
    , id : Int
    }


type alias Kind =
    String



--Positive | Negative | Neutral


kindFromInt : Int -> Kind
kindFromInt n =
    case n of
        1 ->
            "Positive"

        2 ->
            "Neutral"

        3 ->
            "Negative"

        _ ->
            "Neutral"


kindToInt : Kind -> Int
kindToInt k =
    case k of
        "Positive" ->
            1

        "Neutral" ->
            2

        "Negative" ->
            3

        _ ->
            0


init : String -> Int -> Int -> Model
init desc kNum id =
    let
        k =
            kindFromInt kNum
    in
        { description = desc
        , count = 1
        , kind = k
        , editing = False
        , isActive = True
        , id = id
        }



-- MESSAGING


type InternalMsg
    = Editing
    | Update String
    | Increment
    | ToggleStrikethrough


type OutMsg
    = Remove


type Msg
    = ForSelf InternalMsg
    | ForParent OutMsg


type alias TranslationDictionary parentMsg =
    { onInternalMessage : InternalMsg -> parentMsg
    , onRemove : parentMsg
    }


type alias Translator parentMsg =
    Msg -> parentMsg


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator { onInternalMessage, onRemove } msg =
    case msg of
        ForSelf internal ->
            onInternalMessage internal

        ForParent Remove ->
            onRemove



-- UPDATE


update : InternalMsg -> Model -> Model
update msg model =
    case msg of
        Editing ->
            { model | editing = not model.editing }

        Update newDescription ->
            { model | description = newDescription }

        Increment ->
            { model | count = model.count + 1, isActive = True }

        ToggleStrikethrough ->
            { model | isActive = not model.isActive, count = 0 }



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ classList
            [ ( "observation", True )
            , ( "kind-" ++ (toString <| kindToInt model.kind), True )
            , ( "count-" ++ (toString model.count), model.count < 6 )
            ]
        ]
        [ viewCounter model
        , div
            [ class "right-buttons"
            ]
            [ button [ onClick (ForSelf ToggleStrikethrough) ]
                [ text "--" ]
            ]
        , div [ class "description" ] [ viewDesc model ]
        ]


viewWithRemoveButton : Model -> Html Msg
viewWithRemoveButton model =
    li
        [ classList
            [ ( "observation", True )
            , ( "kind-" ++ (toString <| kindToInt model.kind), True )
            , ( "count-" ++ (toString model.count), model.count < 6 )
            ]
        ]
        [ viewCounter model
        , viewDesc model
        , span [ class "right-buttons" ]
            [ button [ onClick (ForParent Remove) ]
                [ text "×" ]
            , button [ onClick (ForSelf ToggleStrikethrough) ]
                [ text "--" ]
            ]
        ]


viewDesc : Model -> Html Msg
viewDesc model =
    span
        [ classList
            [ ( "description", True )
            , ( "editing", model.editing )
            ]
        ]
        [ input
            [ placeholder "Observation"
            , value model.description
            , onEnter (ForSelf Editing)
            , onInput (ForSelf << Update)
            , class "edit"
            ]
            []
        , span
            [ onDoubleClick (ForSelf Editing)
            , classList
                [ ( "view", True )
                , ( "struck", not model.isActive )
                ]
            ]
            [ text model.description ]
        ]


viewCounter : Model -> Html Msg
viewCounter model =
    span [ class "obs-counter" ]
        [ button
            [ onClick (ForSelf Increment)
            , class "increment"
            ]
            [ case model.kind of
                "Positive" ->
                    text "+"

                "Negative" ->
                    text delta

                _ ->
                    text "*"
            ]
        , div [ class "count" ] [ text (toString model.count) ]
        ]



-- UTILITIES


delta : String
delta =
    String.fromChar <| Char.fromCode 916


hue : Kind -> String
hue kind =
    case kind of
        "Positive" ->
            "115"

        "Negative" ->
            "0"

        _ ->
            "55"


lightness : Int -> String
lightness counter =
    let
        scaled =
            clamp 0 5 counter
    in
        100 - 10 * scaled |> toString


obsValue : Model -> Int
obsValue behavior =
    case behavior.kind of
        "Positive" ->
            behavior.count

        "Negative" ->
            behavior.count * -1

        _ ->
            0


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)
