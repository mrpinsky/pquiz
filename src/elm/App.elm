port module App exposing (main)

import Html exposing (..)
import Quiz.App as PQuiz
import Quiz.Settings as Settings


main : Program Never PQuiz.Model PQuiz.Msg
main =
    Html.beginnerProgram
        { model = PQuiz.init Settings.default
        , update = PQuiz.update
        , view = PQuiz.view
        }
