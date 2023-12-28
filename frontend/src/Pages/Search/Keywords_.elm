module Pages.Search.Keywords_ exposing (Model, Msg, page)

import Dict
import Effect exposing (Effect)
import Footer
import Gen.Params.Search.Keywords_ exposing (Params)
import Html exposing (Html, div, h1, main_, p, text)
import Html.Attributes exposing (class)
import Http
import Json.Decode exposing (Decoder, field, map5, string)
import Navbar
import Page
import Pages.Home_ exposing (PostDetails, renderPostsData)
import Request
import Shared
import Url
import Utils exposing (RemoteData(..))
import View exposing (View)


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.advanced
        { init = init req
        , update = update req
        , view = view shared
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { posts : RemoteData (List PostDetails) Http.Error
    , navbarModel : Navbar.Model
    , query : QueryParams
    , req : Request.With Params
    }


type alias QueryParams =
    { searchTerm : String
    , page : Maybe Int
    }


init : Request.With Params -> ( Model, Effect Msg )
init req =
    let
        params =
            getQueryParams req

        navModel =
            Navbar.init
    in
    ( Model Loading
        { navModel
            | searchInput =
                Maybe.withDefault "" <|
                    Url.percentDecode params.searchTerm
        }
        params
        req
    , Effect.fromCmd <|
        getPosts params
    )


getQueryParams : Request.With Params -> QueryParams
getQueryParams req =
    QueryParams
        req.params.keywords
        (Dict.get "page" req.query
            |> Maybe.withDefault ""
            |> String.toInt
        )


getPosts : QueryParams -> Cmd Msg
getPosts params =
    let
        pageUrlQuery =
            case params.page of
                Just n ->
                    "&page=" ++ String.fromInt n

                Nothing ->
                    ""

        query =
            "s=" ++ params.searchTerm ++ "&page=" ++ pageUrlQuery
    in
    Http.get
        { --
          url = "/api/posts?" ++ query
        , expect = Http.expectJson GotPosts postsDecoder
        }


postsDecoder : Decoder (List PostDetails)
postsDecoder =
    Json.Decode.list
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
    | NavbarInputMsg String


update : Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
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
            Navbar.update model innerMsg <| Navbar.requestFromRequestWithParams req

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value <| Navbar.requestFromRequestWithParams req



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title =
        if model.query.searchTerm == "" then
            "Search Page"

        else
            "\"" ++ (Maybe.withDefault "" <| Url.percentDecode model.query.searchTerm) ++ "\" - Search Results"
    , body =
        [ Navbar.view
            shared
            model.navbarModel
            NavbarMsg
            NavbarInputMsg
        , viewPosts model
        , Footer.view
        ]
    }


viewPosts : Model -> Html Msg
viewPosts model =
    if model.query.searchTerm /= "" then
        main_ [ class "search-results" ]
            [ h1 [ class "heading" ]
                [ text <|
                    "Search Results for \""
                        ++ (Maybe.withDefault "" <| Url.percentDecode model.query.searchTerm)
                        ++ "\""
                ]
            , renderPostsData model.posts noResults
            ]

    else
        div [ class "no-search-term" ] [ p [] [ text "You can search for a post at the top-right corner of this window" ] ]


noResults : Html msg
noResults =
    div [ class "no-posts-to-show" ] [ p [] [ text "No posts match your search" ] ]
