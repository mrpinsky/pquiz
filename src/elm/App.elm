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
import Navigation
import Json.Encode as Encode
import Json.Decode as Decode


-- import OAuth
-- import Html.Lazy exposing (..)

import Quiz as PQ
import Util exposing (onContentEdit, (=>))


{-| The Program
-}
main : Program { user : Maybe User, quiz : Maybe Decode.Value } Model Msg
main =
    Navigation.programWithFlags
        (always NoOp)
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = \_ -> Sub.none
        }


port saveQuizLocal : Encode.Value -> Cmd msg


port cacheUserData : String -> Cmd msg


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
    , token : String
    }


encodeUser : User -> String
encodeUser user =
    Encode.object
        [ ( "id", Encode.int user.id )
        , ( "name", Encode.string user.name )
        , ( "email", Encode.string user.email )
        , ( "token", Encode.string user.token )
        ]
        |> Encode.encode 0


type alias Model =
    { login : LoginInfo
    , user : Maybe User
    , quiz : PQ.Model
    }


baseModel : Model
baseModel =
    Model (LoginInfo "" "") Nothing (PQ.init Nothing)


init : { quiz : Maybe Encode.Value, user : Maybe User } -> Navigation.Location -> ( Model, Cmd Msg )
init { quiz, user } _ =
    let
        actualQuiz =
            PQ.init quiz
    in
        ( Model (LoginInfo "" "") user actualQuiz, Cmd.none )



-- MESSAGING


type Msg
    = ChildMsg PQ.Msg
      -- | LoadedModel (Result Http.Error String)
    | SendLoginRequest
    | RegisterLogin (Result Http.Error User)
    | Toast (Result Http.Error Bool)
    | SaveQuiz
    | NoOp


{-| We want to `saveQuizLocal` on every update. This function adds the saveQuizLocal
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
            [ saveQuizLocal <| PQ.toJSON newModel.quiz
            , cmds
            ]
        )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChildMsg pqMsg ->
            let
                ( quiz, qCmds, toFocus ) =
                    PQ.update pqMsg model.quiz

                childCmds =
                    Cmd.map ChildMsg qCmds

                cmds =
                    case toFocus of
                        Nothing ->
                            childCmds

                        Just elId ->
                            Cmd.batch [ focus elId, childCmds ]
            in
                ( { model | quiz = quiz }, cmds )

        SendLoginRequest ->
            ( { model | login = LoginInfo "" "" }
            , Http.send RegisterLogin << logInRequest <| LoginInfo "myEmail" ""
            )

        RegisterLogin (Ok user) ->
            ( { model | user = Just user }, cacheUserData <| encodeUser user )

        RegisterLogin (Err _) ->
            ( model, Cmd.none )

        SaveQuiz ->
            case model.user of
                Nothing ->
                    ( model, Cmd.none )

                Just user ->
                    ( model, saveQuiz user.token model.quiz )

        Toast result ->
            model ! []

        NoOp ->
            model ! []


saveQuiz : String -> PQ.Model -> Cmd Msg
saveQuiz token quiz =
    let
        ( method, quizId ) =
            case quiz.id of
                Nothing ->
                    ( "POST", "" )

                Just id ->
                    ( "PATCH", toString quiz.id )
    in
        Http.request
            { method = method
            , headers = [ Http.header "Authorization" token ]
            , url = "http://localhost:4000/api/quizzes/" ++ quizId
            , body = Http.jsonBody <| PQ.toJSON quiz
            , expect = Http.expectJson Decode.bool
            , timeout = Nothing
            , withCredentials = False
            }
            |> Http.send Toast


logInRequest : LoginInfo -> Http.Request User
logInRequest login =
    Http.request
        { method = "POST"
        , headers = []
        , url = "http://localhost:4000/api/login"
        , body =
            Encode.object [ ( "email", Encode.string login.email ) ]
                |> Http.jsonBody
        , expect = expectUser
        , timeout = Nothing
        , withCredentials = False
        }


decodeUser : Decode.Decoder User
decodeUser =
    Decode.map4
        User
        (Decode.field "id" Decode.int)
        (Decode.field "name" Decode.string)
        (Decode.field "email" Decode.string)
        (Decode.field "bearer_token" Decode.string)


expectUser : Http.Expect User
expectUser =
    Http.expectJson decodeUser



-- VIEW


view : Model -> Html Msg
view model =
    let
        quizView =
            PQ.view model.quiz
    in
        div []
            [ navbar model.quiz model.user
            , Html.map ChildMsg quizView
            ]


navbar : PQ.Model -> Maybe User -> Html Msg
navbar quiz user =
    div
        [ style
            [ "background" => "black"
            , "color" => "white"
            , "display" => "flex"
            , "flex" => "0 0 row"
            , "align-items" => "flex-end"
            ]
        ]
        (navbarContents quiz user)


title : String -> Html Msg
title t =
    div
        [ contenteditable True
        , onContentEdit (PQ.Rename >> ChildMsg)
        , style [ "width" => "50%" ]
        ]
        [ text t ]


navbarContents : PQ.Model -> Maybe User -> List (Html Msg)
navbarContents quiz user =
    case user of
        Nothing ->
            [ button [ onClick SendLoginRequest ] [ text "login" ] ]

        Just userData ->
            [ title quiz.title
            , saveButton
            , text userData.name
            ]


saveButton : Html Msg
saveButton =
    div
        [ style
            [ "background" => "white"
            , "color" => "black"
            , "padding" => "5px"
            ]
        , onClick SaveQuiz
        ]
        [ text "save quiz" ]
