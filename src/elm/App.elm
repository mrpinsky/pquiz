port module App exposing (main)

import Html exposing (..)
import Json.Decode as Decode
import Quiz.App as PQuiz
import Quiz.Settings as Settings


main : Program Decode.Value PQuiz.Model PQuiz.Msg
main =
    Html.programWithFlags
        { init = init
        , update = PQuiz.updateWithPorts
        , view = PQuiz.view
        , subscriptions = (\_ -> Sub.none)
        }


init : Decode.Value -> ( PQuiz.Model, Cmd msg )
init flags =
    ( initModel flags, Cmd.none )


initModel : Decode.Value -> PQuiz.Model
initModel value =
    Decode.decodeValue PQuiz.decoder value
        |> Result.withDefault (PQuiz.init 8 Settings.default)
