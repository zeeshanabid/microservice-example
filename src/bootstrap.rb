require 'nats/client'

["TERM", "INT"].each { |sig| trap(sig) { NATS.stop } }

NATS.on_error { |err| puts "Server Error: #{err}"; exit! }

def create_product(name, price, currency, quantity)
  NATS.connect do
    NATS.request("product.add", {:name => name}.to_json) do |product_add_response|
      puts "Product response #{product_add_response}"
      product = JSON.parse product_add_response
      stock_req = "{\"product_id\": \"#{product['id']}\", \"stock\": #{quantity}}"
      NATS.request("stock.add", stock_req) do |stock_add_response|
        puts "Stock response: '#{stock_add_response}'"
        price_req = "{\"product_id\": \"#{product['id']}\", \"amount\": #{price}, \"currency\": \"#{currency}\"}"
        NATS.request("price.set", price_req) do |price_set_response|
          puts "Price response: '#{price_set_response}'"
          NATS.stop
        end
      end
    end
  end
end

NATS.start do
  ['Apples', 'Oranges', 'Grapes', 'Mangoes'].each do |product|
    create_product(product, rand(100..200), 'SEK', rand(50..100))
  end
end
