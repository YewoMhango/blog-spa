module Shared exposing
    ( CSRFToken
    , Flags
    , Model
    , Msg(..)
    , User
    , init
    , subscriptions
    , update
    )

import Http exposing (stringPart)
import Json.Decode exposing (bool, field)
import Request exposing (Request)


type alias Flags =
    CSRFToken


type alias CSRFToken =
    String


type alias Model =
    { csrfToken : CSRFToken
    , user : User
    , syncingAuthentication : Bool
    }


type alias User =
    { isAuthenticated : Bool, canPost : Bool }


loggedOutUser : User
loggedOutUser =
    User False False


type Msg
    = GetAuthDetails
    | GotAuthDetails (Result Http.Error User)
    | SignOut
    | SignOutResponse (Result Http.Error ())
    | SetCsrfToken String


init : Request -> Flags -> ( Model, Cmd Msg )
init _ csrfToken =
    ( { csrfToken = csrfToken
      , user = loggedOutUser
      , syncingAuthentication = True
      }
    , getAuthDetails
    )


getAuthDetails : Cmd Msg
getAuthDetails =
    Http.get
        { url = "/api/user-details"
        , expect =
            Http.expectJson
                GotAuthDetails
                userDetailsDecoder
        }


userDetailsDecoder : Json.Decode.Decoder User
userDetailsDecoder =
    Json.Decode.map2 User
        (field "authenticated" bool)
        (field "canpost" bool)


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        GetAuthDetails ->
            ( { model | syncingAuthentication = True }
            , getAuthDetails
            )

        GotAuthDetails result ->
            ( case result of
                Ok user ->
                    { model | user = user, syncingAuthentication = False }

                Err _ ->
                    { model | syncingAuthentication = False }
            , Cmd.none
            )

        SignOut ->
            ( { model | syncingAuthentication = True }
            , Http.post
                { url = "/api/logout"
                , body =
                    Http.multipartBody
                        [ stringPart "csrfmiddlewaretoken" model.csrfToken
                        ]
                , expect = Http.expectWhatever SignOutResponse
                }
            )

        SignOutResponse result ->
            ( case result of
                Ok _ ->
                    { model
                        | user = loggedOutUser
                        , syncingAuthentication = False
                    }

                Err _ ->
                    { model | syncingAuthentication = False }
            , Cmd.none
            )

        SetCsrfToken token ->
            ( { model | csrfToken = token }, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
