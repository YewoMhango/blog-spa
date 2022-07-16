module Pages.About exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.About exposing (Params)
import Html exposing (a, div, h2, p, text)
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
    { title = "About Me"
    , body = [ Navbar.view shared model.navbarModel NavbarMsg, viewAbout ]
    }


viewAbout : Html.Html msg
viewAbout =
    div [ class "about-page" ]
        [ div [ class "container" ]
            [ h2 [] [ text "Made by Yewo Mhango" ]
            , p [] [ text "You can contact or find me using these links:" ]
            , div []
                [ p []
                    [ text "Email: "
                    , a [ href "mailto:mhangoyewoh@gmail.com" ] [ text "mhangoyewoh@gmail.com" ]
                    ]
                , p []
                    [ text "GitHub: "
                    , a [ href "https://github.com/YewoMhango" ] [ text "@YewoMhango" ]
                    ]
                , p []
                    [ text "LinkedIn: "
                    , a [ href "https://www.linkedin.com/in/yewo-mhango/" ] [ text "@yewo-mhango" ]
                    ]
                ]
            ]
        ]
