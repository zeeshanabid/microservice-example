module ProductList exposing (Model, OutMsg(..), Msg, init, update, view, refresh)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Task
import Json.Decode as Json exposing((:=))


type alias ProductId = String
type alias Product =
  { id:       ProductId
  , name:     String
  , price:    Int
  , currency: String
  , stock:    Int
  }


type alias ProductList = List Product
type alias Model =
  { name     : String
  , products : ProductList
  }


init : String -> (Model, Cmd Msg)
init name =
  ( Model name []
  , getProducts
  )


type Msg
  = GetProducts
  | FetchSucceed     ProductList
  | FetchFail        Http.Error
  | Add ProductId    Int
  | Remove ProductId Int

type OutMsg
    = SomethingWentWrong Http.Error
    | AddToCart          ProductId Int
    | RemoveFromCart     ProductId Int


update : Msg -> Model -> (Model, Cmd Msg, Maybe OutMsg)
update msg model =
  case msg of
    GetProducts ->
      (model, getProducts, Nothing)

    FetchSucceed newProducts ->
      (Model model.name newProducts, Cmd.none, Nothing)

    FetchFail err ->
      (model, Cmd.none, Just (SomethingWentWrong err))

    Add productId quantity ->
      (model, Cmd.none, Just (AddToCart productId quantity))

    Remove productId quantity ->
      (model, Cmd.none, Just (RemoveFromCart productId quantity))


refresh : Model -> (Model, Cmd Msg)
refresh model = (model, getProducts)


viewProduct product =
  div [] [
    strong[][ text <| product.name ]
    , br[][]
    , formatPrice product.price product.currency
    , br[][]
    , formatStock product.stock
    , br[][]
    , button [ onClick <| Add product.id 1] [ text "Add" ]
    , button [ onClick <| Remove product.id 1] [ text "Remove" ]
    , br[][]
    , hr [][]
  ]


formatPrice : Int -> String -> Html Msg
formatPrice price currency =
  span [] [
   text <| "Price: " ++ toString price ++ " " ++ currency
  ]


formatStock : Int -> Html Msg
formatStock stock =
  span [] [
   text <| "Stock: " ++ toString stock
  ]


view : Model -> Html Msg
view model =
  div []
    [ h2 [] [ text model.name ]
    , div [] (List.map viewProduct model.products)
    , br [] []
    , button [ onClick GetProducts ] [ text "Get products!" ]
    ]


getProducts : Cmd Msg
getProducts =
  let
    url =
      "http://localhost:8000/product"
  in
    Task.perform FetchFail FetchSucceed (Http.get decodeProducts url)


productDecoder : Json.Decoder Product
productDecoder =
  Json.object5 Product
    ("id"       := Json.string)
    ("name"     := Json.string)
    ("price"    := Json.int)
    ("currency" := Json.string)
    ("stock"    := Json.int)


decodeProducts : Json.Decoder ProductList
decodeProducts =
  Json.list productDecoder
