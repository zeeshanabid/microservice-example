# Shopping cart using μ-services
This is a simple shopping cart application built on microservice architecture. All the services are small and simple. All of the services are written in different languages. They communicate via [NATS](http://nats.io/ "NATS").

## How to run?
Install the following requirements to run this application:

```
Vagrant >= 1.8.5
VirtualBox >= 5.1.2
```

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

Foreman will start all the services and the logs will be displayed on STDOUT. Now let's bootstarp the service with some data. Open another terminal and add some data.

``` shell
vagrant ssh
cd /opt/src
ruby2.0 bootstrap.rb
```

This will add some random data. Now point your browser to [http://localhost:8080/Main.elm] (http://localhost:8080/Main.elm) to run the application. You will see a shopping cart with some sample data. You can play around by adding and removing some products to the cart. The cart will update itself automatically.

This is just an example to show how microservices can interact with each other without using REST as the communication. The application does not perform any sanity checks.
