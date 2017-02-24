module Counter exposing (Model, Msg, init, view, update)

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


-- MODEL


type alias Model =
    Int


init : Int -> Model
init value =
    value



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model -> Html Msg
view model =
    span []
        [ button [ onClick Decrement ]
            [ text "-" ]
        , span [ class "counter" ]
            [ text (toString model) ]
        , button [ onClick Increment ]
            [ text "+" ]
        ]
