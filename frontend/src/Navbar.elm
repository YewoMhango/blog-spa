module Navbar exposing (Model, Msg, init, requestFromRequestWithParams, update, updateSearchInput, view)

import Effect exposing (Effect)
import Gen.Route
import Html exposing (a, aside, button, div, form, img, input, li, nav, ol, text)
import Html.Attributes exposing (action, class, href, name, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
import Request
import Shared
import Utils exposing (flipBool, smallLoadingSpinner)


type alias Model =
    { menuOpen : Bool
    , searchFieldShown : Bool
    , searchInput : String
    }


init : Model
init =
    Model False False ""


type Msg
    = ToggleMenu
    | SearchInputOpened
    | SearchInputEntered String
    | FormSubmit
    | Logout


update : { m | navbarModel : Model } -> Msg -> Request.Request -> ( { m | navbarModel : Model }, Effect msg )
update mainModel msg req =
    let
        navbarModel =
            mainModel.navbarModel
    in
    case msg of
        ToggleMenu ->
            ( { mainModel
                | navbarModel =
                    { navbarModel
                        | menuOpen =
                            flipBool mainModel.navbarModel.menuOpen
                    }
              }
            , Effect.none
            )

        SearchInputOpened ->
            ( { mainModel
                | navbarModel =
                    { navbarModel
                        | searchFieldShown =
                            flipBool mainModel.navbarModel.searchFieldShown
                    }
              }
            , Effect.none
            )

        Logout ->
            ( mainModel, Effect.fromShared Shared.SignOut )

        SearchInputEntered input ->
            ( { mainModel
                | navbarModel =
                    { navbarModel
                        | searchInput =
                            input
                    }
              }
            , Effect.none
            )

        FormSubmit ->
            ( mainModel
            , Effect.fromCmd <|
                Request.pushRoute
                    (Gen.Route.Search__Keywords_ { keywords = navbarModel.searchInput })
                    req
            )


updateSearchInput : { m | navbarModel : Model } -> String -> Request.Request -> ( { m | navbarModel : Model }, Effect msg )
updateSearchInput mainModel input req =
    update mainModel (SearchInputEntered input) req


view : Shared.Model -> Model -> (Msg -> msg) -> (String -> msg) -> Html.Html msg
view shared model toMsg inputMsg =
    let
        className =
            "navbar"
                ++ (if model.menuOpen then
                        " menu-open"

                    else
                        ""
                   )
                ++ (if model.searchFieldShown then
                        " search-showing"

                    else
                        ""
                   )
    in
    nav
        [ class className
        ]
        [ aside [ class "overlay", onClick (toMsg ToggleMenu) ] []
        , button [ class "menu-button", onClick (toMsg ToggleMenu) ] [ div [] [], div [] [] ]
        , a [ class "logo", href "/" ] [ img [ src "/static/logo.svg" ] [] ]
        , div [ class "nav-right" ]
            [ ol [ class "nav-links", type_ "none" ]
                (List.concat
                    [ [ li [] [ a [ href "/" ] [ text "Home" ] ]
                      , li [] [ a [ href "/about" ] [ text "About" ] ]
                      ]
                    , if shared.user.isAuthenticated then
                        List.append
                            (if shared.user.canPost then
                                [ li []
                                    [ a [ href "/write" ]
                                        [ text "Write" ]
                                    ]
                                ]

                             else
                                []
                            )
                            [ li [] [ a [ onClick <| toMsg Logout ] [ text "Logout" ] ]
                            ]

                      else
                        [ li [] [ a [ href "/login" ] [ text "Login" ] ]
                        , li [] [ a [ href "/sign-up" ] [ text "Sign-Up" ] ]
                        ]
                    , [ li
                            [ class "loading-spinner-container"
                            ]
                            [ smallLoadingSpinner
                                shared.syncingAuthentication
                            ]
                      ]
                    ]
                )
            , form [ action "/search", onSubmit <| toMsg FormSubmit ]
                [ input
                    [ type_ "search"
                    , placeholder "Search"
                    , name "s"
                    , onInput inputMsg
                    , value model.searchInput
                    ]
                    []
                ]
            , button [ class "search-button", onClick (toMsg SearchInputOpened) ] [ div [] [], div [] [] ]
            ]
        ]


requestFromRequestWithParams : Request.With params -> Request.Request
requestFromRequestWithParams req =
    { url = req.url
    , key = req.key
    , route = req.route
    , params = ()
    , query = req.query
    }
