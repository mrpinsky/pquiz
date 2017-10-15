port module App exposing (main)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Quiz.App as PQuiz
import Quiz.Settings as Settings exposing (Settings)
import Setup exposing (Setup)
-- import Util exposing (onContentEdit, (=>))


main : Program Never Page Msg
main =
    Html.beginnerProgram
        { model = SetupPage Setup.init
        , update = update
        , view = view
        }


type Page
    = SetupPage Setup
    | QuizPage PQuiz.Model


-- UPDATE


type Msg
    = SubMsg PageMsg
    | StartQuiz


type PageMsg
    = SetupMsg Setup.Msg
    | QuizMsg PQuiz.Msg


update : Msg -> Page -> Page
update msg page =
    case (msg, page) of
        (SubMsg pageMsg, _) ->
            updatePage pageMsg page

        (StartQuiz, SetupPage setup) ->
            QuizPage <| Setup.toQuiz setup

        _ ->
            page


updatePage : PageMsg -> Page -> Page
updatePage pageMsg page =
    case (pageMsg, page) of
        (SetupMsg msg, SetupPage setup) ->
            SetupPage <| Setup.update msg setup

        (QuizMsg msg, QuizPage pquiz) ->
            QuizPage <| PQuiz.update msg pquiz

        _ ->
            page


-- VIEW


view : Page -> Html Msg
view page =
    case page of
        SetupPage setup ->
            div []
                [ Html.map (SubMsg << SetupMsg) <| Setup.view setup
                , button [ onClick StartQuiz ] [ text "Start quiz" ]
                ]

        QuizPage pquiz ->
            PQuiz.view pquiz
                |> Html.map (SubMsg << QuizMsg)
