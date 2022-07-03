module Shared exposing
    ( Flags
    , Model
    , Msg
    , init
    , subscriptions
    , update
    , CSRFToken
    )

import Json.Decode as Json
import Request exposing (Request)


type alias Flags =
    CSRFToken

type alias CSRFToken = String

type alias Model =
    {csrfToken: CSRFToken}


type Msg
    = NoOp


init : Request -> Flags -> ( Model, Cmd Msg )
init _ csrfToken =
    ( Model csrfToken, Cmd.none )


update : Request -> Msg -> Model -> ( Model, Cmd Msg )
update _ msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


subscriptions : Request -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none
