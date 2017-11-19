port module Ports exposing (..)

import Json.Encode exposing (Value)

port focus : Int -> Cmd msg

port cacheQuiz : Value -> Cmd msg
