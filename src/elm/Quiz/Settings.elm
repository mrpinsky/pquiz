module Quiz.Settings exposing (..)

import Css exposing (Color)
import Html exposing (..)
import Html.Events
import Json.Decode as Decode
import Json.Encode as Encode
import Quiz.Observation.Options as Options exposing (Options)
import Quiz.Observation.Style as Style exposing (Style)
import Util exposing ((=>), delta)


type alias Settings =
    { options : Options
    , tally : Bool
    , groupWidth : Css.Px
    }


styleIds : Settings -> List Options.Id
styleIds { options } =
    Options.idList options


default : Settings
default =
    { options = Options.init
    , tally = False
    , groupWidth = Css.px 200
    }


type Msg
    = UpdateOptions Options.Msg
    | ToggleTally
    | SetGroupWidth Float


update : Msg -> Settings -> Settings
update msg settings =
    case msg of
        UpdateOptions optionsMsg ->
            { settings
                | options = Options.update optionsMsg settings.options
            }

        ToggleTally ->
            { settings | tally = not settings.tally }

        SetGroupWidth px ->
            { settings | groupWidth = Css.px px }


view : Settings -> Html Msg
view { options } =
    Options.view options
        |> Html.map UpdateOptions



-- JSON


encode : Settings -> Encode.Value
encode { options, tally, groupWidth } =
    Encode.object
        [ "options" => Options.encode options
        , "tally" => Encode.bool tally
        , "groupWidth" => Encode.float groupWidth.numericValue
        ]


decoder : Options.Option -> Decode.Decoder Settings
decoder defaultOption =
    Decode.map3
        Settings
        (Decode.field "options" Options.decoder)
        (Decode.field "tally" Decode.bool)
        (Decode.field "groupWidth" <| Decode.map Css.px Decode.float)
