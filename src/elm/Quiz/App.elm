module Quiz.App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, classList, style, href, target)
import Html.Events exposing (onClick, on)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Ports exposing (focus, cacheQuiz)
import Quiz.Group as Group exposing (Group)
import Quiz.Settings as Settings exposing (Settings, Format(Grid, Column))
import Util
    exposing
        ( (=>)
        , encodeKeyedList
        , keyedListDecoder
        , viewWithRemoveButton
        , subdivide
        , encodeMaybe
        )


-- MODEL


type alias Model =
    { state : State
    , settings : Settings
    , prevSettings : Maybe Settings
    , nextId : Int
    , groups : List Group
    }


type State
    = Setup
    | Active


init : Int -> Settings -> Model
init numGroups settings =
    Model Active settings Nothing (numGroups + 1) <| withGroups numGroups


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
    | CancelSetUp
    | CommitSettings
    | AddGroup String
    | UpdateGroup Int Group.Msg
    | RemoveGroup Int
    | ResetGroups


updateWithPorts : Msg -> Model -> ( Model, Cmd msg )
updateWithPorts msg model =
    case msg of
        UpdateGroup id groupMsg ->
            let
                updateHelper group =
                    if group.id == id then
                        ( Group.update groupMsg group, Just id )
                    else
                        ( group, Nothing )

                ( groups, maybeInts ) =
                    List.map updateHelper model.groups
                        |> List.unzip

                focusCmd =
                    List.filterMap identity maybeInts
                        |> List.head
                        |> Maybe.map focus
                        |> Maybe.withDefault Cmd.none

                newModel =
                    { model | groups = groups }
            in
                newModel ! [ focusCmd, cacheQuiz <| encode newModel ]

        _ ->
            let
                newModel =
                    update msg model
            in
                ( newModel, cacheQuiz <| encode newModel )


update : Msg -> Model -> Model
update msg model =
    case msg of
        SettingsMsg subMsg ->
            { model | settings = Settings.update subMsg model.settings }

        SetUp ->
            { model | state = Setup, prevSettings = Just model.settings }

        CancelSetUp ->
            { model
                | state = Active
                , settings =
                    model.prevSettings
                        |> Maybe.withDefault model.settings
                , prevSettings = Nothing
            }

        CommitSettings ->
            { model | state = Active, prevSettings = Nothing }

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
view model =
    div [ class "page" ]
        [ viewQuiz model
        , viewSettings model.state model.settings
        ]


viewSettings : State -> Settings -> Html Msg
viewSettings state settings =
    div
        [ class "settings"
        , classList [ ( "hidden", state == Active ) ]
        , onClick CommitSettings
        ]
        [ Settings.view
            { updateMsg = SettingsMsg
            , doneMsg = CommitSettings
            , cancelMsg = CancelSetUp
            }
            settings
        ]


decodeCancel : Decode.Value -> Decoder Msg
decodeCancel value =
    Debug.log "event" value
        |> (\_ -> Decode.succeed CancelSetUp)


viewQuiz : Model -> Html Msg
viewQuiz { state, settings, groups } =
    div
        [ class "quiz page"
        , classList [ ( "blurred", state == Setup ) ]
        ]
        [ viewGroups settings groups
        , div [ class "menu-bar" ]
            [ menuButton SetUp "Settings"
            , menuButton (AddGroup "New Group") "+ Add Group"
            , menuButton ResetGroups "Reset All Groups"
            , a
                [ href "mailto:pquiz.feedback@gmail.com"
                , target "_blank"
                ]
                [ text "Send Feedback" ]
            ]
        ]


viewGroups : Settings -> List Group -> Html Msg
viewGroups settings groups =
    case settings.format of
        Grid ->
            groups
                |> arrangeInGrid
                |> List.map (viewRow settings)
                |> div [ class "groups grid" ]

        Column ->
            groups
                |> viewRow settings
                |> List.singleton
                |> div [ class "groups column" ]


arrangeInGrid : List Group -> List (List Group)
arrangeInGrid pairs =
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



-- JSON


encode : Model -> Value
encode { state, settings, prevSettings, nextId, groups } =
    Encode.object
        [ "state" => encodeState state
        , "settings" => Settings.encode settings
        , "prevSettings" => encodeMaybe Settings.encode prevSettings
        , "nextId" => Encode.int nextId
        , "groups" => encodeGroups groups
        ]


encodeState : State -> Value
encodeState state =
    Encode.string <| toString state


encodeGroups : List Group -> Value
encodeGroups groups =
    Encode.list <| List.map Group.encode groups


decoder : Decoder Model
decoder =
    Decode.map5 Model
        (Decode.field "state" stateDecoder)
        (Decode.field "settings" Settings.decoder)
        (Decode.field "prevSettings" <| Decode.nullable Settings.decoder)
        (Decode.field "nextId" Decode.int)
        (Decode.field "groups" <| Decode.list Group.decoder)


stateDecoder : Decoder State
stateDecoder =
    Decode.string
        |> Decode.map stateFromString


stateFromString : String -> State
stateFromString string =
    case string of
        "Setup" ->
            Setup

        _ ->
            Active
