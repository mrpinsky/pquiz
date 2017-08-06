module Quiz exposing (Quiz, encode)

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
import Quiz.Group exposing (Group)
import Util exposing ((=>))


-- MODEL


type alias Quiz =
    { title : String
    , groups : KeyedList Group
    , settings : Settings
    }


encode : Quiz -> Encode.Value
encode quiz =
    Encode.object
        [ "title" => Encode.string quiz.title
        , "groups" => Encode.list <| KeyedList.toList quiz.groups
        , "settings" => Settings.encode quiz.settings
        ]


decoder : Encode.Value -> Quiz
decoder json =
    Decode.map3
        Quiz
        (Decode.field "title" Decode.string)
        (Decode.field "groups" KeyedList.decoder)
        (Decode.field "settings" Settings.decoder)



{--
decoder : Decode.Decoder Quiz
decoder =
    Decode.map5
        Quiz
        (Decode.maybe <| Decode.field "id" Decode.int)
        (Decode.field "title" Decode.string)
        (Decode.field "groups" <| Decode.list G.decoder)
        (Decode.field "nextID" Decode.int)
        (Decode.field "numAcross" Decode.int)


baseModel : Quiz
baseModel =
    { id = Nothing
    , title = "Unnamed Quiz"
    , groups = List.map (\n -> G.init (toString n) n) (List.range 1 8)
    , nextID = 9
    , numAcross = 4
    }


init : Maybe Decode.Value -> Quiz
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
                    Ok quiz ->
                        quiz

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


update : Msg -> Quiz -> ( Quiz, Cmd Msg, Maybe String )
update msg quiz =
    case msg of
        Rename maybeTitle ->
            let
                title =
                    if maybeTitle == "" then
                        "Untitled Quiz"
                    else
                        maybeTitle
            in
                ( { quiz | title = title }, Cmd.none, Nothing )

        UpdateGroup id groupMsg ->
            let
                updates =
                    List.map (updateHelp id groupMsg) quiz.groups

                toDelete =
                    List.filterMap Tuple.second updates

                newGroups =
                    List.map Tuple.first updates
                        |> List.filter (\grp -> not <| List.member grp.id toDelete)
            in
                ( { quiz | groups = newGroups }
                , Cmd.none
                , Just <| "input-group-" ++ toString id
                )

        Reset ->
            ( baseModel, Cmd.none, Nothing )

        Create name ->
            let
                newGroup =
                    G.init name quiz.nextID

                newGroups =
                    quiz.groups ++ [ newGroup ]
            in
                ( { quiz
                    | groups = newGroups
                    , nextID = quiz.nextID + 1
                  }
                , Cmd.none
                , Nothing
                )

        Remove id ->
            ( { quiz
                | groups = List.filter (\group -> group.id /= id) quiz.groups
              }
            , Cmd.none
            , Nothing
            )

        SetTallyDisplays visible ->
            let
                newGroups =
                    List.map
                        (Tuple.first << G.update (G.SetScoreDisplay visible))
                        quiz.groups
            in
                ( { quiz | groups = newGroups }, Cmd.none, Nothing )

        SetNumAcross n ->
            ( { quiz | numAcross = n }, Cmd.none, Nothing )


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


view : Quiz -> Html Msg
view quiz =
    div []
        [ lazy viewMenu quiz
        , div [] (List.map (viewIndexedGroup quiz.numAcross) quiz.groups)
        ]


viewMenu : Quiz -> Html Msg
viewMenu quiz =
    div []
        [ menuButton (Create (toString quiz.nextID)) "Add Group"
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
--}
