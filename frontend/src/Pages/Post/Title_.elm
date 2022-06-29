module Pages.Post.Title_ exposing (Model, Msg, page)

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
page _ req =
    Page.element
        { view = view
        , init = init req
        , update = update
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
    , synopsis : String
    , author : String
    , date : String
    , content : String
    , thumbnail : String
    , views : Int
    }


init : Request.With Params -> ( Model, Cmd Msg )
init req =
    ( Model Loading req.params.title Navbar.init
    , getPost req.params.title
    )



-- UPDATE


type Msg
    = GotPosts (Result Http.Error Post)
    | NavbarMsg Navbar.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        GotPosts result ->
            { model | post = RequestDone result }

        NavbarMsg innerMsg ->
            { model | navbarModel = Navbar.update model.navbarModel innerMsg }
    , Cmd.none
    )


getPost : String -> Cmd Msg
getPost postSLug =
    Http.get
        { url = "/api/post/" ++ postSLug ++ ".json"
        , expect = Http.expectJson GotPosts postDecoder
        }


postDecoder : Decoder Post
postDecoder =
    map7 Post
        (field "title" string)
        (field "synopsis" string)
        (field "author" string)
        (field "date" string)
        (field "content" string)
        (field "thumbnail" string)
        (field "views" int)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = viewTitle model
    , body = [ Navbar.view model.navbarModel NavbarMsg, viewPost model.post ]
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
                                , div [ class "synopsis" ] [ text post.synopsis ]
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
            , div [ class "synopsis line" ] []
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
