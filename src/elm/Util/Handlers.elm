module Util.Handlers exposing (Handlers)


type alias Handlers childMsg parentMsg r =
    { r
        | onUpdate : childMsg -> parentMsg
        , remove : parentMsg
    }
