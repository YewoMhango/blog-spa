module Pages.SignUp exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.Login exposing (Params)
import Html exposing (a, button, div, h1, input, main_, p, text)
import Html.Attributes exposing (class, disabled, href, id, name, placeholder, type_, value)
import Html.Events exposing (onInput)
import Navbar
import Page
import Request
import Shared
import Utils exposing (allNotEmptyStrings, flipBool)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page _ _ =
    Page.advanced
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model
    , email : String
    , firstName : String
    , lastName : String
    , password : String
    }


init : ( Model, Effect Msg )
init =
    ( { navbarModel = Navbar.init
      , email = ""
      , firstName = ""
      , lastName = ""
      , password = ""
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg
    | EmailChanged String
    | PasswordChanged String
    | FirstNameChanged String
    | LastNameChanged String


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NavbarMsg navMsg ->
            ( { model
                | navbarModel =
                    Navbar.update model.navbarModel navMsg
              }
            , Effect.none
            )

        EmailChanged email ->
            ( { model | email = email }, Effect.none )

        PasswordChanged password ->
            ( { model | password = password }, Effect.none )

        FirstNameChanged firstName ->
            ( { model | firstName = firstName }, Effect.none )

        LastNameChanged lastName ->
            ( { model | lastName = lastName }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Sign Up"
    , body =
        [ Navbar.view model.navbarModel NavbarMsg
        , signInView model
        ]
    }


signInView : Model -> Html.Html Msg
signInView model =
    main_ [ class "sign-in-page" ]
        [ div [ class "sign-in-form" ]
            [ h1 [] [ text "Sign Up" ]
            , input
                [ id "email"
                , name "email"
                , type_ "email"
                , placeholder "Email"
                , value model.email
                , onInput EmailChanged
                ]
                []
            , input
                [ id "firstname"
                , name "firstname"
                , type_ "text"
                , placeholder "First Name"
                , value model.firstName
                , onInput FirstNameChanged
                ]
                []
            , input
                [ id "lastname"
                , name "lastname"
                , type_ "text"
                , placeholder "Last Name"
                , value model.lastName
                , onInput LastNameChanged
                ]
                []
            , input
                [ id "password"
                , name "password"
                , type_ "password"
                , placeholder "Password"
                , value model.password
                , onInput PasswordChanged
                ]
                []
            , button
                [ class "confirm"
                , disabled <|
                    flipBool <|
                        allNotEmptyStrings
                            [ model.password
                            , model.email
                            , model.firstName
                            , model.lastName
                            ]
                            && String.length model.password
                            > 5
                            && String.contains "@" model.email
                ]
                [ text "Sign Up" ]
            , p []
                [ text "Or "
                , a
                    [ href "/login"
                    ]
                    [ text "login" ]
                , text " if you already have an account"
                ]
            ]
        ]
