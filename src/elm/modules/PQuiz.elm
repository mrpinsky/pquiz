module PQuiz exposing (Model, Msg, init, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Group as G


-- MODEL


type alias ID =
    Int


type alias Model =
    { groups : List G.Model
    , nextID : ID
    , numAcross : Int
    }


baseModel : Model
baseModel =
    { groups = List.map (\n -> G.init (toString n) n) (List.range 1 8)
    , nextID = 9
    , numAcross = 4
    }


init : Maybe Model -> Model
init savedModel =
    Maybe.withDefault baseModel savedModel



-- MESSAGING


type Msg
    = GroupMsg ID G.InternalMsg
    | Reset
    | Create String
    | Remove ID
    | SetTallyDisplays Bool
    | SetNumAcross Int


translator : ID -> G.Translator Msg
translator id =
    G.translator { onInternalMessage = GroupMsg id, onRemove = Remove id }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GroupMsg id groupMsg ->
            let
                newGroups =
                    List.map (updateHelp id groupMsg) model.groups
            in
                { model | groups = newGroups } ! []

        -- ( { model | groups = newGroups }
        -- , focus ("#input-group-" ++ toString id)
        -- )
        Reset ->
            baseModel ! []

        Create name ->
            let
                newGroup =
                    G.init name model.nextID

                newGroups =
                    model.groups ++ [ newGroup ]
            in
                { model
                    | groups = newGroups
                    , nextID = model.nextID + 1
                }
                    ! []

        Remove id ->
            { model
                | groups = List.filter (\group -> group.myId /= id) model.groups
            }
                ! []

        SetTallyDisplays visible ->
            let
                newGroups =
                    List.map (G.update <| G.SetScoreDisplay visible) model.groups
            in
                { model | groups = newGroups } ! []

        SetNumAcross n ->
            { model | numAcross = n } ! []


updateHelp : Int -> G.InternalMsg -> G.Model -> G.Model
updateHelp id msg group =
    if group.myId /= id then
        group
    else
        G.update msg group



-- VIEW


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


view : Model -> Html Msg
view model =
    div []
        [ lazy viewMenu model
        , div [ class "groups-list" ]
            (List.map (viewIndexedGroup model.numAcross) model.groups)
        ]


viewMenu : Model -> Html Msg
viewMenu model =
    div [ class "menu" ]
        [ button
            [ onClick (Create (toString model.nextID))
            , class "menu-button"
            ]
            [ text "Add Group" ]
        , button
            [ onClick Reset
            , class "menu-button"
            ]
            [ text "Reset All Groups" ]
        , button
            [ onClick (SetTallyDisplays True)
            , class "menu-button"
            ]
            [ text "Show Point Tallies" ]
        , button
            [ onClick (SetTallyDisplays False)
            , class "menu-button"
            ]
            [ text "Hide Point Tallies" ]
        , span [ class "layout-option" ]
            [ text "Groups per Row: "
            , button [ onClick (SetNumAcross 3) ]
                [ text "3" ]
            , button [ onClick (SetNumAcross 4) ]
                [ text "4" ]
            , button [ onClick (SetNumAcross 5) ]
                [ text "5" ]
            ]
        ]


viewIndexedGroup : Int -> G.Model -> Html Msg
viewIndexedGroup numAcross group =
    Html.map (translator group.myId) (G.viewWithRemoveButton numAcross group)
