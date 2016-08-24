#!/bin/bash
while ! nc -q 1 localhost 4222 </dev/null; do echo "Waiting for NATS..."; sleep 2; done
eval $@
