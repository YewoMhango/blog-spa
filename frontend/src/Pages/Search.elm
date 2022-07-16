module Pages.Search exposing (Model, Msg, page)

import Dict
import Effect exposing (Effect)
import Html exposing (Html, div, h2, main_, p, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode exposing (Decoder, field, list, map5, string)
import Navbar
import Page
import Pages.Home_ exposing (PostDetails, renderPostsData)
import Request exposing (Request)
import Shared
import Utils exposing (RemoteData(..))
import View exposing (View)



-- SEARCH PAGE


page : Shared.Model -> Request -> Page.With Model Msg
page shared req =
    Page.advanced
        { view = view shared
        , init = init req
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { posts : RemoteData (List PostDetails) Http.Error
    , navbarModel : Navbar.Model
    , query : QueryParams
    , req : Request
    }


type alias QueryParams =
    { searchTerm : Maybe String
    , page : Maybe Int
    }


init : Request -> ( Model, Effect Msg )
init req =
    let
        params =
            getQueryParams req
    in
    ( Model Loading Navbar.init params req
    , case params.searchTerm of
        Just _ ->
            Effect.fromCmd <|
                getPosts <|
                    Maybe.withDefault "" req.url.query

        Nothing ->
            Effect.none
    )


getQueryParams : Request -> QueryParams
getQueryParams req =
    QueryParams
        (Dict.get "s" req.query
            |> Maybe.andThen
                (\q ->
                    case q of
                        "" ->
                            Nothing

                        s ->
                            Just s
                )
        )
        (Dict.get "page" req.query
            |> Maybe.withDefault ""
            |> String.toInt
        )


getPosts : String -> Cmd Msg
getPosts query =
    Http.get
        { --
          url = "/api/posts?" ++ query
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title =
        case model.query.searchTerm of
            Just s ->
                "\"" ++ s ++ "\" - Search Results"

            Nothing ->
                "Search Page"
    , body =
        [ Navbar.view
            shared
            model.navbarModel
            NavbarMsg
        , viewPosts model
        ]
    }


viewPosts : Model -> Html Msg
viewPosts model =
    case model.query.searchTerm of
        Just term ->
            main_ [ class "search-results" ]
                [ h2 [ class "heading" ]
                    [ text <|
                        "Search Results for \""
                            ++ term
                            ++ "\""
                    ]
                , renderPostsData model.posts noResults
                ]

        Nothing ->
            div [ class "no-search-term" ] [ p [] [ text "You can search for a post at the top-right corner of this window" ] ]


noResults : Html msg
noResults =
    div [ class "no-posts-to-show" ] [ p [] [ text "No posts match your search" ] ]
