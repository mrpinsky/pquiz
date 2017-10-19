module Quiz.App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import KeyedList exposing (KeyedList, Key)
import Json.Encode as Encode
import Json.Decode as Decode
import Quiz.Group as Group exposing (Group)
import Quiz.Observation as Observation exposing (Observation)
import Quiz.Settings as Settings exposing (Settings)
import Util exposing ((=>), encodeKeyedList, keyedListDecoder, viewWithRemoveButton)


main : Program Never Model Msg
main =
    Html.beginnerProgram
        { model = init Settings.default
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { state : State
    , settings : Settings
    , groups : KeyedList Group
    }


type State
    = Setup
    | Active


init : Settings -> Model
init settings =
    Model Active settings <| buildGroups 8 settings


buildGroups : Int -> Settings -> KeyedList Group
buildGroups count settings =
    Settings.defaultObservations settings
        |> withGroups count


blankGroups : Int -> KeyedList Group
blankGroups count =
    withGroups count []


withGroups : Int -> List Observation -> KeyedList Group
withGroups count observations =
    List.range 1 count
        |> List.map (numberedGroup observations)
        |> KeyedList.fromList


numberedGroup : List Observation -> Int -> Group
numberedGroup observations n =
    Group.init ("Group " ++ toString n) observations



-- UPDATE


type Msg
    = SettingsMsg Settings.Msg
    | Build
    | SetUp
    | AddGroup String
    | UpdateGroup Key Group.Msg
    | RemoveGroup Key
    | ResetGroups


update : Msg -> Model -> Model
update msg model =
    case msg of
        SettingsMsg subMsg ->
            { model | settings = Settings.update subMsg model.settings }

        Build ->
            { model
                | groups =
                    buildGroups
                        (KeyedList.length model.groups)
                        model.settings
                , state = Active
            }

        SetUp ->
            { model | state = Setup }

        AddGroup groupName ->
            let
                newGroup =
                    Settings.defaultObservations model.settings
                        |> Group.init groupName
            in
                { model | groups = KeyedList.push newGroup model.groups }

        UpdateGroup key groupMsg ->
            { model
                | groups =
                    KeyedList.update key
                        (Group.update groupMsg)
                        model.groups
            }

        RemoveGroup key ->
            { model | groups = KeyedList.remove key model.groups }

        ResetGroups ->
            { model | groups = buildGroups (KeyedList.length model.groups) model.settings }



-- VIEW


view : Model -> Html Msg
view { settings, groups } =
    div []
        [ Settings.view settings
            |> Html.map SettingsMsg
        , div []
            [ menuButton (AddGroup "New Group") "Add Group"
            , menuButton ResetGroups "Reset All Groups"
            , menuButton Build "Build quiz"
            ]
        , KeyedList.keyedMap (viewKeyedGroup settings) groups
            |> div [ style [ "display" => "flex" ] ]
        ]


viewKeyedGroup : Settings -> Key -> Group -> Html Msg
viewKeyedGroup settings key group =
    Group.view settings group
        |> Html.map (UpdateGroup key)
        |> viewWithRemoveButton (RemoveGroup key)


menuButton : Msg -> String -> Html Msg
menuButton msg label =
    styledButton "menu-button" msg label


styledButton : String -> Msg -> String -> Html Msg
styledButton className msg label =
    button
        [ onClick msg
        , class className
        ]
        [ text label ]



-- JSON


encodeGroups : KeyedList Group -> Encode.Value
encodeGroups groups =
    encodeKeyedList Group.encode groups


groupsDecoder : Decode.Decoder (KeyedList Group)
groupsDecoder =
    keyedListDecoder Group.decoder
