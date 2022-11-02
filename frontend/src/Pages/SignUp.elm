module Pages.SignUp exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.SignUp exposing (Params)
import Html exposing (a, button, div, h1, input, main_, p, text)
import Html.Attributes exposing (class, disabled, href, id, name, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Http exposing (Error(..))
import Navbar
import Page
import Pages.Login exposing (handleLoginApiResultCsrf)
import Request
import Shared exposing (CSRFToken)
import Utils exposing (allNotEmptyStrings, flipBool, smallLoadingSpinner, tickAnimation)
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init shared
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }



-- INIT


type alias Model =
    { navbarModel : Navbar.Model
    , email : String
    , firstName : String
    , lastName : String
    , password : String
    , signupStatus : SignupStatus
    , csrfToken : CSRFToken
    }


type SignupStatus
    = SigningUp
    | EnteringData
    | ResponseReturned (Result Http.Error String)


init : Shared.Model -> ( Model, Effect Msg )
init shared =
    ( { navbarModel = Navbar.init
      , email = ""
      , firstName = ""
      , lastName = ""
      , password = ""
      , signupStatus = EnteringData
      , csrfToken = shared.csrfToken
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg
    | NavbarInputMsg String
    | EmailChanged String
    | PasswordChanged String
    | FirstNameChanged String
    | LastNameChanged String
    | SignupButtonPressed
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

        FirstNameChanged firstName ->
            ( { model | firstName = firstName }, Effect.none )

        LastNameChanged lastName ->
            ( { model | lastName = lastName }, Effect.none )

        SignupButtonPressed ->
            ( { model | signupStatus = SigningUp }
            , Effect.fromCmd <|
                Http.post
                    { url = "/api/sign-up"
                    , body =
                        Http.multipartBody
                            [ Http.stringPart "csrfmiddlewaretoken" model.csrfToken
                            , Http.stringPart "email" model.email
                            , Http.stringPart "password" model.password
                            , Http.stringPart "firstname" model.firstName
                            , Http.stringPart "lastname" model.lastName
                            ]
                    , expect = Http.expectString Uploaded
                    }
            )

        Uploaded result ->
            ( { model | signupStatus = ResponseReturned result }
            , handleLoginApiResultCsrf result
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Sign Up"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg NavbarInputMsg
        , signUpView model
        ]
    }


signUpView : Model -> Html.Html Msg
signUpView model =
    main_ [ class "sign-up-page" ]
        [ div [ class "sign-up-form" ]
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
            , errorMessage model
            , signUpButton model
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


signUpButton : Model -> Html.Html Msg
signUpButton model =
    button
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
                    && (case model.signupStatus of
                            ResponseReturned (Ok _) ->
                                False

                            _ ->
                                True
                       )
        , onClick SignupButtonPressed
        ]
        (case model.signupStatus of
            SigningUp ->
                [ smallLoadingSpinner True, text "Signing Up" ]

            EnteringData ->
                [ text "Sign Up" ]

            ResponseReturned result ->
                case result of
                    Err _ ->
                        [ text "Sign Up" ]

                    Ok _ ->
                        [ tickAnimation "white" True, text "Sign Up Successful" ]
        )


errorMessage : Model -> Html.Html Msg
errorMessage model =
    div [ style "color" "red" ]
        [ text <|
            case model.signupStatus of
                ResponseReturned result ->
                    case result of
                        Err error ->
                            case error of
                                Http.Timeout ->
                                    "The request timed-out"

                                Http.NetworkError ->
                                    "A network error occured while trying to sign up"

                                Http.BadStatus 400 ->
                                    "Incorrect details provided"

                                _ ->
                                    "Signing up failed"

                        Ok _ ->
                            ""

                _ ->
                    ""
        ]
