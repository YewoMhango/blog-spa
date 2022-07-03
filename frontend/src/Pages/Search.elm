module Pages.Search exposing (Model, Msg, page)

import Dict
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
page _ req =
    Page.element
        { view = view
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


init : Request -> ( Model, Cmd Msg )
init req =
    let
        params =
            getQueryParams req
    in
    ( Model Loading Navbar.init params req
    , case params.searchTerm of
        Just _ ->
            getPosts <| Maybe.withDefault "" req.url.query

        Nothing ->
            Cmd.none
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( case msg of
        GotPosts result ->
            { model | posts = RequestDone result }

        NavbarMsg innerMsg ->
            { model | navbarModel = Navbar.update model.navbarModel innerMsg }
    , Cmd.none
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title =
        case model.query.searchTerm of
            Just s ->
                "\"" ++ s ++ "\" - Search Results"

            Nothing ->
                "Search Page"
    , body =
        [ Navbar.view model.navbarModel NavbarMsg
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
