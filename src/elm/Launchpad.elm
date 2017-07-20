module Launchpad exposing (Model, update, view)

import Html exposing (div, h2)
import Html.Attributes exposing (onClick)


init : Model
init =
    []



-- MODEL


type alias Resource =
    { typeName : String
    , id : Int
    , title : String
    }


type alias Model =
    List Resource



-- UPDATE


type Msg
    = Add Resource
    | Remove Int


update : Msg -> Model -> ( Model, Maybe Int )
update msg model =
    case msg of
        Add resource ->
            ( List.append model resource, Nothing )

        Remove id ->
            ( List.filter (\r -> r.id /= id) model, Nothing )



-- VIEW


view : model -> Html Msg
view model =
    div [ onClick ] [ h2 model.title ]
