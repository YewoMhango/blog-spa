module Pages.NotFound exposing (Model, Msg, page)

import Effect exposing (Effect)
import Footer
import Gen.Params.NotFound exposing (Params)
import Html exposing (a, div, h1, h3, main_, p, text)
import Html.Attributes exposing (class, href)
import Navbar
import Page
import Request
import Shared
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model }


init : ( Model, Effect Msg )
init =
    ( Model Navbar.init
    , Effect.fromCmd <|
        Shared.updatePageMetadata <|
            Shared.metadataToJson
                { title = "404 - Page not found"
                , description = "Nothing was found at this URL"
                , image = Shared.defaultPreviewImage
                , author = "Yewo Mhango"
                }
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg
    | NavbarInputMsg String


update : Request.Request -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        NavbarMsg navMsg ->
            Navbar.update model navMsg req

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value req



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "404 - Page not Found"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg NavbarInputMsg
        , view404
        , Footer.view
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
