module Cart exposing ( Model, Msg, OutMsg(..), init, update, view, addToCart, removeFromCart)

import Dict
import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task
import Json.Decode as Json exposing((:=))

type alias ProductId = String
type alias Quantity = Int
type alias CartItem = (ProductId, Int)


type alias Model =
  { name  : String
  , items : Dict.Dict ProductId Quantity
  }

type Msg
  = EmptyCart
  | FetchSucceed String
  | FetchFail Http.Error

type OutMsg
    = CartUpdated


init : String -> (Model, Cmd Msg)
init name =
  (Model name Dict.empty, Cmd.none)


view : Model -> Html Msg
view model =
  div [] [
  h2 [] [text <| model.name]
  , ul [] (List.map toLi <| Dict.toList model.items)
  , button [ onClick <| EmptyCart ] [text <| "Empty cart" ]
  ]


toLi : CartItem -> Html Msg
toLi (productId, quantity) =
  li [] [ text <| (toString productId) ++ ", quantity = " ++ (toString quantity) ]


updateCartItem: Quantity -> Maybe Quantity -> Maybe Quantity
updateCartItem addQuantity currentQuantity =
  case currentQuantity of
    Just quantity ->
      Just (quantity + addQuantity)
    Nothing ->
      Just addQuantity


addToCart: Model -> ProductId -> Quantity -> (Model, Cmd Msg)
addToCart model productId quantity  =
    ( { model | items = Dict.update productId (updateCartItem quantity) model.items }
    , updateStock "remove" productId
    )


removeFromCart: Model -> ProductId -> Quantity -> (Model, Cmd Msg)
removeFromCart model productId quantity  =
  ( { model | items = Dict.update productId (updateCartItem -quantity) model.items }
  , updateStock "add" productId
  )


update : Msg -> Model -> (Model, Cmd Msg, Maybe OutMsg)
update msg model =
  case msg of
    EmptyCart ->
      ({ model | items = Dict.empty }, Cmd.none, Nothing)

    FetchSucceed r ->
      (model, Cmd.none, Just CartUpdated)

    FetchFail _ ->
      (model, Cmd.none, Nothing)


updateStock : String -> ProductId -> Cmd Msg
updateStock updateStock productId =
  let
    url =
      "http://localhost:8000/product/stock/" ++ updateStock ++ "/" ++ productId
  in
    Task.perform FetchFail FetchSucceed (Http.getString url)
