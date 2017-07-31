module Quiz exposing (Model, Msg(Rename), init, update, view, toJSON)

-- Elm Packages

import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (..)
import Html.Lazy exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode


-- Local Files

import Group as G
import Util


-- MODEL


type alias Model =
    { id : Maybe Int
    , title : String
    , groups : List G.Model
    , nextID : Int
    , numAcross : Int
    }


toJSON : Model -> Encode.Value
toJSON model =
    Encode.object
        [ ( "id", Util.encodeMaybe Encode.int model.id )
        , ( "title", Encode.string model.title )
        , ( "groups", Encode.list <| List.map G.toJSON model.groups )
        , ( "nextID", Encode.int model.nextID )
        , ( "numAcross", Encode.int model.numAcross )
        ]


fromJSON : Encode.Value -> Model
fromJSON json =
    let
        result =
            Decode.decodeValue decoder json
    in
        case result of
            Ok model ->
                model

            Err _ ->
                baseModel


decoder : Decode.Decoder Model
decoder =
    Decode.map5
        Model
        (Decode.maybe <| Decode.field "id" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "groups" <| Decode.list G.decoder)
        (Decode.field "nextID" Decode.int)
        (Decode.field "numAcross" Decode.int)


baseModel : Model
baseModel =
    { id = Nothing
    , title = "Unnamed Quiz"
    , groups = List.map (\n -> G.init (toString n) n) (List.range 1 8)
    , nextID = 9
    , numAcross = 4
    }


init : Maybe Decode.Value -> Model
init json =
    case json of
        Nothing ->
            baseModel

        Just savedModel ->
            let
                result =
                    Decode.decodeValue decoder savedModel
            in
                case result of
                    Ok model ->
                        model

                    Err _ ->
                        baseModel



-- MESSAGING


type Msg
    = Rename String
    | UpdateGroup Int G.Msg
    | Reset
    | Create String
    | Remove Int
    | SetTallyDisplays Bool
    | SetNumAcross Int



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg, Maybe String )
update msg model =
    case msg of
        Rename maybeTitle ->
            let
                title =
                    if maybeTitle == "" then
                        "Untitled Quiz"
                    else
                        maybeTitle
            in
                ( { model | title = title }, Cmd.none, Nothing )

        UpdateGroup id groupMsg ->
            let
                updates =
                    List.map (updateHelp id groupMsg) model.groups

                toDelete =
                    List.filterMap Tuple.second updates

                newGroups =
                    List.map Tuple.first updates
                        |> List.filter (\grp -> not <| List.member grp.id toDelete)
            in
                ( { model | groups = newGroups }
                , Cmd.none
                , Just <| "input-group-" ++ toString id
                )

        Reset ->
            ( baseModel, Cmd.none, Nothing )

        Create name ->
            let
                newGroup =
                    G.init name model.nextID

                newGroups =
                    model.groups ++ [ newGroup ]
            in
                ( { model
                    | groups = newGroups
                    , nextID = model.nextID + 1
                  }
                , Cmd.none
                , Nothing
                )

        Remove id ->
            ( { model
                | groups = List.filter (\group -> group.id /= id) model.groups
              }
            , Cmd.none
            , Nothing
            )

        SetTallyDisplays visible ->
            let
                newGroups =
                    List.map
                        (Tuple.first << G.update (G.SetScoreDisplay visible))
                        model.groups
            in
                ( { model | groups = newGroups }, Cmd.none, Nothing )

        SetNumAcross n ->
            ( { model | numAcross = n }, Cmd.none, Nothing )


updateHelp : Int -> G.Msg -> G.Model -> ( G.Model, Maybe Int )
updateHelp id msg group =
    if group.id /= id then
        ( group, Nothing )
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
        , div [] (List.map (viewIndexedGroup model.numAcross) model.groups)
        ]


viewMenu : Model -> Html Msg
viewMenu model =
    div []
        [ menuButton (Create (toString model.nextID)) "Add Group"
        , menuButton Reset "Reset All Groups"
        , menuButton (SetTallyDisplays True) "Show Point Tallies"
        , menuButton (SetTallyDisplays False) "Hide Point Tallies"
        , List.map numAcrossButton [ 3, 4, 5 ]
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


viewIndexedGroup : Int -> G.Model -> Html Msg
viewIndexedGroup numAcross group =
    Html.map (UpdateGroup group.id) (G.viewWithRemoveButton numAcross group)
