module Quiz exposing (..)

-- (Model, Msg(Rename), init, update, view, encode)
-- Elm Packages

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import KeyedList exposing (KeyedList, Key)
import Quiz.Settings as Settings exposing (Settings)
import Quiz.Group as Group exposing (Group)
import Util exposing ((=>), keyedListDecoder, encodeKeyedList)


-- MODEL


type Quiz
    = Quiz String Settings (KeyedList Group)


encode : Quiz -> Encode.Value
encode (Quiz title settings groups) =
    Encode.object
        [ "title" => Encode.string title
        , "groups" => encodeKeyedList Group.encode groups
        , "settings" => Settings.encode settings
        ]


decoder : Decode.Decoder Quiz
decoder =
    Decode.map3
        Quiz
        (Decode.field "title" Decode.string)
        (Decode.field "settings" Settings.decoder)
        (Decode.field "groups" <| keyedListDecoder Group.decoder)


default : Quiz
default =
    let
        groups =
            blankGroups 8
    in
        Quiz "Unnamed Quiz" Settings.default groups


blankGroups : Int -> KeyedList Group
blankGroups count =
    List.range 1 count
        |> List.map numberedGroup
        |> KeyedList.fromList


numberedGroup : Int -> Group
numberedGroup n =
    Group.init ("Group " ++ toString n) []


init : Maybe Decode.Value -> Quiz
init json =
    json
        |> Maybe.andThen (Decode.decodeValue decoder >> Result.toMaybe)
        |> Maybe.withDefault default



-- MESSAGING


type Msg
    = Rename String
    | AddGroup String
    | UpdateGroup Key Group.Msg
    | RemoveGroup Key
    | ResetGroups
    | UpdateSettings Settings



-- UPDATE


update : Msg -> Quiz -> Quiz
update msg (Quiz title settings groups) =
    case msg of
        Rename newTitle ->
            Quiz newTitle settings groups

        AddGroup groupName ->
            let
                newGroups =
                    KeyedList.push (Group.init groupName []) groups
            in
                Quiz title settings newGroups

        UpdateGroup key submsg ->
            let
                newGroups =
                    KeyedList.update key (Group.update submsg) groups
            in
                Quiz title settings newGroups

        RemoveGroup key ->
            let
                newGroups =
                    KeyedList.remove key groups
            in
                Quiz title settings newGroups

        ResetGroups ->
            let
                newGroups =
                    KeyedList.length groups
                        |> blankGroups
            in
                Quiz title settings newGroups

        UpdateSettings newSettings ->
            Quiz title newSettings groups



-- VIEW


view : Quiz -> Html Msg
view quiz =
    div []
        [ lazy viewMenu quiz
        , div [] (List.map (viewIndexedGroup quiz.numAcross) quiz.groups)
        ]


viewMenu : Quiz -> Html Msg
viewMenu quiz =
    div []
        [ menuButton (AddGroup (toString quiz.nextID)) "Add Group"
        , menuButton Reset "Reset All Groups"

        -- , menuButton (SetTallyDisplays True) "Show Point Tallies"
        -- , menuButton (SetTallyDisplays False) "Hide Point Tallies"
        , List.range 2 5
            |> List.map numAcrossButton
            |> List.append [ text "Groups per Row: " ]
            |> span []
        ]


styledButton : String -> Msg -> String -> Html Msg
styledButton styles msg label =
    button
        [ onClick msg
        , class styles
        ]
        [ text label ]


menuButton : Msg -> String -> Html Msg
menuButton msg label =
    styledButton "menu-button" msg label


numAcrossButton : Int -> Html Msg
numAcrossButton numAcross =
    styledButton "" (SetNumAcross numAcross) <| toString numAcross


viewKeyedGroup : Settings -> Key -> Group -> Html Msg
viewKeyedGroup settings key group =
    let
        inner =
            Group.view settings group
                |> Html.map (UpdateGroup key)
    in
        div []
            [ inner
            , button [ onClick (RemoveGroup key) ]
                [ text "x" ]
            ]
