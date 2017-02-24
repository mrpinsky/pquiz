port module App exposing (main)

{-| This module serves as an entry point for the PQuiz app
and will allow further expansion as needed

# Main
@docs main

-}

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json
import OAuth


-- import Html.Lazy exposing (..)

import PQuiz as PQ


{-| The Program
-}
main : Program (Maybe Model) Model Msg
main =
    Html.programWithFlags
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = \_ -> Sub.none
        }


port setLocalStorage : Model -> Cmd msg


port focus : String -> Cmd msg



-- MODEL


type alias LoginInfo =
    { email : String
    , password : String
    }


type alias User =
    { id : Int
    , name : String
    , email : String
    }


type alias Model =
    { login : LoginInfo
    , user : Maybe User
    , quiz : PQ.Model
    }


baseModel : Model
baseModel =
    Model (LoginInfo "" "") Nothing (PQ.init Nothing)


init : Maybe Model -> ( Model, Cmd Msg )
init savedModel =
    Maybe.withDefault baseModel savedModel ! []



-- MESSAGING


type Msg
    = ChildMsg PQ.Msg
      -- | LoadedModel (Result Http.Error String)
    | SendLoginRequest
    | RegisterLogin (Result Http.Error User)


{-| We want to `setLocalStorage` on every update. This function adds the setLocalStorage
command for every step of the update function.
-}
updateWithStorage : Msg -> Model -> ( Model, Cmd Msg )
updateWithStorage msg model =
    let
        ( newModel, cmds ) =
            update msg model
    in
        ( newModel
        , Cmd.batch
            [ setLocalStorage newModel
            , cmds
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChildMsg pqMsg ->
            let
                ( quiz, cmds ) =
                    PQ.update pqMsg model.quiz
            in
                ( { model | quiz = quiz }, Cmd.map ChildMsg cmds )

        SendLoginRequest ->
            ( { model | login = LoginInfo "" "" }
            , Http.send RegisterLogin (logInRequest model.login)
            )

        RegisterLogin (Ok user) ->
            ( { model | user = Just user }, Cmd.none )

        RegisterLogin (Err _) ->
            ( model, Cmd.none )


logInRequest : LoginInfo -> Http.Request User
logInRequest login =
    Http.request
        { method = "GET"
        , headers = [ Http.header "Authorization" "Bearer aa" ]
        , url = "http://localhost:4000/api/users/1"
        , body = Http.emptyBody
        , expect = expectUser
        , timeout = Nothing
        , withCredentials = False
        }


decodeUser : Json.Decoder User
decodeUser =
    Json.map3
        User
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.field "email" Json.string)


expectUser : Http.Expect User
expectUser =
    Http.expectJson decodeUser



-- VIEW


view : Model -> Html Msg
view model =
    let
        msg =
            PQ.view model.quiz
    in
        div []
            [ navbar model.user
            , Html.map ChildMsg msg
            ]


navbar : Maybe User -> Html Msg
navbar user =
    case user of
        Nothing ->
            div
                [ style
                    [ ( "background", "black" )
                    , ( "color", "white" )
                    ]
                ]
                [ button [ onClick SendLoginRequest ] [ text "login" ] ]

        Just userData ->
            div
                [ style
                    [ ( "background", "black" )
                    , ( "color", "white" )
                    ]
                ]
                [ text userData.name ]
