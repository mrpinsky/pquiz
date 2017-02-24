module Group exposing (Model, InternalMsg(SetScoreDisplay), init, Translator, translator, update, view, viewWithRemoveButton)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Json.Decode as Json
import Observation
import Char
import String


-- MODEL


type alias Model =
    { name : String
    , observations : List Observation.Model
    , obs : String
    , obsKind : Int
    , enteringObs : Bool
    , showTally : Bool
    , myId : Int
    , nextObsId : Int
    , total : Int
    }


init : String -> Int -> Model
init name id =
    let
        newObsList =
            []
    in
        { name = name
        , observations = newObsList
        , obs = ""
        , obsKind = 0
        , enteringObs = False
        , showTally = True
        , myId = id
        , nextObsId = 0
        , total = 0
        }



-- MESSAGING


type Msg
    = ForSelf InternalMsg
    | ForParent OutMsg


type InternalMsg
    = EditingNew Int
    | UpdateNew String
    | Create
    | RemoveObs Int
    | UpdateExisting Int Observation.InternalMsg
    | SetScoreDisplay Bool


type OutMsg
    = Remove


obsTranslator : Int -> Observation.Translator InternalMsg
obsTranslator id =
    Observation.translator { onInternalMessage = UpdateExisting id, onRemove = RemoveObs id }


type alias TranslationDictionary parentMsg =
    { onInternalMessage : InternalMsg -> parentMsg
    , onRemove : parentMsg
    }


type alias Translator parentMsg =
    Msg -> parentMsg


translator : TranslationDictionary parentMsg -> Translator parentMsg
translator { onInternalMessage, onRemove } msg =
    case msg of
        ForSelf internal ->
            onInternalMessage internal

        ForParent Remove ->
            onRemove



-- UPDATE


update : InternalMsg -> Model -> Model
update msg model =
    case msg of
        EditingNew kind ->
            { model
                | enteringObs = True
                , obsKind = kind
            }

        UpdateNew obs ->
            { model | obs = obs }

        Create ->
            if model.obs == "" then
                { model | enteringObs = False }
            else
                let
                    newObs =
                        Observation.init model.obs model.obsKind model.nextObsId
                in
                    { model
                        | obs = ""
                        , observations = newObs :: model.observations
                        , enteringObs = False
                        , nextObsId = model.nextObsId + 1
                        , total = model.total + (Observation.obsValue newObs)
                    }

        RemoveObs id ->
            let
                newObservations =
                    List.filter (\obs -> obs.id /= id) model.observations
            in
                { model
                    | observations = newObservations
                    , total = List.sum <| List.map Observation.obsValue newObservations
                }

        UpdateExisting id msg ->
            let
                updateObs obs =
                    if obs.id == id then
                        Observation.update msg obs
                    else
                        obs

                newObservations =
                    List.map updateObs model.observations
            in
                { model
                    | observations = newObservations
                    , total = List.sum <| List.map Observation.obsValue newObservations
                }

        SetScoreDisplay tallyState ->
            { model | showTally = tallyState }



-- VIEW


(=>) : a -> b -> ( a, b )
(=>) =
    (,)


view : Model -> Html Msg
view model =
    div [ class "group" ]
        [ lazy viewTitle model.name
        , lazy viewTotal model
        , lazy viewInput model
        , lazy viewObservations model.observations
        ]


viewTitle : String -> Html Msg
viewTitle title =
    div
        [ class "title"
        , contenteditable True
        ]
        [ text ("Group " ++ title) ]


viewTotal : Model -> Html Msg
viewTotal model =
    model.total
        |> toString
        |> text
        |> listify
        |> h2
            [ classList
                [ ( "points", True )
                , ( "total-" ++ (toString <| clamp 0 10 <| abs model.total), True )
                , ( "hidden", not model.showTally )
                , ( "pos", model.total > 0 )
                ]
            ]


viewInput : Model -> Html Msg
viewInput model =
    div
        [ classList
            [ ( "group-input", True )
            , ( "entering", model.enteringObs )
            ]
        ]
        [ input
            [ placeholder "Observation"
            , value model.obs
            , onEnter <| ForSelf Create
            , onInput <| (ForSelf << UpdateNew)
            , id <| "input-group-" ++ (toString model.myId)
            , class "enter"
            ]
            []
        , div [ class "buttons" ]
            [ button
                [ onClick (ForSelf <| EditingNew 1)
                , class "input-button first-kind"
                ]
                [ text "+" ]
            , button
                [ onClick (ForSelf <| EditingNew 2)
                , class "input-button second-kind"
                ]
                [ text "*" ]
            , button
                [ onClick (ForSelf <| EditingNew 3)
                , class "input-button third-kind"
                ]
                [ text <| String.fromChar <| Char.fromCode 916 ]
            ]
        ]


viewObservations : List Observation.Model -> Html Msg
viewObservations os =
    section []
        [ List.map (\o -> ( "obs-" ++ (toString o.id), viewKeyedObservation o )) os
            |> Keyed.ul [ class "observation-list" ]
        ]


viewKeyedObservation : Observation.Model -> Html Msg
viewKeyedObservation obs =
    Html.map (ForSelf << obsTranslator obs.id) (Observation.viewWithRemoveButton obs)


viewWithRemoveButton : Int -> Model -> Html Msg
viewWithRemoveButton numAcross model =
    div [ class <| "group-box-" ++ (toString numAcross) ]
        [ div [ class "group" ]
            [ button
                [ onClick (ForParent Remove)
                , class "remove"
                ]
                [ text "×" ]
            , lazy viewTitle model.name
            , lazy viewTotal model
            , lazy viewInput model
            , lazy viewObservations model.observations
            ]
        ]



-- UTILITIES


listify : a -> List a
listify item =
    [ item ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Json.succeed msg
            else
                Json.fail "not ENTER"
    in
        on "keydown" (Json.andThen isEnter keyCode)
