# Shopping cart using μ-services
This is a simple shopping cart application built on microservice architecture. All the services are small and simple. All of the services are written in different languages. They communicate via [nats](http://nats.io/ "nats").

## Services
There are 5 services in the system:

* Products (Ruby 2.0.0) - [products.rb](https://github.com/zeeshanabid/microservice-example/blob/master/src/products.rb)
* Inventory (Python 3.4.3) - [inventory.py](https://github.com/zeeshanabid/microservice-example/blob/master/src/inventory.py)
* Price (Elixir 1.3.2) - [Price Service] (https://github.com/zeeshanabid/microservice-example/tree/master/src/price)
* API (Go 1.6) - [API service](https://github.com/zeeshanabid/microservice-example/tree/master/src/api)
* Cart (Elm 0.17.1) - [Cart service](https://github.com/zeeshanabid/microservice-example/tree/master/src/cart)

Take a look at [Procfile](https://github.com/zeeshanabid/microservice-example/blob/master/src/Procfile) to start each of these services individually.
## How to run?

### Requirements
Install the following requirements to run this application:

```
Vagrant >= 1.8.5
VirtualBox >= 5.1.2
```

### Starting services

After the above applications has been installed, follow these steps to run the application:

``` shell
git clone git@github.com:zeeshanabid/microservice-example.git
cd microservice-example

vagrant up
```

Now the vagrant will create the virtual machine and provision will install all the necessary requirements. This might take some time. Once the virtual machine has been provisioned ssh into the machine and run the service:

``` shell
vagrant ssh
cd /opt/src
foreman start
```

Foreman will start all the services and the logs will be displayed on STDOUT. 

### Bootstrap

Now let's bootstarp the service with some data. Open another terminal and add some data.

``` shell
vagrant ssh
cd /opt/src
ruby2.0 bootstrap.rb
```

This will add some random data. Now point your browser to [http://localhost:8080/Main.elm] (http://localhost:8080/Main.elm) to run the application. You will see a shopping cart with some sample data. You can play around by adding and removing some products to the cart. The cart will update itself automatically.

This is just an example to show how microservices can interact with each other without using REST as the communication. The application does not perform any sanity checks.
