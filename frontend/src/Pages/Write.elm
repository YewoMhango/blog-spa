module Pages.Write exposing (Model, Msg, page)

import Effect exposing (Effect)
import File exposing (File)
import Gen.Params.Write exposing (Params)
import Gen.Route
import Html exposing (Html, a, button, div, h1, h3, input, label, main_, table, td, text, textarea, tr)
import Html.Attributes exposing (accept, class, disabled, for, href, id, multiple, style, type_)
import Html.Events exposing (on, onClick, onInput)
import Http
import Json.Decode
import Markdown
import Maybe exposing (Maybe)
import Navbar
import Page
import Request
import Shared exposing (CSRFToken)
import Task
import Utils exposing (allNotEmptyStrings, flipBool, httpErrorAsText, smallLoadingSpinner)
import View exposing (View)



-- HOME PAGE


page : Shared.Model -> Request.With Params -> Page.With Model Msg
page shared req =
    Page.protected.advanced <|
        \_ ->
            { view = view shared
            , init = init shared.csrfToken
            , update = update req
            , subscriptions = subscriptions
            }



-- MODEL


type alias Model =
    { navbarModel : Navbar.Model
    , title : String
    , summary : String
    , thumbnail : Maybe File
    , thumbnailPreview : String
    , postContent : String
    , currentTab : Tab
    , publishStatus : PublishStatus
    , csrfToken : CSRFToken
    }


type PublishStatus
    = Writing
    | Uploading
    | GotResponse (Result Http.Error String)


init : CSRFToken -> ( Model, Effect Msg )
init csrfToken =
    ( { navbarModel = Navbar.init
      , title = ""
      , summary = ""
      , thumbnail = Nothing
      , postContent = ""
      , thumbnailPreview = ""
      , currentTab = Input
      , publishStatus = Writing
      , csrfToken = csrfToken
      }
    , Effect.none
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.Msg
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


update : Request.With Params -> Msg -> Model -> ( Model, Effect Msg )
update req msg model =
    case msg of
        NavbarMsg innerMsg ->
            Navbar.update model innerMsg req

        NavbarInputMsg value ->
            Navbar.updateSearchInput model value req

        GotTitle title ->
            ( { model | title = title }
            , Effect.none
            )

        GotPostContent content ->
            ( { model | postContent = content }
            , Effect.none
            )

        SwitchToInputTab ->
            ( { model | currentTab = Input }
            , Effect.none
            )

        SwitchToPreviewTab ->
            ( { model | currentTab = Preview }
            , Effect.none
            )

        GotSummary summary ->
            ( { model | summary = summary }
            , Effect.none
            )

        GotThumbnailFile file _ ->
            ( { model | thumbnail = Just file }
            , Effect.fromCmd <| Task.perform GotPreview (File.toUrl file)
            )

        GotPreview preview ->
            ( { model | thumbnailPreview = preview }, Effect.none )

        PublishPost ->
            case model.thumbnail of
                Just thumbnail ->
                    ( { model | publishStatus = Uploading }
                    , Effect.fromCmd <|
                        Http.post
                            { url = "/api/publish"
                            , body =
                                Http.multipartBody
                                    [ Http.stringPart "csrfmiddlewaretoken" model.csrfToken
                                    , Http.stringPart "title" model.title
                                    , Http.stringPart "summary" model.summary
                                    , Http.stringPart "postContent" model.postContent
                                    , Http.filePart "thumbnail" thumbnail
                                    ]
                            , expect = Http.expectString Uploaded
                            }
                    )

                Nothing ->
                    ( model, Effect.none )

        Uploaded result ->
            ( { model | publishStatus = GotResponse result }
            , case result of
                Ok postUrlSlug ->
                    Effect.fromCmd <|
                        Request.pushRoute
                            (Gen.Route.Post__Title_
                                { title = postUrlSlug
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
    { title = "Write a New Blog Post"
    , body =
        [ Navbar.view shared model.navbarModel NavbarMsg NavbarInputMsg
        , viewWriter model
        ]
    }


viewWriter : Model -> Html Msg
viewWriter model =
    main_ [ class "writer-page" ]
        [ div [ class "container" ]
            [ h1 [] [ text "Write a New Blog Post" ]
            , table []
                [ tr []
                    [ td [] [ label [ for "title" ] [ text "Title:" ] ]
                    , td [] [ input [ id "title", type_ "text", onInput GotTitle ] [] ]
                    ]
                , tr []
                    [ td [] [ label [ for "summary" ] [ text "Summary:" ] ]
                    , td [] [ textarea [ id "summary", onInput GotSummary ] [] ]
                    ]
                , tr []
                    [ td [] [ label [ for "thumbnail" ] [ text "Thumbnail:" ] ]
                    , td []
                        [ input
                            [ type_ "file"
                            , multiple False
                            , on "change" fileDecoder
                            , accept "image/*"
                            , id "thumbnail"
                            ]
                            []
                        , viewThumbnailPreview model.thumbnailPreview
                        ]
                    ]
                ]
            , h3 [ class "content-heading" ]
                [ text "Post Content (in "
                , a [ href "https://www.markdownguide.org/basic-syntax/" ]
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
                        ]
                        []
                    , Markdown.toHtml
                        [ class <| "preview " ++ tabSelected model Preview ]
                        model.postContent
                    ]
                ]
            , div [ class "uploading-errors" ]
                [ text
                    (case model.publishStatus of
                        GotResponse (Err error) ->
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
                            isPublishable model
                    , onClick PublishPost
                    ]
                    (case model.publishStatus of
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
        ]


tabSelected : Model -> Tab -> String
tabSelected model tab =
    if model.currentTab == tab then
        "selected"

    else
        ""


viewThumbnailPreview : String -> Html msg
viewThumbnailPreview url =
    div
        [ class "thumbnail-preview"
        , style "height"
            (if url /= "" then
                "135px"

             else
                ""
            )
        , style "background-image" <| "url('" ++ url ++ "')"
        ]
        []


isPublishable : Model -> Bool
isPublishable model =
    if
        allNotEmptyStrings
            [ model.title
            , model.summary
            , model.postContent
            ]
            && model.thumbnail
            /= Nothing
            && model.publishStatus
            /= Uploading
    then
        True

    else
        False
