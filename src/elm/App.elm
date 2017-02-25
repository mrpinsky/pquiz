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


{-| The Program
-}
main : Program { user : Maybe User, quiz : Maybe PQ.Model } Model Msg
main =
    Navigation.programWithFlags
        (always NoOp)
        { init = init
        , view = view
        , update = updateWithStorage
        , subscriptions = \_ -> Sub.none
        }


port setLocalStorage : PQ.Model -> Cmd msg


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


init : { quiz : Maybe PQ.Model, user : Maybe User } -> Navigation.Location -> ( Model, Cmd Msg )
init { quiz, user } _ =
    ( Model (LoginInfo "" "") user (PQ.init quiz), Cmd.none )



-- MESSAGING


type Msg
    = ChildMsg PQ.Msg
      -- | LoadedModel (Result Http.Error String)
    | SendLoginRequest
    | RegisterLogin (Result Http.Error User)
    | NoOp


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
            [ setLocalStorage newModel.quiz
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
            , Http.send RegisterLogin << logInRequest <| LoginInfo "myEmail" ""
            )

        RegisterLogin (Ok user) ->
            ( { model | user = Just user }, cacheUserData <| encodeUser user )

        RegisterLogin (Err _) ->
            ( model, Cmd.none )

        NoOp ->
            model ! []


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
