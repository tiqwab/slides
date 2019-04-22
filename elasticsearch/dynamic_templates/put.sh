#!/bin/bash

set -eu

readonly ES_HOST=localhost
readonly ES_PORT=9200
readonly ES_INDEX=index1

request=$(cat <<EOF
{
    "dynamic_templates": [
        {
            "string-double-tags": {
                "path_match": "tag.*",
                "mapping": {
                    "type": "keyword",
                    "fields": {
                        "double": {
                            "type": "double"
                        }
                    }
                }
            }
        }
    ]
}
EOF
)

curl -XPUT -H "Content-Type: application/json" \
    http://$ES_HOST:$ES_PORT/$ES_INDEX/_mapping \
    -d "$request"
