port module Quiz.App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, style, href)
import Html.Events exposing (onClick)
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


-- PORTS

port focus : Int -> Cmd msg


-- MODEL


type alias Model =
    { state : State
    , settings : Settings
    , nextId : Int
    , groups : List Group
    }


type State
    = Setup
    | Active


init : Int -> Settings -> Model
init numGroups settings =
    Model Active settings (numGroups + 1) <| withGroups numGroups


withGroups : Int -> List Group
withGroups count =
    List.range 1 count
        |> List.map numberedGroup


numberedGroup : Int -> Group
numberedGroup n =
    Group.init n ("Group " ++ toString n)



-- UPDATE


type Msg
    = SettingsMsg Settings.Msg
    | SetUp
    | Resume
    | AddGroup String
    | UpdateGroup Int Group.Msg
    | RemoveGroup Int
    | ResetGroups


updateWithFocus : Msg -> Model -> (Model, Cmd msg)
updateWithFocus msg model =
    case msg of
        UpdateGroup id groupMsg ->
            let
                updateHelper group =
                    if group.id == id then
                        (Group.update groupMsg group, Just id)
                    else
                        (group, Nothing)

                (groups, maybeInts) =
                    List.map updateHelper model.groups
                        |> List.unzip

                cmd =
                    List.filterMap identity maybeInts
                        |> List.head
                        |> Maybe.map focus
                        |> Maybe.withDefault Cmd.none
            in
                ({ model | groups = groups }, cmd)

        _ ->
            (update msg model, Cmd.none)

    
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
                    Group.init model.nextId groupName
            in
                { model
                    | groups = model.groups ++ [ newGroup ]
                    , nextId = model.nextId + 1
                }

        UpdateGroup id groupMsg ->
            let
                updateHelper group =
                    if group.id == id then
                        Group.update groupMsg group
                    else
                        group
            in
                { model | groups = List.map updateHelper model.groups }

        RemoveGroup id ->
            let
                removeHelper group =
                    group.id /= id
            in
                { model | groups = List.filter removeHelper model.groups }

        ResetGroups ->
            { model | groups = List.map Group.reset model.groups }



-- VIEW


view : Model -> Html Msg
view { state, settings, groups } =
    case state of
        Setup ->
            div [ class "settings page" ]
                [ Settings.view
                    { updateMsg = SettingsMsg, doneMsg = Resume }
                    settings
                ]

        Active ->
            div [ class "quiz page" ]
                [ viewGroups settings groups
                , div [ class "menu-bar" ]
                    [ menuButton SetUp "Settings"
                    , menuButton (AddGroup "New Group") "+ Add Group"
                    , menuButton ResetGroups "Reset All Groups"
                    , a [ href "mailto:pquiz.feedback@gmail.com" ]
                        [ text "Send Feedback" ]
                    ]
                ]


viewGroups : Settings -> List Group -> Html Msg
viewGroups settings groups =
    groups
        |> arrangeInRows
        |> List.map (viewRow settings)
        |> div [ class "groups" ]


arrangeInRows : List Group -> List (List Group)
arrangeInRows pairs =
    if List.length pairs <= 4 then
        List.singleton pairs
    else
        let
            half =
                List.length pairs // 2
        in
            [ List.take half pairs, List.drop half pairs ]


viewRow : Settings -> List Group -> Html Msg
viewRow settings groups =
    List.map (viewGroup settings) groups
        |> div [ class "row" ]


viewGroup : Settings -> Group -> Html Msg
viewGroup settings group =
    Group.view
        { onUpdate = UpdateGroup group.id
        , remove = RemoveGroup group.id
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
