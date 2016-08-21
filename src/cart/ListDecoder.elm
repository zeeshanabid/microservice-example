import Html exposing (..)
import Task exposing (Task, andThen)
import Json.Decode exposing (Decoder, int, string, list, at, (:=), object1)
import Dict exposing (Dict)

import Http

mailbox =
  Signal.mailbox []

-- VIEW

main : Signal Element
main =
  Signal.map show mailbox.signal


-- TASK

fetchApi =
  Http.get decoder api

handleResponse data =
  Signal.send mailbox.address data

fullNameDecoder : Decoder String
fullNameDecoder =
  object1 identity ("full_name" := string)

decoder =
  at ["items"] (list fullNameDecoder)

port run : Task Http.Error ()
port run =
  fetchApi `andThen` handleResponse

api =
  "https://api.github.com/search/repositories?q=language:elm&sort=starts&language=elm"
