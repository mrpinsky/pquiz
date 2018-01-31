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
        , onClickWithoutPropagation
        )


-- MODEL


type alias Model =
    { settings : Settings
    , groups : List Group
    , settingsCache : Maybe Settings
    , highlightedGroupId : Maybe Int
    , nextId : Int
    }


init : Int -> Settings -> Model
init numGroups settings =
    Model settings (initGroups numGroups) Nothing Nothing (numGroups + 1)


initGroups : Int -> List Group
initGroups count =
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
    | HighlightGroup Int
    | Unhighlight
    | ResetGroups
    | NoOp


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
            { model | settingsCache = Just model.settings }

        CancelSetUp ->
            { model
                | settings =
                    model.settingsCache
                        |> Maybe.withDefault model.settings
                , settingsCache = Nothing
            }

        CommitSettings ->
            { model | settingsCache = Nothing }

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

        HighlightGroup id ->
            { model | highlightedGroupId = Just id }

        Unhighlight ->
            { model | highlightedGroupId = Nothing }

        ResetGroups ->
            { model | groups = List.map Group.reset model.groups }

        NoOp ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "page" ]
        [ viewQuiz model
        , viewHighlightModal model
        , viewSettingsModal model
        ]


viewHighlightModal : Model -> Html Msg
viewHighlightModal { highlightedGroupId, settings, groups } =
    let
        lookupGroup : List Group -> Int -> Maybe Group
        lookupGroup groups id =
            groups
                |> List.filter (\group -> id == group.id)
                |> List.head

        groupView : Html Msg
        groupView =
            highlightedGroupId
                |> Maybe.andThen (lookupGroup groups)
                |> Maybe.map (Group.viewStatic settings)
                |> Maybe.withDefault (text "")
                |> Html.map (\_ -> NoOp)
    in
        viewAsModal
            { isHidden = highlightedGroupId == Nothing
            , backgroundClickMsg = Unhighlight
            }
            [ groupView ]


viewSettingsModal : Model -> Html Msg
viewSettingsModal { settings, settingsCache } =
    viewAsModal
        { isHidden = settingsCache == Nothing
        , backgroundClickMsg = CommitSettings
        }
        [ Settings.view
            { updateMsg = SettingsMsg
            , doneMsg = CommitSettings
            , cancelMsg = CancelSetUp
            }
            settings
        ]


viewAsModal : { isHidden : Bool, backgroundClickMsg : Msg } -> List (Html Msg) -> Html Msg
viewAsModal { isHidden, backgroundClickMsg } contents =
    div
        [ class "modal-container"
        , classList [ ( "hidden", isHidden ) ]
        , onClick backgroundClickMsg
        ]
        [ div [ class "modal", onClickWithoutPropagation NoOp ] contents ]


decodeCancel : Decode.Value -> Decoder Msg
decodeCancel value =
    Debug.log "event" value
        |> (\_ -> Decode.succeed CancelSetUp)


viewQuiz : Model -> Html Msg
viewQuiz { settings, settingsCache, highlightedGroupId, groups } =
    let
        isViewingSettings =
            settingsCache /= Nothing

        isViewingGroup =
            highlightedGroupId /= Nothing

        isViewingModal =
            isViewingSettings || isViewingGroup
    in
        div
            [ class "quiz page"
            , classList [ ( "blurred", isViewingModal ) ]
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
        , highlightMsg = HighlightGroup group.id
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
encode { settings, settingsCache, nextId, groups } =
    Encode.object
        [ "settings" => encodeSettings settingsCache settings
        , "nextId" => Encode.int nextId
        , "groups" => encodeGroups groups
        ]


encodeSettings : Maybe Settings -> Settings -> Value
encodeSettings settingsCache settings =
    Maybe.withDefault settings settingsCache
        |> Settings.encode


encodeGroups : List Group -> Value
encodeGroups groups =
    Encode.list <| List.map Group.encode groups


decoder : Decoder Model
decoder =
    Decode.map5 Model
        (Decode.field "settings" Settings.decoder)
        (Decode.field "groups" <| Decode.list Group.decoder)
        (Decode.succeed Nothing)
        (Decode.succeed Nothing)
        (Decode.field "nextId" Decode.int)
