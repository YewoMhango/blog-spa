module Pages.NotFound exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.NotFound exposing (Params)
import Html exposing (a, div, h1, h3, main_, p, text)
import Html.Attributes exposing (class, href)
import Navbar
import Page
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared _ =
    Page.advanced
        { init = init
        , update = update
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model }


init : ( Model, Effect Msg )
init =
    ( Model Navbar.init, Effect.none )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NavbarMsg navMsg ->
            Navbar.update model navMsg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "404 - Page not Found"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg
        , view404
        ]
    }


view404 : Html.Html msg
view404 =
    main_ [ class "not-found-page" ]
        [ div [ class "container" ]
            [ h1 [] [ text "404" ]
            , h3 [] [ text "Page not Found" ]
            , p [] [ text "There was nothing found at this URL. Please check that you entered correctly or go back to the ", a [ href "/" ] [ text "homepage" ] ]
            ]
        ]
