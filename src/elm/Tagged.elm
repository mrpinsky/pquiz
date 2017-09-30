module Tagged exposing (..)


type alias Tagged tag r =
    { r | tag : tag }


update : (Tagged tag a -> Tagged tag a) -> tag -> Tagged tag a -> Tagged tag a
update fn tag item =
    if tag == item.tag then fn item else item


match : tag -> Tagged tag r -> Bool
match tag item =
    item.tag == tag
