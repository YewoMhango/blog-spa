module Pages.Post.Title_ exposing (Model, Msg, page)

import Effect exposing (Effect)
import Gen.Params.Post.Title_ exposing (Params)
import Html exposing (Html, div, h1, header, main_, p, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode exposing (Decoder, field, int, map7, string)
import Markdown
import Navbar
import Page
import Request
import Shared
import Utils exposing (renderHttpError)
import View exposing (View)



-- HOME PAGE


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { view = view shared
        , init = init req
        , update = update req
        , subscriptions = subscriptions
        }



-- MODEL


type RemoteData data error
    = Loading
    | RequestDone (Result error data)


type alias Model =
    { post : RemoteData Post Http.Error
    , urlSlug : String
    , navbarModel : Navbar.Model
    }


type alias Post =
    { title : String
    , summary : String
    , author : String
    , date : String
    , content : String
    , image : String
    , views : Int
    }


init : Request.With Params -> ( Model, Effect Msg )
init req =
    ( Model Loading req.params.title Navbar.init
    , Effect.fromCmd <| getPost req.params.title
    )



-- UPDATE


type Msg
    = GotPosts (Result Http.Error Post)
    | NavbarMsg Navbar.Msg
    | NavbarInputMsg String


update : Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update req_ msg model =
    let
        req =
            Navbar.requestFromRequestWithParams req_
    in
    case msg of
        GotPosts result ->
            ( { model | post = RequestDone result }
            , Effect.none
            )

        NavbarMsg innerMsg ->
            Navbar.update model innerMsg req

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value req


getPost : String -> Cmd Msg
getPost postSLug =
    Http.get
        { url = "/api/post/" ++ postSLug
        , expect = Http.expectJson GotPosts postDecoder
        }


postDecoder : Decoder Post
postDecoder =
    map7 Post
        (field "title" string)
        (field "summary" string)
        (field "author" string)
        (field "date" string)
        (field "content" string)
        (field "image" string)
        (field "views" int)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = viewTitle model
    , body =
        [ Navbar.view
            shared
            model.navbarModel
            NavbarMsg
            NavbarInputMsg
        , viewPost model.post
        ]
    }


viewTitle : Model -> String
viewTitle model =
    case model.post of
        Loading ->
            "Loading blog post..."

        RequestDone result ->
            case result of
                Ok post ->
                    post.title

                Err _ ->
                    "Error loading blog post"


viewPost : RemoteData Post Http.Error -> Html Msg
viewPost postsData =
    main_ [ class "post-page" ]
        (case postsData of
            Loading ->
                postLoadingAnimation

            RequestDone result ->
                case result of
                    Ok post ->
                        [ header []
                            [ div [ class "container" ]
                                [ h1 [] [ text post.title ]
                                , div [ class "summary" ] [ text post.summary ]
                                , div [ class "details" ]
                                    [ text
                                        (post.author
                                            ++ " | "
                                            ++ post.date
                                            ++ " | "
                                            ++ String.fromInt post.views
                                            ++ " views"
                                        )
                                    ]
                                ]
                            ]
                        , div [ class "content" ] [ Markdown.toHtml [ class "container" ] post.content ]
                        ]

                    Err error ->
                        [ renderHttpError error ]
        )


postLoadingAnimation : List (Html msg)
postLoadingAnimation =
    [ div [ class "header loading-animation" ]
        [ div [ class "container" ]
            [ h1 [ class "line" ] []
            , div [ class "summary line" ] []
            , div [ class "details line" ]
                []
            ]
        ]
    , div [ class "content loading-animation" ]
        [ div [ class "container" ]
            [ p []
                [ div [ class "line first-line" ] []
                , div [ class "line second-line" ] []
                , div [ class "line third-line" ] []
                ]
            , p []
                [ div [ class "line first-line" ] []
                , div [ class "line second-line" ] []
                , div [ class "line third-line" ] []
                ]
            , p []
                [ div [ class "line first-line" ] []
                , div [ class "line second-line" ] []
                , div [ class "line third-line" ] []
                ]
            , p []
                [ div [ class "line first-line" ] []
                , div [ class "line second-line" ] []
                , div [ class "line third-line" ] []
                ]
            , p []
                [ div [ class "line first-line" ] []
                , div [ class "line second-line" ] []
                , div [ class "line third-line" ] []
                ]
            ]
        ]
    ]
