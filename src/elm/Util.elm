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


listify : a -> List a
listify item =
    [ item ]


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


delta : String
delta =
    String.fromChar <| Char.fromCode 916


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
