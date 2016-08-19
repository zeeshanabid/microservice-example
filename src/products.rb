require 'nats/client'
require 'securerandom'

["TERM", "INT"].each { |sig| trap(sig) { NATS.stop } }

NATS.on_error { |err| puts "Server Error: #{err}"; exit! }

QUEUE_GROUP = "product-service"
WORKER_ID   = SecureRandom.uuid

class Product
  attr_accessor :name
  attr_reader   :id

  def initialize name
    @name = name
    @id   = SecureRandom.uuid
  end

  def to_json
    {'id' => @id, 'name' => @name}.to_json
  end
end

class ProductController
  def initialize
    @products = {}
  end

  def add_product name
    product               = Product.new name
    @products[product.id] = product
    product
  end

  def product_list
    @products.values
  end

  def get_product id
    @products[id]
  end
end

product_controller = ProductController.new

NATS.start do |nc|
  puts "Worker started for '#{QUEUE_GROUP}' queue with id: #{WORKER_ID}"

  NATS.subscribe("product.list", :queue => QUEUE_GROUP) do |_, reply, sub|
    puts "Get product list at worker: #{WORKER_ID}"
    NATS.publish(reply, product_controller.product_list.to_json)
  end

  NATS.subscribe("product.get", :queue => QUEUE_GROUP) do |msg, reply, sub|
    msg = JSON.parse msg
    puts "Get product with id: #{msg['id']} at worker: #{WORKER_ID}"
    NATS.publish(reply, product_controller.get_product(msg['id']).to_json)
  end

  NATS.subscribe("product.add", :queue => QUEUE_GROUP) do |msg, reply, sub|
    msg = JSON.parse msg
    puts "Add product with name: '#{msg['name']}' at worker: #{WORKER_ID}"
    product = product_controller.add_product msg['name']
    NATS.publish reply, {'id' => product.id}.to_json if reply
  end
end
