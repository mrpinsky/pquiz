module Group exposing (Model, Msg(SetScoreDisplay), init, update, viewWithRemoveButton, toJSON, decoder)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Json.Encode as Encode
import Json.Decode as Decode
import Observation as Observation
import Util


-- MODEL


type alias Model =
    { name : String
    , observations : List Observation.Model
    , currentObs : Maybe ProtoObs
    , showTally : Bool
    , id : Int
    , nextObsId : Int
    , total : Int
    }


type alias ProtoObs =
    { kind : Int
    , text : String
    }


toJSON : Model -> Encode.Value
toJSON model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "observations"
          , Encode.list <| List.map Observation.toJSON model.observations
          )
        , ( "currentObs", Encode.null )
        ]


decoder : Decode.Decoder Model
decoder =
    Decode.map7
        Model
        (Decode.field "name" Decode.string)
        (Decode.field "observations" <| Decode.list Observation.decoder)
        (Decode.maybe <| Decode.field "currentObs" decodeProtoObs)
        (Decode.field "showTally" Decode.bool)
        (Decode.field "id" Decode.int)
        (Decode.field "nextObsId" Decode.int)
        (Decode.field "total" Decode.int)


decodeProtoObs : Decode.Decoder ProtoObs
decodeProtoObs =
    Decode.map2
        ProtoObs
        (Decode.field "kind" Decode.int)
        (Decode.field "text" Decode.string)


init : String -> Int -> Model
init name id =
    let
        newObsList =
            []
    in
        { name = name
        , currentObs = Nothing
        , observations = newObsList
        , showTally = True
        , id = id
        , nextObsId = 0
        , total = 0
        }



-- MESSAGING


type Msg
    = CreateNew Int
    | UpdateNew String
    | SaveNew
    | UpdateExisting Int Observation.Msg
    | SetScoreDisplay Bool
    | Delete



-- UPDATE


update : Msg -> Model -> ( Model, Maybe Int )
update msg model =
    case msg of
        CreateNew kind ->
            ( { model | currentObs = Just <| ProtoObs kind "" }, Nothing )

        UpdateNew text ->
            ( { model
                | currentObs =
                    Maybe.map2
                        editObservation
                        (Just text)
                        model.currentObs
              }
            , Nothing
            )

        SaveNew ->
            case model.currentObs of
                Nothing ->
                    ( model, Nothing )

                Just obs ->
                    if obs.text == "" then
                        ( { model | currentObs = Nothing }, Nothing )
                    else
                        let
                            newObs =
                                Observation.init obs.text obs.kind model.nextObsId
                        in
                            ( { model
                                | currentObs = Nothing
                                , observations = newObs :: model.observations
                                , nextObsId = model.nextObsId + 1
                                , total = model.total + (Observation.obsValue newObs)
                              }
                            , Nothing
                            )

        UpdateExisting id msg ->
            let
                updates =
                    List.map (updateHelper id msg) model.observations

                toRemove =
                    List.filterMap Tuple.second updates

                newObservations =
                    List.map Tuple.first updates
                        |> List.filter (\obs -> not <| List.member obs.id toRemove)
            in
                ( { model
                    | observations = newObservations
                    , total =
                        List.map Observation.obsValue newObservations
                            |> List.sum
                  }
                , Nothing
                )

        SetScoreDisplay tallyState ->
            ( { model | showTally = tallyState }, Nothing )

        Delete ->
            ( model, Just model.id )


updateHelper : Int -> Observation.Msg -> Observation.Model -> ( Observation.Model, Maybe Int )
updateHelper id msg obs =
    if obs.id == id then
        Observation.update msg obs
    else
        ( obs, Nothing )


editObservation : String -> { kind : Int, text : String } -> { kind : Int, text : String }
editObservation newText observation =
    { observation | text = newText }



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "group" ]
        [ lazy viewTitle model.name
        , lazy viewTotal model
        , lazy2 viewInput model.currentObs model.id
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
    h2
        [ classList
            [ ( "points", True )
            , ( "total-" ++ (toString <| clamp 0 10 <| abs model.total), True )
            , ( "hidden", not model.showTally )
            , ( "pos", model.total > 0 )
            ]
        ]
        (model.total
            |> toString
            |> text
            |> Util.listify
        )


viewButton : Int -> String -> Html Msg
viewButton kind label =
    button
        [ onClick <| CreateNew kind
        , class "input-button"
          -- , class <| ((ordinal kind) ++ "-kind input-button")
        ]
        [ text label ]


viewButtons : Html Msg
viewButtons =
    div [ class "buttons" ]
        [ viewButton 1 "+"
        , viewButton 2 "*"
        , viewButton 3 Util.delta
        ]


viewInput : Maybe ProtoObs -> Int -> Html Msg
viewInput mObs id =
    let
        contents =
            case mObs of
                Nothing ->
                    viewButtons

                Just obs ->
                    input
                        [ placeholder "Observation"
                        , value obs.text
                        , Util.onEnter SaveNew
                        , onInput UpdateNew
                        , Html.Attributes.id <| "input-group-" ++ (toString id)
                        , class "enter"
                        ]
                        []
    in
        div [ class "group-input" ] [ contents ]


viewObservations : List Observation.Model -> Html Msg
viewObservations os =
    section []
        [ Keyed.ul [ class "observation-list" ] <|
            List.map
                (\o -> ( "obs-" ++ (toString o.id), viewKeyedObservation o ))
                os
        ]


viewKeyedObservation : Observation.Model -> Html Msg
viewKeyedObservation obs =
    Html.map (UpdateExisting obs.id) (Observation.viewWithRemoveButton obs)


viewWithRemoveButton : Int -> Model -> Html Msg
viewWithRemoveButton numAcross model =
    div [ class <| "group-box-" ++ (toString numAcross) ]
        [ div [ class "group" ]
            [ button
                [ onClick Delete
                , class "remove"
                ]
                [ text "×" ]
            , lazy viewTitle model.name
            , lazy viewTotal model
            , lazy2 viewInput model.currentObs model.id
            , lazy viewObservations model.observations
            ]
        ]
