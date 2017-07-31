module Quiz.Group exposing (Group, Msg, init, update, encode, decoder)

import Css
import Css.Colors
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events as Events exposing (..)
import Html.Keyed as Keyed
import Html.Lazy exposing (..)
import Json.Decode as Decode
import Json.Encode as Encode
import KeyedList exposing (KeyedList, Key)
import Quiz.Observation as Observation exposing (Observation)
import Util exposing (..)
import Quiz.Config as Config exposing (..)


-- APP TESTING


main : Program Never Group Msg
main =
    Html.beginnerProgram
        { model = init "Test Group" []
        , update = update
        , view = view 1 testConfig
        }


testConfig : Config
testConfig =
    let
        kinds =
            Dict.fromList
                [ "+" => { symbol = '+', color = Css.Colors.green, weight = 1 }
                , "-" => { symbol = '-', color = Css.Colors.red, weight = -1 }
                ]
    in
        { kinds = kinds
        , tally = False
        }



-- MODEL


type Group
    = Group String (KeyedList Observation) (Maybe Observation)


init : String -> List Observation -> Group
init label observations =
    Group label (KeyedList.fromList observations) Nothing


encode : Group -> Encode.Value
encode (Group label observations current) =
    Encode.object
        [ "label" => Encode.string label
        , "observations"
            => (KeyedList.toList observations
                    |> List.map Observation.encode
                    |> Encode.list
               )
        , "current" => encodeMaybe Observation.encode current
        ]


decoder : Decode.Decoder Group
decoder =
    Decode.map3
        Group
        (Decode.field "label" Decode.string)
        (Decode.field "observations" <| keyedListDecoder Observation.decoder)
        (Decode.field "current" <| Decode.maybe Observation.decoder)



-- UPDATE


type Msg
    = StartNew String
    | UpdateCurrent String
    | SaveCurrent
    | UpdateExisting Key Observation.Msg
    | Delete Key
    | Relabel String


update : Msg -> Group -> Group
update msg (Group label observations current) =
    case msg of
        StartNew kind ->
            Observation.init kind "" 1
                |> Just
                |> Group label observations

        UpdateCurrent newLabel ->
            let
                newCurrent =
                    Maybe.map (Observation.relabel newLabel) current
            in
                Group label observations newCurrent

        SaveCurrent ->
            case current of
                Nothing ->
                    Group label observations Nothing

                Just obs ->
                    let
                        newObservations =
                            KeyedList.cons obs observations
                    in
                        Group label newObservations Nothing

        UpdateExisting key submsg ->
            let
                newObservations =
                    KeyedList.update key (Observation.update submsg) observations
            in
                Group label newObservations current

        Delete key ->
            let
                newObservations =
                    KeyedList.remove key observations
            in
                Group label newObservations current

        Relabel newLabel ->
            Group newLabel observations current



-- VIEW


view : Int -> Config -> Group -> Html Msg
view id config (Group label observations current) =
    div [ class "group" ]
        [ lazy viewLabel label

        -- , lazy2 viewTally config.tally observations
        , lazy3 viewCurrent id config current
        , lazy2 viewObservations config observations
        ]


viewLabel : String -> Html Msg
viewLabel label =
    div
        [ class "title"
        , contenteditable True
        , onContentEdit Relabel
        ]
        [ text label ]



-- viewTally : Bool -> KeyedList Observation -> Html Msg
-- viewTally showTally observations =
--     model.total
--         |> toString
--         |> text
--         |> List.singleton
--         |> h2
--             [ classList
--                 [ ( "points", True )
--                 , ( "total-" ++ (toString <| clamp 0 10 <| abs model.total), True )
--                 , ( "hidden", not model.showTally )
--                 , ( "pos", model.total > 0 )
--                 ]
--             ]


viewButton : ( String, KindSettings ) -> Html Msg
viewButton ( label, settings ) =
    button
        [ onClick <| StartNew label
        , class "input-button"
        , styles [ Css.backgroundColor settings.color ]
        ]
        [ text label ]


viewButtons : Config -> Html Msg
viewButtons config =
    Dict.toList config.kinds
        |> List.map viewButton
        |> div [ class "buttons" ]


viewCurrent : Int -> Config -> Maybe Observation -> Html Msg
viewCurrent id config obs =
    div
        []
        -- [ classList [ ( "group-input", True ), ( "editing", editing ) ] ]
        [ viewButtons config
        , input
            [ placeholder "Observation"

            -- , value text
            , onEnter SaveCurrent
            , onInput UpdateCurrent
            , Html.Attributes.id <| "input-group-" ++ (toString id)
            ]
            []
        ]


viewObservations : Config -> KeyedList Observation -> Html Msg
viewObservations config observations =
    KeyedList.keyedMap (viewKeyedObservation config) observations
        |> ul []


viewKeyedObservation : Config -> Key -> Observation -> Html Msg
viewKeyedObservation config key observation =
    let
        inner =
            Observation.view config observation
                |> Html.map (UpdateExisting key)
    in
        li []
            [ inner
            , button [ onClick (Delete key) ] [ text "x" ]
            ]
