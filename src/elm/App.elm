port module App exposing (main)

import Html exposing (..)
import Quiz.App as PQuiz
import Quiz.Settings as Settings


main : Program Never PQuiz.Model PQuiz.Msg
main =
    Html.program
        { init = (PQuiz.init 8 Settings.default, Cmd.none)
        , update = PQuiz.updateWithFocus
        , view = PQuiz.view
        , subscriptions = (\_ -> Sub.none)
        }
