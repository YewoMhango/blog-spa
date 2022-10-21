module Utils exposing (..)

import Html exposing (Html, div, h3, p, span, text)
import Html.Attributes exposing (class, style)
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
    let
        errorText =
            httpErrorAsText error
    in
    div [ class "loading-error" ]
        [ h3 []
            [ closeIcon
            , span [] [ text <| Tuple.first errorText ]
            ]
        , p []
            [ text <|
                Maybe.withDefault "" <|
                    Tuple.second errorText
            ]
        ]


closeIcon : Html msg
closeIcon =
    div [ class "close-icon" ]
        [ div [] []
        , div [] []
        ]


httpErrorAsText : Http.Error -> ( String, Maybe String )
httpErrorAsText error =
    case error of
        Http.Timeout ->
            ( "The request timed-out", Nothing )

        Http.BadUrl details ->
            ( "Bad URL used: ", Just details )

        Http.NetworkError ->
            ( "A network error occured", Nothing )

        Http.BadStatus statusCode ->
            case statusCode of
                404 ->
                    ( "404 - The resouce was not found", Nothing )

                _ ->
                    ( "Bad status code returned when fetching data: "
                    , Just <| String.fromInt statusCode
                    )

        Http.BadBody details ->
            ( "Bad response body returned: "
            , Just <| truncateStringIfTooLong 100 details
            )


truncateStringIfTooLong : Int -> String -> String
truncateStringIfTooLong length string =
    if String.length string > length then
        String.slice 0 length string ++ "..."

    else
        string


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
