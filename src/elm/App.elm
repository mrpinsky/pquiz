port module App exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Quiz.Quiz as Quiz exposing (Quiz, update, view)
import Quiz.Settings as Settings exposing (Settings, update, view)
import Util exposing (onContentEdit, (=>))


main : Program Never ( Quiz, Settings ) Msg
main =
    Html.beginnerProgram
        { model = ( Quiz.default, Settings.default )
        , update = update
        , view = view
        }


type Msg
    = QuizMsg Quiz.Msg
    | SettingsMsg Settings.Msg


update : Msg -> ( Quiz, Settings ) -> ( Quiz, Settings )
update msg ( quiz, settings ) =
    case msg of
        QuizMsg quizMsg ->
            ( Quiz.update quizMsg quiz, settings )

        SettingsMsg settingsMsg ->
            ( quiz, Settings.update settingsMsg settings )


view : ( Quiz, Settings.Settings ) -> Html Msg
view ( quiz, settings ) =
    div []
        [ Quiz.view settings quiz
            |> Html.map QuizMsg
        , Settings.view settings
            |> Html.map SettingsMsg
        ]
