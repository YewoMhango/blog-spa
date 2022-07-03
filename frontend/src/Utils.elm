module Utils exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
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


type RemoteData data error
    = Loading
    | RequestDone (Result error data)


renderHttpError : Http.Error -> Html msg
renderHttpError error =
    div [ class "loading-error" ]
        [ text <| httpErrorAsText error]

httpErrorAsText: Http.Error -> String 
httpErrorAsText error = 
    (case error of
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
    )