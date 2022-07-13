module Utils exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class, hidden, style)
import Http exposing (Error(..))


{-|

    Changes a `True` to a `False` and a `False` to a `True`

-}
flipBool : Bool -> Bool
flipBool bool =
    if bool then
        False

    else
        True


allNotEmptyStrings : List String -> Bool
allNotEmptyStrings list =
    case list of
        head :: rest ->
            if head == "" then
                False

            else
                True && allNotEmptyStrings rest

        [] ->
            True


type RemoteData data error
    = Loading
    | RequestDone (Result error data)


renderHttpError : Http.Error -> Html msg
renderHttpError error =
    div [ class "loading-error" ]
        [ text <| httpErrorAsText error ]


httpErrorAsText : Http.Error -> String
httpErrorAsText error =
    case error of
        Http.Timeout ->
            "The request timed-out"

        Http.BadUrl details ->
            "Bad URL used: " ++ details

        Http.NetworkError ->
            "A network error occured"

        Http.BadStatus statusCode ->
            case statusCode of
                404 ->
                    "404 error: The resouce was not found"

                _ ->
                    "Bad status code returned when fetching data: " ++ String.fromInt statusCode

        Http.BadBody details ->
            "Error - Bad response body returned: " ++ details


smallLoadingSpinner : Bool -> Html.Html msg
smallLoadingSpinner visible =
    displayAnimation visible "loading-spinner small"


largeLoadingSpinner : Bool -> Html.Html msg
largeLoadingSpinner visible =
    displayAnimation visible "loading-spinner large"


tickAnimation : String -> Bool -> Html msg
tickAnimation color visible =
    div
        (if visible then
            [ class "tick-animation-container"
            , style "display" "inline-block"
            ]

         else
            [ style "display" "none" ]
        )
        [ div []
            [ div [ style "background-color" color ] []
            , div [ style "background-color" color ] []
            ]
        ]


displayAnimation : Bool -> String -> Html msg
displayAnimation visible className =
    div
        (if visible then
            [ class className, style "display" "inline-block" ]

         else
            [ style "display" "none" ]
        )
        []
