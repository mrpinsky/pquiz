module Util.Handlers exposing (..)


type alias Handlers childMsg parentMsg r =
    { r
        | onUpdate : childMsg -> parentMsg
        , remove : parentMsg
    }


map : Handlers msg parentMsg r -> (childMsg -> msg) -> Handlers childMsg parentMsg r
map handlers transform =
    { handlers | onUpdate = handlers.onUpdate << transform }
