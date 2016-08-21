import Html exposing (..)
import Html.App as App
import Html.Attributes exposing (..)
import ProductList exposing (OutMsg(..))
import Cart exposing (OutMsg(..))
import Debug
import OutMessage


main =
  App.program
    { init = init "Products" "Cart"
    , view = view
    , update = update
    , subscriptions = subscriptions
    }


type alias Model =
  { products : ProductList.Model
  , cart     : Cart.Model
  }


init : String -> String -> ( Model, Cmd Msg )
init productListName cartName =
  let
    (products, productsFx) =
      ProductList.init productListName

    (cart, cartFx) =
      Cart.init cartName
  in
    ( Model products cart
    , Cmd.batch
        [ Cmd.map Products productsFx
        , Cmd.map Cart cartFx
        ]
    )


type Msg
  = Products ProductList.Msg
  | Cart     Cart.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Products productsMsg ->
      ProductList.update productsMsg model.products
        |> OutMessage.mapComponent
                (\newProducts -> Model newProducts model.cart)
        |> OutMessage.mapCmd Products
        |> OutMessage.evaluateMaybe interpretProductOutMsg Cmd.none
    Cart cartMsg ->
      Cart.update cartMsg model.cart
        |> OutMessage.mapComponent
                (\newCart -> Model model.products newCart)
        |> OutMessage.mapCmd Cart
        |> OutMessage.evaluateMaybe interpretCartOutMsg Cmd.none


interpretCartOutMsg : Cart.OutMsg -> Model -> (Model, Cmd Msg)
interpretCartOutMsg outmsg model =
    case outmsg of
        CartUpdated ->
          let
            (newProducts, productsMsg) = ProductList.refresh model.products
          in
            ({ model | products = newProducts}, Cmd.map Products productsMsg)


interpretProductOutMsg : ProductList.OutMsg -> Model -> (Model, Cmd Msg)
interpretProductOutMsg outmsg model =
    case outmsg of
        SomethingWentWrong err ->
          let
            error = Debug.log "Cannot retrieve products:" (toString err)
          in
            (model, Cmd.none)
        AddToCart productId quantity ->
          let
            (newCart, cartMsg) = Cart.addToCart model.cart productId quantity
          in
          ({ model | cart = newCart}, Cmd.map Cart cartMsg)
        RemoveFromCart productId quantity ->
          let
            (newCart, cartMsg) = Cart.removeFromCart model.cart productId quantity
          in
          ({ model | cart = newCart}, Cmd.map Cart cartMsg)


view : Model -> Html Msg
view model =
  div[][
      App.map Products (ProductList.view model.products)
    , App.map Cart (Cart.view model.cart)
  ]


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none
