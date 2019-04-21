#!/bin/bash

set -eu

readonly ES_HOST=localhost
readonly ES_PORT=9200
readonly ES_INDEX=index1
readonly ES_TYPE=_doc

request=$(cat <<EOF
{
  "refresh_interval": "30s"
}
EOF
)

curl -XPUT -H "Content-Type: application/json" \
    http://$ES_HOST:$ES_PORT/$ES_INDEX/_settings \
    -d "$request"
