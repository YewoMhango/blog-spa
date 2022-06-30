module Navbar exposing (Model, Msg, init, update, view)

import Html exposing (a, aside, button, div, form, img, input, li, nav, ol, text)
import Html.Attributes exposing (action, class, href, name, placeholder, src, type_)
import Html.Events exposing (onClick)
import Utils exposing (flipBool)


type alias Model =
    { menuOpen : Bool
    , searchFieldShown : Bool
    }


init : Model
init =
    Model False False


type Msg
    = ToggleMenu
    | SearchInputOpened


update : Model -> Msg -> Model
update model msg =
    case msg of
        ToggleMenu ->
            { model | menuOpen = flipBool model.menuOpen }

        SearchInputOpened ->
            { model | searchFieldShown = flipBool model.searchFieldShown }


view : Model -> (Msg -> msg) -> Html.Html msg
view model toMsg =
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
        [ aside [ class "shader", onClick (toMsg ToggleMenu) ] []
        , button [ class "menu-button", onClick (toMsg ToggleMenu) ] [ div [] [], div [] [] ]
        , a [ class "logo", href "/" ] [ img [ src "/static/logo.svg" ] [] ]
        , div [ class "nav-right" ]
            [ ol [ class "nav-links", type_ "none" ]
                [ li [] [ a [ href "/" ] [ text "Home" ] ]
                , li [] [ a [ href "/write" ] [ text "Write" ] ]
                , li [] [ a [ href "/about" ] [ text "About" ] ]
                ]
            , form [ action "/search" ]
                [ input
                    [ type_ "search"
                    , placeholder "Search"
                    , name "s"
                    ]
                    []
                ]
            , button [ class "search-button", onClick (toMsg SearchInputOpened) ] [ div [] [], div [] [] ]
            ]
        ]
