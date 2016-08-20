package main
import (
  "github.com/julienschmidt/httprouter"
  "github.com/nats-io/nats"
  "encoding/json"
  "net/http"
  "time"
  "log"
  "fmt"
)

type Product struct {
    Id   string `json:"id"`
    Name string `json:"name"`
}

type Stock struct {
    ProductId string `json:"product_id"`
    Stock     int `json:"stock"`
}

type Price struct {
    ProductId string `json:"product_id"`
    Amount    int    `json:"amount"`
    Currency  string `json:"currency"`
}

type ProductResponse struct {
  Id       string `json:"id"`
  Name     string `json:"name"`
  Stock    int    `json:"stock"`
  Price    int    `json:"price"`
  Currency string `json:"currency"`
}

type Server struct {
  NatsClient *nats.Conn
  Router     *httprouter.Router
}

const DEFAULT_TIMEOUT = 50 * time.Millisecond
const (
  ADD_STOCK    = "stock.add"
  REMOVE_STOCK = "stock.remove"
  GET_STOCK    = "stock.get"
)

func (server *Server) _GetProducts() (products []Product) {
  log.Println("Getting product list from product service...")
  resp, err := server.NatsClient.Request("product.list", nil, DEFAULT_TIMEOUT)
  if err != nil {
    if server.NatsClient.LastError() != nil {
      log.Fatalf("Error in get products request: %v\n", server.NatsClient.LastError())
    }
    log.Fatalf("Error in get products request: %v\n", err)
    return
  }
  err = json.Unmarshal([]byte(string(resp.Data)), &products)
  if err != nil {
    log.Fatalf("Error in parsing products json: %v\n", err)
    return
  }
  return products
}

func (server *Server) _StockRequest(product Product, request string) (stock *Stock) {
  log.Println("Getting stock request from stock service...", request)
  jReq := fmt.Sprintf("{\"product_id\": \"%s\"}", product.Id)
  resp, err := server.NatsClient.Request(request, []byte(jReq), DEFAULT_TIMEOUT)
  if err != nil {
    if server.NatsClient.LastError() != nil {
      log.Fatalf("Error in stock request: %v\n", server.NatsClient.LastError())
    }
    log.Fatalf("Error in stock request: %v\n", err)
    return
	}
  if request == GET_STOCK {
    stock = &Stock{}
    err = json.Unmarshal([]byte(string(resp.Data)), stock)
    if err != nil {
      log.Fatalf("Error in parsing stock json: %v\n", err)
      return
    }
    return stock
  }
  return
}

func (server *Server) _GetPrice(product Product) (price Price) {
  log.Println("Getting product price from price service...")
  jReq := fmt.Sprintf("{\"product_id\": \"%s\"}", product.Id)
  resp, err := server.NatsClient.Request("price.get", []byte(jReq), DEFAULT_TIMEOUT)
  if err != nil {
    if server.NatsClient.LastError() != nil {
      log.Fatalf("Error in get price request: %v\n", server.NatsClient.LastError())
    }
    log.Fatalf("Error in get price request: %v\n", err)
    return
  }
  err = json.Unmarshal([]byte(string(resp.Data)), &price)
  if err != nil {
    log.Fatalf("Error in parsing price json: %v\n", err)
    return
  }
  return price
}

func (server *Server) GetProducts(w http.ResponseWriter, r *http.Request, _ httprouter.Params) {
  productList := server._GetProducts()
  var products []ProductResponse
  for _, p := range productList {
    var product ProductResponse
    price            := server._GetPrice(p)
    stock            := server._StockRequest(p, GET_STOCK)
    product.Id       =  p.Id
    product.Name     =  p.Name
    product.Stock    =  stock.Stock
    product.Price    =  price.Amount
    product.Currency =  price.Currency
    products         =  append(products, product)
  }
  response, _ := json.Marshal(products)
  fmt.Fprint(w, string(response))
}

func (server *Server) AddProductStock(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
  product := Product{Id: ps.ByName("product_id")}
  server._StockRequest(product, ADD_STOCK)
}

func (server *Server) RemoveProductStock(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
  product := Product{Id: ps.ByName("product_id")}
  server._StockRequest(product, REMOVE_STOCK)
}

func (server *Server) Initialize() {
  server.Router = httprouter.New()
  server.Router.GET("/product", server.GetProducts)
  server.Router.GET("/product/stock/add/:product_id", server.AddProductStock)
  server.Router.GET("/product/stock/remove/:product_id", server.RemoveProductStock)
}

func (server *Server) Start() {
  log.Println("Starting API server at port 8080")
  log.Fatal(http.ListenAndServe(":8080", server.Router))
}

func main() {
  nc, _ := nats.Connect(nats.DefaultURL)
  server := Server{NatsClient: nc}
  server.Initialize()
  server.Start()
}
