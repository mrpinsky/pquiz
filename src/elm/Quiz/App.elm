module Quiz.App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import KeyedList exposing (KeyedList, Key)
-- import Json.Encode as Encode
-- import Json.Decode as Decode
import Quiz.Group as Group exposing (Group)
import Quiz.Settings as Settings exposing (Settings)
import Util
    exposing
        ( (=>)
        , encodeKeyedList
        , keyedListDecoder
        , viewWithRemoveButton
        , subdivide
        )


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
    Model Setup settings <| withGroups 8


withGroups : Int -> KeyedList Group
withGroups count =
    List.range 1 count
        |> List.map numberedGroup
        |> KeyedList.fromList


numberedGroup : Int -> Group
numberedGroup n =
    Group.init ("Group " ++ toString n)



-- UPDATE


type Msg
    = SettingsMsg Settings.Msg
    | SetUp
    | Resume
    | AddGroup String
    | UpdateGroup Key Group.Msg
    | RemoveGroup Key
    | ResetGroups


update : Msg -> Model -> Model
update msg model =
    case msg of
        SettingsMsg subMsg ->
            { model | settings = Settings.update subMsg model.settings }

        SetUp ->
            { model | state = Setup }

        Resume ->
            { model | state = Active }

        AddGroup groupName ->
            let
                newGroup =
                    Group.init groupName
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
            { model | groups = withGroups <| KeyedList.length model.groups }



-- VIEW


view : Model -> Html Msg
view { state, settings, groups } =
    case state of
        Setup ->
            div [ class "settings page" ]
                [ Html.map SettingsMsg <| Settings.view settings
                , button [ onClick Resume ] [ text "Save and return" ]
                ]

        Active ->
            div [ class "quiz page" ]
                [ div [ class "menu-bar" ]
                    [ menuButton (AddGroup "New Group") "Add Group"
                    , menuButton ResetGroups "Reset All Groups"
                    , menuButton SetUp "Setup"
                    ]
                , viewGroups settings groups
                ]


viewGroups : Settings -> KeyedList Group -> Html Msg
viewGroups settings groups =
    groups
        |> KeyedList.keyedMap (\key item -> ( key, item ))
        |> subdivide settings.columns
        |> List.map (viewRow settings)
        |> div [ class "groups" ]


viewRow : Settings -> List (Key, Group) -> Html Msg
viewRow settings groups =
    List.map (viewKeyedGroup settings) groups
        |> div [ class "row" ]


viewKeyedGroup : Settings -> (Key, Group) -> Html Msg
viewKeyedGroup settings (key, group) =
    Group.view
        { onUpdate = UpdateGroup key
        , remove = RemoveGroup key
        }
        settings
        group


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
-- encodeGroups : KeyedList Group -> Encode.Value
-- encodeGroups groups =
--     encodeKeyedList Group.encode groups
-- groupsDecoder : Decode.Decoder (KeyedList Group)
-- groupsDecoder =
--     keyedListDecoder Group.decoder
