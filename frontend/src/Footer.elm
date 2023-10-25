module Footer exposing (..)

import Html exposing (a, div, footer, img)
import Html.Attributes exposing (class, href, src, target)


view : Html.Html msg
view =
    footer
        []
        [ div [ class "social-links" ]
            [ a [ href "mailto:mhangoyewoh@gmail.com", target "_blank" ]
                [ img [ src "/static/gmail.svg" ] [] ]
            , a [ href "https://www.linkedin.com/in/yewo-mhango/", target "_blank" ]
                [ img [ src "/static/LinkedIn.svg" ] [] ]
            , a [ href "https://github.com/YewoMhango", target "_blank" ]
                [ img [ src "/static/github.svg" ] [] ]
            , a [ href "https://yewomhango.github.io", target "_blank" ]
                [ img [ src "/static/web.svg" ] [] ]
            ]
        ]
