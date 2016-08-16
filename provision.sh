#!/usr/bin/env bash

apt-get update
curl -sSL https://get.docker.com/ | sh
usermod -aG docker vagrant
curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
