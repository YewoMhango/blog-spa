module Pages.Post.Title_.Edit exposing (Model, Msg, page)

import Effect exposing (Effect)
import File exposing (File)
import Footer
import Gen.Params.Edit.Title_ exposing (Params)
import Gen.Route
import Html exposing (Html, a, button, div, h1, h3, input, label, main_, table, td, text, textarea, tr)
import Html.Attributes exposing (accept, class, disabled, for, href, id, multiple, target, type_, value)
import Html.Events exposing (on, onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, int, map7, string)
import Markdown
import Navbar exposing (requestFromRequestWithParams)
import Page
import Pages.Post.Title_ exposing (Post, postLoadingAnimation)
import Pages.Write exposing (viewThumbnailPreview)
import Request
import Shared exposing (CSRFToken)
import Task
import Utils exposing (RemoteData(..), allNotEmptyStrings, flipBool, httpErrorAsText, renderHttpError, smallLoadingSpinner)
import View exposing (View)



-- HOME PAGE


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.protected.advanced <|
        \_ ->
            { view = view shared
            , init = init shared.csrfToken req
            , update = update req
            , subscriptions = subscriptions
            }



-- MODEL


type alias Model =
    { navbarModel : Navbar.Model
    , currentTab : Tab
    , editStatus : EditStatus
    , csrfToken : CSRFToken
    , post : RemoteData Post Http.Error
    , newThumbnail : Maybe File
    , newThumbnailPreview : String
    }


type EditStatus
    = Editing
    | Uploading
    | GotUploadResponse (Result Http.Error String)


init : CSRFToken -> Request.With Params -> ( Model, Effect Msg )
init csrfToken req =
    ( { navbarModel = Navbar.init
      , post = Loading
      , currentTab = Input
      , editStatus = Editing
      , csrfToken = csrfToken
      , newThumbnail = Nothing
      , newThumbnailPreview = ""
      }
    , Effect.fromCmd <| getPost req.params.title
    )



-- UPDATE


type Msg
    = GotPost (Result Http.Error Post)
    | NavbarMsg Navbar.Msg
    | NavbarInputMsg String
    | GotTitle String
    | GotSummary String
    | GotPostContent String
    | SwitchToInputTab
    | SwitchToPreviewTab
    | GotThumbnailFile File (List File)
    | GotPreview String
    | PublishPost
    | Uploaded (Result Http.Error String)


type Tab
    = Input
    | Preview


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


update : Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        NavbarMsg innerMsg ->
            Navbar.update model innerMsg (requestFromRequestWithParams req)

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value (requestFromRequestWithParams req)

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

        GotTitle title ->
            ( case model.post of
                Successful post ->
                    { model
                        | post =
                            Successful
                                { post
                                    | title = title
                                }
                    }

                _ ->
                    model
            , Effect.none
            )

        GotPostContent content ->
            ( case model.post of
                Successful post ->
                    { model
                        | post =
                            Successful
                                { post
                                    | content = content
                                }
                    }

                _ ->
                    model
            , Effect.none
            )

        GotSummary summary ->
            ( case model.post of
                Successful post ->
                    { model
                        | post =
                            Successful
                                { post
                                    | summary = summary
                                }
                    }

                _ ->
                    model
            , Effect.none
            )

        GotThumbnailFile file _ ->
            ( { model | newThumbnail = Just file }
            , Effect.fromCmd <| Task.perform GotPreview (File.toUrl file)
            )

        GotPreview preview ->
            ( { model | newThumbnailPreview = preview }, Effect.none )

        SwitchToInputTab ->
            ( { model | currentTab = Input }
            , Effect.none
            )

        SwitchToPreviewTab ->
            ( { model | currentTab = Preview }
            , Effect.none
            )

        PublishPost ->
            case model.post of
                Successful post ->
                    ( { model | editStatus = Uploading }
                    , Effect.fromCmd <|
                        Http.post
                            { url = "/api/update_post/" ++ req.params.title
                            , body =
                                Http.multipartBody
                                    [ Http.stringPart "csrfmiddlewaretoken" model.csrfToken
                                    , Http.stringPart "title" post.title
                                    , Http.stringPart "summary" post.summary
                                    , Http.stringPart "postContent" post.content
                                    , case model.newThumbnail of
                                        Just thumbnail ->
                                            Http.filePart "thumbnail" thumbnail

                                        Nothing ->
                                            Http.stringPart "" ""
                                    ]
                            , expect = Http.expectString Uploaded
                            }
                    )

                _ ->
                    ( model, Effect.none )

        Uploaded result ->
            ( { model | editStatus = GotUploadResponse result }
            , case result of
                Ok _ ->
                    Effect.fromCmd <|
                        Request.pushRoute
                            (Gen.Route.Post__Title_
                                { title = req.params.title
                                }
                            )
                            req

                Err _ ->
                    Effect.none
            )


fileDecoder : Json.Decode.Decoder Msg
fileDecoder =
    Json.Decode.at [ "target", "files" ]
        (Json.Decode.oneOrMore
            GotThumbnailFile
            File.decoder
        )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Shared.Model -> Model -> View Msg
view shared model =
    { title = "Editing a Blog Post"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg NavbarInputMsg
        , viewWriter model
        , Footer.view
        ]
    }


viewWriter : Model -> Html Msg
viewWriter model =
    main_ [ class "writer-page" ]
        [ div [ class "container" ]
            (case model.post of
                Loading ->
                    postLoadingAnimation

                Successful post ->
                    [ h1 [] [ text "Write a New Blog Post" ]
                    , table []
                        [ tr []
                            [ td [] [ label [ for "title" ] [ text "Title:" ] ]
                            , td []
                                [ input
                                    [ id "title"
                                    , type_ "text"
                                    , onInput GotTitle
                                    , value post.title
                                    ]
                                    []
                                ]
                            ]
                        , tr []
                            [ td [] [ label [ for "summary" ] [ text "Summary:" ] ]
                            , td []
                                [ textarea
                                    [ id "summary"
                                    , onInput GotSummary
                                    , value post.summary
                                    ]
                                    []
                                ]
                            ]
                        , tr []
                            [ td [] [ label [ for "thumbnail" ] [ text "New Thumbnail:" ] ]
                            , td []
                                [ input
                                    [ type_ "file"
                                    , multiple False
                                    , on "change" fileDecoder
                                    , accept "image/*"
                                    , id "thumbnail"
                                    ]
                                    []
                                , viewThumbnailPreview model.newThumbnailPreview
                                ]
                            ]
                        ]
                    , h3 [ class "content-heading" ]
                        [ text "Post Content (in "
                        , a
                            [ href "https://www.markdownguide.org/basic-syntax/"
                            , target "_blank"
                            ]
                            [ text "Markdown format" ]
                        , text "):"
                        ]
                    , div [ class "post-content" ]
                        [ div
                            [ class "labels " ]
                            [ label
                                [ class <| tabSelected model Input
                                , for "content-input"
                                , onClick SwitchToInputTab
                                ]
                                [ text "Your input" ]
                            , label
                                [ class <| tabSelected model Preview
                                , onClick SwitchToPreviewTab
                                ]
                                [ text "Preview" ]
                            ]
                        , div [ class "input-and-preview" ]
                            [ textarea
                                [ id "content-input"
                                , class <| tabSelected model Input
                                , onInput GotPostContent
                                , value post.content
                                ]
                                []
                            , Markdown.toHtml
                                [ class <| "preview " ++ tabSelected model Preview ]
                                post.content
                            ]
                        ]
                    , div [ class "uploading-errors" ]
                        [ text
                            (case model.editStatus of
                                GotUploadResponse (Err error) ->
                                    let
                                        errorText =
                                            httpErrorAsText error
                                    in
                                    Tuple.first errorText
                                        ++ (Maybe.withDefault "" <|
                                                Tuple.second errorText
                                           )

                                _ ->
                                    ""
                            )
                        ]
                    , div [ class "publish-button-container" ]
                        [ button
                            [ class "confirm"
                            , disabled <|
                                flipBool <|
                                    isPublishable post model
                            , onClick PublishPost
                            ]
                            (case model.editStatus of
                                Uploading ->
                                    [ smallLoadingSpinner True
                                    , text
                                        "Uploading..."
                                    ]

                                _ ->
                                    [ text "Publish"
                                    ]
                            )
                        ]
                    ]

                Failed error ->
                    [ renderHttpError error ]
            )
        ]


tabSelected : Model -> Tab -> String
tabSelected model tab =
    if model.currentTab == tab then
        "selected"

    else
        ""


isPublishable : Post -> Model -> Bool
isPublishable post model =
    if
        allNotEmptyStrings
            [ post.title
            , post.summary
            , post.content
            ]
            && model.editStatus
            == Editing
    then
        True

    else
        False
