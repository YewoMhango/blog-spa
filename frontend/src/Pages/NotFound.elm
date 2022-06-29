module Pages.NotFound exposing (Model, Msg, page)

import Gen.Params.NotFound exposing (Params)
import Html exposing (a, div, h1, h3, main_, p, text)
import Html.Attributes exposing (class, href)
import Navbar
import Page
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model }


init : ( Model, Cmd Msg )
init =
    ( Model Navbar.init, Cmd.none )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NavbarMsg navMsg ->
            ( { model | navbarModel = Navbar.update model.navbarModel navMsg }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "404 - Page not Found"
    , body = [ Navbar.view model.navbarModel NavbarMsg, view404 ]
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
