module Auth exposing
    ( User
    , beforeProtectedInit
    )

{-|

@docs User
@docs beforeProtectedInit

-}

import ElmSpa.Page as ElmSpa
import Gen.Route exposing (Route(..))
import Request exposing (Request)
import Shared exposing (User)


type alias User =
    Shared.User


{-| This function will run before any `protected` pages.

Here, you can provide logic on where to redirect if a user is not signed in.

-}
beforeProtectedInit : Shared.Model -> Request -> ElmSpa.Protected User Route
beforeProtectedInit shared _ =
    if shared.user.canPost then
        ElmSpa.Provide shared.user

    else
        ElmSpa.RedirectTo Login
