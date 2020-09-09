module App exposing (main)

import Browser
import Html exposing (Html)
import Html.Styled
import Json.Decode as Decode
import Quiz.App as PQuiz
import Quiz.Settings as Settings


main : Program Decode.Value PQuiz.Model PQuiz.Msg
main =
    Browser.document
        { init = init
        , update = PQuiz.updateWithPorts
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : Decode.Value -> ( PQuiz.Model, Cmd msg )
init flags =
    ( initModel flags, Cmd.none )


initModel : Decode.Value -> PQuiz.Model
initModel value =
    Decode.decodeValue PQuiz.decoder value
        |> Result.withDefault (PQuiz.init 8 Settings.default)


view : PQuiz.Model -> Browser.Document PQuiz.Msg
view model =
    PQuiz.view model
        |> Html.Styled.toUnstyled
        |> document


document : Html PQuiz.Msg -> Browser.Document PQuiz.Msg
document html =
    { title = "PQuiz", body = [ html ] }
