#!/usr/bin/env bash

apt-get update
apt-get -y upgrade
apt-get install -y ruby2.0 ruby2.0-dev build-essential
gem2.0 install nats
curl -sSL https://get.docker.com/ | sh
usermod -aG docker vagrant
curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

apt-get install -y python3-pip
pip3 install asyncio-nats-client

curl -o /tmp/erlang-solutions_1.0_all.deb https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i /tmp/erlang-solutions_1.0_all.deb
apt-get update
apt-get install -y esl-erlang elixir
