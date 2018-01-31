module Util exposing (..)

import Char
import Css exposing (Color)
import Html exposing (Html, Attribute, div, button, text)
import Html.Attributes as Attributes exposing (class)
import Html.Events exposing (on, onWithOptions, keyCode, onClick)
import Json.Encode as Encode
import Json.Decode as Decode
import KeyedList exposing (KeyedList)


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


viewStaticTally : String -> Html msg
viewStaticTally label =
    div [ class "tally" ] [ Html.text label ]


viewLiveTally : msg -> String -> Html msg
viewLiveTally incrementMsg label =
    button
        [ onClick incrementMsg
        , class "tally"
        ]
        [ Html.text label ]


encodeColor : Color -> Encode.Value
encodeColor color =
    Encode.string color.value


colorDecoder : Decode.Decoder Color
colorDecoder =
    Decode.map Css.hex Decode.string


encodeMaybe : (a -> Encode.Value) -> Maybe a -> Encode.Value
encodeMaybe encoder maybe =
    case maybe of
        Nothing ->
            Encode.null

        Just x ->
            encoder x


stringFromCode : Int -> String
stringFromCode =
    Char.fromCode >> String.fromChar


delta : String
delta =
    stringFromCode 916


emdash : String
emdash =
    stringFromCode 8212


checkmark : String
checkmark =
    stringFromCode 10004


onEnter : (String -> msg) -> Attribute msg
onEnter toMsg =
    let
        isEnter code =
            if code == 13 then
                Decode.at [ "target", "value" ] Decode.string
                    |> Decode.map toMsg
            else
                Decode.fail "not ENTER"
    in
        on "keydown" (Decode.andThen isEnter keyCode)


onChange : (String -> msg) -> Attribute msg
onChange toMsg =
    on "change" (Decode.map toMsg innerHtmlDecoder)


onBlurWithValue : (String -> msg) -> Attribute msg
onBlurWithValue toMsg =
    on "blur" (Decode.map toMsg innerHtmlDecoder)


onClickWithoutPropagation : msg -> Html.Attribute msg
onClickWithoutPropagation msg =
    onWithOptions "click"
        { stopPropagation = True, preventDefault = False }
        (Decode.succeed msg)


innerHtmlDecoder : Decode.Decoder String
innerHtmlDecoder =
    Decode.at [ "target", "value" ] Decode.string


viewWithRemoveButton : msg -> Html msg -> Html msg
viewWithRemoveButton msg html =
    div []
        [ html
        , button [ onClick msg ] [ text "x" ]
        ]


styles : List Css.Style -> Html.Attribute msg
styles =
    Css.asPairs >> Attributes.style


encodeKeyedList : (a -> Encode.Value) -> KeyedList a -> Encode.Value
encodeKeyedList encoder keyedList =
    KeyedList.toList keyedList
        |> List.map encoder
        |> Encode.list


keyedListDecoder : Decode.Decoder a -> Decode.Decoder (KeyedList a)
keyedListDecoder decoder =
    Decode.list decoder
        |> Decode.map KeyedList.fromList


subdivide : Int -> List a -> List (List a)
subdivide subSize list =
    if List.length list <= subSize then
        List.singleton list
    else
        list
            |> List.drop subSize
            |> subdivide subSize
            |> (::) (List.take subSize list)


type alias Handlers childMsg parentMsg r =
    { r
        | onUpdate : childMsg -> parentMsg
        , remove : parentMsg
    }


fade : Css.Color -> Int -> Css.Color
fade { red, green, blue } tally =
    let
        opaqueAt =
            10

        curve =
            sqrt

        alpha =
            toFloat tally
                |> curve
                |> normalize (curve opaqueAt)
    in
        Css.rgba red green blue alpha


faded : Css.Color -> Css.Color
faded color =
    fade color 1


normalize : Float -> Float -> Float
normalize max scaled =
    scaled / max


viewField : String -> Int -> Html msg -> Html msg
viewField label flex inputEl =
    Html.label [ Attributes.class "field", styles [ Css.flex <| Css.int flex ] ]
        [ div [] [ Html.text label ]
        , inputEl
        ]
