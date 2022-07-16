module Pages.Home_ exposing (Model, Msg, PostDetails, page, postsLoadingAnimation, renderPosts, renderPostsData)

import Effect exposing (Effect)
import Html exposing (Html, a, div, h1, img, main_, p, text)
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
page shared _ =
    Page.advanced
        { view = view shared
        , init = init
        , update = update
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


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotPosts result ->
            ( { model | posts = RequestDone result }
            , Effect.none
            )

        NavbarMsg innerMsg ->
            Navbar.update model innerMsg


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
        , viewPosts model.posts
        ]
    }


viewPosts : RemoteData (List PostDetails) Http.Error -> Html Msg
viewPosts postsData =
    main_ [ class "homepage" ]
        [ renderPostsData postsData noPostsToShow
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

        RequestDone result ->
            case result of
                Ok posts ->
                    if List.length posts > 0 then
                        div [ class "post-list" ] <|
                            renderPosts posts

                    else
                        noPosts

                Err error ->
                    renderHttpError error


renderPosts : List PostDetails -> List (Html msg)
renderPosts posts =
    case posts of
        post :: others ->
            div [ class "post" ]
                [ a [ href post.url ]
                    [ img [ src post.thumbnail, class "thumbnail" ] []
                    , div [ class "date" ] [ text post.date ]
                    , h1 [ class "title" ] [ text post.title ]
                    , div [ class "summary" ] [ text post.summary ]
                    ]
                ]
                :: renderPosts others

        [] ->
            []
