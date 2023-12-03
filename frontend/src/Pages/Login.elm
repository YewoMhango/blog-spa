module Pages.Login exposing (Model, Msg, handleLoginApiResultCsrf, page)

import Effect exposing (Effect)
import Footer
import Gen.Params.Login exposing (Params)
import Html exposing (a, button, div, h1, input, main_, p, text)
import Html.Attributes exposing (class, disabled, href, id, name, placeholder, style, type_)
import Html.Events exposing (onClick, onInput)
import Http
import Navbar
import Page
import Request
import Shared exposing (CSRFToken)
import Utils exposing (allNotEmptyStrings, flipBool, smallLoadingSpinner, tickAnimation)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared.csrfToken
        , update = update req
        , view = view shared
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
    | NavbarInputMsg String
    | EmailChanged String
    | PasswordChanged String
    | LoginButtonPressed
    | Uploaded (Result Http.Error String)


update : Request.Request -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        NavbarMsg navMsg ->
            Navbar.update model navMsg req

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value req

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
            ( { model
                | loginStatus =
                    ResponseReturned result
              }
            , handleLoginApiResultCsrf result
            )


handleLoginApiResultCsrf : Result error String -> Effect msg
handleLoginApiResultCsrf result =
    case result of
        Ok _ ->
            Effect.batch
                [ Effect.fromCmd <| Shared.fetchCsrfToken ()
                , Effect.fromShared Shared.GetAuthDetails
                ]

        Err _ ->
            Effect.fromShared Shared.GetAuthDetails



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Login"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg NavbarInputMsg
        , loginView model
        , Footer.view
        ]
    }


loginView : Model -> Html.Html Msg
loginView model =
    main_ [ class "login-page" ]
        [ div [ class "login-form" ]
            [ h1 [] [ text "Login" ]
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
            , div [ style "color" "red" ]
                [ text <|
                    case model.loginStatus of
                        ResponseReturned result ->
                            case result of
                                Err error ->
                                    case error of
                                        Http.Timeout ->
                                            "The request timed-out"

                                        Http.NetworkError ->
                                            "A network error occured while trying to authenticate"

                                        Http.BadStatus 400 ->
                                            "Incorrect email or password"

                                        _ ->
                                            "Authentication failed"

                                Ok _ ->
                                    ""

                        _ ->
                            ""
                ]
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
                            && (case model.loginStatus of
                                    ResponseReturned (Ok _) ->
                                        False

                                    _ ->
                                        True
                               )
                , onClick LoginButtonPressed
                ]
                (case model.loginStatus of
                    LoggingIn ->
                        [ smallLoadingSpinner True, text "Logging In" ]

                    EnteringData ->
                        [ text "Login" ]

                    ResponseReturned result ->
                        case result of
                            Err _ ->
                                [ text "Login" ]

                            Ok _ ->
                                [ tickAnimation "white" True, text "Login Successful" ]
                )
            , p []
                [ text "Or "
                , a [ href "/sign-up" ] [ text "sign-up" ]
                , text " if you don't already have an account"
                ]
            ]
        ]
