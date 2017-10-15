module Quiz.App exposing (..)

import Html exposing (Html)
import Quiz.Quiz as Quiz exposing (Quiz)
import Quiz.Settings as Settings exposing (Settings)

-- MODEL


type alias Model =
    { settings: Settings
    , quiz : Quiz
    }


init : Settings -> Quiz -> Model
init settings quiz =
    Model settings quiz



-- UPDATE


type Msg
    = SettingsMsg Settings.Msg
    | QuizMsg Quiz.Msg


update : Msg -> Model -> Model
update msg model =
    case msg of
        SettingsMsg subMsg ->
            { model | settings = Settings.update subMsg model.settings }

        QuizMsg subMsg ->
            { model | quiz = Quiz.update subMsg model.quiz }


-- VIEW

view : Model -> Html Msg
view { settings, quiz } =
    Quiz.view settings quiz
        |> Html.map QuizMsg
