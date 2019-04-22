#!/bin/bash

set -eu

request=

curl -XPOST -H "Content-Type: application/json" \
    http://$ES_HOST:$ES_PORT/$ES_INDEX/$ES_TYPE \
    -d "$request"

