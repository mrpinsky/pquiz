module Util exposing (..)

import Char
import Css exposing (Color)
import Html exposing (Attribute)
import Html.Attributes
import Html.Events exposing (on, keyCode)
import Json.Encode as Encode
import Json.Decode as Decode
import KeyedList exposing (KeyedList)


type alias Tagged tag =
    { tag : tag }


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


encodeColor : Color -> Encode.Value
encodeColor color =
    Encode.object
        [ "red" => Encode.int color.red
        , "green" => Encode.int color.green
        , "blue" => Encode.int color.blue
        , "alpha" => Encode.float color.alpha
        ]


colorDecoder : Decode.Decoder Color
colorDecoder =
    Decode.map4
        Css.rgba
        (Decode.field "red" Decode.int)
        (Decode.field "green" Decode.int)
        (Decode.field "blue" Decode.int)
        (Decode.field "alpha" Decode.float)


encodeMaybe : (a -> Encode.Value) -> Maybe a -> Encode.Value
encodeMaybe encoder maybe =
    case maybe of
        Nothing ->
            Encode.null

        Just x ->
            encoder x


ordinal : Int -> String
ordinal n =
    case n of
        1 ->
            "first"

        2 ->
            "second"

        3 ->
            "third"

        _ ->
            "nth"


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


onEnter : msg -> Attribute msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed msg
            else
                Decode.fail "not ENTER"
    in
        on "keydown" (Decode.andThen isEnter keyCode)


onContentEdit : (String -> msg) -> Attribute msg
onContentEdit tagger =
    let
        innerHtmlDecoder =
            Decode.at [ "target", "innerHTML" ] Decode.string
    in
        on "blur" (Decode.map tagger innerHtmlDecoder)


styles : List Css.Style -> Html.Attribute msg
styles =
    Css.asPairs >> Html.Attributes.style


encodeKeyedList : (a -> Encode.Value) -> KeyedList a -> Encode.Value
encodeKeyedList encoder keyedList =
    KeyedList.toList keyedList
        |> List.map encoder
        |> Encode.list


keyedListDecoder : Decode.Decoder a -> Decode.Decoder (KeyedList a)
keyedListDecoder decoder =
    Decode.list decoder
        |> Decode.map KeyedList.fromList
