module Pages.Post.Title_ exposing (Model, Msg, Post, page, postLoadingAnimation)

import Effect exposing (Effect)
import Footer
import Gen.Params.Post.Title_ exposing (Params)
import Html exposing (Html, a, div, h1, header, main_, p, span, text)
import Html.Attributes exposing (class, href)
import Http
import Json.Decode exposing (Decoder, field, int, map7, string)
import Markdown
import Navbar
import Page
import Request
import Shared
import Utils exposing (RemoteData(..), renderHttpError)
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
    = GotPost (Result Http.Error Post)
    | NavbarMsg Navbar.Msg
    | NavbarInputMsg String


update : Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update req_ msg model =
    let
        req =
            Navbar.requestFromRequestWithParams req_
    in
    case msg of
        GotPost result ->
            ( { model
                | post =
                    case result of
                        Ok post ->
                            Successful post

                        Err error ->
                            Failed error
              }
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
        , expect = Http.expectJson GotPost postDecoder
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
        , viewPost model shared.user.canPost
        , Footer.view
        ]
    }


viewTitle : Model -> String
viewTitle model =
    case model.post of
        Loading ->
            "Loading blog post..."

        Successful post ->
            post.title

        Failed _ ->
            "Error loading blog post"


viewPost : Model -> Bool -> Html Msg
viewPost model canEdit =
    main_ [ class "post-page" ]
        (case model.post of
            Loading ->
                postLoadingAnimation

            Successful post ->
                [ header []
                    [ div [ class "container" ]
                        [ h1 [] [ text post.title ]
                        , div [ class "summary" ] [ text post.summary ]
                        , div [ class "details" ]
                            [ span []
                                [ text
                                    (post.author
                                        ++ " | "
                                        ++ post.date
                                    )
                                ]
                            , if canEdit then
                                span []
                                    [ text " | "
                                    , a [ href ("/post/" ++ model.urlSlug ++ "/edit") ] [ text "Edit" ]
                                    ]

                              else
                                text ""
                            ]
                        ]
                    ]
                , div [ class "content" ] [ Markdown.toHtml [ class "container" ] post.content ]
                ]

            Failed error ->
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
