module Quiz.App exposing
    ( Model
    , Msg(..)
    , arrangeInGrid
    , decodeCancel
    , decoder
    , encode
    , encodeGroups
    , encodeSettings
    , init
    , initGroups
    , mapWithNext
    , mapWithNextHelper
    , menuButton
    , numberedGroup
    , styledButton
    , update
    , updateWithPorts
    , view
    , viewAsModal
    , viewGroup
    , viewGroups
    , viewHighlightContents
    , viewHighlightModal
    , viewHighlightTab
    , viewHighlightTabs
    , viewQuiz
    , viewRow
    , viewSettingsModal
    )

import Html.Styled as Html exposing (..)
import Html.Styled.Attributes exposing (class, classList, href, rel, style, target)
import Html.Styled.Events exposing (on, onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Ports exposing (cacheQuiz, focus)
import Quiz.Group as Group exposing (Group)
import Quiz.Settings as Settings exposing (Format(..), Settings)
import Util
    exposing
        ( encodeKeyedList
        , encodeMaybe
        , keyedListDecoder
        , onClickWithoutPropagation
        , subdivide
        , viewWithRemoveButton
        )



-- MODEL


type alias Model =
    { settings : Settings
    , groups : List Group
    , settingsCache : Maybe Settings
    , highlightedGroupId : Maybe Int
    , nextId : Int
    , announcementRead : Bool
    }


init : Int -> Settings -> Model
init numGroups settings =
    Model settings (initGroups numGroups) Nothing Nothing (numGroups + 1) False


initGroups : Int -> List Group
initGroups count =
    List.range 1 count
        |> List.map numberedGroup


numberedGroup : Int -> Group
numberedGroup n =
    Group.init n ("Group " ++ String.fromInt n)



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
    | ReadAnnouncement
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
            ( newModel, Cmd.batch [ focusCmd, cacheQuiz <| encode newModel ] )

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

        ReadAnnouncement ->
            { model | announcementRead = True }

        NoOp ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "page" ]
        [ viewQuiz model
        , viewHighlightModal model
        , viewSettingsModal model
        , viewAnnouncementModal model
        ]


viewAnnouncementModal : Model -> Html Msg
viewAnnouncementModal { announcementRead } =
    viewAsModal
        { isHidden = announcementRead
        , backgroundClickMsg =
            ReadAnnouncement
        }
        [ newDomainAnnouncement ]


newDomainAnnouncement : Html Msg
newDomainAnnouncement =
    div
        [ style "margin" "2em"
        , style "height" "100%"
        ]
        [ h3
            [ style "margin-top" "0"
            , style "color" "#1c7556"
            ]
            [ text "Exciting Update" ]
        , p [] [ text "Hi there!" ]
        , p []
            [ text """
            Thanks for using my participation quiz tool; I'm glad you like it. I've
            been hard at work at building a new and improved version. It
            currently supports
            """
            , ul []
                [ li [] [ text "Saving and accessing as many different quizzes as you need" ]
                , li [] [ text "A printable summary of any quiz" ]
                , li [] [ text "Storing and default observations as defaults and appling them to future quizzes" ]
                ]
            , text """
            and it's where I'll be adding all new features in the future.
            """
            ]
        , p []
            [ text """
            I'd love it if you checked it out at
            """
            , a
                [ href "https://pquiz.app"
                , target "_blank"
                , rel "noopener noreferrer"
                ]
                [ text "pquiz.app" ]
            , text "."
            , text """
            And if you have any feedback on either version, or any ideas for
            features you'd like to have, I'd love to hear about them at
            """
            , a
                [ href "mailto:feedback@pquiz.app"
                , target "_blank"
                , rel "noopener noreferrer"
                ]
                [ text "feedback@pquiz.app" ]
            ]
        , p [] [ text "Thanks again for using PQuiz!" ]
        , p [] [ text "Mr. Pinsky" ]
        , div
            [ style "display" "flex"
            , style "flex" "1 0 auto"
            , style "flex-direction" "row"
            , style "align-items" "center"
            ]
            [ a
                [ href "https://pquiz.app"
                , target "_blank"
                , rel "noopener noreferrer"
                , style "padding" "10px"
                , style "text-decoration" "none"
                , style "border-radius" "5px"
                , style "background" "#1c7556"
                , style "color" "#fff"
                ]
                [ text "Take me to the new version!" ]
            , div [ style "width" "1em", style "background" "transparent" ] []
            , button
                [ onClick ReadAnnouncement
                , style "color" "#888"
                , style "text-decoration" "underline"
                , style "font-size" "1em"
                ]
                [ text "Dismiss" ]
            ]
        ]


viewHighlightModal : Model -> Html Msg
viewHighlightModal { highlightedGroupId, settings, groups } =
    let
        lookupGroup : List Group -> Int -> Maybe Group
        lookupGroup groupsList id =
            groupsList
                |> List.filter (\group -> id == group.id)
                |> List.head

        contents : List (Html Msg)
        contents =
            highlightedGroupId
                |> Maybe.andThen (lookupGroup groups)
                |> Maybe.map (viewHighlightContents settings groups)
                |> Maybe.withDefault [ text "" ]
    in
    viewAsModal
        { isHidden = highlightedGroupId == Nothing
        , backgroundClickMsg = Unhighlight
        }
        contents


viewHighlightContents : Settings -> List Group -> Group -> List (Html Msg)
viewHighlightContents settings groups group =
    [ viewHighlightTabs groups group
    , Group.viewStatic settings group
        |> Html.map (\_ -> NoOp)
    ]


viewHighlightTabs : List Group -> Group -> Html Msg
viewHighlightTabs groups group =
    groups
        |> mapWithNext (viewHighlightTab group.id)
        |> div [ class "tabs" ]


mapWithNext : (a -> Maybe a -> b) -> List a -> List b
mapWithNext fn list =
    mapWithNextHelper fn list []


mapWithNextHelper : (a -> Maybe a -> b) -> List a -> List b -> List b
mapWithNextHelper fn list acc =
    case list of
        [] ->
            List.reverse acc

        head :: tail ->
            ((fn head <| List.head tail) :: acc)
                |> mapWithNextHelper fn tail


viewHighlightTab : Int -> Group -> Maybe Group -> Html Msg
viewHighlightTab highlighted { id, label } nextGroup =
    let
        precedesSelected =
            Maybe.map .id nextGroup
                |> Maybe.map ((==) highlighted)
                |> Maybe.withDefault False
    in
    div
        [ class "tab"
        , classList
            [ ( "selected", highlighted == id )
            , ( "preceding", precedesSelected )
            ]
        , onClick (HighlightGroup id)
        ]
        [ span [ class "tab-label" ] [ text label ] ]


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
                [ href "mailto:feedback@pquiz.app"
                , target "_blank"
                , rel "noopener noreferrer"
                ]
                [ text "Send Feedback" ]
            , a
                [ href "https://pquiz.app"
                , target "_blank"
                , rel "noopener noreferrer"
                ]
                [ text "Go to pquiz.app" ]
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
encode { settings, settingsCache, nextId, groups, announcementRead } =
    Encode.object
        [ ( "settings", encodeSettings settingsCache settings )
        , ( "nextId", Encode.int nextId )
        , ( "groups", encodeGroups groups )
        , ( "announcementRead", Encode.bool announcementRead )
        ]


encodeSettings : Maybe Settings -> Settings -> Value
encodeSettings settingsCache settings =
    Maybe.withDefault settings settingsCache
        |> Settings.encode


encodeGroups : List Group -> Value
encodeGroups groups =
    Encode.list Group.encode groups


decoder : Decoder Model
decoder =
    Decode.map6 Model
        (Decode.field "settings" Settings.decoder)
        (Decode.field "groups" <| Decode.list Group.decoder)
        (Decode.succeed Nothing)
        (Decode.succeed Nothing)
        (Decode.field "nextId" Decode.int)
        (Decode.oneOf
            [ Decode.field "announcementRead" Decode.bool
            , Decode.succeed False
            ]
        )
