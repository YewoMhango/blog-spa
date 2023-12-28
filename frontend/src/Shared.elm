port module Shared exposing
    ( CSRFToken
    , Flags
    , Metadata
    , Model
    , Msg(..)
    , User
    , defaultPreviewImage
    , fetchCsrfToken
    , init
    , metadataToJson
    , subscriptions
    , update
    , updatePageMetadata
    )

import Http exposing (stringPart)
import Json.Decode exposing (bool, field)
import Json.Encode
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


type alias Metadata =
    { title : String
    , description : String
    , image : String
    , author : String
    }


defaultPreviewImage : String
defaultPreviewImage =
    "/static/preview-image.jpg"


type Msg
    = GetAuthDetails
    | GotAuthDetails (Result Http.Error User)
    | SignOut
    | SignOutResponse (Result Http.Error ())
    | SetCsrfToken String


loggedOutUser : User
loggedOutUser =
    User False False


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


metadataToJson : Metadata -> String
metadataToJson metadata =
    Json.Encode.object
        [ ( "title", Json.Encode.string metadata.title )
        , ( "description", Json.Encode.string metadata.description )
        , ( "image", Json.Encode.string metadata.image )
        , ( "author", Json.Encode.string metadata.author )
        ]
        |> Json.Encode.encode 0


port updatePageMetadata : String -> Cmd msg


port fetchCsrfToken : () -> Cmd msg


port csrfTokenReciever : (String -> msg) -> Sub msg


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    csrfTokenReciever SetCsrfToken
