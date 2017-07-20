module Util exposing (..)

import Html exposing (Attribute)
import Html.Events exposing (on, keyCode)
import Json.Encode as Encode
import Json.Decode as Decode
import Char


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


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
onContentEdit msg =
    let
        innerHtmlDecoder =
            Decode.at [ "target", "innerHTML" ] Decode.string
    in
        on "blur" (Decode.map msg innerHtmlDecoder)
