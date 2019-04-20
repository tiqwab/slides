#!/bin/bash

set -eu

readonly ES_HOST=localhost
readonly ES_PORT=9200
readonly ES_INDEX=index1
readonly ES_TYPE=_doc

request=$(cat <<EOF
{
  "name": "Alice",
  "age": 21,
  "registered_at": "2019-04-23T03:00:00Z"
}
EOF
)

response=$(curl -XPOST -H "Content-Type: application/json" \
    http://$ES_HOST:$ES_PORT/$ES_INDEX/$ES_TYPE \
    -d "$request")

# output id
echo $response | jq -r '._id'
