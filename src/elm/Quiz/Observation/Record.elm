module Quiz.Observation.Record
    exposing
        ( Record
        , Msg
        , init
        , value
        , update
        , view
        , viewOnlyIncrementable
        , viewStatic
        , encode
        , decoder
        )

import Css
import Html exposing (Html, li, s, button, div, text)
import Html.Attributes as Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Json.Decode as Decode
import Quiz.Observation as Observation exposing (Observation, MenuContent)
import Quiz.Theme as Theme exposing (Theme, Topic)
import Util exposing (..)
import Util.Handlers as Handlers exposing (Handlers)


-- MODEL


type alias Record =
    { observation : Observation
    , state : State
    }


type State
    = Struck
    | Active Int


init : Int -> Observation -> Record
init tally observation =
    Record observation <| Active tally


value : Theme -> Record -> Int
value theme { observation, state } =
    case state of
        Struck ->
            0

        Active tally ->
            let
                weight =
                    theme
                        |> Theme.lookup observation.style
                        |> .weight
            in
                tally * weight



-- UPDATE


type Msg
    = Increment
    | Strike
    | UpdateObservation Observation.Msg


update : Msg -> Record -> Record
update msg record =
    case msg of
        Increment ->
            { record | state = increment record.state }

        Strike ->
            { record | state = Struck }

        UpdateObservation subMsg ->
            { record | observation = Observation.update subMsg record.observation }


increment : State -> State
increment state =
    case state of
        Active n ->
            Active <| n + 1

        _ ->
            state



-- VIEW


view : Handlers Msg msg r -> Theme -> Record -> Html msg
view handlers theme { state, observation } =
    let
        { color, symbol } =
            Theme.lookup observation.style theme

        endButtons =
            case state of
                Struck ->
                    []

                Active _ ->
                    [ button
                        [ onClick (handlers.onUpdate Strike)
                        , class "fas fa-strikethrough"
                        ]
                        []
                    , button
                        [ onClick handlers.remove
                        , class "fas fa-trash"
                        ]
                        []
                    ]

        tally =
            button [ onClick Increment, class "tally" ]
                [ tallyText symbol state ]
                |> viewStartButtons color state
                |> Html.map handlers.onUpdate

        content =
            Observation.view
                (Handlers.map handlers UpdateObservation)
                (MenuContent color [ tally ] endButtons)
                observation
    in
        viewAsListItem state color content


viewOnlyIncrementable : Handlers Msg msg r -> Theme -> Record -> Html msg
viewOnlyIncrementable handlers theme { state, observation } =
    let
        { color, symbol } =
            Theme.lookup observation.style theme

        tally =
            button
                [ onClick Increment, class "tally" ]
                [ tallyText symbol state ]
                |> viewStartButtons color state

        content =
            Observation.viewStatic
                (MenuContent color [ tally ] [])
                observation
    in
        viewAsListItem state color content
            |> Html.map handlers.onUpdate


viewStatic : Theme -> Record -> Html msg
viewStatic theme { state, observation } =
    let
        { color, symbol } =
            Theme.lookup observation.style theme

        tally =
            div [ class "tally" ] [ tallyText symbol state ]
                |> viewStartButtons color state

        content =
            Observation.viewStatic (MenuContent color [ tally ] []) observation
    in
        viewAsListItem state color content


viewAsListItem : State -> Css.Color -> Html msg -> Html msg
viewAsListItem state color content =
    let
        { background, class } =
            stateCss color state
    in
        li
            [ styles [ Css.backgroundColor background ]
            , Attributes.class "observation"
            , Attributes.class class
            ]
            [ content ]


type alias StateCss =
    { class : String
    , background : Css.Color
    }


stateCss : Css.Color -> State -> StateCss
stateCss color state =
    case state of
        Struck ->
            StateCss "struck" <| Css.hex "eeeeee"

        Active tally ->
            StateCss "active" <| fade color tally


viewStartButtons : Css.Color -> State -> Html msg -> Html msg
viewStartButtons color state content =
    let
        background =
            if state == Active 0 then
                Css.hex "eee"
            else
                color
    in
        div
            [ class "buttons start"
            , styles [ Css.backgroundColor background ]
            ]
            [ content ]


tallyText : String -> State -> Html msg
tallyText symbol state =
    case state of
        Struck ->
            Html.text "-"

        Active tally ->
            Html.text <| toString tally ++ symbol



-- JSON


encode : Record -> Encode.Value
encode { observation, state } =
    Encode.object
        [ "observation" => Observation.encode observation
        , "state" => encodeState state
        ]


encodeState : State -> Encode.Value
encodeState state =
    case state of
        Struck ->
            Encode.null

        Active tally ->
            Encode.int tally


decoder : Decode.Decoder Record
decoder =
    Decode.map2 Record
        (Decode.field "observation" Observation.decoder)
        (Decode.field "state" stateDecoder)


stateDecoder : Decode.Decoder State
stateDecoder =
    Decode.oneOf
        [ Decode.null Struck
        , Decode.map Active Decode.int
        ]
