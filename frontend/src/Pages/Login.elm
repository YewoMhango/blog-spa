module Pages.Login exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.Login exposing (Params)
import Html exposing (a, button, div, h1, input, main_, p, text)
import Html.Attributes exposing (class, disabled, href, id, name, placeholder, type_)
import Html.Events exposing (onInput)
import Http
import Navbar
import Page
import Request
import Shared exposing (CSRFToken)
import Utils exposing (allNotEmptyStrings, flipBool, smallLoadingSpinner, tickAnimation)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page sharedModel _ =
    Page.advanced
        { init = init sharedModel.csrfToken
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model
    , email : String
    , password : String
    , loginStatus : LoginStatus
    , csrfToken : CSRFToken
    }


type LoginStatus
    = EnteringData
    | LoggingIn
    | ResponseReturned (Result Http.Error String)


init : CSRFToken -> ( Model, Effect Msg )
init csrfToken =
    ( { navbarModel = Navbar.init
      , email = ""
      , password = ""
      , csrfToken = csrfToken
      , loginStatus = EnteringData
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg
    | EmailChanged String
    | PasswordChanged String
    | LoginButtonPressed
    | Uploaded (Result Http.Error String)


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

        LoginButtonPressed ->
            ( { model | loginStatus = LoggingIn }
            , Effect.fromCmd <|
                Http.post
                    { url = "/api/login"
                    , body =
                        Http.multipartBody
                            [ Http.stringPart "csrfmiddlewaretoken" model.csrfToken
                            , Http.stringPart "email" model.email
                            , Http.stringPart "password" model.password
                            ]
                    , expect = Http.expectString Uploaded
                    }
            )

        Uploaded result ->
            ( { model | loginStatus = ResponseReturned result }, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Login"
    , body =
        [ Navbar.view model.navbarModel NavbarMsg
        , loginView model
        ]
    }


loginView : Model -> Html.Html Msg
loginView model =
    main_ [ class "login-page" ]
        [ div [ class "login-form" ]
            [ h1 [] [ tickAnimation "" True, text "Login" ]
            , input
                [ id "email"
                , name "email"
                , type_ "email"
                , placeholder "Email"
                , onInput EmailChanged
                ]
                []
            , input
                [ id "password"
                , name "password"
                , type_ "password"
                , placeholder "Password"
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
                            ]
                            && String.length model.password
                            > 5
                            && String.contains "@" model.email
                ]
                [ smallLoadingSpinner <| model.loginStatus == LoggingIn
                , case model.loginStatus of
                    LoggingIn ->
                        text "Logging In"

                    EnteringData ->
                        text "Login"

                    ResponseReturned result ->
                        case result of
                            Err _ ->
                                text "Login"

                            Ok _ ->
                                text "Login Successful"
                ]
            , p []
                [ text "Or "
                , a [ href "/sign-up" ] [ text "sign-up" ]
                , text " if you don't already have an account"
                ]
            ]
        ]
