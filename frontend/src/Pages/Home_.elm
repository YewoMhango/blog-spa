module Pages.Home_ exposing (Model, Msg, PostDetails, page, postsLoadingAnimation, renderPosts, renderPostsData)

import Effect exposing (Effect)
import Footer
import Html exposing (Html, a, div, h1, h2, img, main_, p, text)
import Html.Attributes exposing (class, href, src)
import Http
import Json.Decode exposing (Decoder, field, list, map5, string)
import List
import Navbar
import Page
import Request exposing (Request)
import Shared
import Utils exposing (RemoteData(..), renderHttpError)
import View exposing (View)



-- HOME PAGE


page : Shared.Model -> Request -> Page.With Model Msg
page shared req =
    Page.advanced
        { view = view shared
        , init = init
        , update = update req
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { posts : RemoteData (List PostDetails) Http.Error
    , navbarModel : Navbar.Model
    }


type alias PostDetails =
    { title : String
    , summary : String
    , date : String
    , url : String
    , thumbnail : String
    }


init : ( Model, Effect Msg )
init =
    ( Model Loading Navbar.init
    , Effect.fromCmd getPosts
    )



-- UPDATE


type Msg
    = GotPosts (Result Http.Error (List PostDetails))
    | NavbarMsg Navbar.Msg
    | NavbarInputMsg String


update : Request.Request -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        GotPosts result ->
            ( { model
                | posts =
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


getPosts : Cmd Msg
getPosts =
    Http.get
        { url = "/api/posts"
        , expect = Http.expectJson GotPosts postsDecoder
        }


postsDecoder : Decoder (List PostDetails)
postsDecoder =
    list
        (map5 PostDetails
            (field "title" string)
            (field "summary" string)
            (field "date" string)
            (field "url" string)
            (field "thumbnail" string)
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Homepage"
    , body =
        [ Navbar.view
            shared
            model.navbarModel
            NavbarMsg
            NavbarInputMsg
        , viewPosts model.posts
        , Footer.view
        ]
    }


viewPosts : RemoteData (List PostDetails) Http.Error -> Html Msg
viewPosts postsData =
    main_ [ class "homepage" ]
        [ h1 [ class "heading" ] [ text "Yewo's Blog" ]
        , renderPostsData postsData noPostsToShow
        ]


postsLoadingAnimation : Html msg
postsLoadingAnimation =
    div [ class "post loading-animation" ]
        [ div [ class "thumbnail image" ] []
        , div [ class "date line" ] []
        , div [ class "title line" ] []
        , div [ class "summary" ]
            [ div [ class "line" ] []
            , div [ class "line" ] []
            , div [ class "line" ] []
            ]
        ]


noPostsToShow : Html msg
noPostsToShow =
    div [ class "no-posts-to-show" ] [ p [] [ text "No posts have been added yet" ] ]


renderPostsData : RemoteData (List PostDetails) Http.Error -> Html msg -> Html msg
renderPostsData postsData noPosts =
    case postsData of
        Loading ->
            div [ class "post-list" ] <|
                List.repeat 8 postsLoadingAnimation

        Successful posts ->
            if List.length posts > 0 then
                div [ class "post-list" ] <|
                    renderPosts posts

            else
                noPosts

        Failed error ->
            renderHttpError error


renderPosts : List PostDetails -> List (Html msg)
renderPosts posts =
    case posts of
        post :: others ->
            div [ class "post" ]
                [ a [ href post.url ]
                    [ img [ src post.thumbnail, class "thumbnail" ] []
                    , div [ class "date" ] [ text post.date ]
                    , h2 [ class "title" ] [ text post.title ]
                    , div [ class "summary" ] [ text post.summary ]
                    ]
                ]
                :: renderPosts others

        [] ->
            []
